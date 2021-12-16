const hre = require("hardhat");
const prompt = require("prompt-sync")({ sigint: false });
const { ethers} = hre;
const { parseEther } = ethers.utils;
const ether = parseEther;
const { deploy, execute } = deployments;

async function main() {

  const tokenInput = await prompt("Token address to deposit into GLP: ");

  const {
    deployer
  } = await getNamedAccounts();
  const token = await hre.ethers.getContractAt("IWETH9", tokenInput);
  // const protocol = await deployments.get("Protocol");
  const Protocol = await deployments.get("Protocol");
  const protocol = await hre.ethers.getContractAt("Protocol", Protocol.address);

  await token.approve(protocol.address, ether("100"));
  const tokenName = await token.name();
  console.log("Approved the spending of 100", tokenName, "for Protocol");

  await protocol.depositCollateral(token.address, ether("1"));
  // await execute(
  //   "Protocol",
  //   {from: deployer, log: true},
  //   "depositCollateral",
  //   token.address,
  //   ether("1")
  // );
  console.log("Successfully collateralized 1", tokenName, "as GLP");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
