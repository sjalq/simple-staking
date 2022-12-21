// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "forge-std/console.sol";
import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "../src/SimpleStaking.sol";

contract VaraToken is ERC20 {
    constructor() ERC20("Vara", "VARA") 
    {
        _mint(msg.sender, (10**12)*(10**18));
        this;
    }
}

contract SimpleStakingTest is Test 
{
    event Staked(address indexed _staker, uint _amount, uint _duration, uint indexed _releaseDate);
    event Unstaked(address indexed _staker, uint _amount, uint indexed _originalReleaseDate, uint indexed _releaseDate);

    SimpleStaking public simpleStaking;
    VaraToken public vara;

    function clamp(uint value, uint min, uint max) 
        internal 
        pure 
        returns (uint) 
    {
        return value < min ? min : value > max ? max : value;
    }

    function setUp() 
        public 
    {
        vara = new VaraToken();
        simpleStaking = new SimpleStaking(IERC20(address(vara)));
    }

    function testSS_C_01_Constructor_WorksWithNewVaraToken()
        public
    {
        // do not use simpleStaking or vara state variables to validate the constructor

        VaraToken testVara = new VaraToken();
        SimpleStaking testSimpleStaking = new SimpleStaking(IERC20(address(testVara)));

        assertEq(address(testSimpleStaking.vara()), address(testVara));
    }

    function testSS_SU_01_CannotStakeLessThan300(uint _amount)
        public
    {
        _amount = clamp(_amount, 0, 300*10**18 - 1);

        vara.approve(address(simpleStaking), _amount);

        vm.expectRevert(bytes("stake must be >= 300 vara"));
        simpleStaking.Stake(_amount);
    }

    function testSS_SU_02CanStake300orMoreVaraIfNoStakeAtPresent(uint _amount)
        public
    {
        _amount = clamp(_amount, 300*10**18, vara.balanceOf(address(this)));

        vara.approve(address(simpleStaking), _amount);

        vm.expectEmit(true, true, false, true);
        emit Staked(address(this), _amount, 90 days, block.timestamp + 90 days);

        uint stakerVaraBalanceBefore = vara.balanceOf(address(this));
        uint stakingContractVaraBalanceBefore = vara.balanceOf(address(simpleStaking));

        simpleStaking.Stake(_amount);

        uint stakedBalanceAfter = simpleStaking.stakedFunds(address(this));
        assertEq(stakedBalanceAfter, _amount);

        uint releaseDateAfter = simpleStaking.releaseDates(address(this));
        assertEq(releaseDateAfter, 90 days + block.timestamp); 

        uint stakerVaraBalanceAfter = vara.balanceOf(address(this));
        uint stakingContractVaraBalanceAfter = vara.balanceOf(address(simpleStaking));
        assertEq(stakerVaraBalanceAfter, stakerVaraBalanceBefore - _amount);
        assertEq(stakingContractVaraBalanceAfter, stakingContractVaraBalanceBefore + _amount);
    }

    function testSS_SU_03CanStakeMore(uint _firstAmount, uint _secondAmount, uint32 _secondsToJump)
        public
    {
        _firstAmount = clamp(_firstAmount, 300*10**18, vara.balanceOf(address(this)));

        testSS_SU_02CanStake300orMoreVaraIfNoStakeAtPresent(_firstAmount);

        _secondAmount = clamp(_secondAmount, 0, vara.balanceOf(address(this)));
    
        vara.approve(address(simpleStaking), _secondAmount);

        uint timeBefore = block.timestamp;
        vm.warp(block.timestamp + _secondsToJump);

        vm.expectEmit(true, true, true, true);
        emit Unstaked(address(this), _firstAmount, timeBefore + 90 days, block.timestamp);

        uint stakedBalanceBefore = simpleStaking.stakedFunds(address(this));
        vm.expectEmit(true, true, false, true);
        emit Staked(address(this), _secondAmount + stakedBalanceBefore, 90 days, block.timestamp + 90 days);

        uint stakerVaraBalanceBefore = vara.balanceOf(address(this));
        uint stakingContractVaraBalanceBefore = vara.balanceOf(address(simpleStaking));

        simpleStaking.Stake(_secondAmount);

        uint stakedBalanceAfter = simpleStaking.stakedFunds(address(this));
        assertEq(stakedBalanceAfter, stakedBalanceBefore + _secondAmount);
        assertEq(stakedBalanceAfter, _firstAmount + _secondAmount);

        uint releaseDateAfter = simpleStaking.releaseDates(address(this));
        assertEq(releaseDateAfter, 90 days + block.timestamp);

        uint stakerVaraBalanceAfter = vara.balanceOf(address(this));
        uint stakingContractVaraBalanceAfter = vara.balanceOf(address(simpleStaking));
        assertEq(stakerVaraBalanceAfter, stakerVaraBalanceBefore - _secondAmount);
        assertEq(stakingContractVaraBalanceAfter, stakingContractVaraBalanceBefore + _secondAmount); 
    }

    function testSS_U01CannotUnstakeEarly(uint _amount, uint _secondsToJump)
        public
    {
        // logic:
        // * stake
        // * skip forward in time, but less than 90 days
        // * setup revert expect
        // * try to unstake

        _amount = clamp(_amount, 300*10**18, vara.balanceOf(address(this)));
        vara.approve(address(simpleStaking), _amount);

        simpleStaking.Stake(_amount);

        _secondsToJump = clamp(_secondsToJump, 0, 90 days - 1 seconds);
        vm.warp(block.timestamp + _secondsToJump);

        vm.expectRevert(bytes("cannot unstake early"));
        simpleStaking.Unstake();
    }

    function testSS_U02()
        public
    {

    }
}

