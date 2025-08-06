// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import { MockToken } from "../src/MockToken.sol";
import { WETH9 } from "../src/WETH9.sol";
import "../src/UniswapV2Factory.sol";
import "../src/UniswapV2Router02.sol";
import "../src/UniswapV2Pair.sol";
import "../src/interfaces/IUniswapV2Pair.sol";
import "../src/libraries/UniswapV2Library.sol";

contract UniswapV2Test is Test {
    WETH9 public weth;
    MockToken public tokenA;
    MockToken public tokenB;
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    UniswapV2Pair public pair;

    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        // Set up test accounts
        owner = address(this);
        user1 = address(0x100); // Use non-precompiled contract address
        user2 = address(0x200);

        // Deploy WETH9
        weth = new WETH9();

        // Give test contract some ETH and deposit into WETH
        vm.deal(address(this), 1000 ether);
        weth.deposit{ value: 100 ether }();

        // Deploy Factory
        factory = new UniswapV2Factory(owner);

        // Deploy Router
        router = new UniswapV2Router02(address(factory), address(weth));

        // Deploy test tokens
        tokenA = new MockToken("Token A", "TKNA", 1000 ether);
        tokenB = new MockToken("Token B", "TKNB", 1000 ether);

        // Allocate tokens to test users
        tokenA.transfer(user1, 100 ether);
        tokenB.transfer(user1, 100 ether);
        weth.transfer(user1, 10 ether);

        // Give user1 some ETH for WETH interaction
        vm.deal(user1, 100 ether);
        tokenA.transfer(user2, 100 ether);
        tokenB.transfer(user2, 100 ether);
    }

    function testCreatePair() public {
        // Create trading pair
        address pairAddress = factory.createPair(address(tokenA), address(tokenB));
        assertTrue(pairAddress != address(0));

        // Verify trading pair address
        assertEq(factory.getPair(address(tokenA), address(tokenB)), pairAddress);
        assertEq(factory.getPair(address(tokenB), address(tokenA)), pairAddress);

        // Verify trading pair count
        assertEq(factory.allPairsLength(), 1);
    }

    function testAddLiquidity() public {
        // Approve Router
        tokenA.approve(address(router), 10 ether);
        tokenB.approve(address(router), 10 ether);

        // Add liquidity
        (uint256 amountA, uint256 amountB, uint256 liquidity) = router.addLiquidity(
            address(tokenA), address(tokenB), 10 ether, 10 ether, 9 ether, 9 ether, owner, block.timestamp + 300
        );

        assertEq(amountA, 10 ether);
        assertEq(amountB, 10 ether);
        assertTrue(liquidity > 0);

        // Verify LP token balance
        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        pair = UniswapV2Pair(pairAddress);
        assertTrue(pair.balanceOf(owner) > 0);
    }

    function testSwapExactTokensForTokens() public {
        // First add liquidity
        testAddLiquidity();

        // Switch to user1
        vm.startPrank(user1);

        // Approve Router
        tokenA.approve(address(router), 1 ether);

        // Set trading path
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        // Get balance before trading
        uint256 balanceBBefore = tokenB.balanceOf(user1);

        // Execute trade
        uint256[] memory amounts = router.swapExactTokensForTokens(1 ether, 0, path, user1, block.timestamp + 300);

        // Verify trading results
        assertTrue(amounts[1] > 0);
        assertEq(tokenB.balanceOf(user1), balanceBBefore + amounts[1]);

        vm.stopPrank();
    }

    function testRemoveLiquidity() public {
        // First add liquidity
        testAddLiquidity();

        address pairAddress = factory.getPair(address(tokenA), address(tokenB));
        pair = UniswapV2Pair(pairAddress);

        uint256 lpBalance = pair.balanceOf(owner);

        // Approve Router to use LP tokens
        pair.approve(address(router), lpBalance);

        // Get balance before removal
        uint256 balanceABefore = tokenA.balanceOf(owner);
        uint256 balanceBBefore = tokenB.balanceOf(owner);

        // Remove liquidity
        (uint256 amountA, uint256 amountB) =
            router.removeLiquidity(address(tokenA), address(tokenB), lpBalance, 0, 0, owner, block.timestamp + 300);

        // Verify removal results
        assertTrue(amountA > 0);
        assertTrue(amountB > 0);
        assertEq(tokenA.balanceOf(owner), balanceABefore + amountA);
        assertEq(tokenB.balanceOf(owner), balanceBBefore + amountB);
        assertEq(pair.balanceOf(owner), 0);
    }

    function testGetAmountsOut() public {
        // First add liquidity
        testAddLiquidity();

        // Set path
        address[] memory path = new address[](2);
        path[0] = address(tokenA);
        path[1] = address(tokenB);

        // Get expected output
        uint256[] memory amounts = router.getAmountsOut(1 ether, path);

        // Verify results
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 1 ether);
        assertTrue(amounts[1] > 0);
        assertTrue(amounts[1] < 1 ether); // Due to fees, output should be less than input
    }

    function testFactorySetFeeTo() public {
        // Set fee recipient address
        address feeTo = address(0x123);
        factory.setFeeTo(feeTo);
        assertEq(factory.feeTo(), feeTo);

        // Only feeToSetter can set
        vm.prank(user1);
        vm.expectRevert("UniswapV2: FORBIDDEN");
        factory.setFeeTo(address(0x456));
    }

    function testPairCodeHashDynamic() public {
        // Get dynamic pairCodeHash
        bytes32 dynamicHash = factory.pairCodeHash();

        // Verify hash is not zero
        assertTrue(dynamicHash != bytes32(0));

        // Verify hash is the hash of UniswapV2Pair creation code
        bytes32 expectedHash = keccak256(type(UniswapV2Pair).creationCode);
        assertEq(dynamicHash, expectedHash);

        // Verify pairFor uses dynamic hash to correctly calculate address
        address predictedPair = factory.getPair(address(tokenA), address(tokenB));
        if (predictedPair == address(0)) {
            // If pair doesn't exist, create it first
            factory.createPair(address(tokenA), address(tokenB));
            predictedPair = factory.getPair(address(tokenA), address(tokenB));
        }

        // Verify calculated address from pairFor matches actually created address
        address calculatedPair = UniswapV2Library.pairFor(address(factory), address(tokenA), address(tokenB));
        assertEq(calculatedPair, predictedPair);
    }

    function testWETH9Functionality() public {
        // Test basic WETH9 functionality
        uint256 depositAmount = 5 ether;

        vm.startPrank(user1);

        // Check initial balance
        uint256 initialETHBalance = user1.balance;
        uint256 initialWETHBalance = weth.balanceOf(user1);

        // Deposit ETH to get WETH
        weth.deposit{ value: depositAmount }();

        // Verify balance after deposit
        assertEq(user1.balance, initialETHBalance - depositAmount);
        assertEq(weth.balanceOf(user1), initialWETHBalance + depositAmount);

        // Withdraw some WETH to get ETH
        uint256 withdrawAmount = 2 ether;
        weth.withdraw(withdrawAmount);

        // Verify balance after withdrawal
        assertEq(user1.balance, initialETHBalance - depositAmount + withdrawAmount);
        assertEq(weth.balanceOf(user1), initialWETHBalance + depositAmount - withdrawAmount);

        vm.stopPrank();
    }

    function testSwapETHForTokens() public {
        // First add TokenA/WETH liquidity
        tokenA.approve(address(router), 10 ether);
        weth.approve(address(router), 10 ether);

        router.addLiquidity(
            address(tokenA), address(weth), 10 ether, 10 ether, 10 ether, 10 ether, owner, block.timestamp + 300
        );

        vm.startPrank(user1);

        // Set trading path: ETH -> WETH -> TokenA
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = address(tokenA);

        // Get balance before trading
        uint256 balanceTokenABefore = tokenA.balanceOf(user1);
        uint256 swapAmount = 1 ether;

        // Execute ETH -> Token trade
        router.swapExactETHForTokens{ value: swapAmount }(0, path, user1, block.timestamp + 300);

        // Verify trading results
        assertTrue(tokenA.balanceOf(user1) > balanceTokenABefore);

        vm.stopPrank();
    }
}
