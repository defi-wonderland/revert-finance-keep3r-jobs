// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@contracts/jobs/CompoundKeep3rJob.sol';
import '@test/utils/DSTestPlus.sol';
import '@interfaces/jobs/ICompoundJob.sol';

contract CompoundKeep3rJobForTest is CompoundKeep3rJob {
  using EnumerableMap for EnumerableMap.AddressToUintMap;
  address public upkeepKeeperForTest;

  constructor(
    address _governance,
    ICompoundor _compoundor,
    INonfungiblePositionManager _nonfungiblePositionManager
  ) CompoundKeep3rJob(_governance, _compoundor, _nonfungiblePositionManager) {}

  function addTokenWhitelistForTest(address[] calldata tokens, uint256[] calldata thresholds) external {
    for (uint256 _i; _i < tokens.length; ) {
      if (thresholds[_i] > 0) {
        _whitelistedThresholds.set(tokens[_i], thresholds[_i]);
      } else {
        _whitelistedThresholds.remove(tokens[_i]);
      }

      unchecked {
        ++_i;
      }
    }
  }

  function getTokenWhitelistForTest(address token) external view returns (uint256 threshold) {
    threshold = _whitelistedThresholds.get(token);
  }

  function addTokenIdStoredForTest(
    uint256 tokenId,
    address token0,
    address token1
  ) external {
    tokenIdStored[tokenId] = idTokens(token0, token1);
  }

  function pauseForTest() external {
    isPaused = true;
  }

  modifier upkeep(address _keeper) override {
    upkeepKeeperForTest = _keeper;
    _;
  }
}

contract Base is DSTestPlus {
  uint256 constant BASE = 10_000;

  // mock address
  address keeper = label(address(100), 'keeper');
  address governance = label(address(101), 'governance');

  // mock thesholds
  uint256 threshold0 = 1_000;
  uint256 threshold1 = 10_000;

  // mock tokens
  IERC20 mockToken0 = IERC20(mockContract('mockToken0'));
  IERC20 mockToken1 = IERC20(mockContract('mockToken1'));

  // mock arrays
  address[] tokens;
  uint256[] thresholds;

  // mock Compoundor and NonfungiblePositionManager
  ICompoundor mockCompoundor = ICompoundor(mockContract('mockCompoundor'));
  INonfungiblePositionManager mockNonfungiblePositionManager = INonfungiblePositionManager(mockContract('mockNonfungiblePositionManager'));

  IKeep3r keep3r;
  CompoundKeep3rJobForTest job;

  function setUp() public virtual {
    job = new CompoundKeep3rJobForTest(governance, mockCompoundor, mockNonfungiblePositionManager);
    keep3r = job.keep3r();

    tokens.push(address(mockToken0));
    tokens.push(address(mockToken1));
    thresholds.push(threshold0);
    thresholds.push(threshold1);

    job.addTokenWhitelistForTest(tokens, thresholds);
  }
}

contract UnitCompoundKeep3rJobWork is Base {
  event Worked();

  function setUp() public override {
    super.setUp();
    vm.mockCall(
      address(mockNonfungiblePositionManager),
      abi.encodeWithSelector(INonfungiblePositionManager.positions.selector),
      abi.encode(0, address(0), address(mockToken0), address(mockToken1), 0, 0, 0, 0, 0, 0, 0, 0)
    );
  }

  function testRevertIfPaused(uint256 tokenId) external {
    job.pauseForTest();

    vm.expectRevert(IPausable.Paused.selector);
    job.work(tokenId);
  }

  function testRevertIfNotWhitelist(uint256 tokenId) external {
    // sets thresholds to 0
    thresholds[0] = 0;
    thresholds[1] = 0;

    job.addTokenWhitelistForTest(tokens, thresholds);

    vm.expectRevert(ICompoundJob.CompoundJob_NotWhitelist.selector);
    job.work(tokenId);
  }

  function testRevertIfSmallCompound(
    uint256 tokenId,
    uint128 reward0,
    uint128 reward1
  ) external {
    vm.assume(reward0 < threshold0 / 2);
    vm.assume(reward1 < threshold1 / 2);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));

    vm.expectRevert(ICompoundJob.CompoundJob_SmallCompound.selector);
    job.work(tokenId);
  }

  function testWorkIdWith2Tokens(
    uint256 tokenId,
    uint128 reward0,
    uint128 reward1
  ) external {
    vm.assume(reward0 > threshold0);
    vm.assume(reward1 > threshold1);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));
    expectEmitNoIndex();
    emit Worked();
    job.work(tokenId);
  }

  function testWorkNewIdWithToken0(uint256 tokenId, uint128 reward0) external {
    vm.assume(reward0 > threshold0);
    thresholds[1] = 0;
    job.addTokenWhitelistForTest(tokens, thresholds);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, 0, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.work(tokenId);

    (address token0, ) = job.tokenIdStored(tokenId);

    assertEq(job.getTokenWhitelistForTest(token0), threshold0);
  }

  function testWorkNewIdWithToken1(uint256 tokenId, uint128 reward1) external {
    vm.assume(reward1 > threshold1);
    thresholds[0] = 0;
    job.addTokenWhitelistForTest(tokens, thresholds);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(0, reward1, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.work(tokenId);

    (, address token1) = job.tokenIdStored(tokenId);

    assertEq(job.getTokenWhitelistForTest(token1), threshold1);
  }

  function testWorkExistingIdToken(
    uint256 tokenId,
    uint128 reward0,
    uint128 reward1
  ) external {
    vm.assume(reward0 > threshold0);
    vm.assume(reward1 > threshold1);
    vm.clearMockedCalls();

    job.addTokenIdStoredForTest(tokenId, address(mockToken0), address(mockToken1));

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.work(tokenId);
  }
}

contract UnitCompoundKeep3rJobWorkForFree is Base {
  event Worked();

  function setUp() public override {
    super.setUp();
    vm.mockCall(
      address(mockNonfungiblePositionManager),
      abi.encodeWithSelector(INonfungiblePositionManager.positions.selector),
      abi.encode(0, address(0), address(mockToken0), address(mockToken1), 0, 0, 0, 0, 0, 0, 0, 0)
    );
  }

  function testRevertIfNotWhitelist(uint256 tokenId) external {
    // sets thresholds to 0
    thresholds[0] = 0;
    thresholds[1] = 0;
    job.addTokenWhitelistForTest(tokens, thresholds);

    vm.expectRevert(ICompoundJob.CompoundJob_NotWhitelist.selector);
    job.workForFree(tokenId);
  }

  function testRevertIfSmallCompound(
    uint256 tokenId,
    uint128 reward0,
    uint128 reward1
  ) external {
    vm.assume(reward0 < threshold0 / 2);
    vm.assume(reward1 < threshold1 / 2);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));

    vm.expectRevert(ICompoundJob.CompoundJob_SmallCompound.selector);
    job.workForFree(tokenId);
  }

  function testWorkForFreeNewIdWith2Tokens(
    uint256 tokenId,
    uint128 reward0,
    uint128 reward1
  ) external {
    vm.assume(reward0 > threshold0);
    vm.assume(reward1 > threshold1);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));
    expectEmitNoIndex();
    emit Worked();
    job.workForFree(tokenId);
  }

  function testWorkForFreeNewIdWithToken0(uint256 tokenId, uint128 reward0) external {
    vm.assume(reward0 > threshold0);
    thresholds[1] = 0;
    job.addTokenWhitelistForTest(tokens, thresholds);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, 0, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.workForFree(tokenId);

    (address token0, ) = job.tokenIdStored(tokenId);

    assertEq(job.getTokenWhitelistForTest(token0), threshold0);
  }

  function testWorkForFreeNewIdWithToken1(uint256 tokenId, uint128 reward1) external {
    vm.assume(reward1 > threshold1);
    thresholds[0] = 0;
    job.addTokenWhitelistForTest(tokens, thresholds);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(0, reward1, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.workForFree(tokenId);

    (, address token1) = job.tokenIdStored(tokenId);

    assertEq(job.getTokenWhitelistForTest(token1), threshold1);
  }

  function testWorkForFreeExistingIdToken(
    uint256 tokenId,
    uint128 reward0,
    uint128 reward1
  ) external {
    vm.assume(reward0 > threshold0);
    vm.assume(reward1 > threshold1);
    vm.clearMockedCalls();

    job.addTokenIdStoredForTest(tokenId, address(mockToken0), address(mockToken1));

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.workForFree(tokenId);
  }
}

contract UnitCompoundKeep3rJobSetCompoundor is Base {
  event CompoundorSetted(ICompoundor compoundor);

  function testRevertIfNotGovernance(ICompoundor compoundor) public {
    vm.expectRevert(abi.encodeWithSelector(IGovernable.OnlyGovernance.selector));
    job.setCompoundor(compoundor);
  }

  function testSetMultiplier(ICompoundor compoundor) external {
    vm.prank(governance);
    job.setCompoundor(compoundor);

    assertEq(address(compoundor), address(job.compoundor()));
  }

  function testEmitCollectMultiplier(ICompoundor compoundor) external {
    expectEmitNoIndex();
    emit CompoundorSetted(compoundor);

    vm.prank(governance);
    job.setCompoundor(compoundor);
  }
}

contract UnitCompoundKeep3rJobSetNonfungiblePositionManager is Base {
  event NonfungiblePositionManagerSetted(INonfungiblePositionManager nonfungiblePositionManager);

  function testRevertIfNotGovernance(INonfungiblePositionManager nonfungiblePositionManager) public {
    vm.expectRevert(abi.encodeWithSelector(IGovernable.OnlyGovernance.selector));
    job.setNonfungiblePositionManager(nonfungiblePositionManager);
  }

  function testSetMultiplier(INonfungiblePositionManager nonfungiblePositionManager) external {
    vm.prank(governance);
    job.setNonfungiblePositionManager(nonfungiblePositionManager);

    assertEq(address(nonfungiblePositionManager), address(job.nonfungiblePositionManager()));
  }

  function testEmitCollectMultiplier(INonfungiblePositionManager nonfungiblePositionManager) external {
    expectEmitNoIndex();
    emit NonfungiblePositionManagerSetted(nonfungiblePositionManager);

    vm.prank(governance);
    job.setNonfungiblePositionManager(nonfungiblePositionManager);
  }
}

contract UnitCompoundKeep3rJobAddTokenToWhitelist is Base {
  event TokenAddedToWhitelist(address token, uint256 threshold);
  address[] addTokens;
  uint256[] addThresholds;

  function testRevertIfNotGovernance(address[] calldata fuzzTokens, uint256[] calldata fuzzThresholds) public {
    vm.expectRevert(abi.encodeWithSelector(IGovernable.OnlyGovernance.selector));
    job.addTokenToWhitelist(fuzzTokens, fuzzThresholds);
  }

  function testAddTokenToWhitelist(
    address fuzzToken1,
    address fuzzToken2,
    uint256 fuzzThreshold1,
    uint256 fuzzThreshold2
  ) external {
    vm.assume(fuzzThreshold1 > 0 && fuzzThreshold2 > 0);
    vm.assume(fuzzToken1 != fuzzToken2);

    addTokens.push(fuzzToken1);
    addTokens.push(fuzzToken2);
    addThresholds.push(fuzzThreshold1);
    addThresholds.push(fuzzThreshold2);

    vm.startPrank(governance);
    job.addTokenToWhitelist(addTokens, addThresholds);

    for (uint256 i; i < addTokens.length; ++i) {
      assertEq(job.getTokenWhitelistForTest(addTokens[i]), addThresholds[i]);
    }
  }

  function testEmitTokenAddedToWhitelist(address[] calldata fuzzTokens, uint256[] calldata fuzzThresholds) external {
    vm.assume(fuzzTokens.length < 5 && fuzzTokens.length > 0 && fuzzThresholds.length > 4);
    expectEmitNoIndex();
    for (uint256 i; i < fuzzTokens.length; ++i) {
      emit TokenAddedToWhitelist(fuzzTokens[i], fuzzThresholds[i]);
    }

    vm.startPrank(governance);
    job.addTokenToWhitelist(fuzzTokens, fuzzThresholds);
  }
}

contract UnitCompoundKeep3rJobWithdraw is Base {
  function testWithdraw(address[] calldata fuzzTokens, uint256[] calldata balances) external {
    vm.assume(fuzzTokens.length < 5 && balances.length > 4);

    for (uint256 i; i < fuzzTokens.length; ++i) {
      vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.accountBalances.selector), abi.encode(balances[i]));

      vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.withdrawBalance.selector), abi.encode(true));
    }

    job.withdraw(fuzzTokens);
  }
}

contract UnitCompoundKeep3rJobGetWhitelistTokens is Base {
  function setUp() public override {
    super.setUp();
  }

  function testGetWhitelistTokens() external {
    tokens = job.getWhitelistedTokens();
    assertEq(tokens[0], address(mockToken0));
    assertEq(tokens[1], address(mockToken1));
  }
}
