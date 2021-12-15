module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const uniShare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX UNI Share Token",
            "lnxUniShare",
            protocol.address
        ]
    });
    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setBorrowToken',
        '0xFa7F8980b0f1E64A2062791cc3b0871572f1F7f0',
        uniShare.address
    );
    console.log("UNI share set up");
};

module.exports.tags = ['share'];