// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { IHandler } from "../interfaces/IHandler.sol";

/**
 * @title BaseHandler
 * @notice Abstract base contract for implementing handler contracts with a delegate call restriction.
 * @dev Any contract inheriting from this contract must implement the IHandlerContract interface.
 */
abstract contract BaseHandler is IHandler {
    address immutable SELF;

    error OnlyDelegateCall();

    constructor() {
        SELF = address(this);
    }

    function execute(bytes memory _data, uint8 _v, bytes32 _r, bytes32 _s) external virtual { }

    /**
     * @notice Modifier to restrict functions to be called only via delegate call.
     * @dev Reverts if the function is called directly (not via delegate call).
     */
    modifier onlyDelegateCall() {
        if (address(this) == SELF) {
            revert OnlyDelegateCall();
        }
        _;
    }
}
