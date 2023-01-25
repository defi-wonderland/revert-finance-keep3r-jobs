// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@contracts/jobs/CompoundJob.sol';
import '@contracts/jobs/Keep3rRatedJob.sol';

contract CompoundKeep3rRatedJob is CompoundJob, Keep3rRatedJob {
  constructor(address _governance, INonfungiblePositionManager _nonfungiblePositionManager)
    payable
    CompoundJob(_governance, _nonfungiblePositionManager)
  {}

  /// @inheritdoc ICompoundJob
  function work(uint256 _tokenId, ICompoundor _compoundor) external override upkeep(msg.sender, usdPerGasUnit) notPaused {
    _work(_tokenId, _compoundor);
  }

  /// @inheritdoc ICompoundJob
  function workForFree(uint256 _tokenId, ICompoundor _compoundor) external override {
    _work(_tokenId, _compoundor);
  }
}
