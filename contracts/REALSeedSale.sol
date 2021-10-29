
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
 * @title TokenTimelock
 * @dev TokenTimelock is a token holder contract that will allow a
 * beneficiary to extract the tokens after a given release time.
 */
contract SeedTokenTimelock is Ownable {
    using SafeMath for uint256;
    
    uint256 constant public UPFRONT_AMOUNT = 600000 *10**18;
    uint256 constant public AMOUNT_PER_RELEASE = 783333 *10**18;
    uint256 constant public PERIOD = 2592000; // 30days
    uint256 constant public START_TIME = 1637971199 + 5184000; // Time begin unlock linearly 2 month from : 23:59:59 GMT 26/11/2021
    address constant public REAL_TOKEN = 0x5c6499380d0dfB76C6DE990a3A2EC45a4749920E;

    uint256 public lockToken = 10000000 * 10**18;
    uint256 public nextRelease;
    uint256 public countRelease;
    
    constructor() {
        nextRelease = START_TIME + PERIOD.mul(countRelease);
    }
    
    /**
     * Clain UPFRONT_AMOUNT 
     */
    function claimUpfront() public onlyOwner {
        require(IERC20(REAL_TOKEN).balanceOf(address(this)).sub(UPFRONT_AMOUNT) >= 0, "TokenTimelock: no tokens to release");
        lockToken = lockToken.sub(UPFRONT_AMOUNT);
        IERC20(REAL_TOKEN).transfer(owner(), UPFRONT_AMOUNT); 
    }
    
    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function claim() public onlyOwner {
        require(block.timestamp >= START_TIME + PERIOD.mul(countRelease), "TokenTimelock: current time is before release time");
        require(IERC20(REAL_TOKEN).balanceOf(address(this)) > 0,"TokenTimelock: no tokens to release" );
        require(IERC20(REAL_TOKEN).balanceOf(address(this)).sub(AMOUNT_PER_RELEASE) >= 0, "TokenTimelock: not enough tokens to release");
        
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
