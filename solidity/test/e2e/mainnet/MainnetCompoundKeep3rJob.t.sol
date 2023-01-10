// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@test/e2e/mainnet/CommonMainnet.sol';

contract E2EMainnetCompoundKeep3rJob is CommonE2EBase {
  uint256 public tokenId = 360274;
  address public token0;
  address public token1;
  address[] public tokens;
  uint256[] public thresholds;

  uint256 threshold = 20_000;

  function setUp() public override {
    super.setUp();

    _setUpJob(compoundJob);

    // Check which tokens have the tokenId
    (, , token0, token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

    // Add tokens to the whitelist
    vm.startPrank(governance);

    _addTokenToWhitelist();

    vm.stopPrank();

    // costs in dollars were calculated using as gasFee = 14077421096
  }

  function testWorkForFree() public {
    // WorkForFree
    vm.prank(user1);
    compoundJob.workForFree(tokenId);

    uint256 afterBalanceToken0 = compoundor.accountBalances(address(compoundJob), token0);
    uint256 afterBalanceToken1 = compoundor.accountBalances(address(compoundJob), token1);

    // Check the balanaces
    assertGt(afterBalanceToken0, 0);
    assertGt(afterBalanceToken1, 0);
  }

  function testWork() public {
    // Work
    vm.prank(keeper);
    compoundJob.work(tokenId);

    uint256 afterBalanceToken0 = compoundor.accountBalances(address(compoundJob), token0);
    uint256 afterBalanceToken1 = compoundor.accountBalances(address(compoundJob), token1);

    // Check the balanaces
    assertGt(afterBalanceToken0, 0);
    assertGt(afterBalanceToken1, 0);
  }

  function testWorkRevertSmallCompound() public {
    thresholds[0] = 1 ether;
    thresholds[1] = 1 ether;
    vm.prank(governance);
    compoundJob.addTokenToWhitelist(tokens, thresholds);

    vm.expectRevert(abi.encodeWithSelector(ICompoundJob.CompoundJob_SmallCompound.selector));

    // Work
    vm.prank(keeper);
    compoundJob.work(tokenId);
  }

  function _addTokenToWhitelist() internal {
    tokens.push(token0);
    tokens.push(token1);
    thresholds.push(threshold);
    thresholds.push(threshold);

    compoundJob.addTokenToWhitelist(tokens, thresholds);
  }
}
