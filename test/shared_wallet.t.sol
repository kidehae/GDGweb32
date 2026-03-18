// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {SharedWallet} from "../src/shared_wallet.sol";

contract SharedWalletTest is Test {
    SharedWallet public wallet;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = address(this); // test contract acts as owner
        user1 = address(0x1);
        user2 = address(0x2);

        wallet = new SharedWallet();
    }

    function testDeposit() public {
        // user1 deposits 1 ETH
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        wallet.deposit{value: 1 ether}();

        uint256 balance1 = wallet.balances(user1);
        uint256 total = wallet.totalBalance();

        assertEq(balance1, 1 ether);
        assertEq(total, 1 ether);

        // user2 deposits 2 ETH
        vm.deal(user2, 2 ether);
        vm.prank(user2);
        wallet.deposit{value: 2 ether}();

        uint256 balance2 = wallet.balances(user2);
        uint256 total2 = wallet.totalBalance();

        assertEq(balance2, 2 ether);
        assertEq(total2, 3 ether);
    }

    function testOnlyOwnerCanWithdraw() public {
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        wallet.deposit{value: 1 ether}();

        // user1 tries to withdraw → should revert
        vm.prank(user1);
        vm.expectRevert("Only owner can withdraw");
        wallet.withdraw(1 ether);

        // owner withdraws
        uint256 ownerBalanceBefore = address(this).balance;
        wallet.withdraw(1 ether);
        uint256 ownerBalanceAfter = address(this).balance;

        // Balance increased by 1 ETH
        assertEq(ownerBalanceAfter - ownerBalanceBefore, 1 ether);
    }

    function testWithdrawMoreThanBalanceFails() public {
        // deposit 1 ETH
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        wallet.deposit{value: 1 ether}();

        // owner tries to withdraw 2 ETH → should revert
        vm.expectRevert("Insufficient balance");
        wallet.withdraw(2 ether);
    }

    function testDepositRecordsArray() public {
        // user1 deposits 1 ETH
        vm.deal(user1, 1 ether);
        vm.prank(user1);
        wallet.deposit{value: 1 ether}();

        // user2 deposits 2 ETH
        vm.deal(user2, 2 ether);
        vm.prank(user2);
        wallet.deposit{value: 2 ether}();

        (address dUser, uint256 dAmount, ) = wallet.deposits(0);
        assertEq(dUser, user1);
        assertEq(dAmount, 1 ether);

        (dUser, dAmount, ) = wallet.deposits(1);
        assertEq(dUser, user2);
        assertEq(dAmount, 2 ether);
    }
    receive() external payable {}
}