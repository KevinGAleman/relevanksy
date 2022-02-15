const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Relevanksy", function () {
    it("Should change the name and symbol when called by the owner", async function () {
        const relevanksyFactory = await ethers.getContractFactory("Relevanksy");
        const relevanksy = await relevanksyFactory.deploy();
        await relevanksy.deployed();

        expect(await relevanksy.name()).to.equal("Relevanksy");
        expect(await relevanksy.symbol()).to.equal("RSY");

        const setNameTx = await relevanksy.changeTokenName("Grimace");
        await setNameTx.wait();
        expect(await relevanksy.name()).to.equal("Grimace");

        const setSymbolTx = await relevanksy.changeTokenSymbol("GrimaceRSY");
        await setSymbolTx.wait();
        expect(await relevanksy.symbol()).to.equal("GrimaceRSY");
    });
});