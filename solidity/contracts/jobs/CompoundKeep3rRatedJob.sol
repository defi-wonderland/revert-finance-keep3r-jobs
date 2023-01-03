// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@contracts/jobs/CompoundJob.sol';
import '@contracts/jobs/Keep3rRatedJob.sol';

contract CompoundKeep3rRatedJob is CompoundJob, Keep3rRatedJob {
  constructor(
    address _governance,
    ICompoundor _compoundor,
    INonfungiblePositionManager _nonfungiblePositionManager
  ) payable CompoundJob(_governance, _compoundor, _nonfungiblePositionManager) {}

  /// @inheritdoc ICompoundJob
  function work(uint256 _tokenId) external override upkeep(msg.sender, usdPerGasUnit) notPaused {
    _work(_tokenId);
  }

  /// @inheritdoc ICompoundJob
  function workForFree(uint256 _tokenId) external override {
    _work(_tokenId);
  }
}
