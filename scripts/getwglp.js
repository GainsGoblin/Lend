const hre = require("hardhat");
const prompt = require("prompt-sync")({ sigint: false });
const { ethers} = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;
const { deploy, execute } = deployments;

async function main() {

  //const tokenInput = await prompt("Token address to deposit into GLP: ");
  const weth = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1";
  const {
    deployer
  } = await getNamedAccounts();
  const token = await hre.ethers.getContractAt("IWETH9", weth);
  const WGLPManager = await deployments.get("WrappedGLPManager");
  const wglpmanager = await hre.ethers.getContractAt("WrappedGLPManager", WGLPManager.address);

  await token.approve(wglpmanager.address, ether("100"));
  const tokenName = await token.name();
  console.log("Approved the spending of 100", tokenName, "for WGLP Manager");

  await wglpmanager.deposit(token.address, ether("1"));
  console.log("Successfully received WGLP");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
