// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@test/e2e/optimism/CommonOptimism.sol';

contract E2EOptimismAutoCompound is CommonE2EBase {
  uint256 tokenId = 296494;
  ICompoundor.AutoCompoundParams params;

  function setUp() public override {
    super.setUp();
  }

  function testWithdrawRewardTrueSwapTrue() external basicBalanceTest {
    // Autocompound and not collect rewards but swap
    params = ICompoundor.AutoCompoundParams(tokenId, ICompoundor.RewardConversion.NONE, true, true);
    (uint256 reward0, uint256 reward1, , ) = compoundor.autoCompound(params);
  }

  function testWithdrawRewardFalseSwapTrue() external basicBalanceTest {
    // Autocompound and not collect rewards but swap
    params = ICompoundor.AutoCompoundParams(tokenId, ICompoundor.RewardConversion.NONE, false, true);
    compoundor.autoCompound(params);
  }

  function testWithdrawRewardTrueSwapFalse() external basicBalanceTest {
    // Autocompound and collect rewards without swap
    params = ICompoundor.AutoCompoundParams(tokenId, ICompoundor.RewardConversion.NONE, true, false);
    (uint256 reward0, uint256 reward1, , ) = compoundor.autoCompound(params);
  }

  function testWithdrawRewardFalseSwapFalse() external basicBalanceTest {
    // Autocompound without collect nor swap
    params = ICompoundor.AutoCompoundParams(tokenId, ICompoundor.RewardConversion.NONE, false, false);
    compoundor.autoCompound(params);
  }

  modifier basicBalanceTest() {
    // Check which tokens have the tokenId
    (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

    uint256 initialBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 initialBalanceToken1 = IERC20(token1).balanceOf(user1);

    _;

    uint256 afterBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 afterBalanceToken1 = IERC20(token1).balanceOf(user1);

    // Check the balanaces
    assertEq(afterBalanceToken0 - initialBalanceToken0, 0);
    assertEq(afterBalanceToken1 - initialBalanceToken1, 0);
  }
}
