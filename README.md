# Uniswap V2 - Foundry Version

Complete implementation of Uniswap V2 protocol using Foundry framework for development and testing.

## Project Introduction

This is a complete copy of the original Uniswap V2 contracts with the following modifications:
1. All contracts upgraded to Solidity 0.8.13 version
2. Migrated from Hardhat to Foundry framework
3. Removed OpenZeppelin dependency, using custom MockToken implementation
4. Integrated official WETH9 contract for ETH/token swaps
5. Removed outdated UniswapV2Migrator and V1 interfaces (no longer needed)
6. Added UniswapV2Suite for one-click DEX deployment and testing
7. Includes complete deployment scripts and comprehensive test suite

## Contract Structure

- `UniswapV2Factory` - Factory contract for creating trading pairs
- `UniswapV2Router02` - Router contract providing trading interfaces
- `UniswapV2Pair` - Trading pair contract implementing AMM logic
- `UniswapV2ERC20` - LP token implementation
- `WETH9` - Official Wrapped ETH implementation supporting ETH/token swaps
- `MockToken` - Custom ERC20 implementation for testing

## Quick Start

### Install Dependencies

```bash
# Install Foundry (if not already installed)
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Project has no external dependencies, compile directly
```

### Compile Contracts

```bash
forge build
```

### Run Tests

```bash
# Run all tests
forge test

# Run verbose tests (show logs)
forge test -vvv

# Run specific test
forge test --match-test testAddLiquidity

# View gas report
forge test --gas-report
```

### Local Deployment

1. Start local node:
```bash
anvil
```

2. Deploy contracts in another terminal:
```bash
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast
```

### Testnet Deployment

```bash
# Deploy to Sepolia testnet (using default private key)
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# Deploy using specified private key
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Deploy to other networks, modify --rpc-url parameter accordingly
```

## Environment Variables Configuration

Create `.env` file:

```bash
# RPC URLs
MAINNET_RPC_URL=https://eth-mainnet.g.alchemy.com/v2/your-api-key
SEPOLIA_RPC_URL=https://eth-sepolia.g.alchemy.com/v2/your-api-key

# Private key (do not commit to version control!)
PRIVATE_KEY=your-private-key

# Etherscan API key (for contract verification)
ETHERSCAN_API_KEY=your-etherscan-api-key
```

## Interact with Contracts

Use Foundry's `cast` tool to interact with deployed contracts:

```bash
# Query trading pair address
cast call $FACTORY_ADDRESS "getPair(address,address)" $TOKEN_A $TOKEN_B --rpc-url http://localhost:8545

# Query balance
cast call $TOKEN_ADDRESS "balanceOf(address)" $YOUR_ADDRESS --rpc-url http://localhost:8545

# Execute transaction
cast send $ROUTER_ADDRESS "swapExactTokensForTokens(uint256,uint256,address[],address,uint256)" \
  1000000000000000000 0 "[0x...,0x...]" $YOUR_ADDRESS $DEADLINE \
  --private-key $PRIVATE_KEY --rpc-url http://localhost:8545
```

## ⚡ Technical Improvement - Dynamic initcode hash

This project implements an important improvement to the original Uniswap V2, solving address calculation issues caused by compilation environment differences:

### pairCodeHash() Function

We added the `pairCodeHash()` function to the `UniswapV2Factory` contract:

```solidity
function pairCodeHash() external pure returns (bytes32) {
    return keccak256(type(UniswapV2Pair).creationCode);
}
```

### Why is this improvement needed?

**Problem:** Original Uniswap V2 uses a hardcoded initcode hash to calculate trading pair addresses. However:
- Different compiler versions produce different bytecode
- Different compiler optimization settings change bytecode
- Compilation differences between test and production environments cause address calculation errors

**Solution:** 
- `UniswapV2Library.pairFor()` now dynamically fetches the actual initcode hash from the factory contract
- No need to manually update hardcoded hash values
- Ensures correct trading pair address calculation in any compilation environment

**Technical Details:**
- `pairFor()` function changed from `pure` to `view` (needs to call factory contract)
- Fully backward compatible, doesn't affect existing functionality
- All tests pass, including new dynamic hash verification tests

## 🔧 Custom MockToken Implementation

Project includes a complete ERC20 implementation without external dependencies:

### MockToken Features
- **Standard ERC20 functionality**: Complete implementation of transfer, approve, transferFrom
- **Test-friendly**: Includes `mint()` function for easy testing
- **Gas optimized**: Uses `unchecked` blocks to optimize gas consumption
- **Security**: Includes all necessary checks and events

### Why not use OpenZeppelin?
- **Reduce dependencies**: Simplify project structure, avoid version conflicts
- **Better control**: Full control over contract logic and gas optimization
- **Learning value**: Demonstrates complete ERC20 implementation

## 🌊 WETH9 Integration

Project integrates the official WETH9 contract, implementing true ETH/token swap functionality:

### WETH9 Features
- **Official implementation**: Uses the same WETH9 contract as Ethereum mainnet
- **ETH deposit/withdrawal**: Supports `deposit()` and `withdraw()` functions
- **Full compatibility**: Fully compatible with ERC20 standard
- **Router integration**: Supports `swapExactETHForTokens` and other ETH swap functions

### Deployment Configuration
- Automatically deploys WETH9 contract
- Pre-deposits 5 ETH for testing
- Creates TokenA/WETH and TokenB/WETH trading pairs
- Provides complete ETH swap functionality testing

## 🚀 UniswapV2Suite - One-Click DEX Deployment

The project includes `UniswapV2Suite.sol` in the `src/` directory for convenient one-click DEX deployment and interaction:

### Key Features
- **One-click deployment**: Deploy complete DEX (Factory + Router + WETH + Test Tokens) in single transaction
- **Auto liquidity setup**: Automatically create and populate multiple trading pairs
- **Convenient swaps**: Easy-to-use swap functions for testing and development
- **Test token minting**: Mint test tokens for development purposes
- **Emergency controls**: Withdraw functions for contract owner

### Usage Example

```solidity
// Deploy the suite contract
UniswapV2Suite suite = new UniswapV2Suite();

// Deploy complete DEX with 10 ETH and 1000 token supply
suite.deployDEX{value: 10 ether}(5 ether, 1000 ether);

// Add initial liquidity to 4 trading pairs
suite.addInitialLiquidity(10 ether, 10 ether, 1 ether);

// Get all contract addresses
UniswapV2Suite.DEXInfo memory info = suite.getDEXInfo();

// Perform swaps
suite.swapETHForTokens{value: 1 ether}(info.tokenA, 0, msg.sender);
```

### Available Functions

#### Deployment Functions
- `deployDEX(ethAmount, tokenSupply)` - Deploy complete DEX infrastructure
- `addInitialLiquidity(amountA, amountB, amountETH)` - Create and populate trading pairs

#### Swap Functions  
- `swapTokens(tokenIn, tokenOut, amountIn, amountOutMin, to)` - Token-to-token swaps
- `swapETHForTokens(tokenOut, amountOutMin, to)` - ETH-to-token swaps
- `getSwapAmountOut(tokenIn, tokenOut, amountIn)` - Get expected output amounts

#### Information Functions
- `getDEXInfo()` - Get all deployed contract addresses
- `getTradingPairs()` - Get trading pair addresses

#### Testing Functions
- `mintTestTokens(token, to, amount)` - Mint test tokens for development

### Trading Pairs Created
The suite contract automatically creates the following trading pairs:
1. **TokenA/TokenB** - Basic token-to-token pair
2. **TokenA/WETH** - Token-to-ETH pair  
3. **TokenB/WETH** - Another token-to-ETH pair
4. **TokenA/TokenC** - Additional token pair for complex routing

## Project Structure

```
.
├── src/                    # Contract source code
│   ├── interfaces/         # Interface definitions
│   ├── libraries/          # Library contracts
│   ├── UniswapV2Suite.sol # One-click DEX deployment suite
│   └── *.sol              # Main contracts
├── script/                 # Deployment scripts
│   └── Deploy.s.sol       # Main deployment script
├── test/                   # Test files
│   ├── UniswapV2.t.sol    # Main test suite
│   └── UniswapV2Suite.t.sol # Suite contract tests
├── lib/                    # External dependencies
└── foundry.toml           # Foundry configuration file
```

## Foundry Documentation

- [Foundry Book](https://book.getfoundry.sh/)
- [Forge Documentation](https://book.getfoundry.sh/forge/)
- [Cast Documentation](https://book.getfoundry.sh/cast/)
- [Anvil Documentation](https://book.getfoundry.sh/anvil/)

## License

MIT