// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@contracts/jobs/CompoundJob.sol';
import '@test/utils/DSTestPlus.sol';
import '@interfaces/jobs/ICompoundJob.sol';

contract CompoundJobForTest is CompoundJob {
  address public upkeepKeeperForTest;

  constructor(
    address _governance,
    ICompoundor _compoundor,
    INonfungiblePositionManager _nonfungiblePositionManager
  ) CompoundJob(_governance, _compoundor, _nonfungiblePositionManager) {}

  function addTokenWhiteListForTest(address _token, uint256 _threshold) external {
    whiteList[_token] = _threshold;
  }

  function addTokenIdStoredForTest(
    uint256 _tokenId,
    address token0,
    address token1
  ) external {
    tokenIdStored[_tokenId] = idTokens(token0, token1);
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

  // mock Compoundor and NonfungiblePositionManager
  ICompoundor mockCompoundor = ICompoundor(mockContract('mockCompoundor'));
  INonfungiblePositionManager mockNonfungiblePositionManager = INonfungiblePositionManager(mockContract('mockNonfungiblePositionManager'));

  IKeep3r keep3r;
  CompoundJobForTest job;

  function setUp() public virtual {
    job = new CompoundJobForTest(governance, mockCompoundor, mockNonfungiblePositionManager);
    keep3r = job.keep3r();

    // mock whiteList
    job.addTokenWhiteListForTest(address(mockToken0), threshold0);
    job.addTokenWhiteListForTest(address(mockToken1), threshold1);
  }
}

contract UnitCompoundJobWork is Base {
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

  function testRevertIfNotWhiteList(uint256 tokenId) external {
    // sets thresholds to 0
    job.addTokenWhiteListForTest(address(mockToken0), 0);
    job.addTokenWhiteListForTest(address(mockToken1), 0);

    vm.expectRevert(ICompoundJob.CompoundJob_NotWhiteList.selector);
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
    vm.assume(reward0 > BASE);
    vm.assume(reward1 > BASE);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));
    expectEmitNoIndex();
    emit Worked();
    job.work(tokenId);
  }

  function testWorkNewIdWithToken0(uint256 tokenId, uint128 reward0) external {
    vm.assume(reward0 > BASE);
    job.addTokenWhiteListForTest(address(mockToken1), 0);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, 0, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.work(tokenId);

    (address token0, address token1) = job.tokenIdStored(tokenId);

    assertEq(job.whiteList(token0), threshold0);
    assertEq(job.whiteList(token1), 0);
  }

  function testWorkNewIdWithToken1(uint256 tokenId, uint128 reward1) external {
    vm.assume(reward1 > BASE);
    job.addTokenWhiteListForTest(address(mockToken0), 0);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(0, reward1, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.work(tokenId);

    (address token0, address token1) = job.tokenIdStored(tokenId);

    assertEq(job.whiteList(token0), 0);
    assertEq(job.whiteList(token1), threshold1);
  }

  function testWorkExistingIdToken(
    uint256 tokenId,
    uint128 reward0,
    uint128 reward1
  ) external {
    vm.assume(reward0 > BASE);
    vm.assume(reward1 > BASE);
    vm.clearMockedCalls();

    job.addTokenIdStoredForTest(tokenId, address(mockToken0), address(mockToken1));

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.work(tokenId);
  }
}

contract UnitCompoundJobWorkForFree is Base {
  event Worked();

  function setUp() public override {
    super.setUp();
    vm.mockCall(
      address(mockNonfungiblePositionManager),
      abi.encodeWithSelector(INonfungiblePositionManager.positions.selector),
      abi.encode(0, address(0), address(mockToken0), address(mockToken1), 0, 0, 0, 0, 0, 0, 0, 0)
    );
  }

  function testRevertIfNotWhiteList(uint256 tokenId) external {
    // sets thresholds to 0
    job.addTokenWhiteListForTest(address(mockToken0), 0);
    job.addTokenWhiteListForTest(address(mockToken1), 0);

    vm.expectRevert(ICompoundJob.CompoundJob_NotWhiteList.selector);
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
    vm.assume(reward0 > BASE);
    vm.assume(reward1 > BASE);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));
    expectEmitNoIndex();
    emit Worked();
    job.workForFree(tokenId);
  }

  function testWorkForFreeNewIdWithToken0(uint256 tokenId, uint128 reward0) external {
    vm.assume(reward0 > BASE);
    job.addTokenWhiteListForTest(address(mockToken1), 0);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, 0, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.workForFree(tokenId);

    (address token0, address token1) = job.tokenIdStored(tokenId);

    assertEq(job.whiteList(token0), threshold0);
    assertEq(job.whiteList(token1), 0);
  }

  function testWorkForFreeNewIdWithToken1(uint256 tokenId, uint128 reward1) external {
    vm.assume(reward1 > BASE);
    job.addTokenWhiteListForTest(address(mockToken0), 0);

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(0, reward1, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.workForFree(tokenId);

    (address token0, address token1) = job.tokenIdStored(tokenId);

    assertEq(job.whiteList(token0), 0);
    assertEq(job.whiteList(token1), threshold1);
  }

  function testWorkForFreeExistingIdToken(
    uint256 tokenId,
    uint128 reward0,
    uint128 reward1
  ) external {
    vm.assume(reward0 > BASE);
    vm.assume(reward1 > BASE);
    vm.clearMockedCalls();

    job.addTokenIdStoredForTest(tokenId, address(mockToken0), address(mockToken1));

    vm.mockCall(address(mockCompoundor), abi.encodeWithSelector(ICompoundor.autoCompound.selector), abi.encode(reward0, reward1, 0, 0));

    expectEmitNoIndex();
    emit Worked();
    job.workForFree(tokenId);
  }
}

contract UnitCompoundJobSetCompoundor is Base {
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

contract UnitCompoundJobSetNonfungiblePositionManager is Base {
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

contract UnitCompoundJobAddTokenToWhiteList is Base {
  event TokenAddedToWhiteList(address token, uint256 threshold);

  function testRevertIfNotGovernance(address token, uint256 threshold) public {
    vm.expectRevert(abi.encodeWithSelector(IGovernable.OnlyGovernance.selector));
    job.addTokenToWhiteList(token, threshold);
  }

  function testSetMultiplier(address token, uint256 threshold) external {
    vm.prank(governance);
    job.addTokenToWhiteList(token, threshold);

    assertEq(threshold, job.whiteList(token));
  }

  function testEmitCollectMultiplier(address token, uint256 threshold) external {
    expectEmitNoIndex();
    emit TokenAddedToWhiteList(token, threshold);

    vm.prank(governance);
    job.addTokenToWhiteList(token, threshold);
  }
}