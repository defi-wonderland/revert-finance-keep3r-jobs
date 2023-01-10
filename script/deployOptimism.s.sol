// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import 'forge-std/Script.sol';

import '@contracts/jobs/CompoundKeep3rRatedJob.sol';

contract DeployOptimism is Script {
  CompoundKeep3rRatedJob compoundKeep3rRatedJob;

  function run() public {
    address deployer = vm.rememberKey(vm.envUint('DEPLOYER_PRIVATE_KEY'));
    address governance; // GOVERNANCE ADDRESS

    ICompoundor compoundorOptimism = ICompoundor(0x5411894842e610C4D0F6Ed4C232DA689400f94A1);
    INonfungiblePositionManager nonfungiblePositionManagerOptimism = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    vm.startBroadcast(deployer);

    // Deploy compound Keep3r rated job
    compoundKeep3rRatedJob = new CompoundKeep3rRatedJob(governance, compoundorOptimism, nonfungiblePositionManagerOptimism);
    console.log('COMPOUND_KEEP3R_RATED_JOB:', address(compoundKeep3rRatedJob));

    vm.stopBroadcast();
  }
}
