const hre = require("hardhat");

const dai = "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1";
const usdc = "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8";
const usdt = "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9";
const mim = "0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A";
const frax = "0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F";
const weth = "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1";
const wbtc = "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f";
const uni = "0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0";
const link = "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4";
const glp = "0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258";

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
    glp
  );

  await stakerewards.deployed();
  console.log("StakeRewards deployed to:", stakerewards.address);

  // Deploy lending protocol
  const Protocol = await hre.ethers.getContractFactory("Protocol");
  const protocol = await Protocol.deploy(
    "0x489ee077994B6658eAfA855C308275EAd8097C4A", // Vault
    "0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064", // RewardsRouter
    glp,
    weth,
    lnxrewards.address,
    stakerewards.address,
    "0x1CF4579904EB2ACDA0E4081E39eC10d0c32B5DE3" // Price Feed
  );

  await protocol.deployed();
  console.log("Protocol deployed to:", protocol.address);

  // Setup protocol
  await lnxrewards.setProtocol(protocol.address);
  console.log("LNX Rewards contract set up");
  await lnxtoken.setRewards(lnxrewards.address);
  console.log("LNX Token set up");
  await stakerewards.setProtocol(protocol.address);
  console.log("Staking rewards contract set up")

  // Set allowed tokens to be used by the protocol and deploy respective share tokens
  const DaiShare = await hre.ethers.getContractFactory("ShareToken");
  const daishare = await DaiShare.deploy(
    "LNX DAI Share Token",
    "lnxDaiShare",
    protocol.address
  );
  console.log("DAI Share:", daishare.address);

  const UsdcShare = await hre.ethers.getContractFactory("ShareToken");
  const usdcshare = await UsdcShare.deploy(
    "LNX USDC Share Token",
    "lnxUsdcShare",
    protocol.address
  );
  console.log("USDC Share:", usdcshare.address);

  const UsdtShare = await hre.ethers.getContractFactory("ShareToken");
  const usdtshare = await UsdtShare.deploy(
    "LNX USDT Share Token",
    "lnxUsdtShare",
    protocol.address
  );
  console.log("USDT Share:", usdtshare.address);

  const MimShare = await hre.ethers.getContractFactory("ShareToken");
  const mimshare = await MimShare.deploy(
    "LNX MIM Share Token",
    "lnxMimShare",
    protocol.address
  );
  console.log("MIM Share:", mimshare.address);

  const FraxShare = await hre.ethers.getContractFactory("ShareToken");
  const fraxshare = await FraxShare.deploy(
    "LNX FRAX Share Token",
    "lnxFraxShare",
    protocol.address
  );
  console.log("FRAX Share:", fraxshare.address);

  const WethShare = await hre.ethers.getContractFactory("ShareToken");
  const wethshare = await WethShare.deploy(
    "LNX WETH Share Token",
    "lnxWethShare",
    protocol.address
  );
  console.log("WETH Share:", wethshare.address);

  const WbtcShare = await hre.ethers.getContractFactory("ShareToken");
  const wbtcshare = await WbtcShare.deploy(
    "LNX WBTC Share Token",
    "lnxWbtcShare",
    protocol.address
  );
  console.log("WBTC Share:", wbtcshare.address);

  const UniShare = await hre.ethers.getContractFactory("ShareToken");
  const unishare = await UniShare.deploy(
    "LNX UNI Share Token",
    "lnxUniShare",
    protocol.address
  );
  console.log("UNI Share:", unishare.address);

  const LinkShare = await hre.ethers.getContractFactory("ShareToken");
  const linkshare = await LinkShare.deploy(
    "LNX LINK Share Token",
    "lnxLinkShare",
    protocol.address
  );
  console.log("LINK Share:", linkshare.address);

  const GlpShare = await hre.ethers.getContractFactory("ShareToken");
  const glpshare = await GlpShare.deploy(
    "LNX GLP Share Token",
    "lnxGlpShare",
    protocol.address
  );
  console.log("GLP Share:", glpshare.address);

  await protocol.setBorrowToken(dai, daishare.address);
  console.log("DAI allowed");
  await protocol.setBorrowToken(usdc, usdcshare.address);
  console.log("USDC allowed");
  await protocol.setBorrowToken(usdt, usdtshare.address);
  console.log("USDT allowed");
  await protocol.setBorrowToken(mim, mimshare.address);
  console.log("MIM allowed");
  await protocol.setBorrowToken(frax, fraxshare.address);
  console.log("FRAX allowed");
  await protocol.setBorrowToken(weth, wethshare.address);
  console.log("WETH allowed");
  await protocol.setBorrowToken(wbtc, wbtcshare.address);
  console.log("WBTC allowed");
  await protocol.setBorrowToken(uni, unishare.address);
  console.log("UNI allowed");
  await protocol.setBorrowToken(link, linkshare.address);
  console.log("LINK allowed");

  console.log("PROTOCOL SETUP FINISHED, READY TO BE USED");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
