// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SimpleAuction} from "../src/auction.sol";

contract SimpleAuctionTest is Test {
    SimpleAuction public auction;

    address public seller;
    address public bidder1;
    address public bidder2;

    // Allow contract to receive ETH
    receive() external payable {}

    function setUp() public {
        seller = address(this); // test contract acts as seller
        bidder1 = address(0x1);
        bidder2 = address(0x2);

        // Fund bidder addresses with ETH
        vm.deal(bidder1, 10 ether);
        vm.deal(bidder2, 10 ether);

        // Deploy auction contract
        auction = new SimpleAuction();
    }

    function testCreateAuction() public {
        auction.createAuction(100); // 100 seconds duration

        (, , uint256 highestBid, uint256 endTime, bool ended) = auction.auctions(1);

        assertEq(highestBid, 0);
        assertEq(endTime, block.timestamp + 100);
        assertEq(ended, false);
    }

    function testBidUpdatesHighest() public {
        auction.createAuction(100);

        // bidder1 bids 1 ether
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(1);

        (, address highestBidder, uint256 highestBid, , ) = auction.auctions(1);
        assertEq(highestBid, 1 ether);
        assertEq(highestBidder, bidder1);

        // bidder2 bids 2 ether
        vm.prank(bidder2);
        auction.bid{value: 2 ether}(1);

        (, highestBidder, highestBid, , ) = auction.auctions(1);
        assertEq(highestBid, 2 ether);
        assertEq(highestBidder, bidder2);

        // bidder1 should have pending returns
        assertEq(auction.pendingReturns(bidder1), 1 ether);
    }

    function testWithdraw() public {
        auction.createAuction(100);

        // bidder1 bids 1 ether
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(1);

        // bidder2 bids 2 ether
        vm.prank(bidder2);
        auction.bid{value: 2 ether}(1);

        // bidder1 withdraws funds
        uint256 balanceBefore = bidder1.balance;
        vm.prank(bidder1);
        auction.withdraw();

        uint256 balanceAfter = bidder1.balance;
        assertEq(balanceAfter - balanceBefore, 1 ether);

        // pendingReturns should now be zero
        assertEq(auction.pendingReturns(bidder1), 0);
    }

    function testEndAuctionTransfersToSeller() public {
        auction.createAuction(1); // 1 sec duration

        // bidder1 bids 1 ether
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(1);

        // fast-forward time
        vm.warp(block.timestamp + 2);

        uint256 sellerBalanceBefore = address(this).balance;

        auction.endAuction(1);

        uint256 sellerBalanceAfter = address(this).balance;
        assertEq(sellerBalanceAfter - sellerBalanceBefore, 1 ether);

        // Auction ended should be true
        (, , , , bool ended) = auction.auctions(1);
        assertEq(ended, true);
    }

    function testCannotBidAfterEnd() public {
        auction.createAuction(1); // 1 sec duration

        // fast-forward past end
        vm.warp(block.timestamp + 2);

        vm.prank(bidder1);
        vm.expectRevert("Auction ended");
        auction.bid{value: 1 ether}(1);
    }

    function testCannotEndTwice() public {
        auction.createAuction(1);

        // bidder1 bids 1 ether
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(1);

        vm.warp(block.timestamp + 2);

        auction.endAuction(1);

        // Ending again should revert
        vm.expectRevert("Auction already ended");
        auction.endAuction(1);
    }

    function testBidTooLowFails() public {
        auction.createAuction(100);

        // bidder1 bids 1 ether
        vm.prank(bidder1);
        auction.bid{value: 1 ether}(1);

        // bidder2 tries to bid 0.5 ether
        vm.prank(bidder2);
        vm.expectRevert("Bid is too low");
        auction.bid{value: 0.5 ether}(1);
    }
}