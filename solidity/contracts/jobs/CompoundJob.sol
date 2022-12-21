// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0 <0.9.0;

import '@interfaces/jobs/ICompoundJob.sol';
import '@contracts/jobs/Keep3rJob.sol';

contract CompoundJob is ICompoundJob, Keep3rJob {
  /// @inheritdoc ICompoundJob
  INonfungiblePositionManager public nonfungiblePositionManager;

  /// @inheritdoc ICompoundJob
  ICompoundor public compoundor;

  /// @inheritdoc ICompoundJob
  mapping(address => uint256) public whiteList;

  /// @inheritdoc ICompoundJob
  mapping(uint256 => ICompoundor.RewardConversion) public tokenIdStored;

  /** 
  @notice The weth address
  */
  address public constant WETH = 0x4200000000000000000000000000000000000006;

  /** 
  @notice The base to operate in 0.001
  */
  uint256 public constant BASE = 1000;

  constructor(address _governance) payable Governable(_governance) {
    compoundor = ICompoundor(0x5411894842e610C4D0F6Ed4C232DA689400f94A1);
    nonfungiblePositionManager = INonfungiblePositionManager(address(0));
    whiteList[WETH] = 1;
  }

  /// @inheritdoc ICompoundJob
  function work(uint256 _tokenId) external upkeep(msg.sender) notPaused {
    uint256 threshold;
    ICompoundor.RewardConversion _rewardConversion = tokenIdStored[_tokenId];

    (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(_tokenId);

    if (_rewardConversion == ICompoundor.RewardConversion.TOKEN_0 || _rewardConversion == ICompoundor.RewardConversion.TOKEN_1) {
      threshold = _rewardConversion == ICompoundor.RewardConversion.TOKEN_0 ? whiteList[token0] : whiteList[token1];
      _callAutoCompound(_tokenId, _rewardConversion, threshold);

      // If not
    } else {
      if (whiteList[token0] == 0 || whiteList[token1] == 0) revert CompoundJob_NotWhiteList();
      // If tokenId is already in our mapping

      // If whiteList[token0] is greater than 0 the token in the whitelist is token0 and we should swap all rewards to token0
      // If not we should swap all rewards to token1 which is the token in the whitelist
      if (whiteList[token0] > 0) {
        _rewardConversion = ICompoundor.RewardConversion.TOKEN_0;
        threshold = whiteList[token0];
      } else {
        _rewardConversion = ICompoundor.RewardConversion.TOKEN_1;
        threshold = whiteList[token1];
      }
      _callAutoCompound(_tokenId, _rewardConversion, threshold);
    }
  }

  /// @inheritdoc ICompoundJob
  function setCompoundor(ICompoundor _compoundor) external onlyGovernance {
    compoundor = _compoundor;
    emit CompoundorSetted(_compoundor);
  }

  /// @inheritdoc ICompoundJob
  function setNonfungiblePositionManager(INonfungiblePositionManager _nonfungiblePositionManager) external onlyGovernance {
    nonfungiblePositionManager = _nonfungiblePositionManager;
    emit NonfungiblePositionManagerSetted(_nonfungiblePositionManager);
  }

  /// @inheritdoc ICompoundJob
  function addTokenToWhiteList(address _token, uint256 _threshold) external onlyGovernance {
    whiteList[_token] = _threshold;
    emit TokenAddedToWhiteList(_token, _threshold);
  }

  function _callAutoCompound(
    uint256 _tokenId,
    ICompoundor.RewardConversion _rewardConversion,
    uint256 threshold
  ) internal {
    uint256 _reward;
    uint256 _compounded0;
    uint256 _compounded1;

    // first true to withdraw , second for swap in order to add max amount to the position
    ICompoundor.AutoCompoundParams memory _params = ICompoundor.AutoCompoundParams(_tokenId, _rewardConversion, true, true);

    if (_rewardConversion == ICompoundor.RewardConversion.TOKEN_0) {
      (_reward, , _compounded0, _compounded1) = compoundor.autoCompound(_params);
    } else {
      (, _reward, _compounded0, _compounded1) = compoundor.autoCompound(_params);
    }

    if (threshold > _reward * block.basefee * BASE) revert CompoundJob_SmallCompound();
    emit Worked(_reward, _compounded0, _compounded1);
  }
}
