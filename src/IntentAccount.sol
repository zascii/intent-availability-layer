// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { EIP712Upgradeable } from "@openzeppelin-upgradable/contracts/utils/cryptography/EIP712Upgradeable.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin-upgradable/contracts/proxy/utils/Initializable.sol";
import { IHandler } from "./interfaces/IHandler.sol";
import { AccountStorage } from "./AccountStorage.sol";
import { Delegatecall } from "./libraries/Delegatecall.sol";

/**
 * @title AccountManagerV2 contract - implementation that will replace AccountManagerV1
 * @notice This contract is ownable by an EOA and can receive and send ERC20 tokens.
 */
contract IntentAccount is AccountStorage, Initializable, EIP712Upgradeable {
    using Delegatecall for address;
    using SafeERC20 for ERC20;

    error UnknownHandlerContract();

    /// @dev Emitted when a handler contract is updated.
    event HandlerContractUpdated(address indexed _contract, bool _enabled);
    event OwnerUpdated(address oldOwner, address newOwner);

    address public entryPoint;

    constructor() {
        _disableInitializers();
    }

    /**
     * @dev Initializes the AccountManager contract with the provided owner.
     * @param _owner The address that will own this contract.
     */
    function initialize(address _owner, address _entryPoint) public initializer {
        _getStorage().owner = _owner;
        entryPoint = _entryPoint;
        _getStorage().DOMAIN_SEPARATOR = _domainSeparatorV4();
        __EIP712_init("AccountManager", "2.0");
    }

    /**
     * @dev Sends ERC20 tokens from the contract owner to a specified recipient.
     * @param _token The ERC20 token to send.
     * @param _receiver The address to send the tokens to.
     * @param _amount The amount of tokens to send.
     */
    function send(ERC20 _token, address _receiver, uint256 _amount) external onlyOwner {
        _token.safeTransferFrom(owner(), _receiver, _amount);
    }

    /**
     * @dev Approves a specified address to spend a certain amount of ERC20 tokens.
     * @param _token The ERC20 token to approve spending for.
     * @param _spender The address allowed to spend the tokens.
     * @param _amount The amount of tokens to approve for spending.
     */
    function approve(ERC20 _token, address _spender, uint256 _amount) external onlyOwner {
        _token.safeIncreaseAllowance(_spender, _amount);
    }

    /**
     * @notice Executes a call to a handler contract.
     * @param data The handler contract to be called.
     * @param signature The data to be sent to the handler contract.
     * @return ret The returned data from the handler contract.
     */
    function execute(bytes memory data, bytes memory signature)
        public
        payable
        onlyEntryPointOrOwner
        returns (bytes memory ret)
    {
        (address handler, bytes memory subCalldata) = abi.decode(data, (address, bytes));
        (uint8 v, bytes32 r, bytes32 s) = abi.decode(signature, (uint8, bytes32, bytes32));
        bool isHandler = _getStorage().handlerContracts[IHandler(handler)];
        if (!isHandler) revert UnknownHandlerContract();

        handler.delegateCall(abi.encodeCall(IHandler.execute, (subCalldata, v, r, s)));
    }

    /**
     * @dev This function allows to the owner to manually increment the nonce to invalidate signatures that are already issued.
     */
    function invalidateNonce() external onlyOwner {
        getUsedNonces()[_getStorage().nonce++] = true;
    }

    /**
     * @notice Updates the handler contract and its associated callbacks.
     * @param _handler The handler contract to be updated.
     * @param _enabled Whether the handler should be enabled or disabled.
     */
    function updateHandlerContract(IHandler _handler, bool _enabled) external onlyOwner {
        _getStorage().handlerContracts[_handler] = _enabled;
        emit HandlerContractUpdated(address(_handler), _enabled);
    }

    function updateOwner(address _newOwner) external onlyOwner {
        emit OwnerUpdated(_getStorage().owner, _newOwner);
        _getStorage().owner = _newOwner;
    }

    function getDomainSeparator() external view returns (bytes32) {
        return _getStorage().DOMAIN_SEPARATOR;
    }

    function getOwner() external view returns (address) {
        return _getStorage().owner;
    }

    function nonce() external view returns (uint256) {
        return _getStorage().nonce;
    }

    modifier onlyOwner() {
        require(msg.sender == _getStorage().owner, "Not Owner");
        _;
    }

    modifier onlyEntryPointOrOwner() {
        require(msg.sender == _getStorage().owner || msg.sender == entryPoint, "Not Owner or Entry Point");
        _;
    }
}
