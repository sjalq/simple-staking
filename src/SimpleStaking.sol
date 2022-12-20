// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.0;

abstract contract IERC20
{
    function transferFrom(address _from, address _to, uint256 _amount) external virtual returns (bool);
    function transfer(address to, uint256 amount) external virtual returns (bool);
}

contract SimpleStaking 
{
    IERC20 public vara; // = IERC20(0xYourVaraTokenContractAddress) 
     
    mapping (address => uint) stakedFunds;
    mapping (address => uint) releaseDates; 

    event Staked(address _staker, uint _amount, uint _duration, uint _releaseDate);
    event Unstaked(address _staker, uint _amount, uint _originalReleaseDate, uint _releaseDate);

    constructor (IERC20 _vara) {
        vara = _vara;
    }

    function Stake(uint _amount)
        public
    {
        require(_amount + stakedFunds[msg.sender] >= 300 * 10**18, "stake must be >= 300 vara");

        uint currentStake = stakedFunds[msg.sender];
        if (currentStake >= 0) 
            _unstake();

        _stake(currentStake + _amount, 90 days + block.timestamp);
    }

    function Unstake()
        public
    {
        require(releaseDates[msg.sender] > block.timestamp, "too early to unstake");
        _unstake();
    }

    function _stake(uint _amount, uint _releaseDate)
        private
    {
        // update the mappings
        stakedFunds[msg.sender] = _amount; // not += because we unstake first to emit noeugh info to do the accounting for the merkle drop
        releaseDates[msg.sender] = _releaseDate;

        // transfer _amount of vara to this contract
        vara.transferFrom(msg.sender, address(this), _amount);

        // emit a Stake event
        emit Staked(msg.sender, _amount, _releaseDate - block.timestamp, _releaseDate);
    }

    function _unstake()
        private
    {
        uint totalStaked = stakedFunds[msg.sender];
        // emit an unstaking event
        emit Unstaked(msg.sender, totalStaked, releaseDates[msg.sender], block.timestamp);
        // update the mappings
        stakedFunds[msg.sender] = 0; 
        releaseDates[msg.sender] = 0;
        // transfer _amount of vara to msg.sender
        vara.transfer(msg.sender, totalStaked);
    }
}
