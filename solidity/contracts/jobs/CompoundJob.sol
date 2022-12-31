// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@interfaces/jobs/ICompoundJob.sol';
import '@contracts/jobs/Keep3rJob.sol';
import '@contracts/utils/PRBMath.sol';

abstract contract CompoundJob is ICompoundJob, Keep3rJob {
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

  /// @inheritdoc ICompoundJob
  function work(uint256 _tokenId) virtual external {
  }

  /// @inheritdoc ICompoundJob
  function workForFree(uint256 _tokenId) virtual external {
  }

  /**
    @notice Works for the keep3r or for external user
    @param _tokenId The token id
  */
  function _work(uint256 _tokenId) internal virtual {
    idTokens memory _idTokens = tokenIdStored[_tokenId];

    if (_idTokens.token0 == address(0)) {
      (, , address _token0, address _token1, , , , , , , , ) = nonfungiblePositionManager.positions(_tokenId);
      _idTokens = idTokens(_token0, _token1);
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
  function addTokenToWhiteList(address[] calldata _tokens, uint256[] calldata _thresholds) external onlyGovernance {
    for (uint256 _i; _i < _tokens.length; ) {
      whiteList[_tokens[_i]] = _thresholds[_i];

      unchecked {
        emit TokenAddedToWhiteList(_tokens[_i], _thresholds[_i]);
        ++_i;
      }
    }
  }

  /// @inheritdoc ICompoundJob
  function withdraw(address[] calldata _tokens) external {
    uint256 _balance;
    for (uint256 _i; _i < _tokens.length; ) {
      _balance = compoundor.accountBalances(address(this), _tokens[_i]);
      compoundor.withdrawBalance(_tokens[_i], governance, _balance);

      unchecked {
        ++_i;
      }
    }
  }

  /**
    @notice Calls autocompound with the correct parameters
    @param _tokenId The token id
    @param _threshold0 The threshold for token0
    @param _threshold1 The threshold for token1
  */
  function _callAutoCompound(
    uint256 _tokenId,
    uint256 _threshold0,
    uint256 _threshold1
  ) internal virtual{
    ICompoundor.AutoCompoundParams memory _params;
    bool _smallCompound;
    uint256 _reward0;
    uint256 _reward1;

    // We have 2 tokens of interest
    if (_threshold0 * _threshold1 > 0) {
      _params = ICompoundor.AutoCompoundParams(_tokenId, ICompoundor.RewardConversion.NONE, false, false);
      (_reward0, _reward1, , ) = compoundor.autoCompound(_params);
      _reward0 = PRBMath.mulDiv(_reward0, BASE, _threshold0);
      _reward1 = PRBMath.mulDiv(_reward1, BASE, _threshold1);
      _smallCompound = BASE > (_reward0 + _reward1);
    } else if (_threshold0 > 0) {
      _params = ICompoundor.AutoCompoundParams(_tokenId, ICompoundor.RewardConversion.TOKEN_0, false, false);
      (_reward0, , , ) = compoundor.autoCompound(_params);
      _smallCompound = _threshold0 > _reward0 * BASE;
    } else {
      _params = ICompoundor.AutoCompoundParams(_tokenId, ICompoundor.RewardConversion.TOKEN_1, false, false);
      (, _reward1, , ) = compoundor.autoCompound(_params);
      _smallCompound = _threshold1 > _reward1 * BASE;
    }

    if (_smallCompound) revert CompoundJob_SmallCompound();
    emit Worked();
  }
}
