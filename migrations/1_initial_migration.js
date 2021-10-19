const REALSeedSale = artifacts.require("REALSeedSale");

async function deployTestnet(deployer) {
  const REALSeedSaleDeploy = await deployer.deploy(REALSeedSale);
  console.log(
    `Deploy: REALSeedSaleDeploy Address = ${REALSeedSaleDeploy.address}`
  );
}

module.exports = function (deployer) {
  deployer.then(async () => {
    console.log(deployer.network);
    switch (deployer.network) {
      case "bsctestnet":
        await deployTestnet(deployer);
        break;
      case "bscmainnet":
        await deployTestnet(deployer);
        break;
      default:
        throw "Unsupported network";
    }
  });
};
