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

contract Protocol {

    using SafeMath for uint;

    mapping(address => bool) public borrowToken; // Token allowed to be deposited/borrowed
    mapping(address => address) public borrowShare; // Share token from lent token
    mapping(address => uint) public borrowTokenBalance; // Tracks balance of lent tokens

    mapping(address => uint) public decimalMultiplier; // Decimals needed to normalize to 1e18
    mapping(address => uint) public tokenDebt; // Tracks amount of tokens owed
    mapping(address => mapping(address => uint)) public borrowedAmount; // User debt
    mapping(address => uint) public interestCheckpoint; // Tracks token accrued interest using time

    uint256 public totalCollateral; // Total GLP deposited

    address public governance;
    IVault public vault;
    IRewardsRouter public rewardsRouter;
    IERC20 public GLPShare;
    IERC20 public GLP;
    address public weth;
    uint public ltv = 50; // 50 is 50% GLP LTV
    address public lnxReward;
    address public stakeReward;
    IPriceFeed public priceFeed;

    constructor(address _vault, address _rewardsRouter, address _GLP, address _weth, address _lnxReward, address _stakeReward, address _priceFeed) {
        governance = msg.sender;
        rewardsRouter = IRewardsRouter(_rewardsRouter);
        vault = IVault(_vault);
        GLP = IERC20(_GLP);
        weth = _weth;
        lnxReward = _lnxReward;
        stakeReward = _stakeReward;
        priceFeed = IPriceFeed(_priceFeed);
    }



    // End user functions

    // If the user has fsGLP, it should be redeemed beforehand through a tx on frontend
    function depositCollateral(address token, uint256 amount) external {
        if (totalCollateral > 0) compound();
        IERC20(token).transferFrom(msg.sender, address(this), amount);
        amount = rewardsRouter.mintAndStakeGlp(token, amount, 0, 1);
        uint amountToMint = amount.mul(1e18).div(getCollateralShareValue());
        IERC20(GLPShare).mint(msg.sender, amountToMint);
        totalCollateral += amount;
    }

    function withdrawCollateralAll() external {
        require(accountBorrowedValue(msg.sender) == 0, "Account has debt");
        uint shareAmount = IERC20(GLPShare).balanceOf(msg.sender);
        withdrawCollateral(shareAmount);
    }

    function withdrawCollateral(uint256 shareAmount) public returns (uint256) {
        IERC20(GLPShare).burn(msg.sender, shareAmount);
        uint amount = shareAmount.mul(getCollateralShareValue()).div(1e18);
        uint amountWithdrawn = rewardsRouter.unstakeAndRedeemGlp(weth, amount, 1, msg.sender);
        totalCollateral -= amount;
        require(accountHealth(msg.sender) >= 1e18, "Account not healthy after withdraw");
        return amountWithdrawn;
    }
    // rewardsRouter.mintAndStakeGlp() tx should be sent again through the frontend to mint GLP back to the user after withdrawing
    // because GLP isnt transferrable by unauthorized addresses.
    // Someone depositing GLP to this contract can also block withdrawals
    // because there is a 15 minute timer set between the ability to sell GLP after buying GLP

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
        tokenDebt[token] += tokenAmount.mul(10**decimalMultiplier[token]); 
        borrowedAmount[msg.sender][token] += tokenAmount.mul(uint(1e18).mul(10**decimalMultiplier[token])).div(debtValue(token));
        IERC20(token).transfer(msg.sender, tokenAmount);
    }

    function repay(address token, uint256 tokenAmount) public {
        uint interestPaid = tokenAmount.sub(
            totalBorrowedAmount(token)
            .mul(IERC20(borrowShare[token]).balanceOf(msg.sender))
            .div(IERC20(borrowShare[token]).totalSupply())
        );
        require(tokenAmount.mul(10**decimalMultiplier[token]) <= userDebt(msg.sender, token), "Repaying too much");      
        borrowedAmount[msg.sender][token] -= tokenAmount.mul(1e18).mul(10**decimalMultiplier[token]).div(debtValue(token));
        tokenDebt[token] += getTokenAccruedInterest(token);
        interestCheckpoint[token] = block.timestamp;
        tokenDebt[token] -= tokenAmount.mul(10**decimalMultiplier[token]);
        IERC20(token).transferFrom(msg.sender, address(this), tokenAmount);
        IStakeReward(stakeReward).receiveRewards(token, interestPaid.div(4));
        borrowTokenBalance[token] += interestPaid.mul(3).div(4);
        compound();
    }

    function repayAll(address token) external {
        repay(token, userDebt(msg.sender, token).div(10**decimalMultiplier[token]));
    }

    function liquidate(address account) external {
        require(accountHealth(account) < 1e18, "Account healthy");
        uint256 usdLoansTotal = accountBorrowedValue(account);
        uint256 amount;
        address token;
        for (uint i=0; i<vault.allWhitelistedTokensLength(); i++) {
            if (userDebtUSD(account, token) > 0) {
                token = vault.allWhitelistedTokens(i);
                amount = rewardsRouter.unstakeAndRedeemGlp(
                    token,
                    GLPShare.balanceOf(account).mul(getCollateralShareValue().div(1e18)).mul(userDebtUSD(account, token)).div(usdLoansTotal),
                    1,
                    address(this)
                );
                IERC20(token).transfer(msg.sender, amount.mul(5).div(100));
                IERC20(token).transfer(stakeReward, amount.mul(5).div(100));
                tokenDebt[token] += getTokenAccruedInterest(token);
                interestCheckpoint[token] = block.timestamp;
                borrowTokenBalance[token] -= borrowedAmount[account][token];
                borrowedAmount[account][token] = 0;
                borrowTokenBalance[token] += amount;
                tokenDebt[token] -= amount;
            }
        }
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
        totalCollateral += rewardsRouter.mintAndStakeGlp(
            weth,
            IERC20(weth).balanceOf(address(this)).sub(wethBefore),
            1,
            1
        );
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
        IERC20(token).approve(address(rewardsRouter), type(uint).max);
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

    function setGLPShare(address _GLPShare) external {
        require(msg.sender == governance, "!Governance");
        require(address(GLPShare) == address(0), "GLP Share already set!");
        GLPShare = IERC20(_GLPShare);
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
        if (IERC20(GLPShare).totalSupply() == 0) return 1e18;
        return totalCollateral.mul(1e18).div(IERC20(GLPShare).totalSupply());
    }

    // Fetch the price of an asset from GMX price feed contract
    function getLatestPrice(address token) private view returns (uint) {
        uint price = priceFeed.getPrice(token, false, true, false);
        return price.div(1e12); // Normalize to 1e18
    }

    // Price of GLP
    function getCollateralPrice() public view returns (uint) { // 1e18 precision
        uint totalValue;
        for (uint i=0; i<vault.allWhitelistedTokensLength(); i++) {
            totalValue += getLatestPrice(vault.allWhitelistedTokens(i)).mul(IERC20(vault.allWhitelistedTokens(i)).balanceOf(address(vault)).mul(10**(decimalMultiplier[vault.allWhitelistedTokens(i)])));
        }
        uint price = totalValue.mul(1e18).div(IERC20(GLP).totalSupply());
        return uint(price);
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
            .div(1e36);
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
        uint totalCollateralValue = IERC20(GLPShare).balanceOf(account).mul(getCollateralShareValue()).mul(getCollateralPrice()).mul(ltv).div(100);
        return totalCollateralValue;    
    }

    // Annual interest rate of borrowing a token
    function interestRate(address token) public view returns (uint256) { // 1e18 precision, %annual
        return totalBorrowedAmount(token).mul(1e18).div(borrowTokenBalance[token]);
    }

    // How many tokens have been borrowed from liquidity
    function totalBorrowedAmount(address token) public view returns (uint256) {
        return borrowTokenBalance[token].sub(IERC20(token).balanceOf(address(this)).mul(10**decimalMultiplier[token]));
    }

    // How many tokens can an user borrow
    function borrowingPower(address account, address token) public view returns (uint256) {
        return (accountCollateralValue(account).sub(accountBorrowedValue(account))).mul(1e18).div(getLatestPrice(token));
    }

    // How much can an user borrow in USD
    function borrowingPowerUSD(address account) public view returns (uint256) {
        return accountCollateralValue(account).sub(accountBorrowedValue(account));
    }
}