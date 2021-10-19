require("dotenv").config();
const HDWalletProvider = require("@truffle/hdwallet-provider");
const privateKey = process.env.PRIVATE_KEY;
const bscscanKey = process.env.BSCSCAN_KEY;
const etherscanKey = process.env.ETHSCAN_KEY;

module.exports = {
  networks: {
    rinkeby: {
      provider: function () {
        return new HDWalletProvider(
          privateKey,
          "https://rinkeby.infura.io/v3/5b61867f91844cb7aa5f20a0d9068e84"
        );
      },
      network_id: 4,
      gas: 10000000,
      gasPrice: 50000000000,
      skipDryRun: true,
    },
    bscmainnet: {
      provider: () =>
        new HDWalletProvider(
          privateKey,
          "https://bsc-dataseed1.binance.org:443"
        ),
      confirmations: 10,
      timeoutBlocks: 200,
      network_id: 56,
      skipDryRun: true,
    },
    bsctestnet: {
      provider: () =>
        new HDWalletProvider(
          privateKey,
          "https://data-seed-prebsc-1-s1.binance.org:8545"
        ),
      confirmations: 2,
      timeoutBlocks: 200,
      network_id: 97,
      skipDryRun: true,
    },
  },

  mocha: {
    // timeout: 100000
  },

  compilers: {
    solc: {
      version: "0.8.2",
      settings: {
        optimizer: {
          enabled: true,
          runs: 200,
        },
      },
    },
  },

  plugins: ["truffle-plugin-verify"],
  api_keys: {
    bscscan: bscscanKey,
    etherscan: etherscanKey,
  },
};
