import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { ethers } from "hardhat";
import { deployCollection } from "./util/fixtures";
import { hexEncode, hexDecode } from "./util/hex-encode";
import { uid } from 'uid';

const maxPerSale = 300;
const price = '1000000'; // price 1 USD
const ethPriceThreshold = 0.5;

const exampleDNA = "901020345";
//  9 // dummy number to start with
// 01 // trait type 0 / trait number 1
// 02 // trait type 1 / trait number 2
// 03 // trait type 2 / trait number 3
// 45 // trait type 3 / trait number 45

const DNA = uid(16).toString();
const DNA2 = uid(16).toString()
const DNA3 = uid(16).toString();
const encodedDNA = ethers.BigNumber.from(exampleDNA);
const encodedDNA2 = ethers.BigNumber.from(hexEncode(DNA2));
const encodedDNA3 = ethers.BigNumber.from(hexEncode(DNA3));


describe("Minting", function () {

  let collection, owner, user, usdt;
  beforeEach(async () => {
      ({ collection, owner, user, usdt } = await loadFixture(deployCollection));
  });

  it("Should not mint if sale is not enabled", async function () {
    await expect(
      collection.mint([encodedDNA], true)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'CryptoSurfersNFT::mint: Sale is not active.'");
  });

  it("Should not mint if sale enabled by contract is paused", async function () {
    // enables the sale
    let tx = await collection.enableSale();
    await tx.wait();

    await collection.pause();
    await tx.wait();

    await expect(
      collection.connect(owner).mint([encodedDNA], true)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'CryptoSurfersNFT::mint: Sale is not active.'");
  });

  it("Should throw on quantity 0", async function () {

    // enables the sale
    let tx = await collection.enableSale();
    await tx.wait();

    await expect(
      collection.mint([], true)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'CryptoSurfersNFT::mint: Quantity cannot be zero.");
  });

  it("Tx value must cover the cost of the NFT", async function () {

    // enables the sale
    let tx = await collection.enableSale();
    await tx.wait();

    await expect(
      collection.connect(owner).mint([encodedDNA], true)
    ).to.rejectedWith("CryptoSurfersNFT::mint: Value sent is insufficient");
  });

  it("quantity cannot be greater than the max allowed per transaction 'maxPerSale'", async function () {

    // enables the sale
    let tx = await collection.enableSale();
    await tx.wait();

    // quantity greater than maxPerMint
    const greaterQuantity = maxPerSale + 1;

    const dnaList = []
    for (let i = 0; i < greaterQuantity; i++) {
      dnaList.push(encodedDNA)
    }

    const priceInEth = await collection.getLatestPriceInEth()

    // value = price times quantity
    const payValue = priceInEth.mul(greaterQuantity)

    await expect(
      collection.connect(user).mint(dnaList, true, {value: payValue.toString()})
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'CryptoSurfersNFT::mint: Quantity cannot be bigger than maxPerSale.'");
  });

  it("should be able to Mint with ETH", async function () {

    // enables the sale
    let tx = await collection.enableSale();
    await tx.wait();

    const priceInEth = await collection.getLatestPriceInEth()

    const mintQuantity = 1;

    // value = price times quantity
    const payValue = priceInEth.mul(mintQuantity)

    tx = await collection.connect(user).mint([encodedDNA], true, {value: priceInEth.toString()})
    await tx.wait()

    expect(await collection.balanceOf(user.address)).to.equal(1);
    expect(await collection.totalSupply()).to.equal(1);
  });

  it("should be able to Mint with 'approved' USDT", async function () {

    // enables the sale
    let tx = await collection.enableSale();
    await tx.wait();

    tx = await usdt.connect(owner).transfer(user.address, price);
    await tx.wait();

    // approve token transfer
    tx = await usdt.connect(user).approve(collection.address, price);
    await tx.wait();

    tx = await collection.connect(user).mint([encodedDNA], false);
    await tx.wait()

    expect(await collection.balanceOf(user.address)).to.equal(1);
    expect(await collection.totalSupply()).to.equal(1);
  });

  it("should not be able to mint without 'approved' USDT", async function () {

    // enables the sale
    let tx = await collection.enableSale();
    await tx.wait();

    tx = await usdt.connect(owner).transfer(user.address, price);
    await tx.wait();

    await expect(
      collection.connect(user).mint([encodedDNA], false)
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'CryptoSurfersNFT::mint: USDT allowance is insufficient'");
  });

  it("should be able to Mint for someone else in public sale with ETH using different dnas", async function () {

    // enables the sale
    let tx = await collection.enableSale();
    await tx.wait();

    const priceInEth = await collection.getLatestPriceInEth()

    const mintQuantity = 3;

    // value = price times quantity
    const payValue = priceInEth.mul(mintQuantity)

    tx = await collection.connect(user).mintTo(owner.address, [encodedDNA, encodedDNA2, encodedDNA3], true, {value: payValue.toString()})
    await tx.wait()

    expect(await collection.balanceOf(owner.address)).to.equal(3);
    expect(await collection.totalSupply()).to.equal(3);
    expect(await collection.tokenURI(encodedDNA)).not.to.be.reverted;
  });

  it("should not be able to Mint for someone else in public sale with ETH using the same DNA", async function () {

    // enables the sale
    let tx = await collection.enableSale();
    await tx.wait();

    const priceInEth = await collection.getLatestPriceInEth()

    const mintQuantity = 1;

    tx = await collection.connect(user).mintTo(owner.address, [encodedDNA], true, {value: priceInEth.toString()})
    await tx.wait()

    // value = price times quantity
    const payValue = priceInEth.mul(mintQuantity)

    await expect(
      collection.connect(user).mint([encodedDNA], true, {value: payValue.toString()})
    ).to.rejectedWith("VM Exception while processing transaction: reverted with reason string 'ERC721: token already minted'");
  });
});