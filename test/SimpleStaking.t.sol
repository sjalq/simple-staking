// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/SimpleStaking.sol";

contract SimpleStakingTest is Test {
    SimpleStaking public simpleStaking;

    function setUp() 
        public 
    {
        // vara = new WeirdToken();
    }

    function testSS_C_01()
        public
    {
        // simpleStaking = new SimpleStaking(vara);
    }

    function testSS_SU_01(uint _amount)
        public
    {
        // simpleStaking.Stake(100);
    }

    function testSS_SU_02(uint _amount)
        public
    {
        // simpleStaking.Stake(100);
    }

    function testSS_SU_03(uint _amount)
        public
    {
        // simpleStaking.Stake(100);
    }

    function testSS_U01()
        public
    {
        // simpleStaking.Unstake();
    }

    function testSS_U02()
        public
    {
        // simpleStaking.Unstake();
    }
}

