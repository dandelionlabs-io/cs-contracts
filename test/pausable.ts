import { time, loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { deployCollection } from "./util/fixtures";

describe("Pausable", function () {
  let collection, owner, user;
  beforeEach(async () => {
      ({ collection, owner, user } = await loadFixture(deployCollection));
  });


  it("Onwer can pause the contract", async function () {
    const tx = await collection.pause()
    await tx.wait();
    expect(await collection.paused()).to.equal(true);
  });

  it("Non-owner can't pause the contract", async function () {    
    await expect(
      collection.connect(user).pause()
    ).to.be.rejectedWith(
      "VM Exception while processing transaction: reverted with reason string 'Ownable: caller is not the owner'"
    );
    expect(await collection.paused()).to.equal(false);
  });
});
