# CryptoSurfers smart contracts
Crypto Surfers smart contracts are written in solidity and are originally implemented to be used in the Ethereum network, therefore are portable to any other EVM-compatible network.

## About the source code

The source code in this repo has been created from scratch but uses OpenZeppelin standard libraries for safety in basic operations and validations.

- [Getting Started](#getting-started)
  - [Requirements](#requirements)
  - [Usage](#usage)
- [Troubleshooting](#troubleshooting)

## Getting Started

### Requirements
You will need node.js (16.*) and yarn installed to run it locally. We are using Hardhat to handle the project configuration and deployment. The configuration file can be found as `hardhat.config.js`.

1. Import the repository and `cd` into the new directory.
2. Run `yarn install`.
3. Copy the file `.env.example` to `.env`, and:
   - Replace `PRIVATE_KEY` with the private key of your deployer account.
   - Replace `RPC_URL` with an INFURA or ALCHEMY url.
5. Make sure you have gas to run the transactions and deploy the contracts in the account you define.
6. Define the network where you want to deploy it in `hardhat.config.js`.

## Usage

`npx hardhat compile` to compile the contracts

`npx hardhat test` to run tests

`npx hardhat run --network rinkeby scripts/deploy.ts` to deploy to a specific network

Other useful commands:

```shell
npx hardhat help
GAS_REPORT=true npx hardhat test
npx hardhat node
npx hardhat run --network rinkeby scripts/deploy.ts
```

## Troubleshooting

If you have any questions, send them along with a hi to [hello@dandelionlabs.io](mailto:hello@dandelionlabs.io).
