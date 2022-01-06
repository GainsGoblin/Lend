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

  const router = await hre.ethers.getContractAt("Router", "0xaBBc5F99639c9B6bCb58544ddf04EFA6802F4064");

  const dai = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", "0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1");
  const usdc = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", "0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8");
  const usdt = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", "0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9");
  const mim = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", "0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A");
  const frax = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", "0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F");
  const weth = await hre.ethers.getContractAt("IWETH9", "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1");
  const wbtc = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", "0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f");
  const uni = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", "0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0");
  const link = await hre.ethers.getContractAt("contracts/Interfaces/IERC20.sol:IERC20", "0xf97f4df75117a78c1A5a0DBb814Af92458539FB4");
  console.log("Recevied contracts for DAI, USDC, USDT, MIM, FRAX, WETH, WBTC, UNI, LINK");

  const LNXRewards = await deployments.get("LNXRewards");
  const lnxrewards = await hre.ethers.getContractAt("LNXRewards", LNXRewards.address);
  const Protocol = await deployments.get("Protocol");
  const protocol = await hre.ethers.getContractAt("Protocol", Protocol.address);
  const WGLPManager = await deployments.get("WrappedGLPManager");
  const wglpmanager = await hre.ethers.getContractAt("WrappedGLPManager", WGLPManager.address);
  const WGLP = await deployments.get("ShareToken");
  const wglp = await hre.ethers.getContractAt("ShareToken", WGLP.address);

  await weth.deposit({value: ether("9")});
  console.log("Deposited 9 ETH -> 9 WETH");

  await weth.approve(router.address, ether("100"));
  console.log("Approved the spending of 100 WETH for Router");

  await weth.approve(wglpmanager.address, ether("100"));
  console.log("Approved the spending of 100 WETH for WGLP Manager");

  await wglpmanager.deposit(weth.address, ether("1"));
  console.log("Successfully received WGLP");

  await weth.approve(protocol.address, ether("100"));
  console.log("Approved the spending of 100 WETH for Protocol");

  await execute(
    "Protocol",
    {from: deployer, log: true},
    "lend",
    weth.address,
    ether("1")
  );
  console.log("Successfully lending 1 WETH");

  await wglp.approve(protocol.address, ether("10000"));
  console.log("Approved the spending of WGLP for Protocol");

  await protocol.depositCollateral(ether("1000"));
  console.log("Successfully collateralized 1000 WGLP");

  await execute(
    "Protocol",
    {from: deployer, log: true},
    "borrow",
    weth.address,
    ether("0.05")
  );
  console.log("Successfully borrowed 0.05 WETH");

  await execute(
    "Protocol",
    {from: deployer, log: true},
    "repay",
    weth.address,
    ether("0.01")
  );
  console.log("Successfully repaid 0.01 WETH");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
