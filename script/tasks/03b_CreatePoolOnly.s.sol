// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {IPoolManager} from "@uniswap/v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {PoolInputs} from "../types/Types.sol";
import {Stateful} from "../mixins/Stateful.sol";

/// @dev Creates pool only
contract CreatePoolOnlyScript is Stateful {
    IPoolManager public poolManager = IPoolManager(readStateAddress("poolManager"));
    Currency public currency0 = Currency.wrap(readStateAddress("token0"));
    Currency public currency1 = Currency.wrap(readStateAddress("token1"));
    IHooks public hooks = IHooks(readStateAddress("hooks"));

    /// @dev Shared entrypoint
    function run(PoolInputs memory poolInputs) public {
        require(address(poolManager) != address(0), "PoolManager address not found in state file.");
        require(Currency.unwrap(currency0) != Currency.unwrap(currency1), "Token addresses should not match.");
        require(
            uint160(Currency.unwrap(currency0)) < uint160(Currency.unwrap(currency1)),
            "Token addresses should be numerically sorted."
        );

        PoolKey memory poolKey = PoolKey(currency0, currency1, poolInputs.lpFee, poolInputs.tickSpacing, hooks);

        vm.broadcast();
        poolManager.initialize(poolKey, poolInputs.startingPrice);
    }
}
