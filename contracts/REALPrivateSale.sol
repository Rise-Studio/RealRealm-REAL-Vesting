pragma solidity ^0.8.7;

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
contract REALPrivateSale is Ownable {
    
    using SafeMath for uint256;
    
    uint256 public TGE_RELEASE = 75; // Initial release 7.5% of total amount
    // uint256 constant public 2MONTH = 5184000; // 60days
    uint256 constant public PERIOD = 2592000; // 30days
    //uint256 constant public PERIOD = 60; // Testing only 1minute
    uint256 constant public START_TIME = 1637971199 + 5184000; // Time begin unlock linearly 2 month from : 23:59:59 GMT 26/11/2021
    //uint256 constant public START_TIME = 1635262800 + 5*60; // Test will be for now + 2minutes
    address constant public REAL_TOKEN = 0xa1B8bCeF70730e200dF36f0248295f4DC2081b9e;
    
    mapping(address => uint256) internal lockTokens; // REAL
    mapping(address => uint256) internal amountPerReleases; // REAL
    mapping(address => uint256) internal nextReleases; // REAL
    mapping(address => uint256) internal countReleases; // REAL
    
    constructor() {
        
    }
    
    // only owner or added beneficiaries can release the vesting amount
    modifier onlyBeneficiaries() {
        require(
            owner() == msg.sender || lockTokens[msg.sender] > 0,
            "You cannot release tokens!"
        );
        _;
    }
    
     /**
     * @dev Add new beneficiary to vesting contract with some conditions.
     *  _amount : Total amount include _upfrontAmount
     */
    function addBeneficiary(address _beneficiary, uint256 _amount) external onlyOwner {
        require(_beneficiary != address(0), "The beneficiary's address cannot be 0");
        require(_amount > 0, "Shares amount has to be greater than 0");
        require(lockTokens[_beneficiary] == 0, "The beneficiary has added to the vesting pool already");
                
        uint256 upfrontAmount = _amount.mul( TGE_RELEASE).div(1000);
        lockTokens[_beneficiary] = _amount;

         // Transfer immediately if any upfront amount
        if (upfrontAmount > 0) {
            lockTokens[_beneficiary] = lockTokens[_beneficiary].sub(upfrontAmount);
            IERC20(REAL_TOKEN).transfer(_beneficiary, upfrontAmount);
        }
        amountPerReleases[_beneficiary] = lockTokens[_beneficiary].div(12);
        countReleases[_beneficiary] = 0;
        nextReleases[_beneficiary] = START_TIME + PERIOD.mul(0);
    }
        /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function claim() public onlyBeneficiaries {
        require(block.timestamp >= START_TIME + PERIOD.mul(countReleases[msg.sender]), "TokenTimelock: current time is before release time");
        require(IERC20(REAL_TOKEN).balanceOf(address(this)).sub(amountPerReleases[msg.sender]) >= 0, "TokenTimelock: no tokens to release");
        
        uint256 clift = block.timestamp.sub(nextReleases[msg.sender]).div(PERIOD) + 1;
        uint256 amount = amountPerReleases[msg.sender].mul(clift);
        if (amount >= lockTokens[msg.sender] ) {
           
            IERC20(REAL_TOKEN).transfer(msg.sender, lockTokens[msg.sender] );
            lockTokens[msg.sender] = 0;
        } else {
            nextReleases[msg.sender] = nextReleases[msg.sender] + PERIOD.mul(clift);

            lockTokens[msg.sender] = lockTokens[msg.sender].sub(amount);
            IERC20(REAL_TOKEN).transfer(msg.sender, amount); 
        }
        
        countReleases[msg.sender] += clift;
    }
    
    
    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }
    
    function getTimeReleaseNext() public view returns(uint256) {
        return START_TIME + PERIOD.mul(countReleases[msg.sender]);
    }
    
    function getLockToken() public view returns(uint256) {
        return lockTokens[msg.sender];
    }
    
    function getAmountPerRelease() public view returns(uint256) {
        return amountPerReleases[msg.sender];
    }
    
    function getBalance() public view returns (uint256) {
        return IERC20(REAL_TOKEN).balanceOf(address(this));
    }

}
