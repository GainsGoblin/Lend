module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const wrappedglpmanager = await deployments.get("WrappedGLPManager");
    const stakerewards =  await deployments.get("StakeRewards");
    const wglp = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "Wrapped GLP",
            "WGLP",
            wrappedglpmanager.address
        ]
    });


    await execute(
        'StakeRewards',
        { from: deployer, log: true },
        'setWGLP',
        wglp.address,
    );

    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setWGLPManager',
        wrappedglpmanager.address,
    );

    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setWGLP',
        wglp.address,
    );

    await execute(
        'WrappedGLPManager',
        { from: deployer, log: true },
        'setWGLP',
        wglp.address,
    );
    console.log("Wrapped GLP set up");
    console.log("Protocol set up, READY TO BE USED");
};

module.exports.tags = ['share'];