const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Relevanksy", function () {
    var relevanksy;

    before(async function () {
        const relevanksyFactory = await ethers.getContractFactory("Relevanksy");
        relevanksy = await relevanksyFactory.deploy();
        await relevanksy.deployed();
    });

    it("Should be instantiated with the appropriate token distribution", async function () {
        const tokenName = "Relevanksy";
        const tokenSymbol = "RSY";
        const decimals = 9;
        const totalSupply = ethers.utils.parseUnits("1", 18);
        const maxBalance = ethers.utils.parseUnits("2", 16);
        const maxTx = ethers.utils.parseUnits("5", 15);

        expect(await relevanksy.totalSupply()).to.equal(totalSupply);
        expect(await relevanksy.decimals()).to.equal(decimals);
        expect(relevanksy.maxBalance()).to.equal(maxBalance);
        expect(relevanksy.maxTx()).to.equal(maxTx);
        expect(await relevanksy.name()).to.equal(tokenName);
        expect(await relevanksy.symbol()).to.equal(tokenSymbol);
    });

    it("Should change the name and symbol when called by the owner", async function () {
        expect(await relevanksy.name()).to.equal("Relevanksy");
        expect(await relevanksy.symbol()).to.equal("RSY");

        const setNameTx = await relevanksy.changeTokenName("Grimace");
        await setNameTx.wait();
        expect(await relevanksy.name()).to.equal("Grimace");

        const setSymbolTx = await relevanksy.changeTokenSymbol("GrimaceRSY");
        await setSymbolTx.wait();
        expect(await relevanksy.symbol()).to.equal("GrimaceRSY");
    });

// Test totalSupply, taxes, other default values
});