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

interface IVault {
    function allWhitelistedTokensLength() external view returns (uint256);
    function allWhitelistedTokens(uint) external view returns (address);
}

contract StakeRewards {

    using SafeMath for uint;

    IERC20 public lnx; // Governance token
    address public protocol; // Lending protocol
    IVault public vault;
    address public governance;
    mapping(address => uint) public userStaked; // How much LNX has an user staked
    uint public totalStaked; // LNX staked in total
    mapping(address => mapping(address => uint)) public userClaimed; // How many tokens has an user claimed per token
    mapping(address => uint) public tokensRewarded; // How many tokens have been sent as rewards in total per token

    constructor(address _lnx, address _vault) {
        lnx = IERC20(_lnx);
        governance = msg.sender;
        vault= IVault(_vault);
    }

    function setProtocol(address _protocol) external {
        require(msg.sender == governance);
        protocol = _protocol;
    }

    function receiveRewards(address token, uint amount) external {
        require(msg.sender == protocol);
        IERC20(token).transferFrom(protocol, address(this), amount);
        tokensRewarded[token] += amount;
    }

    function stake(uint amount) external {
        lnx.transferFrom(msg.sender, address(this), amount);
        totalStaked += amount;
        userStaked[msg.sender] += amount;
    }

    function unstake(uint amount) external {
        require(userStaked[msg.sender] >= amount);
        totalStaked -= amount;
        userStaked[msg.sender] -= amount;
        lnx.transfer(msg.sender, amount);
    }

    function claimRewards(address account) external {
        require(msg.sender == account || msg.sender == address(protocol), "Cannot claim for another account");
        address token;
        uint rewards;
        for(uint i=0; i<vault.allWhitelistedTokensLength(); i++) {
            token = vault.allWhitelistedTokens(i);
            if (claimableRewards(account, token) == 0) userClaimed[account][token] = tokensRewarded[token];
            rewards = claimableRewards(account, token);
            IERC20(token).transfer(account, rewards);
            userClaimed[account][token] = tokensRewarded[token];
        }
    }

    function claimableRewards(address account, address token) public view returns (uint) {
        uint rewards = tokensRewarded[token];
        uint accountRewards = (rewards.sub(userClaimed[account][token])).mul(userStaked[account]).div(totalStaked);
        return accountRewards;
    }
}