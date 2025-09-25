// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Script} from "forge-std/Script.sol";
import {Escrow} from "contracts/Escrow.sol";

contract DeployEscrow is Script {
    function run() external {
        // Lis les variables d'env (à définir avant le broadcast)
        // export PRIVATE_KEY=0x....
        // export PAYER=0x....
        // export PAYEE=0x....
        uint256 pk = vm.envUint("PRIVATE_KEY");
        address payer = vm.envAddress("PAYER");
        address payee = vm.envAddress("PAYEE");

        uint64 deadline = uint64(block.timestamp + 7 days);

        vm.startBroadcast(pk);
        Escrow esc = new Escrow(payer, payee, deadline);
        vm.stopBroadcast();

        // Pour le confort, tu peux logger l'adresse :
        // console2.log("Escrow:", address(esc));
    }
}
