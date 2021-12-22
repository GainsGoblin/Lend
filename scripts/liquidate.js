const hre = require("hardhat");
const prompt = require("prompt-sync")({ sigint: false });
const { ethers} = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;
const { deploy, execute } = deployments;

async function main() {

  const {
    deployer
  } = await getNamedAccounts();
  const Protocol = await deployments.get("Protocol");
  const protocol = await hre.ethers.getContractAt("Protocol", Protocol.address);

  let accountInput = await prompt("Account to liquidate: ");
  if(accountInput == "me") { accountInput = deployer }

  await protocol.liquidate(accountInput);

  console.log("Successfully liquidated", accountInput);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
