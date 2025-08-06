// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./UniswapV2Factory.sol";
import "./UniswapV2Router02.sol";
import "./MockToken.sol";
import "./WETH9.sol";

/**
 * @title UniswapV2Suite
 * @dev Complete DEX deployment suite for one-click DEX deployment and convenient interactions
 * @author Uniswap V2 - Foundry Version
 */
contract UniswapV2Suite {
    // Deployed contracts
    UniswapV2Factory public factory;
    UniswapV2Router02 public router;
    WETH9 public weth;

    // Test tokens
    MockToken public tokenA;
    MockToken public tokenB;
    MockToken public tokenC;

    // Deployment info
    address public deployer;
    uint256 public deploymentTimestamp;

    // Events
    event DEXDeployed(
        address indexed factory, address indexed router, address indexed weth, address deployer, uint256 timestamp
    );

    event TokensDeployed(address indexed tokenA, address indexed tokenB, address indexed tokenC);

    event LiquidityAdded(
        address indexed tokenA, address indexed tokenB, uint256 amountA, uint256 amountB, uint256 liquidity
    );

    struct DEXInfo {
        address factory;
        address router;
        address weth;
        address tokenA;
        address tokenB;
        address tokenC;
        address deployer;
        uint256 timestamp;
    }

    constructor() {
        deployer = msg.sender;
        deploymentTimestamp = block.timestamp;
    }

    /**
     * @dev Deploy complete DEX with factory, router, WETH and test tokens
     * @param ethAmount Amount of ETH to deposit into WETH (in wei)
     * @param tokenSupply Initial supply for each test token
     */
    function deployDEX(uint256 ethAmount, uint256 tokenSupply) external payable {
        require(address(factory) == address(0), "DEX already deployed");
        require(msg.value >= ethAmount, "Insufficient ETH sent");

        // Deploy core contracts
        weth = new WETH9();
        factory = new UniswapV2Factory(msg.sender);
        router = new UniswapV2Router02(address(factory), address(weth));

        // Deploy test tokens
        tokenA = new MockToken("Test Token A", "TTA", tokenSupply);
        tokenB = new MockToken("Test Token B", "TTB", tokenSupply);
        tokenC = new MockToken("Test Token C", "TTC", tokenSupply);

        // Deposit ETH into WETH
        if (ethAmount > 0) {
            weth.deposit{ value: ethAmount }();
        }

        emit DEXDeployed(address(factory), address(router), address(weth), msg.sender, block.timestamp);

        emit TokensDeployed(address(tokenA), address(tokenB), address(tokenC));
    }

    /**
     * @dev Add liquidity for multiple trading pairs at once
     * @param amountA Amount of tokenA for each pair
     * @param amountB Amount of tokenB for pairs
     * @param amountETH Amount of ETH for ETH pairs
     */
    function addInitialLiquidity(uint256 amountA, uint256 amountB, uint256 amountETH) external {
        require(address(factory) != address(0), "DEX not deployed");
        require(amountA > 0 && amountB > 0, "Invalid amounts");

        _transferAndApprove(amountA, amountB, amountETH);
        _addLiquidityPairs(amountA, amountB, amountETH);
    }

    /**
     * @dev Internal function to transfer tokens and approve router
     */
    function _transferAndApprove(uint256 amountA, uint256 amountB, uint256 amountETH) internal {
        // Transfer tokens to this contract
        tokenA.transfer(address(this), amountA * 3); // For 3 pairs
        tokenB.transfer(address(this), amountB * 2); // For 2 pairs
        tokenC.transfer(address(this), amountA); // For 1 pair
        weth.transfer(address(this), amountETH * 2); // For 2 ETH pairs

        // Approve router
        tokenA.approve(address(router), type(uint256).max);
        tokenB.approve(address(router), type(uint256).max);
        tokenC.approve(address(router), type(uint256).max);
        weth.approve(address(router), type(uint256).max);
    }

    /**
     * @dev Internal function to add liquidity for all pairs
     */
    function _addLiquidityPairs(uint256 amountA, uint256 amountB, uint256 amountETH) internal {
        _addSingleLiquidity(address(tokenA), address(tokenB), amountA, amountB);
        _addSingleLiquidity(address(tokenA), address(weth), amountA, amountETH);
        _addSingleLiquidity(address(tokenB), address(weth), amountB, amountETH);
        _addSingleLiquidity(address(tokenA), address(tokenC), amountA, amountA);
    }

    /**
     * @dev Add liquidity for a single pair
     */
    function _addSingleLiquidity(address tokenX, address tokenY, uint256 amountX, uint256 amountY) internal {
        (uint256 amt1, uint256 amt2, uint256 liq) = router.addLiquidity(
            tokenX,
            tokenY,
            amountX,
            amountY,
            amountX * 95 / 100, // 5% slippage
            amountY * 95 / 100,
            msg.sender,
            block.timestamp + 300
        );
        emit LiquidityAdded(tokenX, tokenY, amt1, amt2, liq);
    }

    /**
     * @dev Get all deployment information
     */
    function getDEXInfo() external view returns (DEXInfo memory) {
        return DEXInfo({
            factory: address(factory),
            router: address(router),
            weth: address(weth),
            tokenA: address(tokenA),
            tokenB: address(tokenB),
            tokenC: address(tokenC),
            deployer: deployer,
            timestamp: deploymentTimestamp
        });
    }

    /**
     * @dev Get trading pair addresses
     */
    function getTradingPairs()
        external
        view
        returns (
            address pairAB,
            address pairAW, // A/WETH
            address pairBW, // B/WETH
            address pairAC // A/C
        )
    {
        if (address(factory) == address(0)) return (address(0), address(0), address(0), address(0));

        pairAB = factory.getPair(address(tokenA), address(tokenB));
        pairAW = factory.getPair(address(tokenA), address(weth));
        pairBW = factory.getPair(address(tokenB), address(weth));
        pairAC = factory.getPair(address(tokenA), address(tokenC));
    }

    /**
     * @dev Convenient function to perform a token swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Input amount
     * @param amountOutMin Minimum output amount
     * @param to Recipient address
     */
    function swapTokens(
        address tokenIn,
        address tokenOut,
        uint256 amountIn,
        uint256 amountOutMin,
        address to
    )
        external
        returns (uint256[] memory amounts)
    {
        require(address(router) != address(0), "DEX not deployed");

        // Transfer tokens from sender
        IERC20(tokenIn).transferFrom(msg.sender, address(this), amountIn);
        IERC20(tokenIn).approve(address(router), amountIn);

        // Create path
        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        // Execute swap
        amounts = router.swapExactTokensForTokens(amountIn, amountOutMin, path, to, block.timestamp + 300);
    }

    /**
     * @dev Convenient function to swap ETH for tokens
     * @param tokenOut Output token address
     * @param amountOutMin Minimum output amount
     * @param to Recipient address
     */
    function swapETHForTokens(
        address tokenOut,
        uint256 amountOutMin,
        address to
    )
        external
        payable
        returns (uint256[] memory amounts)
    {
        require(address(router) != address(0), "DEX not deployed");
        require(msg.value > 0, "No ETH sent");

        // Create path
        address[] memory path = new address[](2);
        path[0] = address(weth);
        path[1] = tokenOut;

        // Execute swap
        amounts = router.swapExactETHForTokens{ value: msg.value }(amountOutMin, path, to, block.timestamp + 300);
    }

    /**
     * @dev Get expected output amount for a swap
     * @param tokenIn Input token address
     * @param tokenOut Output token address
     * @param amountIn Input amount
     */
    function getSwapAmountOut(
        address tokenIn,
        address tokenOut,
        uint256 amountIn
    )
        external
        view
        returns (uint256[] memory amounts)
    {
        if (address(router) == address(0)) {
            amounts = new uint256[](2);
            return amounts;
        }

        address[] memory path = new address[](2);
        path[0] = tokenIn;
        path[1] = tokenOut;

        amounts = router.getAmountsOut(amountIn, path);
    }

    /**
     * @dev Mint test tokens to specified address (only for testing)
     * @param token Token to mint (must be one of the test tokens)
     * @param to Recipient address
     * @param amount Amount to mint
     */
    function mintTestTokens(address token, address to, uint256 amount) external {
        require(token == address(tokenA) || token == address(tokenB) || token == address(tokenC), "Invalid token");

        MockToken(token).mint(to, amount);
    }

    /**
     * @dev Emergency function to withdraw stuck ETH
     */
    function withdrawETH() external {
        require(msg.sender == deployer, "Only deployer");
        payable(deployer).transfer(address(this).balance);
    }

    /**
     * @dev Emergency function to withdraw stuck tokens
     */
    function withdrawToken(address token, uint256 amount) external {
        require(msg.sender == deployer, "Only deployer");
        IERC20(token).transfer(deployer, amount);
    }

    // Allow contract to receive ETH
    receive() external payable { }
}
