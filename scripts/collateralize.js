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
  const WGLP = await deployments.get("ShareToken");
  const wglp = await hre.ethers.getContractAt("ShareToken", WGLP.address);


  await wglp.approve(protocol.address, ether("10000"));
  console.log("Approved the spending of WGLP for Protocol");

  await protocol.depositCollateral(ether("1000"));
  console.log("Successfully collateralized WGLP");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
