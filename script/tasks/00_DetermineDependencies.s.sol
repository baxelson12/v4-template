// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {AddressConstants} from "hookmate/constants/AddressConstants.sol";
import {Stateful} from "../mixins/Stateful.sol";

/// @dev Determines dependency addresses and writes to json.  Reverts if chain is not known.
///       This simply automates creating your own deployments.json in the respective
///       inputs/{chainid}/ folder and could be skipped if deployments.json already exists.
contract DetermineDependenciesScript is Stateful {
    /// @dev Composed/orchestrator contract entrypoint
    function run() public {
        _writeState(
            AddressConstants.getPermit2Address(),
            AddressConstants.getPoolManagerAddress(block.chainid),
            AddressConstants.getPositionManagerAddress(block.chainid),
            AddressConstants.getV4SwapRouterAddress(block.chainid),
            _getDeployer()
        );
    }

    /// @dev CLI entrypoint
    function run(address permit2, address poolManager, address positionManager, address swapRouter, address deployer)
        public
    {
        _writeState(permit2, poolManager, positionManager, swapRouter, deployer);
    }

    /// @dev Core logic
    function _writeState(
        address permit2,
        address poolManager,
        address positionManager,
        address swapRouter,
        address deployer
    ) private {
        _writeAndLabelAddress("permit2", permit2);
        _writeAndLabelAddress("poolManager", poolManager);
        _writeAndLabelAddress("positionManager", positionManager);
        _writeAndLabelAddress("swapRouter", swapRouter);
        _writeAndLabelAddress("deployer", deployer);
    }
    /// @dev Helper, writes state and labels address in one go

    function _writeAndLabelAddress(string memory key, address value) private {
        writeStateAddress(key, value);
        vm.label(value, key);
    }
    /// @dev Gets the deployer address from the vm's broadcast context

    function _getDeployer() private view returns (address) {
        return msg.sender;
    }
}
