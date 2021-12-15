module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy } = deployments;
    const {
        LNXToken,
        deployer
    } = await getNamedAccounts();
    const lnxtoken = await deployments.get("LNXToken");
    await deploy('StakeRewards', {
        from: deployer,
        log: true,
        args: [lnxtoken.address, "0x489ee077994B6658eAfA855C308275EAd8097C4A"]
    });
};

module.exports.tags = ['stakerewards'];