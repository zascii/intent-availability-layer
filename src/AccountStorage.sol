// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Delegatecall } from "./libraries/Delegatecall.sol";
import { IHandler } from "./interfaces/IHandler.sol";

bytes32 constant STORAGE_SLOT = keccak256("IntentAccount.storage");

/// @title LibAccountStorage
/// @notice Library for some storage logic
library LibAccountStorage {
    function getStorage() internal pure returns (AccountStorage.AStorage storage _storage) {
        bytes32 slot = STORAGE_SLOT;

        assembly {
            _storage.slot := slot
        }
    }
}

/// @title AccountStorage
/// @notice Storage inheritance for Accounts
abstract contract AccountStorage {
    struct AStorage {
        uint256 DOMAIN_CHAIN_ID; // 1
        bytes32 DOMAIN_SEPARATOR; // 2
        uint256 nonce; // 3
        mapping(uint256 => bool) usedNonces; // 4
        mapping(IHandler => bool) handlerContracts; // 5
        address owner; // 6
    }

    /**
     * @dev Retrieves the storage struct of the contract.
     * @return _storage The storage struct containing all contract state variables.
     */
    function _getStorage() internal pure returns (AStorage storage _storage) {
        _storage = LibAccountStorage.getStorage();
    }

    function _updateOwner(address _newOwner) internal returns (address) {
        _getStorage().owner = _newOwner;
    }

    function owner() internal view returns (address _owner) {
        _owner = _getStorage().owner;
    }

    function getUsedNonces() internal returns (mapping(uint256 => bool) storage _usedNonces) {
        _usedNonces = _getStorage().usedNonces;
    }

    function getNonce() internal returns (uint256 _nonce) {
        _nonce = _getStorage().nonce;
    }
}
