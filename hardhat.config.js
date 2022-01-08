require("dotenv").config();

require("@nomiclabs/hardhat-etherscan");
require("@nomiclabs/hardhat-waffle");
require("hardhat-gas-reporter");
require("solidity-coverage");
require("@nomiclabs/hardhat-ethers");
require("hardhat-deploy-ethers");
require('hardhat-deploy');

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      }
    }
  },
  networks: {
    localhost: {
      url: 'http://127.0.0.1:8545',
      timeout: 2000000,
      chainId: 1337
    },

    hardhat: {
      mining: {
        auto: false,
        interval: 100
      },
      forking: {
        url: 'https://arb-mainnet.g.alchemy.com/v2/RsblMJD5kSOphpB7kscQRL5oadiXkR-h'
      },
      timeout: 2000000
    }
  },
  namedAccounts: {
    deployer: {
      default: 0,
    }
  },
  gasReporter: {
    enabled: process.env.REPORT_GAS !== undefined,
    currency: "USD",
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_API_KEY,
  },
  mocha: {
    timeout: 2000000
  }
};
