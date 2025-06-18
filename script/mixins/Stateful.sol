// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";

/// @dev Provides scripts with the capability to be state-aware by reading from
///   and writing to a chain-specific deployment.json file. These files will live
///   in script/inputs/{chainid}/ and this directory must exist prior to running the script.
abstract contract Stateful is Script {
    /// @dev Foundry needs this to serialize json
    string private constant DEPLOYMENT_OBJECT_KEY = "";

    /// JSON key does not exist
    error NonexistentKey();
    /// JSON file is not populated
    error EmptyJsonFile();

    /// @dev Constructs the dynamic path to the deployment state file
    function _getDeploymentStateFile() private view returns (string memory) {
        return string(
            abi.encodePacked(vm.projectRoot(), "/script/input/", vm.toString(block.chainid), "/deployments.json")
        );
    }

    /// @dev Reads a specific address for a given key from the state file
    function readStateAddress(string memory key) internal view returns (address) {
        string memory filePath = _getDeploymentStateFile();

        string memory contents = vm.readFile(filePath);
        if (bytes(contents).length == 0) revert EmptyJsonFile();

        string memory path = string.concat(".", key);
        if (!vm.keyExists(contents, path)) revert NonexistentKey();

        return vm.parseJsonAddress(contents, path);
    }

    /// @dev Writes/updates an address for a given key in the state file
    function writeStateAddress(string memory key, address value) internal {
        string memory filePath = _getDeploymentStateFile();
        string memory currentState;

        // Handle file may not exist
        try vm.readFile(filePath) returns (string memory contents) {
            currentState = contents;
        } catch {
            currentState = "{}";
        }

        // Handle file may exist but be empty
        if (bytes(currentState).length == 0) {
            currentState = "{}";
        }

        vm.serializeJson(DEPLOYMENT_OBJECT_KEY, currentState);
        string memory updatedJson = vm.serializeAddress(DEPLOYMENT_OBJECT_KEY, key, value);
        vm.writeFile(filePath, updatedJson);
    }
}
