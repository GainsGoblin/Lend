// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
    function capSupply() external view returns (uint256);
    function decimals() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);
    function mint(address account, uint256 amount) external;
    function burn(address account, uint256 amount) external;
    function claimable(address) external view returns (uint); // for fsGLP
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IProtocol {
    // Value of a debt "token"
    function debtValue(address token) external view returns (uint256);

    // Interest on token since last checkpoint
    function getTokenAccruedInterest(address token) external view returns (uint256);

    // How many tokens does an user owe
    function userDebt(address account, address token) external view returns (uint256);

    // How much USD does an user owe per token
    function userDebtUSD(address account, address token) external view returns (uint256);

    // How many lent tokens is it's share token backed by
    function getShareValue(address token) external view returns (uint256);

    // How many collateral tokens is it's share token backed by
    function getCollateralShareValue() external view returns (uint256);

    // Fetch the price of an asset from Chainlink oracle
    function getLatestPrice(address token) external view returns (uint);

    // Price of GLP
    function getCollateralPrice() external view returns (uint);

    // User's health factor
    function accountHealth(address account) external view returns (uint256);

    // How much an user has borrowed in total in USD
    function accountBorrowedValue(address account) external view returns (uint256);

    // How much an user has lent in total in USD
    function accountLentValue(address account) external view returns (uint256);

    // How much is lent in total in USD
    function totalLentValue() external view returns (uint256);

    // Value of an user's collateral in USD
    function accountCollateralValue(address account) external view returns (uint256);

    // Annual interest rate of borrowing a token
    function interestRate(address token) external view returns (uint256);

    // How many tokens have been borrowed from liquidity
    function totalBorrowedAmount(address token) external view returns (uint256);

    // How many tokens can an user borrow
    function borrowingPower(address account, address token) external view returns (uint256);

    // How much can an user borrow in USD
    function borrowingPowerUSD(address account) external view returns (uint256); 
}

interface IRewardsRouter {
    function unstakeAndRedeemGlp(address _tokenOut, uint256 _glpAmount, uint256 _minOut, address _receiver) external returns (uint256);
    function mintAndStakeGlp(address _token, uint256 _amount, uint256 _minUsdg, uint256 _minGlp) external returns (uint256);
    function handleRewards(
        bool _shouldClaimGmx,
        bool _shouldStakeGmx,
        bool _shouldClaimEsGmx,
        bool _shouldStakeEsGmx,
        bool _shouldStakeMultiplierPoints,
        bool _shouldClaimWeth,
        bool _shouldConvertWethToEth
    ) external;
}

interface IRewardTracker {
    function claimable(address) external view returns (uint);
}

interface IVault {
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint) external view returns (address);
}

interface IGLPManager {
    function cooldownDuration() external view returns (uint);
}

contract WrappedGLPManager {

    using SafeMath for uint;

    IERC20 public WGLP; // Wrapped GLP
    IERC20 public weth = IERC20(0x82aF49447D8a07e3bd95BD0d56f35241523fBab1);
    IERC20 public fsGLP = IERC20(0x1aDDD80E6039594eE970E5872D247bf0414C8903);
    IProtocol public protocol; // Lending protocol
    address public governance;
    bool public canWithdraw;
    uint public checkpoint;
    IRewardsRouter public rewardsRouter = IRewardsRouter(0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1);
    IGLPManager public GLPManager = IGLPManager(0x321F653eED006AD1C29D174e17d96351BDe22649);
    IVault public vault = IVault(0x489ee077994B6658eAfA855C308275EAd8097C4A);
    mapping(address => bool) public allowedToken;

    constructor(address _protocol) {
        protocol = IProtocol(_protocol);
        checkpoint = block.timestamp;
        governance = msg.sender;
        address token;
        for (uint i=0; i<vault.allWhitelistedTokensLength(); i++) {
            token = vault.allWhitelistedTokens(i);
            allowedToken[token] = true;
            IERC20(token).approve(address(GLPManager), type(uint).max);
        }
    }

    function setWGLP(address _WGLP) external {
        require(msg.sender == governance);
        require(address(WGLP) == address(0), "WGLP already set");
        WGLP = IERC20(_WGLP);
    }
    
    function withdraw(address token, uint shareAmount) external returns (uint) {
        if(block.timestamp.sub(checkpoint) > 7200) canWithdraw = true; 
        require(canWithdraw == true, "Cannot withdraw at this time");
        uint amount = shareAmount.mul(getShareValue()).div(1e18);
        IERC20(WGLP).burn(msg.sender, shareAmount);
        uint amountWithdrawn = rewardsRouter.unstakeAndRedeemGlp(token, amount, 1, msg.sender);
        return amountWithdrawn;
    }

    function deposit(address token, uint amount) external {
        require(allowedToken[token] == true, "Token not allowed");
        require(amount > 0, "Cannot deposit 0");
        if(canWithdraw == true) {
            require(block.timestamp.sub(checkpoint) >= uint(10800).sub(GLPManager.cooldownDuration()), "Cannot deposit at this time");
            checkpoint = block.timestamp;
        }
        canWithdraw = false;
        if (WGLP.totalSupply() > 0 && fsGLP.claimable(address(this)) > 0) compound();
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        amount = rewardsRouter.mintAndStakeGlp(token, amount, 0, 1);
        uint amountToMint = amount.mul(1e18).div(getShareValue());
        IERC20(WGLP).mint(msg.sender, amountToMint);
    }

    function compound() internal {
        uint wethBefore = IERC20(weth).balanceOf(address(this));
        rewardsRouter.handleRewards(
            false,
            false,
            true,
            true,
            true,
            true,
            false
        );
        rewardsRouter.mintAndStakeGlp(
            address(weth),
            IERC20(weth).balanceOf(address(this)).sub(wethBefore),
            1,
            1
        );
    }

    function getShareValue() public view returns (uint) {
        if (WGLP.totalSupply() == 0) return 1e18;
        return fsGLP.balanceOf(address(this)).mul(1e18).div(WGLP.totalSupply());
    }
}