const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Relevanksy NFT", function () {
    var relevanksyNFT;
    var owner, addr1, addr2, addr3, addr4;

    before(async function () {
        const relevanksyNFTFactory = await ethers.getContractFactory("RelevanksyNFT");
        relevanksyNFT = await relevanksyNFTFactory.deploy();
        await relevanksyNFT.deployed();
        [owner, addr1, addr2, addr3, addr4] = await ethers.getSigners();
    });

    it("Should be created with the appropriate token information", async function () {
        expect(await relevanksyNFT.name()).to.equal("the relevanksy collection");
        expect(await relevanksyNFT.symbol()).to.equal("trc");
        expect(await relevanksyNFT._totalSupply()).to.equal(1000);
    });

    it("Should only allow the owner or the raffle contract to set a new allowlist", async function () {
        await relevanksyNFT._setRaffleContract(addr1.address);
        expect(relevanksyNFT.connect(addr2).setNewMinters([addr3.address])).to.be.revertedWith("");
        await relevanksyNFT.setNewMinters([addr2.address]);
        await relevanksyNFT.connect(addr1).setNewMinters([addr2.address]);
    });

    it("Should only allow wallets on the allowlist to mint a new Token", async function () {
        await relevanksyNFT.setNewMinters([addr2.address]);

        await relevanksyNFT.connect(addr2).mintToken("testUri");

        expect(relevanksyNFT.connect(addr1).mintToken("testUri")).to.be.revertedWith("");
    });

    it("Should not allow an allow-lister to mint twice", async function () {
        expect(relevanksyNFT.connect(addr2).mintToken("testUri")).to.be.revertedWith("");
    });

    it("Should clear the previous allow-list when a new one is set", async function () {
        await relevanksyNFT.setNewMinters([addr1.address, addr3.address, addr4.address]);

        expect(relevanksyNFT.connect(addr2).mintToken("testUri")).to.be.revertedWith("");
        await relevanksyNFT.connect(addr1).mintToken("testUri");
        await relevanksyNFT.connect(addr3).mintToken("testUri");
        await relevanksyNFT.connect(addr4).mintToken("testUri");
        expect(relevanksyNFT.connect(addr1).mintToken("testUri")).to.be.revertedWith("");
        expect(relevanksyNFT.connect(addr3).mintToken("testUri")).to.be.revertedWith("");
        expect(relevanksyNFT.connect(addr4).mintToken("testUri")).to.be.revertedWith("");
    });
});