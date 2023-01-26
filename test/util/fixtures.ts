import {ethers, upgrades} from "hardhat";

const usdtEthConversionPrice = "813117070000000";
const mintLimit = 777;

async function deployCollection() {
    const [owner, user, operator] = await ethers.getSigners();

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
            owner.address, // owner
            [],
            'https://cryptosurfers.club/assets/',
            "1000000",     // sale price (1 USDT)
            20,
            mintLimit,
            usdt.address,
            priceFeed.address,
            1000, // 10%
            [owner.address, user.address],
            [5000, 5000]
        ],
        {initializer: '__CryptoSurfersNFT_initialize'}
    );

    await collection.deployed()

    return {collection, owner, user, operator, usdt, mintLimit};
}

export {deployCollection};
