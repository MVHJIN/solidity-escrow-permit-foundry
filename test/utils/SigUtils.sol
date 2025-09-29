// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20PermitLike {
    function DOMAIN_SEPARATOR() external view returns (bytes32);
}

contract SigUtils {
    struct Permit {
        address owner;
        address spender;
        uint256 value;
        uint256 nonce;
        uint256 deadline;
    }

    bytes32 internal constant PERMIT_TYPEHASH =
        keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

    IERC20PermitLike public immutable token;

    constructor(IERC20PermitLike _token) {
        token = _token;
    }

    function getTypedDataHash(Permit memory p) public view returns (bytes32) {
        bytes32 ds = token.DOMAIN_SEPARATOR();
        return keccak256(
            abi.encodePacked(
                "\x19\x01",
                ds,
                keccak256(
                    abi.encode(
                        PERMIT_TYPEHASH,
                        p.owner,
                        p.spender,
                        p.value,
                        p.nonce,
                        p.deadline
                    )
                )
            )
        );
    }
}
