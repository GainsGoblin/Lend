module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    let {
        deployer
    } = await getNamedAccounts();
    const lnxtoken = await deployments.get("LNXToken");
    const lnxrewards = await deploy('LNXRewards', {
        from: deployer,
        log: true,
        args: [lnxtoken.address]
    });
    await execute(
        'LNXToken',
        {from: deployer, log: true},
        'setRewards',
        lnxrewards.address
    );
    console.log("LNX Token ready");
};

module.exports.tags = ['lnxrewards'];