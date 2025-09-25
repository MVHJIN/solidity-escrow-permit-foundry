// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol"; import {Escrow} from "../../contracts/Escrow.sol";

contract EscrowInvariants is Test {
    Escrow esc;
    address payer = address(0xA11CE);
    address payee = address(0xB0B);
    uint64 deadline;

    function setUp() public {
        deadline = uint64(block.timestamp + 2 days);
        esc = new Escrow(payer, payee, deadline);
        vm.deal(payer, 1000 ether);
        vm.deal(payee, 1 ether);
    }

    // Invariant simple d'intégrité : le solde du contrat ne doit pas être négatif
    // et s'aligne avec l'état logique "funded/amount".
    function invariant_CannotHoldNegativeOrExceedBalance() public view {
        uint256 tracked = esc.amount();
        bool funded = esc.funded();
        if (funded) {
            assertEq(address(esc).balance, tracked);
        } else {
            assertLe(address(esc).balance, tracked);
        }
    }
}
