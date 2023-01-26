import { loadFixture } from "@nomicfoundation/hardhat-network-helpers";
import { expect } from "chai";
import { deployCollection } from "./util/fixtures";

describe("Operatable", function () {
  let collection, owner, user, operator;
  beforeEach(async () => {
      ({ collection, owner, user, operator } = await loadFixture(deployCollection));
  });

  it("Owner can add operators", async function () {
    expect(await collection.isOperator(operator.address)).to.equal(false);

    const tx = await collection.changeOperator(operator.address, true)
    await tx.wait();

    expect(await collection.isOperator(operator.address)).to.equal(true);
  });

  it("Owner can remove operators", async function () {
    expect(await collection.isOperator(operator.address)).to.equal(false);

    let tx = await collection.changeOperator(operator.address, true)
    await tx.wait();

    expect(await collection.isOperator(operator.address)).to.equal(true);

    tx = await collection.changeOperator(operator.address, false)
    await tx.wait();

    expect(await collection.isOperator(operator.address)).to.equal(false);
  });
});
