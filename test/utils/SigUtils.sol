// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Permit.sol";

contract SigUtils {
    // EXACTEMENT le même typehash que OZ
    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    IERC20Permit public immutable token;

    constructor(IERC20Permit _token) {
        token = _token;
    }

    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    function getTypedDataHash(Permit memory p) external view returns (bytes32) {
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                p.owner,
                p.spender,
                p.value,
                p.nonce,
                p.deadline
            )
        );
        // Domaine lu sur le token (EIP712 d’OZ)
        bytes32 domainSeparator = token.DOMAIN_SEPARATOR();

        return keccak256(
            abi.encodePacked("\x19\x01", domainSeparator, structHash)
        );
    }
}

