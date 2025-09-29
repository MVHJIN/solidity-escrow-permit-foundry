// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol"; import {MyTokenPermit} from 
"../../contracts/tokens/MyTokenPermit.sol"; import {SigUtils, IERC20PermitLike} from "../utils/SigUtils.sol";

contract ERC20PermitTest is Test {
    MyTokenPermit token;
    SigUtils sigUtils;

    // "owner" qui va signer le permit
    uint256 ownerPk;
    address owner;
    address spender = address(0xBEEF);
    address receiver = address(0xCAFE);
    uint256 initialSupply = 1_000_000 ether;

    function setUp() public {
        ownerPk = 0xA11CE;
        owner = vm.addr(ownerPk);
        token = new MyTokenPermit("MyToken", "MTK", initialSupply, owner);
        sigUtils = new SigUtils(IERC20PermitLike(address(token)));
        vm.deal(owner, 10 ether);
    }

    function test_Permit_AllowsTransferFrom() public {
        uint256 value = 123 ether;
        uint256 nonce = token.nonces(owner);
        uint256 DEADLINE = block.timestamp + 1 days;

        SigUtils.Permit memory p = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: value,
            nonce: nonce,
            deadline: DEADLINE
        });

        bytes32 digest = sigUtils.getTypedDataHash(p);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        // 1) On écrit l'allowance par signature
        token.permit(owner, spender, value, DEADLINE, v, r, s);
        assertEq(token.allowance(owner, spender), value);

        // 2) Le spender peut maintenant tirer les fonds
        vm.prank(spender);
        bool ok1 = token.transferFrom(owner, receiver, 100 ether);
  assertTrue(ok1);

        assertEq(token.balanceOf(receiver), 100 ether);
        assertEq(token.allowance(owner, spender), value - 100 ether);
    }

    function test_Revert_PermitExpired() public {
        uint256 value = 1 ether;
        uint256 nonce = token.nonces(owner);
        uint256 DEADLINE = block.timestamp - 1; // déjà expiré

        SigUtils.Permit memory p = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: value,
            nonce: nonce,
            deadline: DEADLINE
        });

        bytes32 digest = sigUtils.getTypedDataHash(p);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        vm.expectRevert(); // DEADLINE expirée
        token.permit(owner, spender, value, DEADLINE, v, r, s);
    }

    function test_Revert_PermitReplay() public {
        uint256 value = 5 ether;
        uint256 nonce = token.nonces(owner);
        uint256 DEADLINE = block.timestamp + 1 days;

        SigUtils.Permit memory p = SigUtils.Permit({
            owner: owner,
            spender: spender,
            value: value,
            nonce: nonce,
            deadline: DEADLINE
        });

        bytes32 digest = sigUtils.getTypedDataHash(p);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);

        token.permit(owner, spender, value, DEADLINE, v, r, s);
        assertEq(token.nonces(owner), nonce + 1);

        // Rejouer la même signature doit échouer (nonce plus le même)
        vm.expectRevert();
        token.permit(owner, spender, value, DEADLINE, v, r, s);
    }
function test_Revert_PermitWrongSigner() public {
    uint256 badPk = 0xBADC0DE;

    uint256 value = 1 ether;
    uint256 nonce = token.nonces(owner);
    uint256 DEADLINE = block.timestamp + 1 days;

    SigUtils.Permit memory p = SigUtils.Permit({
        owner: owner,                 // <- owner réel (pas badOwner)
        spender: spender,
        value: value,
        nonce: nonce,
        deadline: DEADLINE
    });

    bytes32 digest = sigUtils.getTypedDataHash(p);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(badPk, digest); // <- MAUVAISE clé

    vm.expectRevert();               // signature invalide => revert
    token.permit(owner, spender, value, DEADLINE, v, r, s);
}
function test_Permit_NonceMonotonic() public {
    uint256 n0 = token.nonces(owner);
    for (uint i; i < 3; i++) {
        uint256 value = 1 ether;
        uint256 nonce = token.nonces(owner);
        uint256 DEADLINE = block.timestamp + 1 days;

        SigUtils.Permit memory p = SigUtils.Permit({
            owner: owner, spender: spender, value: value, nonce: nonce, deadline: DEADLINE
        });

        bytes32 digest = sigUtils.getTypedDataHash(p);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);
        token.permit(owner, spender, value, DEADLINE, v, r, s);
    }
    assertEq(token.nonces(owner), n0 + 3);
}
function test_Permit_InfiniteApproval_NotDecremented() public {
    uint256 max = type(uint256).max;
    uint256 nonce = token.nonces(owner);
    uint256 DEADLINE = block.timestamp + 1 days;

    SigUtils.Permit memory p = SigUtils.Permit({
        owner: owner, spender: spender, value: max, nonce: nonce, deadline: DEADLINE
    });
    bytes32 digest = sigUtils.getTypedDataHash(p);
    (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digest);
    token.permit(owner, spender, max, DEADLINE, v, r, s);

    vm.prank(spender);
     bool ok2 = token.transferFrom(owner, receiver, 100 ether);
  assertTrue(ok2);

    // OZ ne décrémente pas si allowance==type(uint256).max
    assertEq(token.allowance(owner, spender), max);
}
}
