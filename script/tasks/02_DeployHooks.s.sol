// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Hooks} from "@uniswap/v4-core/src/libraries/Hooks.sol";
import {HookMiner} from "@uniswap/v4-periphery/src/utils/HookMiner.sol";
import {Counter} from "../../src/Counter.sol"; // Adjust path as needed
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {Stateful} from "../mixins/Stateful.sol";

/// @dev Mines the address and deploys a hook contract
contract DeployHooksScript is Stateful {
    IPoolManager public poolManager = IPoolManager(readStateAddress("poolManager"));

    /// @dev Composed/orchestrator contract entrypoint
    function run() public {
        require(address(poolManager) != address(0), "PoolManager address not found in state file.");

        // hook contracts must have specific flags encoded in the address
        uint160 flags = uint160(
            Hooks.BEFORE_SWAP_FLAG | Hooks.AFTER_SWAP_FLAG | Hooks.BEFORE_ADD_LIQUIDITY_FLAG
                | Hooks.BEFORE_REMOVE_LIQUIDITY_FLAG
        );

        // Mine a salt that will produce a hook address with the correct flags
        bytes memory constructorArgs = abi.encode(poolManager);
        (address hookAddress, bytes32 salt) =
            HookMiner.find(CREATE2_FACTORY, flags, type(Counter).creationCode, constructorArgs);

        // Deploy the hook using CREATE2
        vm.startBroadcast();
        Counter counter = new Counter{salt: salt}(poolManager);
        vm.stopBroadcast();

        require(address(counter) == hookAddress, "DeployHookScript: Hook Address Mismatch");
        _writeAndLabel(address(poolManager));
    }

    /// @dev CLI entrypoint
    function run(address hooks) public {
        _writeAndLabel(hooks);
    }

    /// @dev Write and label addresses
    function _writeAndLabel(address hooks) private {
        writeStateAddress("hooks", hooks);
        vm.label(hooks, "HookContract");
    }
}
