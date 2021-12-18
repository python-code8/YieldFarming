//SPDX-License-Identifier:MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Reward {

    using SafeMath for uint;
    mapping(address => uint) public addressToBalance;
    mapping(address => uint) public addressToStakeTime;
    mapping(address => uint) public addressToUnstakeTime;
    mapping(address => uint) public addressToHodlTime;
    mapping(address => uint) public addressToNextRewardTime;
    uint oneWeek = 604800;
    uint oneMonth = 2629746;
    uint public contractBalance;
    address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address owner;
    event Rewarded(address receiver, uint time, uint nextRewardTime);
    event Staked(address staker, uint _amount, uint time);
    event Unstaked(address unstaker, uint _amount, uint time);

    constructor(address _rewardTokenAddress) public {
        owner = msg.sender;
        IERC20 Gigs = IERC20(_rewardTokenAddress);
    }

    function stake(uint _amount, address _token) public payable {
        require(_amount > 0, "Enter a valid amount");
        require(_token == DAI, "Only stake wEth");
        IERC20(_token).transferFrom(msg.sender, address(this), _amount);
        addressToBalance[msg.sender] += _amount;
        addressToStakeTime[msg.sender] = block.timestamp;
        contractBalance += _amount;
        emit Staked(msg.sender, _amount, block.timestamp);
    }

    function unstake(uint _amount, address _token) public payable {
        require(_amount > 0, "Enter a valid amount");
        require(_amount < addressToBalance[msg.sender], "Insufficient Balance");
        contractBalance -= _amount;
        addressToBalance[msg.sender] -= _amount;
        addressToUnstakeTime[msg.sender] = block.timestamp;
        IERC20(_token).transfer(msg.sender, _amount);
        emit Unstaked(msg.sender, _amount, block.timestamp);
    }

    function issueReward(address _receiver) public payable {
        require(msg.sender == owner, "You don't have access");
        require(addressToNextRewardTime[_receiver] < block.timestamp, "Rewards already sent");
        addressToHodlTime[_receiver] = addressToUnstakeTime[_receiver] - addressToStakeTime[msg.sender];
        require(addressToHodlTime[_receiver] > oneWeek, "You aren't eligible yet");
        IERC20(Gigs).transfer(_receiver, addressToBalance[_receiver].div(10));
        addressToNextRewardTime[_receiver] = block.timestamp + oneMonth;
        emit Rewarded(_receiver, block.timestamp, block.timestamp + oneMonth);
    }
}
