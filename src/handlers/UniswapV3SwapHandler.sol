// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { BaseSwapManager } from "./BaseSwapManager.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";
import { ISwapRouter } from "../interfaces/uniswap/ISwapRouter.sol";
import { IUniswapV3Pool } from "../interfaces/uniswap/IUniswapV3Pool.sol";
import { IUniswapV3Factory } from "../interfaces/uniswap/IUniswapV3Factory.sol";
import { UNISWAP_SWAP_ROUTER, UNISWAP_FACTORY } from "../constants.sol";
import { AccountStorage } from "../AccountStorage.sol";

/**
 * @title UniswapV3SwapManager
 * @notice Uniswap V3 implementation of the BaseSwapManager for swapping tokens.
 * @dev This contract uses the Uniswap V3 router for performing token swaps.
 */
contract UniswapV3SwapHandler is BaseSwapManager, AccountStorage {
    using SafeTransferLib for ERC20;

    bytes32 public constant SWAP_TYPEHASH =
        keccak256("Swap(address tokenIn,address tokenOut,uint256 amountIn,uint256 minOut,uint256 deadline)");

    // STORAGE
    // ------------------------------------------------------------------------------------------

    /// @notice UniV3 router for calling swaps
    /// https://github.com/Uniswap/v3-periphery/blob/main/contracts/SwapRouter.sol
    ISwapRouter public constant uniV3Router = ISwapRouter(UNISWAP_SWAP_ROUTER);

    /// @notice UniV3 factory for discovering pools
    /// https://github.com/Uniswap/v3-core/blob/main/contracts/UniswapV3Factory.sol
    IUniswapV3Factory public constant uniV3factory = IUniswapV3Factory(UNISWAP_FACTORY);

    // EXTERNAL
    // ------------------------------------------------------------------------------------------

    function execute(bytes memory _data, uint8 _v, bytes32 _r, bytes32 _s) external override onlyDelegateCall {
        (address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _minOut, uint256 _deadline, bytes memory path)
        = abi.decode(_data, (address, address, uint256, uint256, uint256, bytes));

        address signatory = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _getStorage().DOMAIN_SEPARATOR,
                    keccak256(abi.encode(SWAP_TYPEHASH, _tokenIn, _tokenOut, _amountIn, _minOut, _deadline, getNonce()))
                )
            ),
            _v,
            _r,
            _s
        );

        require(_deadline < block.timestamp);
        require(signatory == owner() && signatory != address(0));
        require(!getUsedNonces()[getNonce()]);
        getUsedNonces()[_getStorage().nonce++] = true;
        _swap(_tokenIn, _tokenOut, _amountIn, _minOut, path);
    }

    /**
     * @notice Swaps tokens using the Uniswap V3 router.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountIn The amount of input tokens to swap.
     * @param _minOut The minimum amount of output tokens to receive.
     * @param path Encoded swap data (not used in this implementation).
     * @return _amountOut The actual amount of output tokens received.
     */
    function _swap(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _minOut, bytes memory path)
        internal
        onlyDelegateCall
        swapChecks(_tokenIn, _tokenOut, _amountIn, _minOut)
        returns (uint256 _amountOut)
    {
        _amountOut = _swapTokenExactInput(_tokenIn, _amountIn, _minOut, path);
    }

    // INTERNAL
    // ------------------------------------------------------------------------------------------

    /**
     * @notice Internal function to perform a token swap with exact input.
     * @param _tokenIn The address of the input token.
     * @param _amountIn The amount of input tokens to swap.
     * @param _minOut The minimum amount of output tokens to receive.
     * @param _path The encoded path for the swap.
     * @return _out The actual amount of output tokens received.
     */
    function _swapTokenExactInput(address _tokenIn, uint256 _amountIn, uint256 _minOut, bytes memory _path)
        internal
        returns (uint256 _out)
    {
        ISwapRouter.ExactInputParams memory params = ISwapRouter.ExactInputParams({
            path: _path,
            recipient: address(this),
            deadline: block.timestamp,
            amountIn: _amountIn,
            amountOutMinimum: _minOut
        });
        ERC20(_tokenIn).safeApprove(address(uniV3Router), _amountIn);
        return uniV3Router.exactInput(params);
    }
}
