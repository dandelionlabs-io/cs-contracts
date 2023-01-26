import {ethers, upgrades} from "hardhat";

const PRICE_FEED = '0xEe9F2375b4bdF6387aa8265dD4FB8F16512A1d46';
const USDT_ADDRESS = '0xdAC17F958D2ee523a2206206994597C13D831ec7';
const reneAddress = '0x41cF8444dE6004317038ef920F5c99A90176cE0a';

async function main() {

    const CryptoSurfersNFT = await ethers.getContractFactory("CryptoSurfersNFT");

    const collection = await upgrades.deployProxy(
        CryptoSurfersNFT,
        [
            process.env.DEPLOYER_ADDRESS, // owner
            [reneAddress],
            'https://cryptosurfers.club/api/assets/',
            "100000000", // sale price (100 USDT)
            20, // MAX PER MINT
            777, // MINT LIMIT IN THE COLLECTION
            USDT_ADDRESS,
            PRICE_FEED,
            1000, // 10%
            [process.env.DEPLOYER_ADDRESS],
            [5000]
        ],
        {initializer: '__CryptoSurfersNFT_initialize'}
    );

    await collection.deployed()

    console.log(`CryptoSurfersNFT has been upgraded at ${collection.address}`);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
    console.error(error);
    process.exitCode = 1;
});
