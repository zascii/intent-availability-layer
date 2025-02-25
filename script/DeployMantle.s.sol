// SPDX-License-Identifier: MIT
pragma solidity ^0.8.25;

import { Script } from "forge-std/Script.sol";
import { AccountEntryPoint } from "src/AccountEntryPoint.sol";
import { IntentAccount } from "src/IntentAccount.sol";
import { TransferHandler } from "src/handlers/TransferHandler.sol";
import { UniswapV3SwapHandler } from "src/handlers/UniswapV3SwapHandler.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DeployMantle is Script {
    AccountEntryPoint public factory;
    TransferHandler public transferHandler;
    UniswapV3SwapHandler public swapHandler;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mantle"));
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);
        factory = new AccountEntryPoint();
        transferHandler = new TransferHandler();
        swapHandler = new UniswapV3SwapHandler();
        vm.stopBroadcast();
    }
}
