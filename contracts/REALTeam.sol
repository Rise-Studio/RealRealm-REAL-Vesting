// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract REALTeamClaim is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  ERC20 public REAL;

  bool public isInit;

  uint256 public FULL_LOCK = 86400 * 30 * 6; //6 months
  uint256 public VESTING_DURATION = 86400 * 30 * 15; //15 months
  uint256 public TOTAL_ALLOCATION = 150000000000000000000000000; // 150.000.000 token REAL

  uint256 public startTime;
  uint256 public endTime;

  uint8 public stage;

  address public constant TEAM_ADDRESS =
    0x0D1Ba337c0f17322155EDDbc1c2f246d61698D40;
  uint256 lock;
  uint256 released;

  event Claim(address indexed account, uint256 amount, uint256 time);

  constructor() {}

  function initial(ERC20 _real) external onlyOwner {
    require(isInit != true, "Init before!");
    REAL = ERC20(_real);
    stage = 0;
    lock = TOTAL_ALLOCATION; // 150.000.000 token REAL

    isInit = true;
  }

  function setTime(uint256 _time) external onlyOwner {
    require(stage == 0, "Can not setup tge");
    startTime = _time + FULL_LOCK;
    endTime = startTime + VESTING_DURATION;

    stage = 1;
  }

  function claim() external nonReentrant {
    require(stage == 1, "Can not claim now");
    require(block.timestamp > startTime, "still locked");
    require(_msgSender() == TEAM_ADDRESS, "Address invalid");
    require(lock > released, "no locked");

    uint256 amount = canUnlockAmount();
    require(amount > 0, "Nothing to claim");

    released += amount;

    REAL.transfer(_msgSender(), amount);

    emit Claim(_msgSender(), amount, block.timestamp);
  }

  function canUnlockAmount() public view returns (uint256) {
    if (block.timestamp < startTime) {
      return 0;
    } else if (block.timestamp >= endTime) {
      return lock - released;
    } else {
      uint256 releasedTime = releasedTimes();
      uint256 totalVestingTime = endTime - startTime;
      return ((lock * releasedTime) / totalVestingTime) - released;
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
      uint256,
      uint256,
      uint256,
      uint256
    )
  {
    if (stage == 0) return (stage, startTime, endTime, lock, released, 0);
    return (stage, startTime, endTime, lock, released, canUnlockAmount());
  }

  /* ========== EMERGENCY ========== */
  function governanceRecoverUnsupported(
    address _token,
    address _to,
    uint256 _amount
  ) external onlyOwner {
    require(
      _token != address(REAL) ||
        REAL.balanceOf(address(this)) - _amount >= lock - released,
      "Not enough locked amount left"
    );
    ERC20(_token).transfer(_to, _amount);
  }
}
