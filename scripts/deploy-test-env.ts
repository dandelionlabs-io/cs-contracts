import {ethers, upgrades} from "hardhat";

const usdtEthConversionPrice = "813117070000000";
const reneAddress = '0x41cF8444dE6004317038ef920F5c99A90176cE0a';

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
            process.env.DEPLOYER_ADDRESS, // owner
            [reneAddress],
            'https://cryptosurfers.club/assets/',
            "1000000", // sale price (1 USDT)
            20,
            777,
            usdt.address,
            priceFeed.address,
            1000, // 10%
            [process.env.DEPLOYER_ADDRESS],
            [5000]
        ],
        {initializer: '__CryptoSurfersNFT_initialize'}
    );

    await collection.deployed()

    console.log(`CryptoSurfersNFT has been deployed at ${collection.address}`);

    const transferTx = await usdt.transfer(reneAddress, "100000000")
    await transferTx.wait()

    console.log(`USDT has been transfered to rene address ${reneAddress}`);

    console.log(`Deployment script executed successfully.`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
