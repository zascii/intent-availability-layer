// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import { Test } from "forge-std/Test.sol";
import { console } from "forge-std/console.sol";
import { AccountEntryPoint } from "src/AccountEntryPoint.sol";
import { IntentAccount } from "src/IntentAccount.sol";
import { UniswapV3SwapHandler } from "src/handlers/UniswapV3SwapHandler.sol";
import { TransferHandler } from "src/handlers/TransferHandler.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

/**
 * @title AccountFactoryTest
 * @notice Contract for testing the functionalities of the AccountFactory contract.
 */
contract AccountFactoryTest is Test {
    AccountEntryPoint public factory;
    IntentAccount public accountImplementation;
    IntentAccount public proxy;
    TransferHandler public transferHandler;
    UniswapV3SwapHandler public swapHandler;
    ERC20 public usdc = ERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    address public usdcHolder = 0xAc4c0b5103652C588164ADD17eCE94325f71293B;
    address public spender;
    uint256 public spenderPk;
    address public anyone;
    uint256 forkId;
    uint256 amount = 100;
    bytes32 public constant TRANSFER_TYPEHASH =
        keccak256("Transfer(address token,address spender,address receiver,uint256 amount)");

    function setUp() public {
        createTestWallets();
        createMainnetFork();
        deployFactoryAndProxy();
        deployHandlersAndEnable();
        vm.prank(usdcHolder);
        usdc.transfer(spender, amount * 10);
        vm.prank(spender);
        usdc.approve(address(proxy), amount * 10);
    }

    function deployFactoryAndProxy() public {
        factory = new AccountEntryPoint();
        vm.prank(spender);
        factory.deployAccount(spender);
        proxy = IntentAccount(factory.proxies(1));
    }

    function deployHandlersAndEnable() public {
        transferHandler = new TransferHandler();
        swapHandler = new UniswapV3SwapHandler();
        vm.startPrank(spender);
        proxy.updateHandlerContract(transferHandler, true);
        proxy.updateHandlerContract(swapHandler, true);
        vm.stopPrank();
    }

    function test_sendTokensWithProxy() public {
        vm.startPrank(spender);
        proxy.send(usdc, anyone, amount);
        uint256 _anyoneBalance = usdc.balanceOf(anyone);
        assertEq(_anyoneBalance, amount);
        vm.stopPrank();
    }

    function test_approveSpenderforProxies() public {
        vm.startPrank(spender);
        proxy.approve(usdc, anyone, amount);
        uint256 _anyoneAllowance = usdc.allowance(address(proxy), anyone);
        assertEq(_anyoneAllowance, amount);
        vm.stopPrank();
    }

    function test_canSendTokensWithSignature() public {
        bytes32 _hash = getTypedDataHash();
        (uint8 _v, bytes32 _r, bytes32 _s) = vm.sign(spenderPk, _hash);

        AccountEntryPoint.AccountOperation memory op = AccountEntryPoint.AccountOperation({
            callData: abi.encode(address(transferHandler), getEncodedData()),
            signature: abi.encode(_v, _r, _s),
            callGasLimit: 1e18
        });
        bool res = factory.executeOnAccount(address(proxy), op);
        assert(res);
    }

    function getDataHash() internal view returns (bytes32) {
        return keccak256(abi.encode(TRANSFER_TYPEHASH, address(usdc), proxy.getOwner(), anyone, amount, proxy.nonce()));
    }

    function getEncodedData() internal view returns (bytes memory) {
        return abi.encode(address(usdc), anyone, amount);
    }

    function getTypedDataHash() public view returns (bytes32) {
        return keccak256(abi.encodePacked("\x19\x01", proxy.getDomainSeparator(), getDataHash()));
    }

    function createTestWallets() public {
        (spender, spenderPk) = makeAddrAndKey("spender");
        console.log("spender: ", spender);
        anyone = makeAddr("anyone");
    }

    function createMainnetFork() public {
        uint256 _forkBlock = 19731704;
        forkId = vm.createSelectFork(vm.rpcUrl("mainnet"), _forkBlock);
    }
}
