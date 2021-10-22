// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract REALPrivateSale is Ownable, ReentrancyGuard {
  using SafeMath for uint256;

  bool public isInit;

  ERC20 public REAL;
  ERC20 public tokenBuy;

  uint256 public TGE_RELEASE = 6;
  uint256 public TGE_CLIFF = 86400 * 30 * 2; // 2 months
  uint256 public VESTING_DURATION = 86400 * 30 * 12; // 12 months
  uint256 public REAL_PRICE = 60000000000000000; // 0.006 USDT / REAL
  uint256 public TOTAL_ALLOCATION = 30000000000000000000000000; // 30.000.000 token REAL

  uint256 public startTime;
  uint256 public endTime;

  // address coldWallet;
  uint8 public stage;

  address[] private whilelists;
  mapping(address => uint256) private locks; // REAL
  mapping(address => uint256) private released; // REAL

  event Claim(address indexed account, uint256 amount, uint256 time);

  constructor() {}

  modifier canClaim() {
    require(stage == 1, "Can not claim now");
    _;
  }

  modifier canSetup() {
    require(stage == 0, "Can not setup now");
    _;
  }

  function initial(ERC20 _real, ERC20 _tokenBuy) external onlyOwner {
    require(isInit != true, "Init before!");
    REAL = ERC20(_real);
    tokenBuy = ERC20(_tokenBuy);
    stage = 0;

    isInit = true;
  }

  function setTime(uint256 _time) external canSetup onlyOwner {
    startTime = _time + TGE_CLIFF;
    endTime = startTime + VESTING_DURATION;

    stage = 1;

    for (uint256 i = 0; i < whilelists.length; i++) {
      uint256 realAmount = (locks[whilelists[i]] * TGE_RELEASE) / 100;
      locks[whilelists[i]] -= realAmount;
      REAL.transfer(whilelists[i], realAmount);
    }
  }

  function setWhilelist(address[] calldata _users, uint256[] memory _balance)
    external
    canSetup
    onlyOwner
  {
    require(_users.length == _balance.length, "Invalid input");

    for (uint256 i = 0; i < _users.length; i++) {
      //calculate
      uint256 realAmount = (_balance[i] * 10**tokenBuy.decimals()) / REAL_PRICE;
      // boughts[_users[i]] += _balance[i];
      locks[_users[i]] += realAmount;
      whilelists.push(_users[i]);
    }
  }

  function setBalanceUser(address _user, uint256 _newBalance)
    external
    onlyOwner
  {
    require(locks[_user] > 0, "This new user");
    uint256 realAmount = (_newBalance * 10**tokenBuy.decimals()) / REAL_PRICE;
    locks[_user] = realAmount;
  }

  function claim() external canClaim nonReentrant {
    require(block.timestamp > startTime, "still locked");
    require(locks[_msgSender()] > released[_msgSender()], "no locked");

    uint256 amount = canUnlockAmount(_msgSender());
    require(amount > 0, "Nothing to claim");

    released[_msgSender()] += amount;

    REAL.transfer(_msgSender(), amount);

    emit Claim(_msgSender(), amount, block.timestamp);
  }

  function canUnlockAmount(address _account) public view returns (uint256) {
    if (block.timestamp < startTime) {
      return 0;
    } else if (block.timestamp >= endTime) {
      return locks[_account] - released[_account];
    } else {
      uint256 releasedTime = releasedTimes();
      uint256 totalVestingTime = endTime - startTime;
      return
        (((locks[_account]) * releasedTime) / totalVestingTime) -
        released[_account];
    }
  }

  function releasedTimes() public view returns (uint256) {
    uint256 targetNow = (block.timestamp >= endTime)
      ? endTime
      : block.timestamp;
    uint256 releasedTime = targetNow - startTime;
    return releasedTime;
  }

  function info()
    external
    view
    returns (
      uint8,
      uint256,
      uint256
    )
  {
    return (stage, startTime, endTime);
  }

  //For FE
  function infoWallet(address _user)
    external
    view
    returns (
      uint256,
      uint256,
      uint256
    )
  {
    if (stage == 0) return (locks[_user], released[_user], 0);
    return (locks[_user], released[_user], canUnlockAmount(_user));
  }

  /* ========== EMERGENCY ========== */
  function governanceRecoverUnsupported(
    address _token,
    address _to,
    uint256 _amount
  ) external onlyOwner {
    require(_token != address(REAL), "Token invalid");
    ERC20(_token).transfer(_to, _amount);
  }
}
