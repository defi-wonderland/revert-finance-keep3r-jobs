// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@contracts/jobs/CompoundJob.sol';
import '@contracts/jobs/Keep3rJob.sol';

contract CompoundKeep3rJob is CompoundJob, Keep3rJob {
  constructor(
    address _governance,
    INonfungiblePositionManager _nonfungiblePositionManager
  ) payable CompoundJob(_governance, _nonfungiblePositionManager) {}

  /// @inheritdoc ICompoundJob
  function work(uint256 _tokenId, ICompoundor _compoundor) external override upkeep(msg.sender) notPaused {
    _work(_tokenId, _compoundor);
  }

  /// @inheritdoc ICompoundJob
  function workForFree(uint256 _tokenId, ICompoundor _compoundor) external override {
    _work(_tokenId, _compoundor);
  }
}
