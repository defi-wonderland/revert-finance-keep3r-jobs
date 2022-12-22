// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@interfaces/jobs/ICompoundJob.sol';
import '@contracts/jobs/Keep3rJob.sol';
import '@contracts/utils/PRBMath.sol';

contract CompoundJob is ICompoundJob, Keep3rJob {
  /// @inheritdoc ICompoundJob
  INonfungiblePositionManager public nonfungiblePositionManager;

  /// @inheritdoc ICompoundJob
  ICompoundor public compoundor;

  /// @inheritdoc ICompoundJob
  mapping(address => uint256) public whiteList;

  /// @inheritdoc ICompoundJob
  mapping(uint256 => idTokens) public tokenIdStored;

  /** 
  @notice The base
  */
  uint256 public constant BASE = 10_000;

  constructor(address _governance) payable Governable(_governance) {
    compoundor = ICompoundor(0x5411894842e610C4D0F6Ed4C232DA689400f94A1);
    nonfungiblePositionManager = INonfungiblePositionManager(address(0));
  }

  /// @inheritdoc ICompoundJob
  function work(uint256 _tokenId) external upkeep(msg.sender) notPaused {
    idTokens memory _idTokens = tokenIdStored[_tokenId];

    if (_idTokens.token0 == address(0)) {
      (, , address token0, address token1, , , , , , , , ) = nonfungiblePositionManager.positions(_tokenId);
      _idTokens = idTokens(token0, token1);
      tokenIdStored[_tokenId] = _idTokens;
    }
    uint256 _threshold0 = whiteList[_idTokens.token0];
    uint256 _threshold1 = whiteList[_idTokens.token1];
    if (_threshold0 + _threshold1 == 0) revert CompoundJob_NotWhiteList();

    _callAutoCompound(_tokenId, _threshold0, _threshold1);
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
    uint256 _threshold0,
    uint256 _threshold1
  ) internal {
    ICompoundor.AutoCompoundParams memory _params;
    bool _smallCompound;
    uint256 _reward0;
    uint256 _reward1;

    // We have 2 tokens of interest
    if (_threshold0 * _threshold1 > 0) {
      _params = ICompoundor.AutoCompoundParams(_tokenId, ICompoundor.RewardConversion.NONE, true, true);
      (_reward0, _reward1, , ) = compoundor.autoCompound(_params);
      _reward0 = PRBMath.mulDiv(_reward0, BASE, _threshold0);
      _reward1 = PRBMath.mulDiv(_reward1, BASE, _threshold1);
      _smallCompound = BASE > (_reward0 + _reward1) * BASE;
    } else if (_threshold0 > 0) {
      _params = ICompoundor.AutoCompoundParams(_tokenId, ICompoundor.RewardConversion.TOKEN_0, true, true);
      (_reward0, , , ) = compoundor.autoCompound(_params);
      _smallCompound = _threshold0 > _reward0 * BASE;
    } else {
      _params = ICompoundor.AutoCompoundParams(_tokenId, ICompoundor.RewardConversion.TOKEN_1, true, true);
      (, _reward1, , ) = compoundor.autoCompound(_params);
      _smallCompound = _threshold1 > _reward1 * BASE;
    }

    if (_smallCompound) revert CompoundJob_SmallCompound();
    emit Worked();
  }
}
