const hre = require("hardhat");

async function main() {
    if (hre.network.name === "localhost")
    {
        console.log("Deploying Token1 and Token2");
        const Relevanksy = await hre.ethers.getContractFactory("Relevanksy");
        const relevanksyFactory = await Relevanksy.deploy();
        await relevanksyFactory.deployed();

        console.log("Relevanksy is deployed to address: ", relevanksyFactory.address)
    }
    else if (hre.network.name == "ropstenTest")
    {
      // Ropsten ERC20Token1
        token1Address = "0x8d1ddfe0860b9e6632579400aebf7735684c8bce"
      // Meter-ERC20
        token2Address = "0x8f9ec10f71afc10b123234e470d625713fc59514"
    }
    else {
        throw new Error(`Invalid network ${hre.network.name}`)
    }

    const [deployer] = await hre.ethers.getSigners();
    const accountBalance = await deployer.getBalance();

    console.log("Deploying contracts with account: ", deployer.address);
    console.log("Account balance: ", accountBalance.toString());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });