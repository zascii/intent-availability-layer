// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

interface IHandler {
    function execute(bytes calldata _data, uint8 _v, bytes32 _r, bytes32 _s) external;
}
