// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@interfaces/ICompoundor.sol';
import '@interfaces/INonfungiblePositionManager.sol';
import '@interfaces/jobs/IKeep3rJob.sol';

interface ICompoundJob is IKeep3rJob {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  event Worked(uint256 reward, uint256 compounded0, uint256 compounded1);

  event CompoundorSetted(ICompoundor _compoundor);

  event NonfungiblePositionManagerSetted(INonfungiblePositionManager _nonfungiblePositionManager);

  event TokenAddedToWhiteList(address _token, uint256 threshold);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  error CompoundJob_SmallCompound();

  error CompoundJob_NotWhiteList();

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  function compoundor() external view returns (ICompoundor);

  function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

  function whiteList(address) external view returns (uint256);

  function tokenIdStored(uint256) external view returns (ICompoundor.RewardConversion);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  function work(uint256 _tokenId) external;

  function setCompoundor(ICompoundor _compoundor) external;

  function setNonfungiblePositionManager(INonfungiblePositionManager _nonfungiblePositionManager) external;

  function addTokenToWhiteList(address _token, uint256 threshold) external;
}
