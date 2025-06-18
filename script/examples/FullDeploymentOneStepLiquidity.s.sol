// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script} from "forge-std/Script.sol";
import {TickMath} from "@uniswap/v4-core/src/libraries/TickMath.sol";
import {PoolInputs, PositionInputs} from "../types/Types.sol";
import {DetermineDependenciesScript} from "../tasks/00_DetermineDependencies.s.sol";
import {DeployTokensScript} from "../tasks/01_DeployTokens.s.sol";
import {DeployHooksScript} from "../tasks/02_DeployHooks.s.sol";
import {CreatePoolAndAddLiquidityScript} from "../tasks/03a_CreatePoolAndAddLiquidity.s.sol";
import {SwapScript} from "../tasks/04_Swap.s.sol";

/// @dev Run e2e for create pool / add liquidity in one step
contract OneStepLiquidityScript is Script {
    /// Pool configuration
    PoolInputs poolInputs = PoolInputs({
        lpFee: 5000, // 0.5%
        tickSpacing: 100,
        startingPrice: 2 ** 96 // sqrtPriceX96; floor(sqrt(1) * 2^96)
    });

    /// Position configuration
    PositionInputs positionInputs = PositionInputs({
        token0Amount: 1 ether,
        token1Amount: 1 ether,
        // We're just creating a 50/50 position surrounding starting price
        tickLower: TickMath.getTickAtSqrtPrice(poolInputs.startingPrice) - 750,
        tickUpper: TickMath.getTickAtSqrtPrice(poolInputs.startingPrice) + 750,
        // Position slippage
        amount0Max: 1 ether + 1 wei,
        amount1Max: 1 ether + 1 wei,
        deadline: block.timestamp + 2500,
        hookData: new bytes(0)
    });

    function run() public {
        // 00
        new DetermineDependenciesScript().run();
        // 01
        new DeployTokensScript().run();
        // 02
        new DeployHooksScript().run();
        // 03a
        new CreatePoolAndAddLiquidityScript().run(poolInputs, positionInputs);
        // 04 -- amountOutMin set to zero -- NOT for use in prod!
        new SwapScript().run(poolInputs, 1 ether, 0, block.timestamp + 2500, positionInputs.hookData);
    }
}
