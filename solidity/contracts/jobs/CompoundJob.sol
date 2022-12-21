// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@interfaces/jobs/ICompoundJob.sol';
import '@contracts/jobs/Keep3rJob.sol';

contract CompoundJob is ICompoundJob, Keep3rJob {
  constructor(address _governance) payable Governable(_governance) {}
}
