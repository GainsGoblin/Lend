module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const wglpmanager = await deploy('WrappedGLPManager', {
        from: deployer,
        log: true,
        args: [
            protocol.address
        ]
    });
};

module.exports.tags = ['share'];