// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/UniswapV2Suite.sol";

contract UniswapV2SuiteTest is Test {
    UniswapV2Suite public suite;
    address public user;

    function setUp() public {
        suite = new UniswapV2Suite();
        user = address(0x123);

        // Give test accounts some ETH
        vm.deal(address(this), 100 ether);
        vm.deal(user, 100 ether);
    }

    function testDeployDEX() public {
        uint256 ethAmount = 10 ether;
        uint256 tokenSupply = 1000 ether;

        // Deploy DEX
        suite.deployDEX{ value: ethAmount }(ethAmount, tokenSupply);

        // Verify deployment
        UniswapV2Suite.DEXInfo memory info = suite.getDEXInfo();
        assertTrue(info.factory != address(0));
        assertTrue(info.router != address(0));
        assertTrue(info.weth != address(0));
        assertTrue(info.tokenA != address(0));
        assertTrue(info.tokenB != address(0));
        assertTrue(info.tokenC != address(0));
        assertEq(info.deployer, address(this));

        // Verify WETH balance
        WETH9 weth = WETH9(payable(info.weth));
        assertEq(weth.balanceOf(address(suite)), ethAmount);

        // Verify token supplies
        MockToken tokenA = MockToken(info.tokenA);
        MockToken tokenB = MockToken(info.tokenB);
        MockToken tokenC = MockToken(info.tokenC);

        assertEq(tokenA.totalSupply(), tokenSupply);
        assertEq(tokenB.totalSupply(), tokenSupply);
        assertEq(tokenC.totalSupply(), tokenSupply);
        assertEq(tokenA.balanceOf(address(suite)), tokenSupply);
        assertEq(tokenB.balanceOf(address(suite)), tokenSupply);
        assertEq(tokenC.balanceOf(address(suite)), tokenSupply);
    }

    function testCannotDeployTwice() public {
        suite.deployDEX{ value: 1 ether }(1 ether, 1000 ether);

        // Should revert when trying to deploy again
        vm.expectRevert("DEX already deployed");
        suite.deployDEX{ value: 1 ether }(1 ether, 1000 ether);
    }

    function testAddInitialLiquidity() public {
        // First deploy DEX
        suite.deployDEX{ value: 10 ether }(5 ether, 1000 ether);

        // Add initial liquidity
        uint256 amountA = 10 ether;
        uint256 amountB = 10 ether;
        uint256 amountETH = 1 ether;

        suite.addInitialLiquidity(amountA, amountB, amountETH);

        // Verify pairs were created
        (address pairAB, address pairAW, address pairBW, address pairAC) = suite.getTradingPairs();
        assertTrue(pairAB != address(0));
        assertTrue(pairAW != address(0));
        assertTrue(pairBW != address(0));
        assertTrue(pairAC != address(0));

        // Verify liquidity exists
        UniswapV2Pair pair = UniswapV2Pair(pairAB);
        assertTrue(pair.balanceOf(address(this)) > 0);
    }

    function testSwapTokens() public {
        // Deploy and setup liquidity
        suite.deployDEX{ value: 10 ether }(5 ether, 1000 ether);
        suite.addInitialLiquidity(10 ether, 10 ether, 1 ether);

        UniswapV2Suite.DEXInfo memory info = suite.getDEXInfo();
        MockToken tokenA = MockToken(info.tokenA);
        MockToken tokenB = MockToken(info.tokenB);

        // Mint tokens to user
        suite.mintTestTokens(address(tokenA), user, 5 ether);

        vm.startPrank(user);

        // Approve suite contract to spend tokens
        tokenA.approve(address(suite), 1 ether);

        // Get expected output
        uint256[] memory expectedAmounts = suite.getSwapAmountOut(address(tokenA), address(tokenB), 1 ether);
        assertTrue(expectedAmounts[1] > 0);

        // Perform swap
        uint256 balanceBefore = tokenB.balanceOf(user);
        uint256[] memory amounts = suite.swapTokens(
            address(tokenA),
            address(tokenB),
            1 ether,
            0, // No minimum for test
            user
        );

        // Verify swap results
        assertEq(amounts[0], 1 ether);
        assertTrue(amounts[1] > 0);
        assertEq(tokenB.balanceOf(user), balanceBefore + amounts[1]);

        vm.stopPrank();
    }

    function testSwapETHForTokens() public {
        // Deploy and setup liquidity
        suite.deployDEX{ value: 10 ether }(5 ether, 1000 ether);
        suite.addInitialLiquidity(10 ether, 10 ether, 1 ether);

        UniswapV2Suite.DEXInfo memory info = suite.getDEXInfo();
        MockToken tokenA = MockToken(info.tokenA);

        vm.startPrank(user);

        // Get expected output
        uint256[] memory expectedAmounts = suite.getSwapAmountOut(info.weth, address(tokenA), 1 ether);
        assertTrue(expectedAmounts[1] > 0);

        // Perform ETH to token swap
        uint256 balanceBefore = tokenA.balanceOf(user);
        uint256[] memory amounts = suite.swapETHForTokens{ value: 1 ether }(
            address(tokenA),
            0, // No minimum for test
            user
        );

        // Verify swap results
        assertEq(amounts[0], 1 ether);
        assertTrue(amounts[1] > 0);
        assertEq(tokenA.balanceOf(user), balanceBefore + amounts[1]);

        vm.stopPrank();
    }

    function testMintTestTokens() public {
        suite.deployDEX{ value: 1 ether }(1 ether, 1000 ether);

        UniswapV2Suite.DEXInfo memory info = suite.getDEXInfo();
        MockToken tokenA = MockToken(info.tokenA);

        uint256 balanceBefore = tokenA.balanceOf(user);
        suite.mintTestTokens(address(tokenA), user, 100 ether);
        assertEq(tokenA.balanceOf(user), balanceBefore + 100 ether);
    }

    function testCannotMintInvalidToken() public {
        suite.deployDEX{ value: 1 ether }(1 ether, 1000 ether);

        // Should revert for invalid token
        vm.expectRevert("Invalid token");
        suite.mintTestTokens(address(0x456), user, 100 ether);
    }

    function testEmergencyFunctions() public {
        suite.deployDEX{ value: 1 ether }(1 ether, 1000 ether);

        // Send some ETH to suite contract
        payable(address(suite)).transfer(1 ether);

        uint256 balanceBefore = address(this).balance;
        suite.withdrawETH();
        assertEq(address(this).balance, balanceBefore + 1 ether);

        // Test token withdrawal
        UniswapV2Suite.DEXInfo memory info = suite.getDEXInfo();
        MockToken tokenA = MockToken(info.tokenA);

        uint256 myBalanceBefore = tokenA.balanceOf(address(this));

        suite.withdrawToken(address(tokenA), 100 ether);
        assertEq(tokenA.balanceOf(address(this)), myBalanceBefore + 100 ether);
    }

    function testOnlyDeployerCanWithdraw() public {
        suite.deployDEX{ value: 1 ether }(1 ether, 1000 ether);

        vm.prank(user);
        vm.expectRevert("Only deployer");
        suite.withdrawETH();

        vm.prank(user);
        vm.expectRevert("Only deployer");
        suite.withdrawToken(address(0x123), 100);
    }

    function testGetSwapAmountOutBeforeDeployment() public view {
        // Should return zero amounts if DEX not deployed
        uint256[] memory amounts = suite.getSwapAmountOut(address(0x123), address(0x456), 1 ether);
        assertEq(amounts.length, 2);
        assertEq(amounts[0], 0);
        assertEq(amounts[1], 0);
    }

    function testGetTradingPairsBeforeDeployment() public view {
        // Should return zero addresses if DEX not deployed
        (address pairAB, address pairAW, address pairBW, address pairAC) = suite.getTradingPairs();
        assertEq(pairAB, address(0));
        assertEq(pairAW, address(0));
        assertEq(pairBW, address(0));
        assertEq(pairAC, address(0));
    }

    // Allow test contract to receive ETH
    receive() external payable { }
}
