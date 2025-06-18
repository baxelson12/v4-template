// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {IPositionManager} from "@uniswap/v4-periphery/src/interfaces/IPositionManager.sol";
import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {StateLibrary} from "@uniswap/v4-core/src/libraries/StateLibrary.sol";
import {Stateful} from "../mixins/Stateful.sol";
import {ParameterBuilder} from "../mixins/ParameterBuilder.sol";
import {CalldataEncoder} from "../mixins/CalldataEncoder.sol";
import {TokenApprover} from "../mixins/TokenApprover.sol";
import {PoolInputs, PositionInputs} from "../types/Types.sol";

/// @dev Adds liquidity only
contract AddLiquidityOnlyScript is Stateful, ParameterBuilder, CalldataEncoder, TokenApprover {
    using StateLibrary for IPoolManager;

    IPermit2 public permit2 = IPermit2(readStateAddress("permit2"));
    IPoolManager poolManager = IPoolManager(readStateAddress("poolManager"));
    IPositionManager positionManager = IPositionManager(readStateAddress("positionManager"));
    address public deployer = readStateAddress("deployer");
    Currency public currency0 = Currency.wrap(readStateAddress("token0"));
    Currency public currency1 = Currency.wrap(readStateAddress("token1"));
    IHooks public hooks = IHooks(readStateAddress("hooks"));

    /// @dev Shared entrypoint
    function run(PoolInputs memory poolInputs, PositionInputs memory positionInputs) public {
        require(address(permit2) != address(0), "Permit2 address not found in state file.");
        require(address(poolManager) != address(0), "PoolManager address not found in state file.");
        require(address(positionManager) != address(0), "PositionManager address not found in state file.");
        require(deployer != address(0), "Deployer not found in state file.");
        require(Currency.unwrap(currency0) != Currency.unwrap(currency1), "Token addresses should not match.");
        require(
            uint160(Currency.unwrap(currency0)) < uint160(Currency.unwrap(currency1)),
            "Token addresses should be numerically sorted."
        );

        PoolKey memory poolKey = PoolKey(currency0, currency1, poolInputs.lpFee, poolInputs.tickSpacing, hooks);
        // Pool should already be deployed, deployed price takes priority
        (uint160 sqrtPriceX96,,,) = poolManager.getSlot0(poolKey.toId());
        poolInputs.startingPrice = sqrtPriceX96;

        (, uint128 liquidity, int24 tickLower, int24 tickUpper) =
            buildPositionParams(currency0, currency1, hooks, poolInputs, positionInputs);
        (bytes memory actions, bytes[] memory params) = encodeModifyLiquidityParams(
            poolKey,
            tickLower,
            tickUpper,
            liquidity,
            deployer,
            positionInputs.amount0Max,
            positionInputs.amount1Max,
            positionInputs.hookData
        );
        uint256 valueToPass = currency0.isAddressZero() ? positionInputs.amount0Max : 0;

        vm.startBroadcast();

        approveUnlimited(permit2, currency0, address(positionManager));
        approveUnlimited(permit2, currency1, address(positionManager));

        positionManager.modifyLiquidities{value: valueToPass}(abi.encode(actions, params), positionInputs.deadline);

        vm.stopBroadcast();
    }
}
