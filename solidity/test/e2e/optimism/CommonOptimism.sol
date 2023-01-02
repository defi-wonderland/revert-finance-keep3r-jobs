// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import 'forge-std/console.sol';
import '@interfaces/jobs/IKeep3rJob.sol';
import '@contracts/jobs/CompoundKeep3rRatedJob.sol';
import '@test/utils/DSTestPlus.sol';

contract CommonE2EBase is DSTestPlus {
  uint256 constant FORK_BLOCK = 427897;

  address user1 = label(address(100), 'user1');
  address governance = label(address(102), 'governance');
  address keeper = label(0x745a50320B6eB8FF281f1664Fc6713991661B129, 'keeper');
  address keep3rGovernance = label(0x0D5Dc686d0a2ABBfDaFDFb4D0533E886517d4E83, 'keep3rGovernance');

  uint256 userInitialBalance = 1_000_000_000 ether;

  CompoundJob compoundJob;

  IERC20 kp3r = IERC20(label(0x1cEB5cB57C4D4E2b2433641b95Dd330A33185A44, 'KP3R'));
  IERC20 dai = IERC20(label(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1, 'DAI'));
  IERC20 weth = IERC20(label(0x4200000000000000000000000000000000000006, 'WETH'));

  ICompoundor compoundor = ICompoundor(label(0x5411894842e610C4D0F6Ed4C232DA689400f94A1, 'Compoundor'));
  IKeep3r keep3r = IKeep3r(label(0xeb02addCfD8B773A5FFA6B9d1FE99c566f8c44CC, 'Keep3rV2'));
  INonfungiblePositionManager nonfungiblePositionManager =
    INonfungiblePositionManager(label(0xC36442b4a4522E871399CD717aBDD847Ab11FE88, 'NFPM'));

  function setUp() public virtual {
    vm.createSelectFork(vm.rpcUrl('optimism'), FORK_BLOCK);

    // Transfer WETH
    deal(address(weth), governance, userInitialBalance);
    deal(address(kp3r), governance, userInitialBalance);
    deal(address(weth), user1, userInitialBalance);

    // Deploy every contract needed
    vm.startPrank(governance);

    compoundJob = new CompoundKeep3rRatedJob(governance, compoundor, nonfungiblePositionManager);
    label(address(compoundJob), 'CompoundJob');

    vm.stopPrank();
  }

  /// @notice Adding job to the Keep3r network and providing credits
  function _setUpJob(IKeep3rJob job) internal {
    vm.startPrank(keep3rGovernance);
    keep3r.addJob(address(job));
    keep3r.forceLiquidityCreditsToJob(address(job), keep3r.liquidityMinimum() * 10);
    vm.stopPrank();
  }
}
