const Advertising = artifacts.require("Advertising");

module.exports = function (deployer) {
  deployer.deploy(Advertising);
};
