const hre = require("hardhat");
const prompt = require("prompt-sync")({ sigint: false });
const { ethers} = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;
const { deploy, execute } = deployments;

async function main() {

  const tokenInput = await prompt("Token address to repay: ");

  const {
    deployer
  } = await getNamedAccounts();
  const token = await hre.ethers.getContractAt("IWETH9", tokenInput);
  const tokenName = await token.name();
  const protocol = await deployments.get("Protocol");
  await token.approve(protocol.address, ether("100"));
  console.log("Approved", tokenName, "spending for protocol");

  await execute(
    "Protocol",
    {from: deployer, log: true},
    "repay",
    token.address,
    ether("0.1")
  );
  console.log("Successfully repaid 0.1", tokenName);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
