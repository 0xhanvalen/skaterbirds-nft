require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-etherscan");
require("hardhat-gas-reporter");
require("hardhat-contract-sizer");
require("dotenv").config();

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const privateKey = process.env.DEVWALLET;
const url = process.env.INFURA_URL;
const rinkebyURL = process.env.INFURA_RINKEBY_URL;
const etherScan = process.env.ETHERSCAN;

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  solidity: "0.8.12",
  optimizer: {
    enabled: true,
    runs: 200,
    details: {
      yul: true,
      yulDetails: {
        stackAllocation: true,
        optimizerSteps: "dhfoDgvulfnTUtnIf",
      },
    },
  },
  networks: {
    mainnet: {
      url: `${url}`,
      accounts: [`${privateKey}`],
      live: true,
      saveDeployments: true,
      tags: ["production"],
    },
    xdai: {
      url: `https://rpc.gnosischain.com/`,
      accounts: [`${privateKey}`],
      live: true,
      saveDeployments: true,
      tags: ["staging"],
    },
  },
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: { mainnet: etherScan, xdai: "BASED" },
  },
  gasReporter: {
    currency: "usd",
    token: "eth",
    gasPrice: 37,
  },
  mocha: {
    timeout: 600000,
  },
};
