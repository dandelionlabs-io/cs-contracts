import { time } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { BigNumber } from "ethers";
import { ethers, upgrades } from "hardhat";

const usdtEthConversionPrice = "813117070000000";

async function deployCollection() {
  const [owner, user] = await ethers.getSigners();

  const CryptoSurfersNFT = await ethers.getContractFactory("CryptoSurfersNFT");
  const USDT = await ethers.getContractFactory("MockUSDT");
  const PriceFeed = await ethers.getContractFactory("MockPriceFeed");

  const usdt = await USDT.deploy()
  await usdt.deployed();

  const priceFeed = await PriceFeed.deploy(usdtEthConversionPrice)
  await priceFeed.deployed();
  
  const collection = await upgrades.deployProxy(
    CryptoSurfersNFT, 
    [
      owner.address,         // owner
      "1000000000000000000", // sale price (0.1 ETH)
      300,
      usdt.address,
      priceFeed.address,
      [owner.address, user.address],
      [5000, 5000]
    ], 
    { initializer: '__CryptoSurfersNFT_initialize' }
  );

  await collection.deployed()

  return { collection, owner, user };
}

export { deployCollection };
