module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const usdcShare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX USDC Share Token",
            "lnxUsdcShare",
            protocol.address
        ]
    });
    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setBorrowToken',
        '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8',
        usdcShare.address
    );
    console.log("USDC share set up");
};

module.exports.tags = ['share'];