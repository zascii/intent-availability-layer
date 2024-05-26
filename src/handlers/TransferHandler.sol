// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { BaseHandler } from "./BaseHandler.sol";
import { AccountStorage } from "../AccountStorage.sol";
import { ERC20 } from "solmate/tokens/ERC20.sol";
import { SafeTransferLib } from "solmate/utils/SafeTransferLib.sol";

contract TransferHandler is AccountStorage, BaseHandler {
    using SafeTransferLib for ERC20;

    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256("Transfer(address token,address spender,address receiver,uint256 amount)");

    /**
     * @dev Executes a transfer of ERC20 tokens using a signed message.
     * @param _data Transfer packed data.
     * @param _v The recovery id of the signature.
     * @param _r The R component of the signature.
     * @param _s The S component of the signature.
     */
    function execute(bytes memory _data, uint8 _v, bytes32 _r, bytes32 _s) external override onlyDelegateCall {
        (address _token, address _receiver, uint256 _amount) = abi.decode(_data, (address, address, uint256));
        require(_verifySignature(_token, _receiver, _amount, _v, _r, _s), "Signature Invalid");
        getUsedNonces()[_getStorage().nonce++] = true;
        ERC20(_token).safeTransferFrom(owner(), _receiver, _amount);
    }

    function _verifySignature(address _token, address _receiver, uint256 _amount, uint8 _v, bytes32 _r, bytes32 _s)
        internal
        returns (bool)
    {
        address signatory = ecrecover(
            keccak256(
                abi.encodePacked(
                    "\x19\x01",
                    _getStorage().DOMAIN_SEPARATOR,
                    keccak256(abi.encode(TRANSFER_TYPEHASH, _token, owner(), _receiver, _amount, _getStorage().nonce))
                )
            ),
            _v,
            _r,
            _s
        );

        if (getUsedNonces()[_getStorage().nonce]) {
            return false;
        }
        if (signatory == owner() && signatory != address(0)) {
            return true;
        } else {
            return false;
        }
    }
}
