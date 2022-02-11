const main = async () => {
    const [owner, randomPerson] = await hre.ethers.getSigners();
    const relevanksyFactory = await hre.ethers.getContractFactory("Relevanksy");
    const relevanksy = await relevanksyFactory.deploy();
    await relevanksy.deployed();

    console.log("Contract deployed to:", relevanksy.address);
    console.log("Contract deployed by:", owner.address);

    let waveCount;
    waveCount = await relevanksy.getTotalWaves();

    let waveTxn = await relevanksy.wave();
    await waveTxn.wait();

    waveTxn = await relevanksy.connect(randomPerson).wave();
    await waveTxn.wait();

    waveCount = await relevanksy.getTotalWaves();
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