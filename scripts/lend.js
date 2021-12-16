const hre = require("hardhat");
const prompt = require("prompt-sync")({ sigint: false });
const { ethers} = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;
const { deploy, execute } = deployments;

async function main() {

  const tokenInput = await prompt("Token address to lend: ");

  const {
    deployer
  } = await getNamedAccounts();
  const token = await hre.ethers.getContractAt("IWETH9", tokenInput);
  const protocol = await deployments.get("Protocol");

  await token.approve(protocol.address, ether("100"));
  const tokenName = await token.name();
  console.log("Approved the spending of 100", tokenName, "for Protocol");

  await execute(
    "Protocol",
    {from: deployer, log: true},
    "lend",
    token.address,
    ether("1")
  );
  console.log("Successfully lending 1", tokenName);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
