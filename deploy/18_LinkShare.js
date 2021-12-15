module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const linkShare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX LINK Share Token",
            "lnxLinkShare",
            protocol.address
        ]
    });
    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setBorrowToken',
        '0xf97f4df75117a78c1A5a0DBb814Af92458539FB4',
        linkShare.address
    );
    console.log("LINK share set up");
};

module.exports.tags = ['share'];