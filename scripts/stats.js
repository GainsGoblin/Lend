const hre = require("hardhat");
const prompt = require("prompt-sync")({ sigint: false });
const { ethers } = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;
const { deploy, execute } = deployments;

async function main() {

  const {
    deployer
  } = await getNamedAccounts();

  const Protocol = await deployments.get("Protocol");
  const protocol = await hre.ethers.getContractAt("Protocol", Protocol.address);

  const LNXRewards = await deployments.get("LNXRewards");
  const lnxrewards = await hre.ethers.getContractAt("LNXRewards", LNXRewards.address);

  const tokenInput = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1"//await prompt("Token address to get stats for: ");
  const userInput = "0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266"//await prompt("User address to get stats for: ");
  const token = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", tokenInput);
  const tokenName = await token.symbol();

  const userDebtUSD = await protocol.userDebtUSD(userInput, tokenInput);
  console.log("userDebtUSD:", userDebtUSD.toString());

  const debtvalue = await protocol.debtValue(tokenInput);
  console.log(tokenName, "debt value:", debtvalue.toString());

  const getTokenAccruedInterest = await protocol.getTokenAccruedInterest(tokenInput);
  console.log(tokenName, "accrued interest:", getTokenAccruedInterest.toString());

  const getShareValue = await protocol.getShareValue(tokenInput);
  console.log(tokenName, "share value:", getShareValue.toString());

  const getCollateralShareValue = await protocol.getCollateralShareValue();
  console.log("GLP share value:", getCollateralShareValue.toString());

  const getCollateralPrice = await protocol.getCollateralPrice();
  console.log("GLP price:", getCollateralPrice.toString());

  const totalLentValue = await protocol.totalLentValue();
  console.log("Total lent value:", totalLentValue.toString());

  const interestRate = await protocol.interestRate(tokenInput);
  console.log(tokenName, "interest rate:", interestRate.toString());

  const totalBorrowedAmount = await protocol.totalBorrowedAmount(tokenInput);
  console.log(tokenName, "total borrowed amount:", totalBorrowedAmount.toString());

  const accountHealth = await protocol.accountHealth(userInput);
  console.log("Account health:", accountHealth.toString());

  const accountBorrowedValue = await protocol.accountBorrowedValue(userInput);
  console.log("Account borrowed value:", accountBorrowedValue.toString());

  const userDebt = await protocol.userDebt(userInput, tokenInput);
  console.log("Account debt amount in", tokenName, ":", userDebt.toString());

  const accountLentValue = await protocol.accountLentValue(userInput);
  console.log("Account lent value:", accountLentValue.toString());

  const accountCollateralValue = await protocol.accountCollateralValue(userInput);
  console.log("Account collateral value:", accountCollateralValue.toString());

  const borrowingPower = await protocol.borrowingPower(userInput, tokenInput);
  console.log("Account borrowing power in", tokenName, ":", borrowingPower.toString());

  const borrowingPowerUSD = await protocol.borrowingPowerUSD(userInput);
  console.log("Account borrowing power in USD:", borrowingPowerUSD.toString());

  const tokenDebt = await protocol.tokenDebt(tokenInput);
  console.log("Token debt:", tokenDebt.toString());

  const borrowedAmount = await protocol.borrowedAmount(deployer, tokenInput);
  console.log("borrowedAmount:", borrowedAmount.toString());

  const claimableLNXrewards = await lnxrewards.claimableRewards(userInput);
  console.log("Claimable LNX rewards:", claimableLNXrewards.toString());

  const baserate = await lnxrewards.baseRate();
  console.log("LNX reward base rate:", baserate.toString());

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
