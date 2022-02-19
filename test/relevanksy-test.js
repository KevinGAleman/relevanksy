const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("Relevanksy", function () {
    var relevanksy;
    var owner, addr1, addr2, marketingWallet, devWallet;
    var router;
    var wbnb;
    const routerABI = require("./RouterABI.json");
    const wbnbABI = require("./WBNBABI.json");
    const pcsRouterAddress = "0x10ED43C718714eb63d5aA57B78B54704E256024E";
    const pcsRouterTestnetAddress = "0xD99D1c33F9fC3444f8101754aBC46c52416550D1";
    const wbnbAddress = "0xbb4CdB9CBd36B01bD1cBaEBF2De08d9173bc095c";
    const wbnbTestnetAddress = "0xae13d989dac2f0debff460ac112a837c89baa7cd";
    const liqPairTestnetAddress = "0x99002ff5b686e65bd01f18b5b536e57b1b73ee67";

    before(async function () {
        const relevanksyFactory = await ethers.getContractFactory("Relevanksy");
        relevanksy = await relevanksyFactory.deploy();
        await relevanksy.deployed();
        [owner, addr1, addr2, marketingWallet, devWallet] = await ethers.getSigners();
        router = new ethers.Contract(pcsRouterTestnetAddress, routerABI, owner);
        wbnb = await ethers.getContractAt(wbnbABI, wbnbTestnetAddress, owner);
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

    it("Should transfer appropriately", async function () {
        // Transfer 50 tokens from owner to addr1
        await relevanksy.transfer(addr1.address, 50);
        expect(await relevanksy.balanceOf(addr1.address)).to.equal(50);

        // Transfer 50 tokens from addr1 to addr2
        await relevanksy.connect(addr1).transfer(addr2.address, 50);
        expect(await relevanksy.balanceOf(addr2.address)).to.equal(50);
    });

    it("Should tax the hell out of bots before the launch happens and sell to the contract", async function () {
        // TODO: This is temporary because I don't have WBNB in the other accounts on testnet
        var wbnbTransferAmount = ethers.utils.parseUnits("1", 17);
        var wbnbPurchaseAmount = ethers.utils.parseUnits("1", 15);
        await wbnb.transfer(relevanksy.address, wbnbTransferAmount);
        await wbnb.transfer(addr1.address, wbnbTransferAmount);
        await wbnb.transfer(addr2.address, wbnbTransferAmount);

        await relevanksy.approve(pcsRouterTestnetAddress, ethers.utils.parseUnits("3", 17));
        await wbnb.approve(pcsRouterTestnetAddress, ethers.utils.parseUnits("1", 40));

        await router.addLiquidity(
            relevanksy.address,
            wbnbTestnetAddress,
            ethers.utils.parseUnits("3", 17),
            ethers.utils.parseUnits("5", 17),
            0,
            0,
            owner.address,
            Date.now() + 1000 * 60 * 10
        );

        for (var i = 0; i<7; i++) {
            await router.connect(addr1).swapExactETHForTokensSupportingFeeOnTransferTokens(
                0, 
                [wbnb.address, relevanksy.address], 
                addr1.address, 
                Date.now() + 1000 * 60 * 10, 
                {
                    'value': wbnbPurchaseAmount,
                    'gasLimit': 2140790,
                    'gasPrice': ethers.utils.parseUnits('10', 'gwei')
                }
            );
        }

        await relevanksy.connect(addr1).approve(pcsRouterTestnetAddress, ethers.utils.parseUnits("3", 17));
        await router.connect(addr1).swapExactTokensForETHSupportingFeeOnTransferTokens(
            await relevanksy.balanceOf(addr1.address), 
            0,
            [relevanksy.address, wbnb.address], 
            addr1.address, 
            Date.now() + 1000 * 60 * 10, 
            {
                'gasLimit': 2140790,
                'gasPrice': ethers.utils.parseUnits('10', 'gwei')
            }
        );
    });

    it("Should change fee percentages when called by the owner", async function () {
        await relevanksy.setBuyFees(2, 4, 4);
        await relevanksy.setSellFees(2, 4, 4);

        expect(await relevanksy._totalBuyFees()).to.equal(10);
        expect(await relevanksy._totalSellFees()).to.equal(10);
    });

    it("Should change max balance and max transaction percentages when called by the owner", async function () {
        await relevanksy.setMaxBalancePercentage(3);
        await relevanksy.setMaxTxPercentage(10);

        expect(await relevanksy._maxBalance()).to.equal(ethers.utils.parseUnits("3", 16));
        expect(await relevanksy._maxTx()).to.equal(ethers.utils.parseUnits("10", 15));
    });

    it("Should not tax the hell out of based buyers who wait for the launch signal", async function () {
        var wbnbPurchaseAmount = ethers.utils.parseUnits("1", 15);

        await router.connect(addr1).swapExactETHForTokensSupportingFeeOnTransferTokens(
            0, 
            [wbnb.address, relevanksy.address], 
            addr1.address, 
            Date.now() + 1000 * 60 * 10, 
            {
                'value': wbnbPurchaseAmount,
                'gasLimit': 2140790,
                'gasPrice': ethers.utils.parseUnits('10', 'gwei')
            }
        );

        await router.connect(addr1).swapExactTokensForETHSupportingFeeOnTransferTokens(
            await relevanksy.balanceOf(addr1.address), 
            0,
            [relevanksy.address, wbnb.address], 
            addr1.address, 
            Date.now() + 1000 * 60 * 10, 
            {
                'gasLimit': 2140790,
                'gasPrice': ethers.utils.parseUnits('10', 'gwei')
            }
        );
    });

    it("Should not allow a wallet to accumulate more than max balance", async function () {
        var wbnbPurchaseAmount = ethers.utils.parseUnits("15", 15);
        
        for (var i = 0; i<4; i++) {
            await router.connect(addr1).swapExactETHForTokensSupportingFeeOnTransferTokens(
                0, 
                [wbnb.address, relevanksy.address], 
                addr1.address, 
                Date.now() + 1000 * 60 * 10, 
                {
                    'value': wbnbPurchaseAmount,
                    'gasLimit': 2140790,
                    'gasPrice': ethers.utils.parseUnits('10', 'gwei')
                }
            );
        }

        expect(
            router.connect(addr1).swapExactETHForTokensSupportingFeeOnTransferTokens(
                0, 
                [wbnb.address, relevanksy.address], 
                addr1.address, 
                Date.now() + 1000 * 60 * 10, 
                {
                    'value': wbnbPurchaseAmount,
                    'gasLimit': 2140790,
                    'gasPrice': ethers.utils.parseUnits('10', 'gwei')
                }
            )
        ).to.be.revertedWith("");
    });

    it("Should now allow a wallet to buy/sell more than the max transaction", async function() {
        expect(
            router.connect(addr1).swapExactTokensForETHSupportingFeeOnTransferTokens(
                await relevanksy.balanceOf(addr1.address), 
                0,
                [relevanksy.address, wbnb.address], 
                addr1.address, 
                Date.now() + 1000 * 60 * 10, 
                {
                    'gasLimit': 2140790,
                    'gasPrice': ethers.utils.parseUnits('10', 'gwei')
                }
            )
        ).to.be.revertedWith("");

        await router.connect(addr1).swapExactTokensForETHSupportingFeeOnTransferTokens(
            await relevanksy.balanceOf(addr1.address)/4, 
            0,
            [relevanksy.address, wbnb.address], 
            addr1.address, 
            Date.now() + 1000 * 60 * 10, 
            {
                'gasLimit': 2140790,
                'gasPrice': ethers.utils.parseUnits('10', 'gwei')
            }
        );
    });

    it("Should not allow fees to be set higher than expected", async function () {
        await expect(relevanksy.setBuyFees(3, 3, 3)).to.be.revertedWith("");
        await expect(relevanksy.setSellFees(3, 3, 3)).to.be.revertedWith("");
        await expect(relevanksy.setBuyFees(1, 30, 30)).to.be.revertedWith("");
        await expect(relevanksy.setSellFees(1, 30, 30)).to.be.revertedWith("");

        expect(await relevanksy._totalBuyFees()).to.equal(10);
        expect(await relevanksy._totalSellFees()).to.equal(10);
    });

    it("Should not allow max transaction and max balance percentages to be set too low", async function () {
        await expect(relevanksy.setMaxBalancePercentage(1)).to.be.revertedWith("");
        await expect(relevanksy.setMaxTxPercentage(4)).to.be.revertedWith("");

        expect(await relevanksy._maxBalance()).to.equal(ethers.utils.parseUnits("3", 16));
        expect(await relevanksy._maxTx()).to.equal(ethers.utils.parseUnits("10", 15));
    });
});