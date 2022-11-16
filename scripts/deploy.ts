import { ethers } from "hardhat";

const usdtEthConversionPrice = "813117070000000";

async function main() {

  const CryptoSurfersNFT = await ethers.getContractFactory("CryptoSurfersNFT");
  const USDT = await ethers.getContractFactory("MockUSDT");
  const PriceFeed = await ethers.getContractFactory("MockPriceFeed");

  const usdt = await USDT.deploy()
  await usdt.deployed();

  console.log(`Mock USDT has been deployed at ${usdt.address}`);

  const priceFeed = await PriceFeed.deploy(usdtEthConversionPrice)
  await priceFeed.deployed();

  console.log(`Mock Price Feed has been deployed at ${priceFeed.address}`);
  
  const collection = await upgrades.deployProxy(
    CryptoSurfersNFT, 
    [
      owner.address,         // owner
      "1000000", // sale price (1 USDT)
      300,
      usdt.address,
      priceFeed.address,
      [owner.address, user.address],
      [5000, 5000]
    ], 
    { initializer: '__CryptoSurfersNFT_initialize' }
  );

  await collection.deployed()

  console.log(`CryptoSurfersNFT has been deployed at ${collection.address}`);

  console.log(`Deployment script executed successfully.`);

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
