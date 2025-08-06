# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a modernized Uniswap V2 implementation using Foundry, upgraded from Hardhat with Solidity ^0.8.20. The project includes a complete AMM DEX with significant improvements over the original implementation.

## Development Commands

### Build and Test
```bash
# Build contracts
forge build

# Run all tests
forge test

# Run tests with verbose output
forge test -vvv

# Run specific test contract
forge test --match-contract UniswapV2Test
forge test --match-contract UniswapV2SuiteTest

# Run specific test function
forge test --match-test testAddLiquidity

# Gas reporting
forge test --gas-report

# Clean build artifacts
forge clean
```

### Deployment
```bash
# Local deployment (requires anvil running)
anvil  # In separate terminal
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast

# Testnet deployment
forge script script/Deploy.s.sol:DeployScript --rpc-url $SEPOLIA_RPC_URL --broadcast --verify

# One-click DEX deployment example
forge script script/DeployUtils.s.sol:DeployUtilsScript --rpc-url http://localhost:8545 --broadcast
```

### Code Formatting
```bash
# Format code (configured for 120 char lines, 4-space tabs)
forge fmt
```

## Core Architecture

### Key Technical Innovation: Dynamic InitCode Hash

**Critical**: This implementation fixes a major issue with the original Uniswap V2 hardcoded initcode hash:

- `UniswapV2Factory.pairCodeHash()` - Returns actual bytecode hash at runtime
- `UniswapV2Library.pairFor()` - Dynamically fetches hash instead of using hardcoded value
- This ensures correct pair address calculation across different compiler versions/settings

### Contract Hierarchy

1. **Core AMM Contracts**:
   - `UniswapV2Factory` - Creates and manages trading pairs
   - `UniswapV2Router02` - High-level trading interface with slippage protection
   - `UniswapV2Pair` - Individual trading pair implementing x*y=k AMM logic
   - `UniswapV2ERC20` - LP token implementation

2. **Supporting Contracts**:
   - `WETH9` - Official wrapped ETH implementation
   - `MockToken` - Custom ERC20 for testing (no OpenZeppelin dependency)

3. **UniswapV2Suite** - **Important**: One-click DEX deployment utility
   - Deploys entire DEX infrastructure in single transaction
   - Auto-creates 4 trading pairs (TokenA/TokenB, TokenA/WETH, TokenB/WETH, TokenA/TokenC)
   - Includes convenience functions for testing and development

### Library Architecture

- `UniswapV2Library` - Core AMM calculations and pair address computation
- `SafeMath` - Overflow protection (kept for compatibility despite Solidity ^0.8.20)
- `TransferHelper` - Safe ERC20 transfer utilities
- `Math` - Basic mathematical operations

### Key Data Flows

1. **Pair Creation**: Factory → generates deterministic address → deploys pair contract
2. **Trading**: Router → validates → calls pair.swap() → updates reserves
3. **Liquidity**: Router → adds to both tokens → mints LP tokens → transfers to user

## Important Implementation Details

### Address Calculation
The `pairFor()` function in UniswapV2Library **must** remain `view` (not `pure`) because it calls `factory.pairCodeHash()`. This is intentional and resolves compilation environment dependencies.

### Test Structure
- `test/UniswapV2.t.sol` - Core AMM functionality tests
- `test/UniswapV2Suite.t.sol` - One-click deployment suite tests
- All tests use Foundry's testing framework with 20 comprehensive test cases

### Environment Configuration
Required environment variables in `.env`:
- `MAINNET_RPC_URL` / `SEPOLIA_RPC_URL` - Network endpoints
- `PRIVATE_KEY` - Deployment key
- `ETHERSCAN_API_KEY` - Contract verification

### Contract Versions
All contracts use `pragma solidity ^0.8.20` for latest optimizations while maintaining compatibility.

## Development Patterns

### When Adding New Features
1. Always test with both individual contracts and UniswapV2Suite
2. Consider impact on pair address calculation if modifying Factory
3. Use MockToken for testing rather than external dependencies

### Deployment Strategy
- Use `Deploy.s.sol` for individual contract deployment
- Use `DeployUtils.s.sol` for complete DEX setup with initial liquidity
- UniswapV2Suite is production-ready and located in `src/` directory

### Testing Philosophy
The codebase maintains comprehensive test coverage focusing on:
- Core AMM mechanics (reserves, pricing, slippage)
- Edge cases (zero liquidity, invalid tokens, access control)
- Integration between all components
- Gas optimization verification