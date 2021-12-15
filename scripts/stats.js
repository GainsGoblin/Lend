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

  const tokenInput = await prompt("Token address to get stats for: ");
  const token = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", tokenInput);
  const tokenName = await token.symbol();

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
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});