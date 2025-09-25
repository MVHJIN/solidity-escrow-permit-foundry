// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @title Erreurs custom pour Escrow / @author Mehdi / @notice Réduit le gas vs messages require et facilite 
//les tests

library Errors {
    error ZeroAmount();
    error NotPayer();
    error NotPayee();
    error AlreadyFunded();
    error NotFunded();
    error AlreadyApproved();
    error NotApproved();
    error DeadlineNotReached();
    error DeadlinePassed();
}
