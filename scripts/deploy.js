const hre = require("hardhat");

async function main() {

  // Deploy LNX token
  const LNXToken = await hre.ethers.getContractFactory("LNXToken");
  const lnxtoken = await LNXToken.deploy();

  await lnxtoken.deployed();
  console.log("LNXToken deployed to:", lnxtoken.address);

  // Deploy LNX rewards contract
  const LNXRewards = await hre.ethers.getContractFactory("LNXRewards");
  const lnxrewards = await LNXRewards.deploy(lnxtoken.address);

  await lnxrewards.deployed();
  console.log("LNXRewards deployed to:", lnxrewards.address);

  // Deploy staking rewards contract
  const StakeRewards = await hre.ethers.getContractFactory("StakeRewards");
  const stakerewards = await StakeRewards.deploy(
    lnxtoken.address,
    "0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258"
  );
  console.log("StakeRewards deployed to:", stakerewards.address);

  // Deploy lending protocol
  const Protocol = await hre.ethers.getContractFactory("Protocol");
  const protocol = await Protocol.deploy(
    "0x489ee077994B6658eAfA855C308275EAd8097C4A",
    "0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064",
    "0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258",
    "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1",
    lnxrewards.address,
    stakerewards.address
  );

  await protocol.deployed();
  console.log("Protocol deployed to:", protocol.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
