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

    // Fetch the price of an asset from oracle
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

contract LNXRewards {

    using SafeMath for uint;

    IERC20 public lnx; // Governance token
    uint256 public mintCheckpoint;
    uint256 public baseRate; // Wei per second
    IProtocol public protocol; // Lending protocol
    address public governance;
    mapping(address => uint) public userClaimed; // How many tokens has an user claimed

    constructor(address _lnx) {
        lnx = IERC20(_lnx);
        governance = msg.sender;
    }

    function startRewards() external {
        require(msg.sender == governance && baseRate == 0);
        mintRewards();
        baseRate = 1e16; // 0.01 LNX per second
    }

    function setProtocol(address _protocol) external {
        require(msg.sender == governance);
        protocol = IProtocol(_protocol);
    }

    function mintRewards() internal returns (uint256) {
        uint amountToMint = 0;
        if (baseRate.mul(lnx.totalSupply()).div(lnx.capSupply()) <= 1e16) {
            uint rate = baseRate.sub(baseRate.mul(lnx.totalSupply()).div(lnx.capSupply()));
            amountToMint = (block.timestamp.sub(mintCheckpoint)).mul(rate);    
        }
        lnx.mint(address(this), amountToMint);
        mintCheckpoint = block.timestamp;
        return amountToMint;
    }

    function claimRewards(address account) external {
        require(msg.sender == account || msg.sender == address(protocol) || msg.sender == address(lnx), "Cannot claim for another account");
        if (claimableRewards(account) == 0) userClaimed[account] = lnx.totalSupply();    
        uint rewards = claimableRewards(account);
        mintRewards();
        lnx.transfer(account, rewards);
        userClaimed[account] = lnx.totalSupply();
    }

    function claimableRewards(address account) public view returns (uint) {
        if (baseRate == 0) return 0;
        uint mintable = (block.timestamp.sub(mintCheckpoint)).mul(baseRate.sub(baseRate.mul(lnx.totalSupply()).div(lnx.capSupply())));
        uint rewards = lnx.totalSupply().add(mintable);
        uint accountRewards = (rewards.sub(userClaimed[account])).mul(protocol.accountLentValue(account)).div(protocol.totalLentValue());
        return accountRewards;
    }
}