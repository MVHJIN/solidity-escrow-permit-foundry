// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Test} from "forge-std/Test.sol";
import {console2} from "forge-std/console2.sol";
import {MyTokenPermit} from "../../contracts/tokens/MyTokenPermit.sol";

contract ERC20PermitTest is Test {
    MyTokenPermit token;

    uint256 ownerPk;
    address owner;
    address spender = address(0xBEEF);
    address receiver = address(0xCAFE);
    uint256 initialSupply = 1_000_000 ether;

    function setUp() public {
        ownerPk = 0xA11CE;
        owner = vm.addr(ownerPk);
        token = new MyTokenPermit("MyToken", "MTK", initialSupply, owner);
        vm.deal(owner, 10 ether);
    }

    /// Debug: reconstruit le structHash et le digest "comme permit"
    function _expectedDigest(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline
    ) internal view returns (bytes32 digest, bytes32 structHash, bytes32 typehash, bytes32 domain) {
        typehash = keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");
        uint256 nonce = token.nonces(_owner);
        structHash = keccak256(abi.encode(typehash, _owner, _spender, _value, nonce, _deadline));
        domain = token.DOMAIN_SEPARATOR();
        digest = keccak256(abi.encodePacked("\x19\x01", domain, structHash));
    }

    function test_Permit_AllowsTransferFrom() public {
        uint256 value = 123 ether;
        uint256 deadline = block.timestamp + 1 days;

        // 1) Digest via helper du contrat
        bytes32 digestFromHelper = token.previewPermitTypedHash(owner, spender, value, deadline);

        // 2) Digest reconstruit côté test (doit être IDENTIQUE)
        (bytes32 digestExpected, bytes32 structHash, bytes32 typehash, bytes32 domain) =
            _expectedDigest(owner, spender, value, deadline);

        // Asserts de diagnostic
        assertEq(digestFromHelper, digestExpected, "digest(helper) != digest(expected)");
        console2.log("DOMAIN_SEPARATOR");
console2.logBytes32(domain);
        console2.log("TYPEHASH");
console2.logBytes32(typehash);
        console2.log("STRUCT_HASH");
console2.logBytes32(structHash);
        console2.log("DIGEST");
console2.logBytes32(digestExpected);
        console2.log("owner");
console2.logAddress(owner);

        // Signature avec la bonne clé
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digestExpected);

        // Vérifie que la signature recover bien le owner
        address rec = ecrecover(digestExpected, v, r, s);
        console2.log("recovered");
console2.logAddress(rec);
        assertEq(rec, owner, "recovered != owner");

        // Appel permit
        token.permit(owner, spender, value, deadline, v, r, s);
        assertEq(token.allowance(owner, spender), value);

        vm.prank(spender);
        bool ok = token.transferFrom(owner, receiver, 100 ether);
        assertTrue(ok);
        assertEq(token.balanceOf(receiver), 100 ether);
        assertEq(token.allowance(owner, spender), value - 100 ether);
    }

    function test_Revert_PermitExpired() public {
        uint256 value = 1 ether;
        uint256 deadline = block.timestamp - 1;

        (bytes32 digestExpected,,,) = _expectedDigest(owner, spender, value, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digestExpected);

        vm.expectRevert();
        token.permit(owner, spender, value, deadline, v, r, s);
    }

    function test_Revert_PermitReplay() public {
        uint256 value = 5 ether;
        uint256 deadline = block.timestamp + 1 days;

        (bytes32 digestExpected,,,) = _expectedDigest(owner, spender, value, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digestExpected);

        token.permit(owner, spender, value, deadline, v, r, s);
        vm.expectRevert(); // nonce a changé => re-jouer la même sig doit revert
        token.permit(owner, spender, value, deadline, v, r, s);
    }

    function test_Permit_NonceMonotonic() public {
        uint256 n0 = token.nonces(owner);
        for (uint256 i; i < 3; i++) {
            uint256 value = 1 ether;
            uint256 deadline = block.timestamp + 1 days;
            (bytes32 digestExpected,,,) = _expectedDigest(owner, spender, value, deadline);
            (uint8 v, bytes32 r, bytes32 s) = vm.sign(ownerPk, digestExpected);
            token.permit(owner, spender, value, deadline, v, r, s);
        }
        assertEq(token.nonces(owner), n0 + 3);
    }

    function test_Revert_PermitWrongSigner() public {
        uint256 badPk = 0xBADC0DE;
        uint256 value = 1 ether;
        uint256 deadline = block.timestamp + 1 days;

        (bytes32 digestExpected,,,) = _expectedDigest(owner, spender, value, deadline);
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(badPk, digestExpected);

        vm.expectRevert();
        token.permit(owner, spender, value, deadline, v, r, s);
    }
}
