module.exports = async ({ getNamedAccounts, deployments }) => {
    const { deploy, execute } = deployments;
    const {
        deployer
    } = await getNamedAccounts();
    const lnxrewards = await deployments.get("LNXRewards");
    const stakerewards = await deployments.get("StakeRewards");
    const protocol = await deploy('Protocol', {
        from: deployer,
        log: true,
        args: [
            "0x489ee077994B6658eAfA855C308275EAd8097C4A", // Vault
            "0xA906F338CB21815cBc4Bc87ace9e68c87eF8d8F1", // RewardsRouterV2
            "0x4277f8F2c384827B5273592FF7CeBd9f2C1ac258", // GLP
            "0x82aF49447D8a07e3bd95BD0d56f35241523fBab1", // WETH
            lnxrewards.address,
            stakerewards.address,
            "0x1CF4579904EB2ACDA0E4081E39eC10d0c32B5DE3", // Price Feed
            "0x321F653eED006AD1C29D174e17d96351BDe22649" // GLPManager
        ]
    });
    await execute(
        'LNXRewards',
        {from: deployer, log: true},
        'setProtocol',
        protocol.address
    );
    console.log("LNX Rewards contract ready");

    await execute(
        'StakeRewards',
        {from: deployer, log: true},
        'setProtocol',
        protocol.address
    );
    console.log("Staking Rewards contract ready");
};

module.exports.tags = ['protocol'];