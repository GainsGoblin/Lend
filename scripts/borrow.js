const hre = require("hardhat");
const prompt = require("prompt-sync")({ sigint: false });
const { ethers} = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;
const { deploy, execute } = deployments;

async function main() {

  const weth = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1";
  //const tokenInput = await prompt("Token address to borrow: ");

  const {
    deployer
  } = await getNamedAccounts();
  const token = await hre.ethers.getContractAt("IWETH9", weth);
  const protocol = await deployments.get("Protocol");

  const tokenName = await token.name();

  await execute(
    "Protocol",
    {from: deployer, log: true},
    "borrow",
    token.address,
    ether("0.05755")
  );
  console.log("Successfully borrowed", tokenName);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
