// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import {Errors} from "./utils/Errors.sol";

/// @title Escrow simple à 2 parties avec DEADLINE / @author Mehdi / @notice Le PAYER dépose; le PAYEE retire si 
//approuvé ou après la DEADLINE; sinon le PAYER peut refund.

/**
 * @title Simple time-based escrow with PAYER approval
 * @notice Flow:
 * - PAYER deploys or is set at construction
 * - PAYER funds via deposit(amount)
 * - PAYEE can withdraw if PAYER approved OR after DEADLINE
 * - PAYER can refund before approval and after DEADLINE
 */
contract Escrow is ReentrancyGuard {
    using Errors for *;

// --- ETATS ---------------------------------------------------------------------------------
    address public immutable PAYER;
    address public immutable PAYEE;
    uint64 public immutable DEADLINE; // unix timestamp (seconds)

/* solhint-disable use-natspec */
// --- EVENEMENTS ----------------------------------------------------------------------------
    event Deposited(address indexed from, uint256 amount);
    event Approved(address indexed by);
    event Withdrawn(address indexed to, uint256 amount);
    event Refunded(address indexed to, uint256 amount);

    uint256 public amount; // wei to be released
    bool public funded; // true after deposit
    bool public approved; // set by PAYER
/* solhint-enable use-natspec */

/// @param _payer adresse qui déposera les fonds
/// @param _payee adresse autorisée à retirer
/// @param _deadline timestamp (secondes) de la limite
constructor(address _payer, address _payee, uint64 _deadline) {
    require(_payer != address(0) && _payee != address(0), "zero addr");
    PAYER = _payer;
    PAYEE = _payee;
    DEADLINE = _deadline;

    }

    modifier onlyPayer() {
        if (msg.sender != PAYER) revert Errors.NotPayer();
        _;
    }

    modifier onlyPayee() {
        if (msg.sender != PAYEE) revert Errors.NotPayee();
        _;
    }

/// @notice Le PAYER dépose des fonds avant la DEADLINE (une seule fois)
    function deposit() external payable onlyPayer {
        if (msg.value == 0) revert Errors.ZeroAmount();
        if (funded) revert Errors.AlreadyFunded();
        if (block.timestamp > DEADLINE) revert Errors.DeadlinePassed();
        amount = msg.value;
        funded = true;
        emit Deposited(msg.sender, msg.value);
    }

/// @notice Le PAYER approuve le retrait du PAYEE
    function approve() external onlyPayer {
        if (!funded) revert Errors.NotFunded();
        if (approved) revert Errors.AlreadyApproved();
        approved = true;
        emit Approved(msg.sender);
    }

/// @notice Le PAYEE retire si `approved` ou si la DEADLINE est dépassée (protégé contre la réentrance)
    function withdraw() external nonReentrant onlyPayee {
        if (!funded) revert Errors.NotFunded();
        // PAYEE may withdraw if approved OR after DEADLINE has passed
        if (!approved && block.timestamp <= DEADLINE) revert Errors.NotApproved();
        uint256 toSend = amount;
        amount = 0;
        funded = false;
        approved = false;
        (bool ok, ) = PAYEE.call{value: toSend}("");
        require(ok, "transfer failed");
        emit Withdrawn(PAYEE, toSend);
    }

/// @notice Le PAYER se rembourse si DEADLINE passée et pas d’approbation (protégé contre la réentrance)
    function refund() external nonReentrant onlyPayer {
        if (!funded) revert Errors.NotFunded();
        // refund allowed only if NOT approved and DEADLINE reached
        if (approved) revert Errors.AlreadyApproved();
        if (block.timestamp < DEADLINE) revert Errors.DeadlineNotReached();
        uint256 toSend = amount;
        amount = 0;
        funded = false;
        (bool ok, ) = PAYER.call{value: toSend}("");
        require(ok, "refund failed");
        emit Refunded(PAYER, toSend);
    }
}
