module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const wbtcShare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX WBTC Share Token",
            "lnxWbtcShare",
            protocol.address
        ]
    });
    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setBorrowToken',
        '0x2f2a2543B76A4166549F7aaB2e75Bef0aefC5B0f',
        wbtcShare.address
    );
    console.log("WBTC share set up");
};

module.exports.tags = ['share'];