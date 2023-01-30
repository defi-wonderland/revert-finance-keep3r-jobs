// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ICompoundKeep3rRatedJob {
  /*///////////////////////////////////////////////////////////////
                              ERRORS
  //////////////////////////////////////////////////////////////*/

  /**
    @notice Thrown when tokenId has an active cooldown
    @param  _cooldown The active cooldown
   */
  error CompoundKeep3rRatedJob_ActiveCooldown(uint256 _cooldown);

  /*///////////////////////////////////////////////////////////////
                            VARIABLES
//////////////////////////////////////////////////////////////*/

  /**
    @notice The mapping which store when was worked each tokenId
    @param  _tokenId The token Id 
    @return The last time worked
*/
  function lastWorkedAt(uint256 _tokenId) external view returns (uint256);
}
