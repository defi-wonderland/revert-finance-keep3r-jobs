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
    @notice Emitted a new non fungible PositionManager is set
    @param  _nonfungiblePositionManager The new non fungible PositionManager address
  */
  event NonfungiblePositionManagerSetted(INonfungiblePositionManager _nonfungiblePositionManager);

  /**
    @notice Emitted a new token is added to the whitelist
    @param  _token The new token address
    @param  _threshold The new threshold setted
  */
  event TokenAddedToWhitelist(address _token, uint256 _threshold);

  /**
    @notice Emitted a new compoundor is added to the whitelist
    @param  _compoundor The new compoundor address
  */
  event CompoundorAddedToWhitelist(ICompoundor _compoundor);

  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
    @notice Thrown when the compounded amount it less than needed
  */
  error CompoundJob_SmallCompound();

  /**
    @notice Thrown when the element is not in the whitelist
  */
  error CompoundJob_NotWhitelist();

  /*///////////////////////////////////////////////////////////////
                            STRUCTS
  //////////////////////////////////////////////////////////////*/

  /**
    @notice The two tokens associated with the tokenId
    @param  token0 The address of the token0
    @param  token1 The address of the token1
   */
  struct tokenIdInfo {
    address token0;
    address token1;
  }

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
  //////////////////////////////////////////////////////////////*/

  /**
    @notice The address of the non fungible PositionManager contract
    @return The address of the token
  */
  function nonfungiblePositionManager() external view returns (INonfungiblePositionManager);

  /**
    @notice Mapping which contains the tokenId and their tokens addresses
    @param  _tokenId The token id
    @return token0 The address of the token0
    @return token1 The address of the token1
  */
  function tokensIdInfo(uint256 _tokenId) external view returns (address token0, address token1);

  /*///////////////////////////////////////////////////////////////
                              LOGIC
  //////////////////////////////////////////////////////////////*/

  /**
    @notice The function worked by the keeper, which will call autocompound for a given tokenId
    @param  _tokenId The token id
    @param  _compoundor The compoundor
  */
  function work(uint256 _tokenId, ICompoundor _compoundor) external;

  /**
    @notice The function worked by anyone, which will call autocompound for a given tokenId
    @param  _tokenId The token id
    @param  _compoundor The compoundor
  */
  function workForFree(uint256 _tokenId, ICompoundor _compoundor) external;

  /**
    @notice Withdraws token balance for a address and token
    @param _tokens The list of tokens
    @param  _compoundor The compoundor
  */
  function withdraw(address[] calldata _tokens, ICompoundor _compoundor) external;


  /**
    @notice Sets the token that has to be whitelisted
    @param  _tokens The list of tokens
    @param  _thresholds The list of thresholds
   */
  function addTokenToWhitelist(address[] memory _tokens, uint256[] memory _thresholds) external;

  /**
    @notice Array which contains all tokens in the whitelist
    @return _whitelistedTokens The array with all address
  */
  function getWhitelistedTokens() external view returns (address[] memory _whitelistedTokens);

  /**
    @notice Sets the compoundor that has to be whitelisted
    @param  _compoundor The compoundor
   */
  function addCompoundorToWhitelist(ICompoundor _compoundor) external;

  /**
    @notice Array which contains all compoundors in the whitelist
    @return _whitelistedCompoundors The array with all compoundors
  */
  function getWhitelistedCompoundors() external view returns (address[] memory _whitelistedCompoundors);

  /**
    @notice Sets the address of the non fungible PositionManager
    @param  _nonfungiblePositionManager The address of the non fungible PositionManager to be set
   */
  function setNonfungiblePositionManager(INonfungiblePositionManager _nonfungiblePositionManager) external;
}
