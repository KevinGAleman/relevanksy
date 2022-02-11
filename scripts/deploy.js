const main = async () => {
    const [deployer] = await hre.ethers.getSigners();
    const accountBalance = await deployer.getBalance();

    console.log("Deploying contracts with account: ", deployer.address);
    console.log("Account balance: ", accountBalance.toString());

    const relevanksyFactory = await hre.ethers.getContractFactory("Relevanksy");
    const relevanksy = await relevanksyFactory.deploy();
    await relevanksy.deployed();

    console.log("Relevanksy address: ", relevanksy.address);
};

const runMain = async () => {
    try {
        await main();
        process.exit(0);
    } catch (error) {
        console.log(error);
        process.exit(1);
    }
};

runMain();