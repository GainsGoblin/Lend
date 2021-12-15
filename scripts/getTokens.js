const hre = require("hardhat");
const { deployments, ethers } = hre;
const { execute } = deployments;
const { parseEther } = ethers.utils;
const ether = parseEther;

async function main() {

  const [owner] = await ethers.getSigners();

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

  await weth.deposit({value: ether("9")});
  console.log("Deposited 9 ETH -> 9 WETH");

  await weth.approve(router.address, ether("1000"));
  console.log("Approved the spending of 1000 WETH for Router");

  await router.swap(
    [weth.address, dai.address],
    ether("1"),
    1,
    owner.address
  );
  let daibalance = await dai.balanceOf(owner.address);
  console.log("Swapped 1 WETH for", daibalance.toString(), "DAI");

  await router.swap(
    [weth.address, usdc.address],
    ether("1"),
    1,
    owner.address
  );
  let usdcbalance = await usdc.balanceOf(owner.address);
  console.log("Swapped 1 WETH for", usdcbalance.toString(), "USDC");

  await router.swap(
    [weth.address, usdt.address],
    ether("1"),
    1,
    owner.address
  );
  let usdtbalance = await usdt.balanceOf(owner.address);
  console.log("Swapped 1 WETH for", usdtbalance.toString(), "USDT");

  await router.swap(
    [weth.address, mim.address],
    ether("1"),
    1,
    owner.address
  );
  let mimbalance = await mim.balanceOf(owner.address);
  console.log("Swapped 1 WETH for", mimbalance.toString(), "MIM");

  await router.swap(
    [weth.address, frax.address],
    ether("1"),
    1,
    owner.address
  );
  let fraxbalance = await frax.balanceOf(owner.address);
  console.log("Swapped 1 WETH for", fraxbalance.toString(), "FRAX");

  await router.swap(
    [weth.address, wbtc.address],
    ether("1"),
    1,
    owner.address
  );
  let wbtcbalance = await wbtc.balanceOf(owner.address);
  console.log("Swapped 1 WETH for", wbtcbalance.toString(), "WBTC");

  await router.swap(
    [weth.address, uni.address],
    ether("1"),
    1,
    owner.address
  );
  let unibalance = await uni.balanceOf(owner.address);
  console.log("Swapped 1 WETH for", unibalance.toString(), "UNI");

  await router.swap(
    [weth.address, link.address],
    ether("1"),
    1,
    owner.address
  );
  let linkbalance = await link.balanceOf(owner.address);
  console.log("Swapped 1 WETH for", linkbalance.toString(), "LINK");
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
