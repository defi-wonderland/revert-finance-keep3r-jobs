// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

interface ICompoundor {
  /**
  @notice how reward should be converted
  */
  enum RewardConversion {
    NONE,
    TOKEN_0,
    TOKEN_1
  }

  /**
  @notice params for autoCompound()
  */
  struct AutoCompoundParams {
    // tokenid to autocompound
    uint256 tokenId;
    // which token to convert to
    RewardConversion rewardConversion;
    // should token be withdrawn to compounder immediately
    bool withdrawReward;
    // do swap - to add max amount to position (costs more gas)
    bool doSwap;
  }

  /**
   @notice Autocompounds for a given NFT (anyone can call this and gets a percentage of the fees)
   @param params Autocompound specific parameters (tokenId, ...)
   @return reward0 Amount of token0 caller recieves
   @return reward1 Amount of token1 caller recieves
   @return compounded0 Amount of token0 that was compounded
   @return compounded1 Amount of token1 that was compounded
   */
  function autoCompound(AutoCompoundParams calldata params)
    external
    returns (
      uint256 reward0,
      uint256 reward1,
      uint256 compounded0,
      uint256 compounded1
    );
}
