import {ethers, upgrades} from "hardhat";

const USDT_ADDRESS = "0x27BC619491c8F2F4770631DAEf902eee2aB2aA4E";
const PRICE_FEED_ADDRESS = '0xfA9b6cb4aD08036F93A37c66CB663EEfd149D1ce';
const reneAddress = '0x41cF8444dE6004317038ef920F5c99A90176cE0a';

async function main() {

    const CryptoSurfersNFT = await ethers.getContractFactory("CryptoSurfersNFT");
    const USDT = await ethers.getContractFactory("MockUSDT");

    const usdt = await USDT.attach(USDT_ADDRESS)

    const collection = await upgrades.deployProxy(
        CryptoSurfersNFT,
        [
            process.env.DEPLOYER_ADDRESS, // owner
            [reneAddress],
            'https://cryptosurfers.club/assets/',
            "1000000", // sale price (1 USDT)
            20,
            777,
            USDT_ADDRESS,
            PRICE_FEED_ADDRESS,
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
