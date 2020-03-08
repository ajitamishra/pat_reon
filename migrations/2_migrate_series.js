const series = artifacts.require("./Series.sol");

module.exports = function(deployer) {
  deployer.deploy(series,"ProofOfCast",web3.utils.toWei('0.005','ether'),14*24*60*60/15);
};
