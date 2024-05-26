// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { BaseHandler } from "./BaseHandler.sol";
import { IHandler } from "../interfaces/IHandler.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";

/**
 * @title BaseSwapManager
 * @notice Abstract base contract for implementing swap managers.
 * @dev This contract provides common functionality for swap manager implementations and enforces
 * swap checks using the `swapChecks` modifier.
 */
abstract contract BaseSwapManager is BaseHandler {
    error InsufficientOutput();
    error InsufficientInput();

    /**
     * @notice Modifier to enforce swap checks, ensuring sufficient input and output token amounts.
     * @param _tokenIn The address of the input token.
     * @param _tokenOut The address of the output token.
     * @param _amountIn The amount of input tokens to swap.
     * @param _minOut The minimum amount of output tokens to receive.
     */
    modifier swapChecks(address _tokenIn, address _tokenOut, uint256 _amountIn, uint256 _minOut) {
        uint256 tokenInBalance = ERC20(_tokenIn).balanceOf(address(this));
        if (tokenInBalance < _amountIn) revert InsufficientInput();
        uint256 tokenOutBalanceBefore = ERC20(_tokenOut).balanceOf(address(this));
        _;
        uint256 tokenOutBalanceAfter = ERC20(_tokenOut).balanceOf(address(this));
        uint256 actualOut = tokenOutBalanceAfter - tokenOutBalanceBefore;
        if (actualOut < _minOut) revert InsufficientOutput();
    }
}
