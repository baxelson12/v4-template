// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {Math} from "@openzeppelin/contracts/utils/math/Math.sol";
import {DetermineDependenciesScript} from "../tasks/00_DetermineDependencies.s.sol";
import {DeployTokensScript} from "../tasks/01_DeployTokens.s.sol";
import {CreatePoolOnlyScript} from "../tasks/03b_CreatePoolOnly.s.sol";
import {PoolInputs} from "../types/Types.sol";

// Create a 7% ETH/USDC pool

/// @dev Example mixed task usage - Create a new ETH/USDC pool (mainnet)
contract MixedDeploymentScript is Script {
    // Pair
    address public constant USDC = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant ETH = address(0);

    PoolInputs poolInputs = PoolInputs({
        lpFee: 70_000, // 7% (not realistic)
        tickSpacing: 200,
        // Assume ETH is 2500.  Should be ~ correct
        startingPrice: uint160(Math.sqrt(2500) * 2 ** 96)
    });

    function run() public {
        // 00
        new DetermineDependenciesScript().run();
        // 01 -- Use cli entrypoint for pre-deployed addresses
        new DeployTokensScript().run(ETH, USDC);
        // 03b
        new CreatePoolOnlyScript().run(poolInputs);
    }
}
