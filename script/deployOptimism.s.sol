// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import 'forge-std/Script.sol';

import '@contracts/jobs/CompoundKeep3rRatedJob.sol';

contract DeployOptimism is Script {
  CompoundKeep3rRatedJob compoundKeep3rRatedJob;

  function run() public {
    address governance = vm.envAddress('mainnet_optimism');

    ICompoundor compoundorOptimism = ICompoundor(0x5411894842e610C4D0F6Ed4C232DA689400f94A1);
    INonfungiblePositionManager nonfungiblePositionManagerOptimism = INonfungiblePositionManager(0xC36442b4a4522E871399CD717aBDD847Ab11FE88);

    // Deploy compound Keep3r rated job
    compoundKeep3rRatedJob = new CompoundKeep3rRatedJob(governance, nonfungiblePositionManagerOptimism);
    console.log('COMPOUND_KEEP3R_RATED_JOB:', address(compoundKeep3rRatedJob));
  }
}
