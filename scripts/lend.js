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

  const weth = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1";
  //let tokenInput = prompt("Token address to lend: ");
  //if(tokenInput == "weth") { tokenInput == weth }

  const protocol = await deployments.get("Protocol");
  const token = await hre.ethers.getContractAt("IWETH9", weth);

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
