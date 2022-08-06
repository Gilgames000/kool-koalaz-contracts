// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity ^0.8.13;

import "../src/KoolKoalazNFT.sol";
import "forge-std/Script.sol";

contract Deploy is Script {
    function run() public {
        vm.broadcast();
        new KoolKoalazNFT();
    }
}
