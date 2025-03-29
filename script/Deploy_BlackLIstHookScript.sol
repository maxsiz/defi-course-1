// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

//import "forge-std/Script.sol";
import {Script, console2} from "forge-std/Script.sol";
import "../lib/forge-std/src/StdJson.sol";

import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {HookMiner} from "v4-periphery/src/utils/HookMiner.sol";

import {Constants} from "./base/Constants.sol";
import {BlackListHook} from "../src/BlackListHook.sol";

/// @notice Mines the address and deploys the PointsHook.sol Hook contract
contract Deploy_BlackLIstHookScript is Script, Constants {
	// Ethereum
    // address constant public TRUSTED_ROUTER = 0x66a9893cC07D91D95644AEDD05D03f95e1dBA8Af;

    // UniChain
    // address constant public TRUSTED_ROUTER = 0xEf740bf23aCaE26f6492B10de645D6B98dC8Eaf3;
    
    // Optimism
    //address constant public TRUSTED_ROUTER = 0x851116D9223fabED8E56C0E6b8Ad0c31d98B3507;
    
    // Arbitrum One
    address constant public TRUSTED_ROUTER = 0xA51afAFe0263b40EdaEf0Df8781eA9aa03E381a3;
 
    // Sepolia
    // address constant public TRUSTED_ROUTER = 0x3A9D48AB9751398BbFa63ad67599Bb04e4BdF98b;

    function run() public {
    	console2.log("Chain id: %s", vm.toString(block.chainid));
        console2.log(
            "Deployer address: %s, "
            "\n native balnce %s",
            msg.sender, msg.sender.balance
        );
        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG 
        );

        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(POOLMANAGER, TRUSTED_ROUTER, msg.sender);
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_DEPLOYER, flags, type(BlackListHook).creationCode, constructorArgs);

        // Deploy the hook using CREATE2
        vm.startBroadcast();
        BlackListHook blackListHook = new BlackListHook{salt: salt}(
        	IPoolManager(POOLMANAGER),
            TRUSTED_ROUTER,
            msg.sender
        );
        vm.stopBroadcast();
        console2.log("Calculated address: %s, fact address  %s", hookAddress, address(blackListHook));
        require(address(blackListHook) == hookAddress, "BlackListHook: hook address mismatch");
    }
}