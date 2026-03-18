// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract StakingPool {

    /* =============================================================
                            STEP 1
       Create a Stake struct.
       It must store:
       - amount (uint256)
       - startTime (uint256)
       - claimed (bool)
    ============================================================= */

    // TODO: Define struct here

    struct Stake{
        uint256 amount;
        uint256 startTime;
        bool claimed;
    }

    /* =============================================================
                            STEP 2
       Create state variables:
       - owner (address)
       - rewardRate (uint256)  // reward per second
       - mapping to track user stakes
    ============================================================= */

    // TODO: Declare owner

    address owner;
    
    // TODO: Declare rewardRate

    uint256 rewardRate;
    
    // TODO: Declare stakes mapping

    mapping(address => Stake) public stakes;

    /* =============================================================
                            STEP 3
       Create constructor
       It should:
       - set owner = msg.sender
       - set rewardRate
    ============================================================= */

    // TODO: Implement constructor
    constructor(uint256 rrate){
        owner = msg.sender;
        rewardRate = rrate;
    }

    /* =============================================================
                            STEP 4
       Create stake() function
       It should:
       - Be payable
       - Require msg.value > 0
       - Store stake amount
       - Store startTime
       - Set claimed = false
    ============================================================= */

    // TODO: Implement stake()

    function stake() payable public {
        require(msg.value > 0, "Must stake ETH");
        stakes[msg.sender] = Stake({
            amount: msg.value,
            startTime: block.timestamp,
            claimed: false
        });

    }


    /* =============================================================
                            STEP 5
       Create calculateReward() function
       It should:
       - Take user address
       - Calculate staking duration
       - reward = duration * rewardRate
       - Return reward
    ============================================================= */

    // TODO: Implement calculateReward()

    function calculateReward(address user) public view returns(uint256){
        Stake storage s = stakes[user];
        if (s.claimed) return 0;

        uint256 duration = block.timestamp - s.startTime;  
        uint256 reward = duration * rewardRate;
        return reward;
    }


    /* =============================================================
                            STEP 6
       Create unstake() function
       It should:
       - Get user's stake
       - Require not already claimed
       - Calculate reward
       - Mark claimed = true
       - Transfer stake + reward to user
    ============================================================= */

    // TODO: Implement unstake()


    function unstake() public {
    Stake storage s = stakes[msg.sender];
    require(!s.claimed, "Already claimed");

    uint256 reward = calculateReward(msg.sender);
    s.claimed = true;

    uint256 payout = s.amount + reward;
    (bool success, ) = msg.sender.call{value: payout}("");
    require(success, "Transfer failed");
}



}
