// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@contracts/jobs/CompoundJob.sol';
import '@contracts/jobs/Keep3rRatedJob.sol';
import '@interfaces/jobs/ICompoundKeep3rRatedJob.sol';

contract CompoundKeep3rRatedJob is CompoundJob, Keep3rRatedJob, ICompoundKeep3rRatedJob {
  /// inheritdoc ICompoundKeep3rRatedJob
  mapping(uint256 => uint256) public lastWorkedAt;

  /**
    @notice The cooldown that has to be waited before work again
  */
  uint256 internal constant _COOLDOWN = 5 minutes;

  constructor(address _governance, INonfungiblePositionManager _nonfungiblePositionManager)
    payable
    CompoundJob(_governance, _nonfungiblePositionManager)
  {}

  /// @inheritdoc ICompoundJob
  function work(uint256 _tokenId, ICompoundor _compoundor) external override upkeep(msg.sender, usdPerGasUnit) notPaused {
    uint256 _lastWorkedAt = lastWorkedAt[_tokenId];
    uint256 _actualTimestamp = block.timestamp;
    if (_lastWorkedAt > _actualTimestamp - _COOLDOWN) revert CompoundKeep3rRatedJob_ActiveCooldown(_lastWorkedAt + _COOLDOWN - _actualTimestamp);
    lastWorkedAt[_tokenId] = _actualTimestamp;
    _work(_tokenId, _compoundor);
  }

  /// @inheritdoc ICompoundJob
  function workForFree(uint256 _tokenId, ICompoundor _compoundor) external override {
    _work(_tokenId, _compoundor);
  }
}
