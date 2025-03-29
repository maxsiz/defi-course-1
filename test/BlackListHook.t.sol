// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {IHooks} from "v4-core/src/interfaces/IHooks.sol";
import {Hooks} from "v4-core/src/libraries/Hooks.sol";
import {TickMath} from "v4-core/src/libraries/TickMath.sol";
import {IPoolManager} from "v4-core/src/interfaces/IPoolManager.sol";
import {PoolKey} from "v4-core/src/types/PoolKey.sol";
import {BalanceDelta} from "v4-core/src/types/BalanceDelta.sol";
import {PoolId, PoolIdLibrary} from "v4-core/src/types/PoolId.sol";
import {CurrencyLibrary, Currency} from "v4-core/src/types/Currency.sol";
import {PoolSwapTest} from "v4-core/src/test/PoolSwapTest.sol";
import {BlackListHook} from "../src/BlackListHook.sol";
import {StateLibrary} from "v4-core/src/libraries/StateLibrary.sol";

import {LiquidityAmounts} from "v4-core/test/utils/LiquidityAmounts.sol";
import {IPositionManager} from "v4-periphery/src/interfaces/IPositionManager.sol";
import {EasyPosm} from "./utils/EasyPosm.sol";
import {Fixtures} from "./utils/Fixtures.sol";

// Transform test, step 0
import {PoolSwapTestWithSender} from "./utils/PoolSwapTestWithSender.sol";
import {IERC20Minimal} from "v4-core/src/interfaces/external/IERC20Minimal.sol";

contract BlackListHookTest is Test, Fixtures {
    using EasyPosm for IPositionManager;
    using PoolIdLibrary for PoolKey;
    using CurrencyLibrary for Currency;
    using StateLibrary for IPoolManager;

    BlackListHook hook;
    PoolId poolId;

    // Transform test, step 1
    PoolSwapTestWithSender swapRouterWithSender;

    uint256 tokenId;
    int24 tickLower;
    int24 tickUpper;

    function setUp() public {
        // creates the pool manager, utility routers, and test tokens
        deployFreshManagerAndRouters();
        deployMintAndApprove2Currencies();

        deployAndApprovePosm(manager);

        // Transform test, step 2
        //////////////////////////////////////////////// 
        ///// Deploy new router  for test with msgSender
        //////////////////////////////////////////////// 
        swapRouterWithSender = new PoolSwapTestWithSender(manager);
        IERC20Minimal(Currency.unwrap(currency0)).approve(
            address(swapRouterWithSender), 
            type(uint256).max
        );

        IERC20Minimal(Currency.unwrap(currency1)).approve(
            address(swapRouterWithSender), 
            type(uint256).max
        );
        ////////////////////////////////////////////////////////

        // Deploy the hook to an address with the correct flags
        address flags = address(
            uint160(
                Hooks.BEFORE_SWAP_FLAG 
            ) ^ (0x4444 << 144) // Namespace the hook to avoid collisions
        );
        bytes memory constructorArgs = abi.encode(manager, swapRouterWithSender, address(this)); //Add all the necessary constructor arguments from the hook
        deployCodeTo("BlackListHook.sol:BlackListHook", constructorArgs, flags);
        hook = BlackListHook(flags);

        // Create the pool
        key = PoolKey(currency0, currency1, 3000, 60, IHooks(hook));
        poolId = key.toId();
        manager.initialize(key, SQRT_PRICE_1_1);

        // Provide full-range liquidity to the pool
        tickLower = TickMath.minUsableTick(key.tickSpacing);
        tickUpper = TickMath.maxUsableTick(key.tickSpacing);

        uint128 liquidityAmount = 100e18;

        (uint256 amount0Expected, uint256 amount1Expected) = LiquidityAmounts.getAmountsForLiquidity(
            SQRT_PRICE_1_1,
            TickMath.getSqrtPriceAtTick(tickLower),
            TickMath.getSqrtPriceAtTick(tickUpper),
            liquidityAmount
        );

        (tokenId,) = posm.mint(
            key,
            tickLower,
            tickUpper,
            liquidityAmount,
            amount0Expected + 1,
            amount1Expected + 1,
            address(this),
            block.timestamp,
            ZERO_BYTES
        );
    }

    function testBlackListHook_swapOk() public {
        // positions were created in setup()

        // Perform a test swap //
        bool zeroForOne = true;
        int256 amountSpecified = -1e18; // negative number indicates exact input swap!
        BalanceDelta swapDelta = swap2(key, zeroForOne, amountSpecified, abi.encode(address(this)));
        // ------------------- //
        assertEq(int256(swapDelta.amount0()), amountSpecified);
    }

    function testBlackListHook_swapFail() public {
        // positions were created in setup()

        // Perform a test swap //
        bool zeroForOne = true;
        int256 amountSpecified = -1e18; // negative number indicates exact input swap!
        hook.setBlackListStatusForAddress(poolId, address(this), true);
        vm.expectRevert();
        BalanceDelta swapDelta = swap2(key, zeroForOne, amountSpecified, abi.encode(address(this)));
        // ------------------- //

    }

    // Transform test, step 4
    /// @notice Helper function for a simple ERC20 swaps that allows for unlimited price impact
    function swap2(PoolKey memory _key, bool zeroForOne, int256 amountSpecified, bytes memory hookData)
        internal
        returns (BalanceDelta)
    {
        // allow native input for exact-input, guide users to the `swapNativeInput` function
        bool isNativeInput = zeroForOne && _key.currency0.isAddressZero();
        if (isNativeInput) require(0 > amountSpecified, "Use swapNativeInput() for native-token exact-output swaps");

        uint256 value = isNativeInput ? uint256(-amountSpecified) : 0;

        return swapRouterWithSender.swap{value: value}(
            _key,
            IPoolManager.SwapParams({
                zeroForOne: zeroForOne,
                amountSpecified: amountSpecified,
                sqrtPriceLimitX96: zeroForOne ? MIN_PRICE_LIMIT : MAX_PRICE_LIMIT
            }),
            PoolSwapTestWithSender.TestSettings({takeClaims: false, settleUsingBurn: false}),
            hookData
        );
    }

}
