// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import 'forge-std/console.sol';
import '@interfaces/jobs/IKeep3rJob.sol';
import '@contracts/jobs/CompoundKeep3rRatedJob.sol';
import '@test/utils/DSTestPlus.sol';

contract CommonE2EBase is DSTestPlus {
  uint256 constant FORK_BLOCK = 71360840;

  address user1 = label(address(100), 'user1');
  address governance = label(address(102), 'governance');
  address keeper = label(0x9429cd74A3984396f3117d51cde46ea8e0e21487, 'keeper');
  address keep3rGovernance = label(0x7d6daDb31dBeBc68c8A0b2cCfE5C1f26F24bD41d, 'keep3rGovernance');

  uint256 userInitialBalance = 1_000_000_000 ether;

  CompoundJob compoundJob;

  IERC20 weth = IERC20(label(0x4200000000000000000000000000000000000006, 'WETH'));

  ICompoundor compoundor = ICompoundor(label(0x5411894842e610C4D0F6Ed4C232DA689400f94A1, 'Compoundor'));
  IKeep3r keep3r = IKeep3r(label(0x745a50320B6eB8FF281f1664Fc6713991661B129, 'Keep3rV2'));
  INonfungiblePositionManager nonfungiblePositionManager =
    INonfungiblePositionManager(label(0xC36442b4a4522E871399CD717aBDD847Ab11FE88, 'NFPM'));

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('optimism'), FORK_BLOCK);

    // Transfer WETH
    deal(address(weth), governance, userInitialBalance);
    deal(address(weth), user1, userInitialBalance);

    // Deploy every contract needed
    vm.startPrank(governance);

    compoundJob = new CompoundKeep3rRatedJob(governance, nonfungiblePositionManager);
    label(address(compoundJob), 'CompoundRatedJob');

    compoundJob.addCompoundorToWhitelist(compoundor);

    vm.stopPrank();
  }

  /// @notice Adding job to the Keep3r network and providing credits
  function _setUpJob(IKeep3rJob job) internal {
    vm.startPrank(keep3rGovernance);
    keep3r.addJob(address(job));
    keep3r.forceLiquidityCreditsToJob(address(job), 10e18);
    vm.stopPrank();
  }
}
