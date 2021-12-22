// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";

interface IERC20 {
    function totalSupply() external view returns (uint256);
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
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

interface IVault {
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint) external view returns (address);
}

interface IPriceFeed {
    function getPrice(address, bool, bool, bool) external view returns (uint256);
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

interface ILNXReward {
    function claimRewards(address account) external;
}

interface IStakeReward {
    function receiveRewards(address token, uint amount) external;
}

interface IGLPManager {
    function getAumInUsdg(bool) external view returns (uint256);
}

interface IWGLPManager {
    function getShareValue() external view returns (uint256);
    function canWithdraw() external view returns (bool);
    function compound() external;
    function withdraw(address, uint) external returns (uint256);
}

contract Protocol {

    using SafeMath for uint;

    mapping(address => bool) public borrowToken; // Token allowed to be deposited/borrowed
    mapping(address => address) public borrowShare; // Share token from lending
    mapping(address => uint) public borrowTokenBalance; // Tracks balance of deposited tokens
    mapping(address => uint) public initialLentAmount; // Tracks the amount of tokens borrowed initially; w/o interest, liquidations

    mapping(address => uint) public decimalMultiplier; // Decimals needed to normalize to 1e18
    mapping(address => uint) public tokenDebt; // Tracks amount of tokens owed
    mapping(address => mapping(address => uint)) public borrowedAmount; // User debt
    mapping(address => uint) public interestCheckpoint; // Tracks token accrued interest using time

    uint256 public totalCollateral; // Total WGLP deposited
    mapping(address => uint) public userCollateral; // WGLP deposited by users

    uint256 public totalPendingLiquidationUSD;
    uint256 public totalPendingLiquidationWGLP;
    mapping(address => uint) public tokenPendingLiquidationUSD;

    address public governance;
    IVault public vault;
    IRewardsRouter public rewardsRouter;
    IERC20 public WGLP;
    IERC20 public GLP;
    address public weth;
    uint public ltv = 50; // 50 is 50% GLP LTV
    address public lnxReward;
    address public stakeReward;
    IPriceFeed public priceFeed;
    address public GLPManager;
    IWGLPManager public WGLPManager;

    constructor(
        address _vault,
        address _rewardsRouter,
        address _GLP,
        address _weth,
        address _lnxReward,
        address _stakeReward,
        address _priceFeed,
        address _GLPManager
    ) {
        governance = msg.sender;
        vault = IVault(_vault);
        rewardsRouter = IRewardsRouter(_rewardsRouter);
        GLP = IERC20(_GLP);
        weth = _weth;
        lnxReward = _lnxReward;
        stakeReward = _stakeReward;
        priceFeed = IPriceFeed(_priceFeed);
        GLPManager = _GLPManager;
    }



    // End user functions

    function depositCollateral(uint256 amount) external {
        WGLP.transferFrom(msg.sender, address(this), amount);
        userCollateral[msg.sender] += amount;
    }

    function withdrawCollateralAll() external {
        require(accountBorrowedValue(msg.sender) == 0, "Account has debt");
        uint amount = userCollateral[msg.sender];
        withdrawCollateral(amount);
    }

    function withdrawCollateral(uint256 amount) public {
        totalCollateral -= amount;
        userCollateral[msg.sender] -= amount;
        require(accountHealth(msg.sender) >= 1e18, "Account not healthy after withdraw");
    }

    function lend(address token, uint256 amount) external {
        ILNXReward(lnxReward).claimRewards(msg.sender);
        uint transferAmount = amount;
        amount = amount.mul(10**(decimalMultiplier[token]));
        require(borrowToken[token] == true, "Token not allowed");
        uint amountToMint = amount.mul(1e18).div(getShareValue(token));
        tokenDebt[token] += getTokenAccruedInterest(token);
        interestCheckpoint[token] = block.timestamp;
        IERC20(token).transferFrom(msg.sender, address(this), transferAmount);
        IERC20(borrowShare[token]).mint(msg.sender, amountToMint);
        borrowTokenBalance[token] += amount;
    }

    function withdrawAll(address token) external {
        uint shareAmount = IERC20(borrowShare[token]).balanceOf(msg.sender);
        withdraw(token, shareAmount);
    }

    function withdraw(address token, uint256 shareAmount) public {
        ILNXReward(lnxReward).claimRewards(msg.sender);
        uint amountToSend = shareAmount.mul(getShareValue(token)).div(1e18);
        require(amountToSend > IERC20(token).balanceOf(address(this)).mul(10**decimalMultiplier[token]), "Too much borrowed from liquidity to withdraw");
        IERC20(borrowShare[token]).burn(msg.sender, shareAmount);
        borrowTokenBalance[token] -= amountToSend;
        tokenDebt[token] += getTokenAccruedInterest(token);
        interestCheckpoint[token] = block.timestamp;        
        IERC20(token).transfer(msg.sender, amountToSend.div(10**decimalMultiplier[token]));
    }

    function borrow(address token, uint256 tokenAmount) external {
        require(borrowingPower(msg.sender, token) >= tokenAmount.mul(10**decimalMultiplier[token]), "Not enough borrowing power");
        tokenDebt[token] += getTokenAccruedInterest(token);
        interestCheckpoint[token] = block.timestamp;
        borrowedAmount[msg.sender][token] += tokenAmount.mul(uint(1e18).mul(10**decimalMultiplier[token])).div(debtValue(token));
        initialLentAmount[token] += tokenAmount.mul(10**decimalMultiplier[token]);
        tokenDebt[token] += tokenAmount.mul(10**decimalMultiplier[token]); 
        IERC20(token).transfer(msg.sender, tokenAmount);
    }

    function repay(address token, uint256 tokenAmount) public {
        tokenAmount = tokenAmount.mul(10**decimalMultiplier[token]);
        uint interest = userDebt(msg.sender, token).sub(borrowedAmount[token][msg.sender]);
        uint interestPaid;
        if (tokenAmount >= interest) {
            interestPaid = interest;
        }
        else {
            interestPaid = tokenAmount;
        }
        require(tokenAmount <= userDebt(msg.sender, token), "Repaying too much");
        tokenDebt[token] += getTokenAccruedInterest(token);
        interestCheckpoint[token] = block.timestamp;
        borrowedAmount[msg.sender][token] -= tokenAmount.sub(interestPaid);
        initialLentAmount[token] -= tokenAmount.sub(interestPaid);
        tokenDebt[token] -= tokenAmount;
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount.div(10**decimalMultiplier[token]));
        IStakeReward(stakeReward).receiveRewards(token, interestPaid.div(4).div(10**decimalMultiplier[token]));
        borrowTokenBalance[token] += interestPaid.mul(3).div(4).div(10**decimalMultiplier[token]);
    }

    function repayAll(address token) external {
        repay(token, userDebt(msg.sender, token).div(10**decimalMultiplier[token]));
    }

    function liquidate(address account) external {
        require(accountHealth(account) < 1e18, "Account healthy");
        uint256 amount = userCollateral[account];
        totalPendingLiquidationWGLP += amount.mul(9).div(10);
        userCollateral[account] = 0;
        totalCollateral -= amount;
        WGLP.transfer(msg.sender, amount.mul(5).div(100));
        IStakeReward(stakeReward).receiveRewards(address(WGLP), amount.mul(5).div(100));
        address token;
        uint tokenDebtAmount;
        uint allWhitelistedTokensLength = vault.allWhitelistedTokensLength();
        for(uint i=0; i<allWhitelistedTokensLength; i++) {
            token = vault.allWhitelistedTokens(i);
            tokenDebtAmount = userDebtUSD(account, token);
            if(tokenDebtAmount > 0) {
                tokenPendingLiquidationUSD[token] += tokenDebtAmount;
                totalPendingLiquidationUSD += tokenDebtAmount;
            }
        }
        if(WGLPManager.canWithdraw() == true) {
            for(uint j=0; j<allWhitelistedTokensLength; j++) {
                token = vault.allWhitelistedTokens(j);
                if(tokenPendingLiquidationUSD[token] > 0) {
                    WGLPManager.withdraw(token, totalPendingLiquidationWGLP.mul(tokenPendingLiquidationUSD[token]).div(totalPendingLiquidationUSD));
                }
            }
        }
    }



    // Governance functions

    function setGovernance(address _governance) external {
        require(msg.sender == governance, "!Governance");
        governance = _governance;
    }

    function setBorrowToken(address token, address share) external {
        require(msg.sender == governance, "!Governance");
        require(borrowShare[token] == address(0), "!Governance");
        borrowShare[token] = share;
        borrowToken[token] = true;
        decimalMultiplier[token] = uint(18).sub(IERC20(token).decimals());
        IERC20(token).approve(GLPManager, type(uint).max);
        IERC20(token).approve(stakeReward, type(uint).max);
    }

    function setBorrowTokenAllowed(address token, bool allowed) external {
        require(msg.sender == governance, "!Governance");
        borrowToken[token] = allowed;
    }

    function setltv(uint _ltv) external {
        require(msg.sender == governance, "!Governance");
        require(_ltv <= 90 && _ltv >= 50, "Invalid LTV"); // Decreasing LTV can cause unfair liquidations, careful
        ltv = _ltv;
    }

    function setWGLP(address _WGLP) external {
        require(msg.sender == governance, "!Governance");
        require(address(WGLP) == address(0), "WGLP already set!");
        WGLP = IERC20(_WGLP);
    }

    function setWGLPManager(address _WGLPManager) external {
        require(msg.sender == governance);
        require(address(WGLPManager) == address(0));
        WGLPManager = IWGLPManager(_WGLPManager);
    }

    function rescueExcess(address token) external { // Used to rescue tokens sent to this contract without a purpose
        require(msg.sender == governance);
        require(token != address(WGLP));
        uint amount = (IERC20(token).balanceOf(address(this))).sub(borrowTokenBalance[token].sub(initialLentAmount[token]));
        require(amount > 0, "Nothing to rescue");
        IERC20(token).transfer(governance, amount);
    }



    // View functions

    // Value of a debt "token"
    function debtValue(address token) public view returns (uint256) { // 1e18 precision
        if (totalBorrowedAmount(token) == 0) return 1e18;
        return (tokenDebt[token].add(getTokenAccruedInterest(token))).mul(1e18).div(totalBorrowedAmount(token));
    }

    // Interest on token since last checkpoint
    function getTokenAccruedInterest(address token) public view returns (uint256) { // 1e18 precision
        uint secondsBorrowed = block.timestamp.sub(interestCheckpoint[token]);
        uint interest = tokenDebt[token].mul(secondsBorrowed).div(31536000); // 31536000 seconds in a year
        return interest;
    }

    // How many tokens does an user owe
    function userDebt(address account, address token) public view returns (uint256) {
        return borrowedAmount[account][token].mul(debtValue(token)).div(1e18);
    }

    // How much USD does an user owe per token
    function userDebtUSD(address account, address token) public view returns (uint256) {
        return userDebt(account, token).mul(getLatestPrice(token)).div(1e18);
    }

    // How many lent tokens is it's share token backed by
    function getShareValue(address token) public view returns (uint256) {
        if (IERC20(borrowShare[token]).totalSupply() == 0) return 1e18;
        return borrowTokenBalance[token].mul(1e18).div(IERC20(borrowShare[token]).totalSupply());
    }

    // How many collateral tokens is it's share token backed by
    function getCollateralShareValue() public view returns(uint256) { // 1e18 precision
        return WGLPManager.getShareValue();
    }

    // Fetch the price of an asset from GMX price feed contract
    function getLatestPrice(address token) private view returns (uint) {
        uint price = priceFeed.getPrice(token, false, true, false);
        return price.div(1e12); // Normalize to 1e18
    }

    // Price of GLP
    function getCollateralPrice() public view returns (uint) { // 1e18 precision
        return IGLPManager(GLPManager).getAumInUsdg(true).mul(1e18).div(IERC20(GLP).totalSupply());
    }

    // User's health factor
    function accountHealth(address account) public view returns (uint256) { // 1e18 precision
        if (accountBorrowedValue(account) == 0) return 100e18;
        if (accountCollateralValue(account).mul(1e18).div(accountBorrowedValue(account)) > 100e18) return 100e18;
        return accountCollateralValue(account).mul(1e18).div(accountBorrowedValue(account));
    }

    // How much an user has borrowed in total in USD
    function accountBorrowedValue(address account) public view returns (uint256) { // 1e18 precision
        uint totalBorrowedValue;
        for (uint i=0; i<vault.allWhitelistedTokensLength(); i++) {
            totalBorrowedValue += userDebt(account, vault.allWhitelistedTokens(i)).mul(getLatestPrice(vault.allWhitelistedTokens(i))).div(1e18);
        }  
        return totalBorrowedValue;      
    }

    // How much an user has lent in total in USD
    function accountLentValue(address account) public view returns (uint256) { // 1e18 precision
        uint accountValue;
        for (uint i=0; i<vault.allWhitelistedTokensLength(); i++) {
            address token = vault.allWhitelistedTokens(i);
            accountValue += borrowTokenBalance[token]
            .mul(IERC20(borrowShare[token]).balanceOf(account))
            .mul(getShareValue(token))
            .mul(getLatestPrice(token))
            .div(1e54);
        }  
        return accountValue;      
    }

    // How much is lent in total in USD
    function totalLentValue() public view returns (uint256) { // 1e18 precision
        uint total;
        for (uint i=0; i<vault.allWhitelistedTokensLength(); i++) {
            address token = vault.allWhitelistedTokens(i);
            total += borrowTokenBalance[token]
            .mul(getLatestPrice(token))
            .div(1e18);
        }  
        return total;      
    }

    // Value of an user's collateral in USD
    function accountCollateralValue(address account) public view returns (uint256) { // 1e18 precision
        uint totalCollateralValue = userCollateral[account].mul(getCollateralShareValue()).mul(getCollateralPrice()).mul(ltv).div(1e36).div(100);
        return totalCollateralValue;
    }

    // Annual interest rate of borrowing a token
    function interestRate(address token) public view returns (uint256) { // 1e18 precision, %annual
        return totalBorrowedAmount(token).mul(1e18).div(borrowTokenBalance[token]);
    }

    // How many tokens have been borrowed from liquidity
    function totalBorrowedAmount(address token) public view returns (uint256) {
        return initialLentAmount[token];
    }

    // How many tokens can an user borrow
    function borrowingPower(address account, address token) public view returns (uint256) {
        if (accountBorrowedValue(account) > accountCollateralValue(account)) return 0;
        return (accountCollateralValue(account).sub(accountBorrowedValue(account))).mul(1e18).div(getLatestPrice(token));
    }

    // How much can an user borrow in USD
    function borrowingPowerUSD(address account) public view returns (uint256) {
        if (accountBorrowedValue(account) > accountCollateralValue(account)) return 0;
        return accountCollateralValue(account).sub(accountBorrowedValue(account));
    }
}