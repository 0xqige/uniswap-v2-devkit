// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import { MockToken } from "../src/MockToken.sol";
import { WETH9 } from "../src/WETH9.sol";
import { UniswapV2Factory } from "../src/UniswapV2Factory.sol";
import { UniswapV2Router02 } from "../src/UniswapV2Router02.sol";
import { UniswapV2Pair } from "../src/UniswapV2Pair.sol";

contract DeployScript is Script {
    function run() external {
        // Use Foundry's default sender
        vm.startBroadcast();

        address owner = msg.sender;

        // Deploy WETH9
        WETH9 weth = new WETH9();
        console.log("WETH9 deployed at:", address(weth));

        // Deploy Uniswap Factory
        UniswapV2Factory factory = new UniswapV2Factory(owner);
        console.log("Factory deployed at:", address(factory));

        // Deploy Router
        UniswapV2Router02 router = new UniswapV2Router02(address(factory), address(weth));
        console.log("Router deployed at:", address(router));

        // Deploy test tokens A and B
        MockToken tokenA = new MockToken("Token A", "TKNA", 10 ether);
        console.log("Token A deployed at:", address(tokenA));

        MockToken tokenB = new MockToken("Token B", "TKNB", 10 ether);
        console.log("Token B deployed at:", address(tokenB));

        // Deposit some ETH into WETH
        weth.deposit{ value: 5 ether }();
        console.log("Deposited 5 ETH to WETH9, balance:", weth.balanceOf(owner));

        // Approve Router to use tokens
        tokenA.approve(address(router), 2 ether);
        tokenB.approve(address(router), 2 ether);
        weth.approve(address(router), 2 ether);

        // Add TokenA/TokenB liquidity (will automatically create trading pair)
        router.addLiquidity(
            address(tokenA), address(tokenB), 1 ether, 1 ether, 1 ether, 1 ether, owner, block.timestamp + 300
        );

        // Add TokenA/WETH liquidity
        router.addLiquidity(
            address(tokenA), address(weth), 1 ether, 1 ether, 1 ether, 1 ether, owner, block.timestamp + 300
        );

        // Get trading pair addresses
        address pairAB = factory.getPair(address(tokenA), address(tokenB));
        address pairAWETH = factory.getPair(address(tokenA), address(weth));
        console.log("Pair (Token A, Token B) deployed at:", pairAB);
        console.log("Pair (Token A, WETH) deployed at:", pairAWETH);

        vm.stopBroadcast();

        // Output all contract addresses
        console.log("\n===== Deployed Contracts =====");
        console.log("WETH9:", address(weth));
        console.log("Factory:", address(factory));
        console.log("Router:", address(router));
        console.log("Token A:", address(tokenA));
        console.log("Token B:", address(tokenB));
        console.log("Pair (A/B):", pairAB);
        console.log("Pair (A/WETH):", pairAWETH);
        console.log("==============================\n");
    }
}
