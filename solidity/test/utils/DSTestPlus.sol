// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity >=0.8.0;

import 'ds-test/test.sol';
import 'forge-std/Test.sol';
import 'forge-std/Vm.sol';
import 'forge-std/console.sol';

contract DSTestPlus is Test {
  address constant DEAD_ADDRESS = 0xDeaDbeefdEAdbeefdEadbEEFdeadbeEFdEaDbeeF;
  address constant WETH_ADDRESS = 0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2;
  address constant UNISWAP_V3_FACTORY_ADDRESS = 0x1F98431c8aD98523631AE4a59f267346ea31F984;
  int24 internal constant MIN_TICK = -887272;
  int24 internal constant MAX_TICK = 887272;
  uint160 internal constant MIN_SQRT_RATIO = 4295128739;
  uint160 internal constant MAX_SQRT_RATIO = 1461446703485210103287273052203988822378723970342;
  uint16 internal constant STARTING_CARDINALITY = 64;

  string private checkpointLabel;
  uint256 private checkpointGasLeft = 1; // Start the slot warm.

  bytes32 internal nextAddressSeed = keccak256(abi.encodePacked('address'));

  function startMeasuringGas(string memory _checkpointLabel) internal virtual {
    checkpointLabel = _checkpointLabel;

    checkpointGasLeft = gasleft();
  }

  function stopMeasuringGas() internal virtual {
    uint256 checkpointGasLeft2 = gasleft();

    // Subtract 100 to account for the warm SLOAD in startMeasuringGas.
    uint256 gasDelta = checkpointGasLeft - checkpointGasLeft2 - 100;

    emit log_named_uint(string(abi.encodePacked(checkpointLabel, ' Gas')), gasDelta);
  }

  function fail(string memory err) internal virtual override {
    emit log_named_string('Error', err);
    fail();
  }

  function assertUint128Eq(uint128 a, uint128 b) internal virtual {
    assertEq(uint256(a), uint256(b));
  }

  function assertUint64Eq(uint64 a, uint64 b) internal virtual {
    assertEq(uint256(a), uint256(b));
  }

  function assertUint96Eq(uint96 a, uint96 b) internal virtual {
    assertEq(uint256(a), uint256(b));
  }

  function assertUint32Eq(uint32 a, uint32 b) internal virtual {
    assertEq(uint256(a), uint256(b));
  }

  function assertBoolEq(bool a, bool b) internal virtual {
    b ? assertTrue(a) : assertFalse(a);
  }

  function assertRelApproxEq(
    uint256 a,
    uint256 b,
    uint256 maxPercentDelta
  ) internal virtual {
    uint256 delta = a > b ? a - b : b - a;
    uint256 abs = a > b ? a : b;

    uint256 percentDelta = (delta * 1e18) / abs;

    if (percentDelta > maxPercentDelta) {
      emit log('Error: a ~= b not satisfied [uint]');
      emit log_named_uint('    Expected', b);
      emit log_named_uint('      Actual', a);
      emit log_named_uint(' Max % Delta', maxPercentDelta);
      emit log_named_uint('     % Delta', percentDelta);
      fail();
    }
  }

  function assertBytesEq(bytes memory a, bytes memory b) internal virtual {
    if (keccak256(a) != keccak256(b)) {
      emit log('Error: a == b not satisfied [bytes]');
      emit log_named_bytes('  Expected', b);
      emit log_named_bytes('    Actual', a);
      fail();
    }
  }

  function assertUintArrayEq(uint256[] memory a, uint256[] memory b) internal virtual {
    require(a.length == b.length, 'LENGTH_MISMATCH');

    for (uint256 i = 0; i < a.length; i++) {
      assertEq(a[i], b[i]);
    }
  }

  function assertAddressArrayEq(address[] memory a, address[] memory b) internal virtual {
    require(a.length == b.length, 'LENGTH_MISMATCH');

    for (uint256 i = 0; i < a.length; i++) {
      assertEq(a[i], b[i]);
    }
  }

  function min3(
    uint256 a,
    uint256 b,
    uint256 c
  ) internal pure returns (uint256) {
    return a > b ? (b > c ? c : b) : (a > c ? c : a);
  }

  function min2(uint256 a, uint256 b) internal pure returns (uint256) {
    return a > b ? b : a;
  }

  function label(address addy, string memory name) internal returns (address) {
    vm.label(addy, name);
    return addy;
  }

  function mockContract(address addy, string memory name) internal returns (address) {
    vm.etch(addy, new bytes(0x1));
    return label(addy, name);
  }

  function mockContract(string memory name) internal returns (address) {
    return mockContract(newAddress(), name);
  }

  function advanceTime(uint256 timeToAdvance) internal {
    vm.warp(block.timestamp + timeToAdvance);
  }

  function newAddress() internal returns (address) {
    address payable nextAddress = payable(address(uint160(uint256(nextAddressSeed))));
    nextAddressSeed = keccak256(abi.encodePacked(nextAddressSeed));
    return nextAddress;
  }

  function expectEmitNoIndex() internal {
    vm.expectEmit(false, false, false, true);
  }
}
