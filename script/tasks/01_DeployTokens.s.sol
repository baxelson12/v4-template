// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IERC20} from "forge-std/interfaces/IERC20.sol";
import {MockERC20} from "solmate/src/test/utils/mocks/MockERC20.sol";
import {Stateful} from "../mixins/Stateful.sol";
import {TokenUtils} from "../utils/TokenUtils.sol";

/// @dev Deploy mock tokens for local testing
///   ...or simply update state for existing tokens
contract DeployTokensScript is Stateful {
    address public deployer = readStateAddress("deployer");

    /// @dev Composed/orchestrator contract entrypoint
    function run() public {
        require(deployer != address(0), "Deployer not found in state file.");

        vm.startBroadcast();
        // Using placeholder/mock tokens here
        IERC20 token0 = IERC20(address(new MockERC20("MockTokenA", "MOCKA", 18)));
        MockERC20(address(token0)).mint(deployer, 100 ether);
        IERC20 token1 = IERC20(address(new MockERC20("MockTokenB", "MOCKB", 18)));
        MockERC20(address(token0)).mint(deployer, 100 ether);
        vm.stopBroadcast();

        _writeAndLabel(token0, token1);
    }

    /// @dev CLI entrypoint
    function run(address token0, address token1) public {
        _writeAndLabel(IERC20(token0), IERC20(token1));
    }

    /// @dev Write and label addresses
    function _writeAndLabel(IERC20 token0, IERC20 token1) private {
        // This may change the ordering
        (token0, token1) = TokenUtils.sortTokens(token0, token1);

        writeStateAddress("token0", address(token0));
        writeStateAddress("token1", address(token1));

        // Try to get token symbol for better readability
        try token0.symbol() returns (string memory symbol) {
            vm.label(address(token0), string.concat("Token0 (", symbol, ")"));
        } catch {
            vm.label(address(token0), "Token0");
        }
        try token1.symbol() returns (string memory symbol) {
            vm.label(address(token1), string.concat("Token1 (", symbol, ")"));
        } catch {
            vm.label(address(token1), "Token1");
        }
    }
}
