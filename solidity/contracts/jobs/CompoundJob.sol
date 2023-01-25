// SPDX-License-Identifier: MIT
pragma solidity >=0.8.4 <0.9.0;

import '@interfaces/jobs/ICompoundJob.sol';
import '@contracts/utils/PRBMath.sol';
import 'keep3r/contracts/peripherals/Governable.sol';
import 'openzeppelin/contracts/utils/structs/EnumerableMap.sol';
import 'openzeppelin/contracts/utils/structs/EnumerableSet.sol';

abstract contract CompoundJob is Governable, ICompoundJob {
  using EnumerableMap for EnumerableMap.AddressToUintMap;
  using EnumerableSet for EnumerableSet.AddressSet;

  /// @inheritdoc ICompoundJob
  INonfungiblePositionManager public nonfungiblePositionManager;

  /// @inheritdoc ICompoundJob
  mapping(uint256 => tokenIdInfo) public tokensIdInfo;

  /**
    @notice Mapping which stores the token whitelisted and its threshold
  */
  EnumerableMap.AddressToUintMap internal _whitelistedThresholds;

  /**
    @notice Array which stores the compoundors whitelisted
  */
  EnumerableSet.AddressSet internal _whitelistedCompoundors;

  /** 
    @notice The base
  */
  uint256 public constant BASE = 10_000;

  constructor(address _governance, INonfungiblePositionManager _nonfungiblePositionManager) payable Governable(_governance) {
    nonfungiblePositionManager = _nonfungiblePositionManager;
  }

  /// @inheritdoc ICompoundJob
  function work(uint256 _tokenId, ICompoundor _compoundor) external virtual {}

  /// @inheritdoc ICompoundJob
  function workForFree(uint256 _tokenId, ICompoundor _compoundor) external virtual {}

  /**
    @notice Works for the keep3r or for external user
    @param _tokenId The token id
  */
  function _work(uint256 _tokenId, ICompoundor _compoundor) internal {
    if (!_whitelistedCompoundors.contains(address(_compoundor))) revert CompoundJob_NotWhitelist();
    tokenIdInfo memory _infoTokenId = tokensIdInfo[_tokenId];

    if (_infoTokenId.token0 == address(0)) {
      (, , address _token0, address _token1, , , , , , , , ) = nonfungiblePositionManager.positions(_tokenId);
      _infoTokenId = tokenIdInfo(_token0, _token1);
      tokensIdInfo[_tokenId] = _infoTokenId;
    }
    (, uint256 _threshold0) = _whitelistedThresholds.tryGet(_infoTokenId.token0);
    (, uint256 _threshold1) = _whitelistedThresholds.tryGet(_infoTokenId.token1);
    if (_threshold0 + _threshold1 == 0) revert CompoundJob_NotWhitelist();

    _callAutoCompound(_tokenId, _threshold0, _threshold1, _compoundor);
  }

  /// @inheritdoc ICompoundJob
  function withdraw(address[] calldata _tokens, ICompoundor _compoundor) external {
    uint256 _balance;
    address _token;
    for (uint256 _i; _i < _tokens.length; ) {
      _token = _tokens[_i];
      _balance = _compoundor.accountBalances(address(this), _token);
      _compoundor.withdrawBalance(_token, governance, _balance);

      unchecked {
        ++_i;
      }
    }
  }

  /// @inheritdoc ICompoundJob
  function addTokenToWhitelist(address[] calldata _tokens, uint256[] calldata _thresholds) external onlyGovernance {
    uint256 _threshold;
    address _token;
    for (uint256 _i; _i < _tokens.length; ) {
      _threshold = _thresholds[_i];
      _token = _tokens[_i];

      if (_threshold > 0) {
        _whitelistedThresholds.set(_token, _threshold);
      } else {
        _whitelistedThresholds.remove(_token);
      }

      emit TokenAddedToWhitelist(_token, _threshold);
      unchecked {
        ++_i;
      }
    }
  }

  /// @inheritdoc ICompoundJob
  function getWhitelistedTokens() external view returns (address[] memory _whitelistedTokens) {
    _whitelistedTokens = _whitelistedThresholds.keys();
  }

  /// @inheritdoc ICompoundJob
  function addCompoundorToWhitelist(ICompoundor _compoundor) external onlyGovernance {
    _whitelistedCompoundors.add(address(_compoundor));

    emit CompoundorAddedToWhitelist(_compoundor);
  }

  /// @inheritdoc ICompoundJob
  function getWhitelistedCompoundors() external view returns (address[] memory _compoundors) {
    _compoundors = _whitelistedCompoundors.values();
  }

  /// @inheritdoc ICompoundJob
  function setNonfungiblePositionManager(INonfungiblePositionManager _nonfungiblePositionManager) external onlyGovernance {
    nonfungiblePositionManager = _nonfungiblePositionManager;
    emit NonfungiblePositionManagerSetted(_nonfungiblePositionManager);
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
    uint256 _threshold1,
    ICompoundor _compoundor
  ) internal {
    ICompoundor.AutoCompoundParams memory _params;
    bool _smallCompound;
    uint256 _reward0;
    uint256 _reward1;

    // We have 2 tokens of interest
    if (_threshold0 * _threshold1 > 0) {
      _params = ICompoundor.AutoCompoundParams(_tokenId, ICompoundor.RewardConversion.NONE, false, true);
      (_reward0, _reward1, , ) = _compoundor.autoCompound(_params);
      _reward0 = PRBMath.mulDiv(_reward0, BASE, _threshold0);
      _reward1 = PRBMath.mulDiv(_reward1, BASE, _threshold1);
      _smallCompound = BASE > (_reward0 + _reward1);
    } else if (_threshold0 > 0) {
      _params = ICompoundor.AutoCompoundParams(_tokenId, ICompoundor.RewardConversion.TOKEN_0, false, true);
      (_reward0, , , ) = _compoundor.autoCompound(_params);
      _smallCompound = _threshold0 > _reward0 * BASE;
    } else {
      _params = ICompoundor.AutoCompoundParams(_tokenId, ICompoundor.RewardConversion.TOKEN_1, false, true);
      (, _reward1, , ) = _compoundor.autoCompound(_params);
      _smallCompound = _threshold1 > _reward1 * BASE;
    }

    if (_smallCompound) revert CompoundJob_SmallCompound();
    emit Worked();
  }
}
