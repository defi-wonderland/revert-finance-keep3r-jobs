// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@interfaces/jobs/IKeep3rJob.sol';

interface IKeep3rRatedJob is IKeep3rJob {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
    @notice Emitted a value for usd per gas unit is set
    @param  _usdPerGasUnit The usd per gas unit
   */
  event UsdPerGasUnitSet(uint256 _usdPerGasUnit);

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
    @notice The usd per gas unit paid
    @return The usd per gas unit
   */
  function usdPerGasUnit() external view returns (uint256);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  function setUsdPerGasUnit(uint256 _usdPerGasUnit) external;
}
