// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

/*****************************************************************************
 * @dev Wrappers over Solidity's arithmetic operations with added overflow
 * checks.
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b <= a, "SafeMath: subtraction overflow");

        return a - b;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        require(b > 0, "SafeMath: division by zero");
        uint256 c = a / b;

        return c;
    }
}


/*****************************************************************************
 * @dev Interface of the IERC20 standard as defined in the EIP.
 */
interface IERC20 {
    /**
     * @dev Returns the amount of tokens in existence.
     */
    function totalSupply() external view returns (uint256);

    /**
     * @dev Returns the amount of tokens owned by `account`.
     */
    function balanceOf(address account) external view returns (uint256);

    /**
     * @dev Moves `amount` tokens from the caller's account to `recipient`.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transfer(address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Returns the remaining number of tokens that `spender` will be
     * allowed to spend on behalf of `owner` through `transferFrom`. This is
     * zero by default.
     *
     * This value changes when `approve` or `transferFrom` are called.
     */
    function allowance(address owner, address spender) external view returns (uint256);

    /**
     * @dev Sets `amount` as the allowance of `spender` over the caller's tokens.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     * Emits an `Approval` event.
     */
    function approve(address spender, uint256 amount) external returns (bool);

    /**
     * @dev Moves `amount` tokens from `sender` to `recipient` using the
     * allowance mechanism. `amount` is then deducted from the caller's
     * allowance.
     *
     * Returns a boolean value indicating whether the operation succeeded.
     *
     * Emits a `Transfer` event.
     */
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);

    /**
     * @dev Emitted when `value` tokens are moved from one account (`from`) to
     * another (`to`).
     *
     * Note that `value` may be zero.
     */
    event Transfer(address indexed from, address indexed to, uint256 value);

    /**
     * @dev Emitted when the allowance of a `spender` for an `owner` is set by
     * a call to `approve`. `value` is the new allowance.
     */
    event Approval(address indexed owner, address indexed spender, uint256 value);
}

contract Ownable {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    /**
     * @dev Initializes the contract setting the deployer as the initial owner.
     */
    constructor () {
        _owner = msg.sender;
        emit OwnershipTransferred(address(0), _owner);
    }

    /**
     * @dev Returns the address of the current owner.
     */
    function owner() public view returns (address) {
        return _owner;
    }

    /**
     * @dev Throws if called by any account other than the owner.
     */
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    /**
     * @dev Returns true if the caller is the current owner.
     */
    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    /**
     * @dev Transfers ownership of the contract to a new account (`newOwner`).
     * Can only be called by the current owner.
     */
    function transferOwnership(address newOwner) public onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        emit OwnershipTransferred(_owner, newOwner);
        _owner = newOwner;
    }
}


/*****************************************************************************
 * @title REALAdvisor
 * @dev REALAdvisor is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time.
 */
contract REALAdvisor is Ownable {
    using SafeMath for uint256;
    
    uint256 constant public AMOUNT_PER_RELEASE = 10000000 *10**18;
    // uint256 constant public 2MONTH = 5184000; // 60days
    uint256 constant public PERIOD = 7776000; // 90days
    // uint256 constant public PERIOD = 5*60; // Testing only 5minute
    uint256 constant public START_TIME = 1637971199 + 15552000; // Time begin unlock linearly 6 month from now
    // uint256 constant public START_TIME = 1635230912 + 2*60; // Test will be for now + 2minutes
    address constant public REAL_TOKEN = 0xa1B8bCeF70730e200dF36f0248295f4DC2081b9e;

    uint256 public lockToken = 50000000 * 10**18;
    uint256 public nextRelease;
    uint256 public countRelease;
    
    constructor() {now 
        
        nextRelease = START_TIME + PERIOD.mul(countRelease);
    }
    
    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function claim() public onlyOwner {
        require(block.timestamp >= START_TIME + PERIOD.mul(countRelease), "TokenTimelock: current time is before release time");
        require(IERC20(REAL_TOKEN).balanceOf(address(this)).sub(AMOUNT_PER_RELEASE) >= 0, "TokenTimelock: no tokens to release");
        
        uint256 clift = block.timestamp.sub(nextRelease).div(PERIOD) + 1;
        uint256 amount = AMOUNT_PER_RELEASE.mul(clift);
        if (amount >= lockToken) {
            IERC20(REAL_TOKEN).transfer(owner(), lockToken);
            lockToken = 0;
        } else {
            nextRelease = nextRelease + PERIOD.mul(clift);
            lockToken = lockToken.sub(amount);
            IERC20(REAL_TOKEN).transfer(owner(), amount); 
        }
        
        countRelease += clift;
    }
    
    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }
    
    function getTimeReleaseNext() public view returns(uint256) {
        return START_TIME + PERIOD.mul(countRelease);
    }
    
    function getBalance() public view returns (uint256) {
        return IERC20(REAL_TOKEN).balanceOf(address(this));
    }

}

    stage = 1;
  }

  function claim() external nonReentrant {
    require(stage == 1, "Can not claim now");
    require(block.timestamp > startTime, "still locked");
    require(_msgSender() == ADVISOR_ADDRESS, "Address invalid");
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
