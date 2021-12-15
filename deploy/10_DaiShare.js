module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const daiShare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX DAI Share Token",
            "lnxDaiShare",
            protocol.address
        ]
    });
    await execute(
        "Protocol",
        { from: deployer, log: true },
        'setBorrowToken',
        '0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1',
        daiShare.address
    );
    console.log("DAI share set up");
};

module.exports.tags = ['share'];