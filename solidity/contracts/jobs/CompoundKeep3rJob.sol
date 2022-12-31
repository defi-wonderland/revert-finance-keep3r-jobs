// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@contracts/jobs/CompoundJob.sol';

contract CompoundKeep3rJob is CompoundJob {

  constructor(
    address _governance,
    ICompoundor _compoundor,
    INonfungiblePositionManager _nonfungiblePositionManager
  ) payable Governable(_governance) {
    compoundor = _compoundor;
    nonfungiblePositionManager = _nonfungiblePositionManager;
  }

  /// @inheritdoc ICompoundJob
  function work(uint256 _tokenId) external override upkeep(msg.sender) notPaused {
    _work(_tokenId);
  }

  /// @inheritdoc ICompoundJob
  function workForFree(uint256 _tokenId) override external {
    _work(_tokenId);
  }
}