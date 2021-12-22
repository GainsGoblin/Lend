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

  const LNXRewards = await deployments.get("LNXRewards");
  const lnxrewards = await hre.ethers.getContractAt("LNXRewards", LNXRewards.address);

  await lnxrewards.claimRewards(deployer);
  console.log("Claimed LNX rewards");

}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
