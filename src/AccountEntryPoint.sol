// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { IntentAccount } from "./IntentAccount.sol";

/**
 * @dev Contract for deploying and managing IntentAccount contracts deployed as beacon proxies.
 */
contract AccountEntryPoint is Ownable {
    /**
     * @param callData the method call to execute on this account.
     * @param signature sender-verified signature over the entire request, the EntryPoint address and the chain ID.
     */
    struct AccountOperation {
        bytes callData;
        bytes signature;
        uint256 callGasLimit;
    }

    event Execute(address account, AccountOperation op);
    event ExecuteOnAccountError(address account, bytes error, AccountOperation op);

    error OnlySelf();

    address public immutable beacon;
    address public implementation;
    mapping(uint256 => address) public proxies;
    mapping(address => bool) public isAccount;
    uint256 public proxiesCounter;

    /**
     * @dev Constructor that initializes the AccountFactory contract.
     */
    constructor() Ownable(msg.sender) {
        implementation = address(new IntentAccount());
        UpgradeableBeacon _beacon = new UpgradeableBeacon(implementation, address(this));
        beacon = address(_beacon);
        proxiesCounter = 1;
    }

    /**
     * @dev Deploys a specified number of proxies for the AccountManager contract.
     * @param owner the initial owner of the proxy
     */
    function deployAccount(address owner) external {
        proxies[proxiesCounter] = address(new BeaconProxy(beacon, ""));
        isAccount[proxies[proxiesCounter]] = true;
        IntentAccount(proxies[proxiesCounter++]).initialize(owner, address(this));
    }

    /**
     * execute a user intent
     * @param account into into the opInfo array
     * @param operation the userOp to execute
     */
    function executeOnAccount(address account, AccountOperation calldata operation) public onlyOwner returns (bool) {
        require(isAccount[account]);
        try this.callAccount(IntentAccount(account), operation) {
            emit Execute(account, operation);
            return true;
        } catch (bytes memory reason) {
            emit ExecuteOnAccountError(account, reason, operation);
            return false;
        }
    }

    /**
     * to call the account
     */
    function callAccount(IntentAccount account, AccountOperation calldata operation) external {
        if (msg.sender != address(this)) revert OnlySelf();
        if (operation.callData.length > 0) {
            account.execute{ gas: operation.callGasLimit }(operation.callData, operation.signature);
        }
    }

    /**
     * @dev Upgrades the implementation of the AccountManager contract.
     * @param _newImplementation The address of the new implementation contract.
     */
    function upgradeImplementation(address _newImplementation) external onlyOwner {
        UpgradeableBeacon(beacon).upgradeTo(_newImplementation);
        implementation = _newImplementation;
    }
}
