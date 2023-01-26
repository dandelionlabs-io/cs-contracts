import {ethers, upgrades} from "hardhat";

const NFT_ADDRESS = "0x8814734062d0761fC1B99b2f52613e765BB9AebF";

async function main() {

    const CryptoSurfersNFT = await ethers.getContractFactory("CryptoSurfersNFT");

    const collection = await upgrades.upgradeProxy(
        NFT_ADDRESS,
        CryptoSurfersNFT,
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
