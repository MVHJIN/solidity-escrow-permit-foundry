// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Aide à calculer le digest EIP-2612 pour ERC20Permit
contract SigUtils {
    bytes32 internal domainSeparator;

    // keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)")
    bytes32 public constant PERMIT_TYPEHASH =
        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)");

    constructor(bytes32 domainSeparator_) {
        domainSeparator = domainSeparator_;
    }

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    function getTypedDataHash(Permit memory p) external view returns (bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                domainSeparator,
                keccak256(
                    abi.encode( PERMIT_TYPEHASH, p.owner, p.spender, p.value, p.nonce, p.deadline
                    )
                )
            )
        );
    }
}
