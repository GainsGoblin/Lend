const hre = require("hardhat");
const prompt = require("prompt-sync")({ sigint: false });
const { ethers} = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;
const { deploy, execute } = deployments;

async function main() {

  const tokenInput = await prompt("Token address to borrow: ");

  const {
    deployer
  } = await getNamedAccounts();
  const token = await hre.ethers.getContractAt("IWETH9", tokenInput);
  const protocol = await deployments.get("Protocol");

  const tokenName = await token.name();

  await execute(
    "Protocol",
    {from: deployer, log: true},
    "borrow",
    token.address,
    ether("0.1")
  );
  console.log("Successfully borrowed 0.1", tokenName);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
