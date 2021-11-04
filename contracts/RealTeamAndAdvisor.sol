// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import '@openzeppelin/contracts/access/Ownable.sol';
import '@openzeppelin/contracts/token/ERC20/ERC20.sol';
import '@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol';

contract REALTeamAndAdvisor is Ownable {
    
    using SafeMath for uint256;
    using SafeERC20 for ERC20;
    
    uint256 constant public PERIOD = 90 days;
    uint256 public START_TIME = 1643155199; // Time begin unlock linearly 2 month from : 23:59:59 GMT 23/11/2021
    uint256 public totalBeneficiaries;
    ERC20 public REAL_TOKEN;

    struct LockInfo {
        uint256 amountLock;
        uint256 amountClaimed;
        uint256 nextRelease;
        uint256 countReleases;
    }
    
    mapping(address => LockInfo) public lockTokens; // REAL
    mapping (uint256 => address) public listBeneficiaries;
    
    
    event ClaimToken(address addr, uint256 amount);
    
    constructor(address _realToken, uint256 _startTime) {
        REAL_TOKEN = ERC20(_realToken);
        START_TIME = _startTime;
    }
    
    // only owner or added beneficiaries can release the vesting amount
    modifier onlyBeneficiaries() {
        require(
            owner() == msg.sender || lockTokens[msg.sender].amountLock > 0,
            "You cannot release tokens!"
        );
        _;
    }
    
    function addBeneficiary(address[] calldata _beneficiarys, uint256[] calldata _amounts) external onlyOwner {
        require (_beneficiarys.length == _amounts.length,"Input not correct");
        for(uint256 i=0; i <_beneficiarys.length; i++){
            address addr = _beneficiarys[i];
            require(addr != address(0), "The beneficiary's address cannot be 0");
            require(_amounts[i] > 0, "Shares amount has to be greater than 0");
            require(lockTokens[addr].amountLock == 0, "The beneficiary has added to the vesting pool already");
            lockTokens[addr].amountLock = _amounts[i];
            listBeneficiaries[totalBeneficiaries.add(i+1)] = addr;
            lockTokens[addr].nextRelease = START_TIME + PERIOD.mul(0);
        }
        totalBeneficiaries = totalBeneficiaries.add(_beneficiarys.length);
    }
    /**
     * @notice Transfers tokens held by timelock to beneficiary.
     */
    function claim() public onlyBeneficiaries {
        require(block.timestamp >= START_TIME + PERIOD.mul(lockTokens[msg.sender].countReleases), "TokenTimelock: current time is before release time");
        (uint256 amount, uint256 clift) = _tokenCanClaim(msg.sender);
        require(amount > 0, "Token Lock: Do not have any token can unlock ");
       
        REAL_TOKEN.safeTransfer(msg.sender, amount);
        lockTokens[msg.sender].amountClaimed += amount;
        lockTokens[msg.sender].nextRelease += PERIOD.mul(clift);
        lockTokens[msg.sender].countReleases += clift;

        emit ClaimToken(msg.sender, amount);
    }
    
    function _tokenCanClaim(address add) internal view returns(uint256, uint256) {
        uint256 nextRelease = lockTokens[add].nextRelease;
        if(lockTokens[add].amountLock == lockTokens[add].amountClaimed || block.timestamp < nextRelease){
            return (0,0);
        }
        uint256 clift = block.timestamp.sub(nextRelease).div(PERIOD) + 1;
        uint256 amount = lockTokens[add].amountLock.div(5).mul(clift);
        if (lockTokens[add].amountClaimed.add(amount) >= lockTokens[add].amountLock) {
            amount = lockTokens[add].amountLock.sub(lockTokens[add].amountClaimed);
        }
        return (amount, clift);
    }
    
    function getCurrentTime() public view returns(uint256) {
        return block.timestamp;
    }

    
    function getTimeReleaseNext(address addr) external view returns(uint256) {
        return lockTokens[addr].nextRelease;
    }

    function getTokenCanClaim(address addr) external view returns(uint256) {
        (uint256 amount, ) = _tokenCanClaim(addr);
        return amount;
    }
    
    
    function getTokenClaimed(address addr) external view returns(uint256) {
        return lockTokens[addr].amountClaimed;
    }

    function getReamingToken(address addr) external view returns(uint256) {
         return lockTokens[addr].amountLock.sub(lockTokens[addr].amountClaimed);
    }
        
    function getBalance() public view returns (uint256) {
        return REAL_TOKEN.balanceOf(address(this));
    }

    function withdrawREAL(uint256 _amount) external onlyOwner {
        uint256 balance = REAL_TOKEN.balanceOf(address(this));
        if(balance >= _amount){
            REAL_TOKEN.safeTransfer(owner(), _amount);
        } else {
            REAL_TOKEN.safeTransfer(owner(), balance);
        }
    }
}
