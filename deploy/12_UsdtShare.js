module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const protocol = await deployments.get("Protocol");
    const usdtShare = await deploy('ShareToken', {
        from: deployer,
        log: true,
        args: [
            "LNX USDT Share Token",
            "lnxUsdtShare",
            protocol.address
        ]
    });
    await execute(
        'Protocol',
        { from: deployer, log: true },
        'setBorrowToken',
        '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
        usdtShare.address
    );
    console.log("USDT share set up");
};

module.exports.tags = ['share'];