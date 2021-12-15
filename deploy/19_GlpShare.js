module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const glpshare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX GLP Share Token",
            "lnxGlpShare",
            protocol.address
        ]
    });
    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setGLPShare',
        glpshare.address,
    );
    console.log("GLP share set up");
};

module.exports.tags = ['share'];