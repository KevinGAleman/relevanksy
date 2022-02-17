const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Relevanksy", function () {
    var relevanksy;

    before(async function () {
        const relevanksyFactory = await ethers.getContractFactory("Relevanksy");
        relevanksy = await relevanksyFactory.deploy();
        await relevanksy.deployed();
    });

    it("Should be created with the appropriate token distribution", async function () {
        expect(await relevanksy.totalSupply()).to.equal(ethers.utils.parseUnits("1", 18));
        expect(await relevanksy.decimals()).to.equal(9);
        expect(await relevanksy._maxBalance()).to.equal(ethers.utils.parseUnits("2", 16));
        expect(await relevanksy._maxTx()).to.equal(ethers.utils.parseUnits("5", 15));
        expect(await relevanksy.name()).to.equal("Relevanksy");
        expect(await relevanksy.symbol()).to.equal("RSY");
    });

    it("Should be created with the correct fees", async function () {
        expect(await relevanksy._totalBuyFees()).to.equal(99);
        expect(await relevanksy._totalSellFees()).to.equal(99);
    });

    it("Should change fee percentages when called by the owner", async function () {
        await relevanksy.setBuyFees(2, 5, 5);
        await relevanksy.setSellFees(2, 5, 4);

        expect(await relevanksy._totalBuyFees()).to.equal(12);
        expect(await relevanksy._totalSellFees()).to.equal(11);
    });

    it("Should change max balance and max transaction percentages when called by the owner", async function () {
        await relevanksy.setMaxBalancePercentage(3);
        await relevanksy.setMaxTxPercentage(10);

        expect(await relevanksy._maxBalance()).to.equal(ethers.utils.parseUnits("3", 16));
        expect(await relevanksy._maxTx()).to.equal(ethers.utils.parseUnits("10", 15));
    });

    it("Should not allow fees to be set higher than expected", async function () {
        await expect(relevanksy.setBuyFees(3, 3, 3)).to.be.revertedWith("");
        await expect(relevanksy.setSellFees(3, 3, 3)).to.be.revertedWith("");
        await expect(relevanksy.setBuyFees(1, 30, 30)).to.be.revertedWith("");
        await expect(relevanksy.setSellFees(1, 30, 30)).to.be.revertedWith("");

        expect(await relevanksy._totalBuyFees()).to.equal(12);
        expect(await relevanksy._totalSellFees()).to.equal(11);
    });

    it("Should not allow max transaction and max balance percentages to be set too low", async function () {
        await expect(relevanksy.setMaxBalancePercentage(1)).to.be.revertedWith("");
        await expect(relevanksy.setMaxTxPercentage(4)).to.be.revertedWith("");

        expect(await relevanksy._maxBalance()).to.equal(ethers.utils.parseUnits("3", 16));
        expect(await relevanksy._maxTx()).to.equal(ethers.utils.parseUnits("10", 15));
    });

// Test totalSupply, taxes, other default values
});