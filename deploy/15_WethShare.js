module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const wethShare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX WETH Share Token",
            "lnxWethShare",
            protocol.address
        ]
    });
    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setBorrowToken',
        '0x82aF49447D8a07e3bd95BD0d56f35241523fBab1',
        wethShare.address
    );
    console.log("WETH share set up");
};

module.exports.tags = ['share'];