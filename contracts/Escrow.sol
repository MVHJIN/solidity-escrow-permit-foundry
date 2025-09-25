// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Errors} from "./utils/Errors.sol";

/// @title Escrow simple à 2 parties avec deadline / @author Mehdi / @notice Le payer dépose; le payee retire si 
//approuvé ou après la deadline; sinon le payer peut refund.

/**
 * @title Simple time-based escrow with payer approval
 * @notice Flow:
 * - payer deploys or is set at construction
 * - payer funds via deposit(amount)
 * - payee can withdraw if payer approved OR after deadline
 * - payer can refund before approval and after deadline
 */
contract Escrow is ReentrancyGuard {
    using Errors for *;

// --- ETATS ---------------------------------------------------------------------------------
    address public immutable payer;
    address public immutable payee;
    uint64 public immutable deadline; // unix timestamp (seconds)

/* solhint-disable use-natspec */
// --- EVENEMENTS ----------------------------------------------------------------------------
    event Deposited(address indexed from, uint256 amount);
    event Approved(address indexed by);
    event Withdrawn(address indexed to, uint256 amount);
    event Refunded(address indexed to, uint256 amount);

    uint256 public amount; // wei to be released
    bool public funded; // true after deposit
    bool public approved; // set by payer
/* solhint-enable use-natspec */

/// @param _payer adresse qui déposera les fonds
/// @param _payee adresse autorisée à retirer
/// @param _deadline timestamp (secondes) de la limite
constructor(address _payer, address _payee, uint64 _deadline) {
    require(_payer != address(0) && _payee != address(0), "zero addr");
    payer = _payer;
    payee = _payee;
    deadline = _deadline;

    }

    modifier onlyPayer() {
        if (msg.sender != payer) revert Errors.NotPayer();
        _;
    }

    modifier onlyPayee() {
        if (msg.sender != payee) revert Errors.NotPayee();
        _;
    }

/// @notice Le payer dépose des fonds avant la deadline (une seule fois)
    function deposit() external payable onlyPayer {
        if (msg.value == 0) revert Errors.ZeroAmount();
        if (funded) revert Errors.AlreadyFunded();
        if (block.timestamp > deadline) revert Errors.DeadlinePassed();
        amount = msg.value;
        funded = true;
        emit Deposited(msg.sender, msg.value);
    }

/// @notice Le payer approuve le retrait du payee
    function approve() external onlyPayer {
        if (!funded) revert Errors.NotFunded();
        if (approved) revert Errors.AlreadyApproved();
        approved = true;
        emit Approved(msg.sender);
    }

/// @notice Le payee retire si `approved` ou si la deadline est dépassée (protégé contre la réentrance)
    function withdraw() external nonReentrant onlyPayee {
        if (!funded) revert Errors.NotFunded();
        // payee may withdraw if approved OR after deadline has passed
        if (!approved && block.timestamp <= deadline) revert Errors.NotApproved();
        uint256 toSend = amount;
        amount = 0;
        funded = false;
        approved = false;
        (bool ok, ) = payee.call{value: toSend}("");
        require(ok, "transfer failed");
        emit Withdrawn(payee, toSend);
    }

/// @notice Le payer se rembourse si deadline passée et pas d’approbation (protégé contre la réentrance)
    function refund() external nonReentrant onlyPayer {
        if (!funded) revert Errors.NotFunded();
        // refund allowed only if NOT approved and deadline reached
        if (approved) revert Errors.AlreadyApproved();
        if (block.timestamp < deadline) revert Errors.DeadlineNotReached();
        uint256 toSend = amount;
        amount = 0;
        funded = false;
        (bool ok, ) = payer.call{value: toSend}("");
        require(ok, "refund failed");
        emit Refunded(payer, toSend);
    }
}
