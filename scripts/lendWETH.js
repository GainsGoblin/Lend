const hre = require("hardhat");
const { deployments, ethers } = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;

async function main() {

  const [owner] = await ethers.getSigners();
  const weth = await hre.ethers.getContractAt("IWETH9", "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1");
  const Protocol = await deployments.get("Protocol");
  const protocol = await ethers.getContractAt("Protocol", Protocol.address);

  await weth.approve(protocol.address, ether("1000"));
  console.log("Approved the spending of 1000 WETH for Protocol");

  await protocol.lend(weth.address, ether("1"));
  console.log("Lending 1 WETH");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
