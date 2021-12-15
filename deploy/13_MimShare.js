module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const mimShare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX MIM Share Token",
            "lnxMimShare",
            protocol.address
        ]
    });
    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setBorrowToken',
        '0xFEa7a6a0B346362BF88A9e4A88416B77a57D6c2A',
        mimShare.address
    );
    console.log("MIM share set up");
};

module.exports.tags = ['share'];