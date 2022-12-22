// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@interfaces/ICompoundor.sol';
import '@interfaces/INonfungiblePositionManager.sol';
import '@interfaces/jobs/IKeep3rJob.sol';

interface ICompoundJob is IKeep3rJob {
  /*///////////////////////////////////////////////////////////////
                              EVENTS
  //////////////////////////////////////////////////////////////*/

  /**
  @notice Emitted when job works
  */
  event Worked();

  /**
    @notice Emitted a new compoundor is set
    @param  _compoundor The new compoundor address
  */
  event CompoundorSetted(ICompoundor _compoundor);

  /**
    @notice Emitted a new non fungible PositionManager is set
    @param  _nonfungiblePositionManager The new non fungible PositionManager address
  */
  event NonfungiblePositionManagerSetted(INonfungiblePositionManager _nonfungiblePositionManager);

  /**
    @notice Emitted a new token is added to the whitelist
    @param  _token The new token address
    @param  _threshold The new threshold setted
  */
  event TokenAddedToWhiteList(address _token, uint256 _threshold);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
  @notice Thrown when the compounded amount it less than needed
  */
  error CompoundJob_SmallCompound();

  /**
  @notice Thrown when the tokens are not in the whitelist
  */
  error CompoundJob_NotWhiteList();

  /*///////////////////////////////////////////////////////////////
                            STRUCTS
  //////////////////////////////////////////////////////////////*/

  /**
    @notice The two tokens associated with the tokenId
    @param  token0 The address of the token0
    @param  token1 The address of the token1
   */
  struct idTokens {
    address token0;
    address token1;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
    @notice The address of the compoundor contract
    @return The address of the token
  */
  function compoundor() external view returns (ICompoundor);

  /**
    @notice The address of the non fungible PositionManager contract
    @return The address of the token
  */
  function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

  /**
    @notice Mapping which stores the token whitelisted and its threshold
    @param  _token The address of the token whitelisted
    @return The treshold for the corresponding token
  */
  function whiteList(address _token) external view returns (uint256);

  /**
    @notice Mapping which contains the tokenId and their tokens addresses
    @param  _tokenId The token id
    @return The address of the token0
    @return The address of the token1
  */
  function tokenIdStored(uint256 _tokenId) external view returns (address, address);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
    @notice The function worked by the keeper, which will call autocompound for a given tokenId
    @param  _tokenId The token id
  */
  function work(uint256 _tokenId) external;

  /**
    @notice The function worked by anyone, which will call autocompound for a given tokenId
    @param  _tokenId The token id
  */
  function workForFree(uint256 _tokenId) external;

    /**
    @notice Sets the address of the compoundor
    @param  _compoundor The address of the compoundor to be set
   */
  function setCompoundor(ICompoundor _compoundor) external;

    /**
    @notice Sets the address of the non fungible PositionManager
    @param  _nonfungiblePositionManager The address of the non fungible PositionManager to be set
   */
  function setNonfungiblePositionManager(INonfungiblePositionManager _nonfungiblePositionManager) external;

    /**
    @notice Sets the token that has to be whitelisted
    @param  _token The address of the token
    @param  _threshold The threshold
   */
  function addTokenToWhiteList(address _token, uint256 _threshold) external;
}
