// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MyTokenPermit is ERC20, ERC20Permit, Ownable {
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply_,
        address owner_
    ) ERC20(name_, symbol_) ERC20Permit(name_) Ownable(owner_) {
        _mint(owner_, initialSupply_);
    }

    // Helper pour les tests: renvoie le digest EIP-712 que "permit" attend.
    function previewPermitTypedHash(
        address _owner,
        address _spender,
        uint256 _value,
        uint256 _deadline
    ) external view returns (bytes32) {
        bytes32 PERMIT_TYPEHASH = keccak256(
            "Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"
        );

        // IMPORTANT: on utilise le nonce courant (nonces(_owner)),
        // identique à celui que ERC20Permit utilisera (via _useNonce) au moment du permit.
        bytes32 structHash = keccak256(
            abi.encode(
                PERMIT_TYPEHASH,
                _owner,
                _spender,
                _value,
                nonces(_owner),
                _deadline
            )
        );

        return _hashTypedDataV4(structHash);
    }
}
