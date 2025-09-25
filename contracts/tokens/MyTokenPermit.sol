// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

/// @title MyTokenPermit — ERC20 avec EIP-2612 permit
/// @author Mehdi
/// @notice Autorise une allowance par signature off-chain (permit) puis transferFrom.

contract MyTokenPermit is ERC20, ERC20Permit, Ownable {
/// @param name_ Ethereum (utilisé aussi par le domaine EIP-712)
/// @param symbol_ $
/// @param initialSupply supply initial mintée à `initialOwner`
/// @param initialOwner propriétaire initial recevant le supply    
    constructor(
        string memory name_,
        string memory symbol_,
        uint256 initialSupply,
        address initialOwner
    ) ERC20(name_, symbol_) ERC20Permit(name_) Ownable(initialOwner) {
        _mint(initialOwner, initialSupply);
    }

/// @notice Mint des tokens (réservé au owner) / @param to destinataire / @param amount quantité à mint
/// @param to destinataire
/// @param amount quantité à mint
    function mint(address to, uint256 amount) external onlyOwner {
        _mint(to, amount);
    }
}
