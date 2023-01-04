// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@test/utils/DSTestPlus.sol';
import 'keep3r/interfaces/IKeep3r.sol';
import 'keep3r/interfaces/peripherals/IKeep3rJobs.sol';
import '@contracts/jobs/Keep3rRatedJob.sol';
import 'keep3r/interfaces/peripherals/IGovernable.sol';

contract Keep3rRatedJobForTest is Keep3rRatedJob {
  constructor(address governance) Governable(governance) {}

  function upkeepForTest() external upkeep(msg.sender, usdPerGasUnit) {}
}

contract Base is DSTestPlus {
  address governance = label(address(100), 'governance');
  address keeper = label(address(101), 'keeper');

  IKeep3r keep3r;
  Keep3rRatedJobForTest job;

  function setUp() public virtual {
    job = new Keep3rRatedJobForTest(governance);
    keep3r = IKeep3r(mockContract(address(job.keep3r()), 'keep3r'));
  }
}

contract UnitKeep3rRatedJobSetUsdPerGasUnit is Base {
  event UsdPerGasUnitSet(uint256 usdPerGasUnit);

  function testRevertIfNotGovernance(IKeep3r fuzzKeep3r) public {
    vm.expectRevert(abi.encodeWithSelector(IGovernable.OnlyGovernance.selector));
    job.setKeep3r(fuzzKeep3r);
  }

  function testSetUsdPerGasUnit(uint256 usdPerGasUnit) public {
    vm.prank(governance);
    job.setUsdPerGasUnit(usdPerGasUnit);

    assertEq(job.usdPerGasUnit(), usdPerGasUnit);
  }

  function testEmitEvent(uint256 usdPerGasUnit) public {
    vm.expectEmit(false, false, false, true);
    emit UsdPerGasUnitSet(usdPerGasUnit);

    vm.prank(governance);
    job.setUsdPerGasUnit(usdPerGasUnit);
  }
}

contract UnitKeep3rRatedJobSetKeep3r is Base {
  event Keep3rSet(IKeep3r keep3r);

  function testRevertIfNotGovernance(IKeep3r fuzzKeep3r) public {
    vm.expectRevert(abi.encodeWithSelector(IGovernable.OnlyGovernance.selector));
    job.setKeep3r(fuzzKeep3r);
  }

  function testSetKeep3r(IKeep3r fuzzKeep3r) public {
    vm.prank(governance);
    job.setKeep3r(fuzzKeep3r);

    assertEq(address(job.keep3r()), address(fuzzKeep3r));
  }

  function testEmitEvent(IKeep3r fuzzKeep3r) public {
    vm.expectEmit(false, false, false, true);
    emit Keep3rSet(fuzzKeep3r);

    vm.prank(governance);
    job.setKeep3r(fuzzKeep3r);
  }
}

contract UnitKeep3rRatedJobUpkeep is Base {
  function setUp() public override {
    super.setUp();
    vm.mockCall(address(keep3r), abi.encodeWithSelector(IKeep3rJobWorkableRated.worked.selector, keeper, job.usdPerGasUnit()), abi.encode());
  }

  function testRevertIfInvalidKeeper() public {
    vm.mockCall(address(keep3r), abi.encodeWithSelector(IKeep3rJobWorkable.isKeeper.selector), abi.encode(false));

    vm.expectRevert(abi.encodeWithSelector(IKeep3rJob.InvalidKeeper.selector));
    job.upkeepForTest();
  }

  function testCallWorked() public {
    vm.mockCall(address(keep3r), abi.encodeWithSelector(IKeep3rJobWorkable.isKeeper.selector), abi.encode(true));
    vm.expectCall(address(keep3r), abi.encodeWithSelector(IKeep3rJobWorkableRated.worked.selector, keeper, job.usdPerGasUnit()));

    vm.prank(keeper);
    job.upkeepForTest();
  }
}
