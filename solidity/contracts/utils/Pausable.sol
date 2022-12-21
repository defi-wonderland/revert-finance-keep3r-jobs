// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import 'keep3r/contracts/peripherals/Governable.sol';
import '@interfaces/utils/IPausable.sol';

/**
  @notice Provides pausable functionalities to a given contract
 */
abstract contract Pausable is Governable, IPausable {
  /// @inheritdoc IPausable
  bool public isPaused;

  /// @inheritdoc IPausable
  function setPaused(bool _paused) external onlyGovernance {
    isPaused = _paused;
    emit PausedSet(_paused);
  }

  /**
    @notice provides pausable logic to the function marked with this modifier
   */
  modifier notPaused() {
    if (isPaused) revert Paused();
    _;
  }
}
