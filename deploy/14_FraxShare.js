module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const fraxShare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX FRAX Share Token",
            "lnxFraxShare",
            protocol.address
        ]
    });
    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setBorrowToken',
        '0x17FC002b466eEc40DaE837Fc4bE5c67993ddBd6F',
        fraxShare.address
    );
    console.log("FRAX share set up");
};

module.exports.tags = ['share'];