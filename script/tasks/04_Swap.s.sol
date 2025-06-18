// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {PoolKey} from "@uniswap/v4-core/src/types/PoolKey.sol";
import {Currency} from "@uniswap/v4-core/src/types/Currency.sol";
import {IHooks} from "@uniswap/v4-core/src/interfaces/IHooks.sol";
import {IUniswapV4Router04} from "hookmate/interfaces/router/IUniswapV4Router04.sol";
import {IPermit2} from "permit2/src/interfaces/IPermit2.sol";
import {Stateful} from "../mixins/Stateful.sol";
import {TokenApprover} from "../mixins/TokenApprover.sol";
import {PoolInputs} from "../types/Types.sol";

/// @dev Swap tokens
contract SwapScript is Stateful, TokenApprover {
    IPermit2 public permit2 = IPermit2(readStateAddress("permit2"));
    IUniswapV4Router04 public router = IUniswapV4Router04(payable(readStateAddress("swapRouter")));
    address public deployer = readStateAddress("deployer");
    Currency public currency0 = Currency.wrap(readStateAddress("token0"));
    Currency public currency1 = Currency.wrap(readStateAddress("token1"));
    IHooks public hooks = IHooks(readStateAddress("hooks"));

    function run(
        PoolInputs memory poolInputs,
        uint256 amountIn,
        uint256 amountOutMin,
        uint256 deadline,
        bytes memory hookData
    ) public {
        require(address(permit2) != address(0), "Permit2 address not found in state file.");
        require(address(router) != address(0), "Router address not found in state file.");
        require(address(deployer) != address(0), "Deployer address not found in state file.");
        require(Currency.unwrap(currency0) != Currency.unwrap(currency1), "Token addresses should not match.");
        require(
            uint160(Currency.unwrap(currency0)) < uint160(Currency.unwrap(currency1)),
            "Token addresses should be numerically sorted."
        );

        PoolKey memory poolKey = PoolKey(currency0, currency1, poolInputs.lpFee, poolInputs.tickSpacing, hooks);

        vm.startBroadcast();

        approveUnlimited(permit2, currency0, address(router));
        router.swapExactTokensForTokens({
            amountIn: amountIn,
            amountOutMin: amountOutMin,
            zeroForOne: true,
            poolKey: poolKey,
            hookData: hookData,
            receiver: deployer,
            deadline: deadline
        });

        vm.stopBroadcast();
    }
}
