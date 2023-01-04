// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@contracts/utils/Pausable.sol';
import '@interfaces/jobs/IKeep3rRatedJob.sol';
import 'keep3r/interfaces/sidechain/IKeep3rJobWorkableRated.sol';

abstract contract Keep3rRatedJob is IKeep3rRatedJob, Pausable {
  /// @inheritdoc IKeep3rJob
  IKeep3r public keep3r = IKeep3r(0x745a50320B6eB8FF281f1664Fc6713991661B129);

  /// @inheritdoc IKeep3rRatedJob
  uint256 public usdPerGasUnit = 1e12;

  /// @inheritdoc IKeep3rRatedJob
  function setUsdPerGasUnit(uint256 _usdPerGasUnit) public onlyGovernance {
    usdPerGasUnit = _usdPerGasUnit;
    emit UsdPerGasUnitSet(_usdPerGasUnit);
  }

  /// @inheritdoc IKeep3rJob
  function setKeep3r(IKeep3r _keep3r) public onlyGovernance {
    keep3r = _keep3r;
    emit Keep3rSet(_keep3r);
  }

  /**
    @notice Checks if the sender is a valid keeper in the Keep3r network
    @param  _keeper the address to check the keeper status
   */
  modifier upkeep(address _keeper, uint256 _usdPerGasUnit) virtual {
    if (!_isValidKeeper(_keeper)) revert InvalidKeeper();
    _;
    IKeep3rJobWorkableRated(address(keep3r)).worked(_keeper, _usdPerGasUnit);
  }

  /**
    @notice Checks if a keeper meets the bonding requirements
    @param  _keeper the address to check the keeper data
    @return _isValid true if the keeper meets the bonding requirements
   */
  function _isValidKeeper(address _keeper) internal returns (bool _isValid) {
    return keep3r.isKeeper(_keeper);
  }
}
