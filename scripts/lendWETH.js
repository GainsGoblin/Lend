const hre = require("hardhat");
const { ethers} = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;
const { deploy, execute } = deployments;

async function main() {

  const {
    deployer
  } = await getNamedAccounts();
  const weth = await hre.ethers.getContractAt("IWETH9", "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1");
  const protocol = await deployments.get("Protocol");

  await weth.approve(protocol.address, ether("1000"));
  console.log("Approved the spending of 1000 WETH for Protocol");

  await execute(
    "Protocol",
    {from: deployer, log: true},
    "lend",
    weth.address,
    ether("1")
  );
  console.log("Successfully lending 1 WETH");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
