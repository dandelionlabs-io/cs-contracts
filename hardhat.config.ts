import * as dotenv from "dotenv";
import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import '@openzeppelin/hardhat-upgrades';
import "@nomiclabs/hardhat-etherscan";
import "hardhat-gas-reporter"

dotenv.config();

const config: HardhatUserConfig = {
  defaultNetwork: "hardhat",
  networks: {
    hardhat: {
    },
    goerli: {
      network: 5,
      url: process.env.RPC_URL,
      accounts: process.env.PRIVATE_KEY ? [process.env.PRIVATE_KEY] : []
    },
    mainnet: {
      network: 1,
      url: process.env.PROD_RPC_URL,
      accounts: process.env.PROD_PRIVATE_KEY ? [process.env.PROD_PRIVATE_KEY] : []
    }
  },
  solidity: {
    version: "0.8.4",
    settings: {
      optimizer: {
        enabled: true,
        runs: 1000,
      },
    },
  },
  gasReporter: {
    coinmarketcap: 'b5aa6c8e-e54a-4291-b372-6afac549d9fc',
    currency: 'USD',
    enabled: true,
    token: 'ETH'
  },
  etherscan: {
    apiKey: {
      goerli: process.env.ETHERSCAN_APIKEY ?? "",
      mainnet: process.env.PROD_ETHERSCAN_APIKEY ?? ''
    }
  }
};

export default config;
