
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol"; import {Escrow} from "../contracts/Escrow.sol"; import {Errors} from 
"../contracts/utils/Errors.sol";

contract EscrowTest is Test {
    Escrow esc;
    address PAYER = address(0xA11CE);
    address PAYEE = address(0xB0B);
    uint64 DEADLINE;

    function setUp() public {
        DEADLINE = uint64(block.timestamp + 3 days);
        esc = new Escrow(PAYER, PAYEE, DEADLINE);
        vm.deal(PAYER, 1000 ether);
        vm.deal(PAYEE, 1 ether);
    }

    function _deposit(uint256 value) internal {
        vm.prank(PAYER);
        esc.deposit{value: value}();
    }

    function test_DepositAndWithdrawWithApproval() public {
        _deposit(10 ether);
        vm.prank(PAYER);
        esc.approve();

        uint256 balBefore = PAYEE.balance;
        vm.prank(PAYEE);
        esc.withdraw();
        assertEq(PAYEE.balance, balBefore + 10 ether);
        assertEq(address(esc).balance, 0);
    }

    function test_Deposit_thenRefundAfterDeadline() public {
        _deposit(5 ether);
        vm.warp(DEADLINE + 1);
        uint256 balBefore = PAYER.balance;
        vm.prank(PAYER);
        esc.refund();
        assertEq(PAYER.balance, balBefore + 5 ether);
        assertEq(address(esc).balance, 0);
    }

    function test_Revert_OnlyPayerCanDeposit() public {
        vm.expectRevert(Errors.NotPayer.selector);
        vm.prank(PAYEE);
        esc.deposit{value: 1 ether}();
    }

    function test_Revert_DepositTwice() public {
        _deposit(1 ether);
        vm.expectRevert(Errors.AlreadyFunded.selector);
        _deposit(1 ether);
    }

    function test_Revert_WithdrawBeforeApprovalAndBeforeDeadline() public {
        _deposit(2 ether);
        vm.prank(PAYEE);
        vm.expectRevert(Errors.NotApproved.selector);
        esc.withdraw();
    }function test_Revert_DepositAfterDeadline() public {
    vm.warp(DEADLINE + 1); // après la DEADLINE vm.prank(PAYER); vm.expectRevert(Errors.DeadlinePassed.selector); esc.deposit{value: 1 ether}(); // doit échouer
}


    function test_Revert_RefundBeforeDeadline() public {
        _deposit(2 ether);
        vm.expectRevert(Errors.DeadlineNotReached.selector);
        vm.prank(PAYER);
        esc.refund();
    }

    function testFuzz_DepositAmountWithinRange(uint96 amt) public {
        uint256 amount = 1e9 + (uint256(amt) % (100 ether));
        vm.prank(PAYER);
        esc.deposit{value: amount}();
        assertEq(address(esc).balance, amount);
    }

    // === EXO 1 : seul le PAYEE peut withdraw ===
    function test_Revert_OnlyPayeeCanWithdraw() public {
        _deposit(1 ether);
        vm.expectRevert(Errors.NotPayee.selector);
        vm.prank(PAYER);
        esc.withdraw();
    }

    // === EXO 2 : après la DEADLINE, le PAYEE peut withdraw sans approve ===
    function test_WithdrawAfterDeadlineWithoutApprove() public {
        _deposit(2 ether);
        vm.warp(DEADLINE + 1);
        uint256 before = PAYEE.balance;
        vm.prank(PAYEE);
        esc.withdraw();
        assertEq(PAYEE.balance, before + 2 ether);
        assertEq(address(esc).balance, 0);
    }
}
