// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {StakingPool} from "../src/staking_pool.sol";

contract StakingPoolTest is Test {
    StakingPool public pool;

    // Allow this contract to receive ETH from the pool
    receive() external payable {}

  function setUp() public {
    // Deploy the staking pool with rewardRate = 1 wei/sec
    pool = new StakingPool(1);

    // Fund the test contract with ETH
    vm.deal(address(this), 10 ether);

    // Fund the pool contract so it can pay rewards
    vm.deal(address(pool), 1 ether);
}

    function testStake() public {
        // Stake 1 ETH
        pool.stake{value: 1 ether}();

        // Check the stake stored correctly
        (uint256 amount, uint256 startTime, bool claimed) = pool.stakes(address(this));
        assertEq(amount, 1 ether);
        assertEq(claimed, false);
        assertGt(startTime, 0);
    }

    function testRewardCalculation() public {
        pool.stake{value: 1 ether}();

        // Fast-forward 100 seconds
        vm.warp(block.timestamp + 100);

        uint256 reward = pool.calculateReward(address(this));
        assertEq(reward, 100); // rewardRate = 1 wei/sec
    }

    function testUnstake() public {
        pool.stake{value: 1 ether}();

        // Warp forward 50 seconds
        vm.warp(block.timestamp + 50);

        // Unstake
        pool.unstake();

        // Stake should now be marked claimed
        (, , bool claimed) = pool.stakes(address(this));
        assertEq(claimed, true);

        // Check that ETH was received (stake + reward)
        assertEq(address(this).balance, 10 ether - 1 ether + 1 ether + 50); 
        // initial 10 ETH - 1 ETH staked + 1 ETH stake returned + 50 wei reward
    }

    function testCannotUnstakeTwice() public {
        pool.stake{value: 1 ether}();

        // Unstake once
        pool.unstake();

        // Second unstake should revert
        vm.expectRevert("Already claimed");
        pool.unstake();
    }

    function testMultipleStakes() public {
    // Stake 1 ETH first time
    pool.stake{value: 1 ether}();

    // Fast-forward 30 seconds
    vm.warp(block.timestamp + 30);

    // Stake 2 ETH second time (overwrites previous)
    pool.stake{value: 2 ether}();

    // Destructure the tuple returned by the public mapping getter
    (uint256 amount, uint256 startTime, bool claimed) = pool.stakes(address(this));
    
    assertEq(claimed, false);
    assertEq(amount, 2 ether);
}
}