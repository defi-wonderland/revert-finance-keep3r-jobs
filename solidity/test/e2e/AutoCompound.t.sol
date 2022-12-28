// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@test/e2e/Common.sol';

contract E2EAutoCompound is CommonE2EBase {
  uint256 tokenId = 360274;
  ICompoundor.AutoCompoundParams params;

  function setUp() public override {
    super.setUp();

    // costs in dollars were calculated using as gasFee = 14077421096
  }

  function testWithdrawRewardTrueSwapTrue() external {
    vm.startPrank(user1);

    // Check which tokens have the tokenId
    (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

    uint256 initialBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 initialBalanceToken1 = IERC20(token1).balanceOf(user1);

    // Autocompound and collect rewards adn swap
    params = ICompoundor.AutoCompoundParams(tokenId, ICompoundor.RewardConversion.NONE, true, true);
    (uint256 reward0, uint256 reward1, , ) = compoundor.autoCompound(params);

    uint256 afterBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 afterBalanceToken1 = IERC20(token1).balanceOf(user1);

    // Check the balanaces
    assertEq(afterBalanceToken0 - initialBalanceToken0, reward0);
    assertEq(afterBalanceToken1 - initialBalanceToken1, reward1);

    // COST OF TRANSACTION IN DOLLAR = 8.7528 $
  }

  function testWithdrawRewardFalseSwapTrue() external {
    vm.startPrank(user1);

    // Check which tokens have the tokenId
    (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

    uint256 initialBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 initialBalanceToken1 = IERC20(token1).balanceOf(user1);

    // Autocompound and not collect rewards but swap
    params = ICompoundor.AutoCompoundParams(tokenId, ICompoundor.RewardConversion.NONE, false, true);
    compoundor.autoCompound(params);

    uint256 afterBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 afterBalanceToken1 = IERC20(token1).balanceOf(user1);

    // Check the balanaces
    assertEq(afterBalanceToken0 - initialBalanceToken0, 0);
    assertEq(afterBalanceToken1 - initialBalanceToken1, 0);

    // COST OF TRANSACTION IN DOLLAR = 8.7320 $
  }

  function testWithdrawRewardTrueSwapFalse() external {
    vm.startPrank(user1);

    // Check which tokens have the tokenId
    (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

    uint256 initialBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 initialBalanceToken1 = IERC20(token1).balanceOf(user1);

    // Autocompound and collect rewards without swap
    params = ICompoundor.AutoCompoundParams(tokenId, ICompoundor.RewardConversion.NONE, true, false);
    (uint256 reward0, uint256 reward1, , ) = compoundor.autoCompound(params);

    uint256 afterBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 afterBalanceToken1 = IERC20(token1).balanceOf(user1);

    // Check the balanaces
    assertEq(afterBalanceToken0 - initialBalanceToken0, reward0);
    assertEq(afterBalanceToken1 - initialBalanceToken1, reward1);

    // COST OF TRANSACTION IN DOLLAR = 7.2005 $
  }

  function testWithdrawRewardFalseSwapFalse() external {
    vm.startPrank(user1);

    // Check which tokens have the tokenId
    (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(tokenId);

    uint256 initialBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 initialBalanceToken1 = IERC20(token1).balanceOf(user1);

    // Autocompound without swap and collect
    params = ICompoundor.AutoCompoundParams(tokenId, ICompoundor.RewardConversion.NONE, false, false);
    compoundor.autoCompound(params);

    uint256 afterBalanceToken0 = IERC20(token0).balanceOf(user1);
    uint256 afterBalanceToken1 = IERC20(token1).balanceOf(user1);

    // Check the balanaces
    assertEq(afterBalanceToken0 - initialBalanceToken0, 0);
    assertEq(afterBalanceToken1 - initialBalanceToken1, 0);

    // COST OF TRANSACTION IN DOLLAR = 6.8479 $
  }
}
