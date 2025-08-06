// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/UniswapV2Suite.sol";

/**
 * @title DeployUtils Script
 * @dev Example script showing how to use UniswapV2Suite for one-click DEX deployment
 */
contract DeployUtilsScript is Script {
    function run() external {
        // Use Foundry's default sender
        vm.startBroadcast();

        console.log("Deploying UniswapV2Suite...");

        // Deploy the suite contract
        UniswapV2Suite suite = new UniswapV2Suite();
        console.log("UniswapV2Suite deployed at:", address(suite));

        // Deploy complete DEX infrastructure
        // - 5 ETH will be deposited into WETH
        // - Each test token will have 1000 ether supply
        uint256 ethForWETH = 5 ether;
        uint256 tokenSupply = 1000 ether;

        console.log("Deploying complete DEX infrastructure...");
        suite.deployDEX{ value: ethForWETH }(ethForWETH, tokenSupply);

        // Get deployment info
        UniswapV2Suite.DEXInfo memory info = suite.getDEXInfo();

        console.log("\n===== DEX Infrastructure Deployed =====");
        console.log("Factory:", info.factory);
        console.log("Router:", info.router);
        console.log("WETH:", info.weth);
        console.log("Token A:", info.tokenA);
        console.log("Token B:", info.tokenB);
        console.log("Token C:", info.tokenC);
        console.log("==========================================");

        // Add initial liquidity to all trading pairs
        console.log("\nAdding initial liquidity to trading pairs...");
        uint256 liquidityA = 50 ether; // 50 tokens per pair
        uint256 liquidityB = 50 ether; // 50 tokens per pair
        uint256 liquidityETH = 2 ether; // 2 ETH per ETH pair

        suite.addInitialLiquidity(liquidityA, liquidityB, liquidityETH);

        // Get trading pair addresses
        (address pairAB, address pairAW, address pairBW, address pairAC) = suite.getTradingPairs();

        console.log("\n===== Trading Pairs Created =====");
        console.log("TokenA/TokenB pair:", pairAB);
        console.log("TokenA/WETH pair:", pairAW);
        console.log("TokenB/WETH pair:", pairBW);
        console.log("TokenA/TokenC pair:", pairAC);
        console.log("==================================");

        // Demonstrate token minting for testing
        address testUser = 0x1234567890123456789012345678901234567890;
        console.log("\nMinting test tokens for user:", testUser);

        suite.mintTestTokens(info.tokenA, testUser, 100 ether);
        suite.mintTestTokens(info.tokenB, testUser, 100 ether);
        suite.mintTestTokens(info.tokenC, testUser, 100 ether);

        console.log("Minted 100 tokens of each type to test user");

        vm.stopBroadcast();

        console.log("\n=== Complete DEX deployed successfully! ===");
        console.log("You can now interact with the DEX using the UniswapV2Suite contract");
    }
}
