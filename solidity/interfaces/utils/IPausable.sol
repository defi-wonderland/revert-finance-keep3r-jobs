// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import 'keep3r/interfaces/peripherals/IGovernable.sol';

interface IPausable is IGovernable {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
    @notice Emitted when the pause status of the contract changes
    @param  _paused The new paused status, true if the contract is paused
   */
  event PausedSet(bool _paused);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
    @notice Thrown when trying to access a paused contract
   */
  error Paused();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/
  /**
    @notice Returns the pause status
    @return _isPaused True if paused
   */
  function isPaused() external returns (bool _isPaused);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/
  /**
    @notice Set the pause status
    @param  _paused True to pause the contract, false to resume it
   */
  function setPaused(bool _paused) external;
}
