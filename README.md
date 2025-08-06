# Uniswap V2 DevKit 🚀

**The Complete Development Toolkit for Uniswap V2 Protocol**

Build, test, and deploy Uniswap V2-based decentralized exchanges with confidence. This comprehensive DevKit provides everything you need to develop DeFi applications on the battle-tested Uniswap V2 AMM protocol.

[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE) 
[![Foundry](https://img.shields.io/badge/Built%20with-Foundry-FFDB1C.svg)](https://getfoundry.sh/) 
[![Solidity](https://img.shields.io/badge/Solidity-^0.8.20-363636.svg)](https://solidity.readthedocs.io/)

## What is Uniswap V2 DevKit?

**Uniswap V2 DevKit** is a complete development toolkit that provides:

✅ **Production-ready contracts**: Full Uniswap V2 protocol implementation  
✅ **One-click deployment**: Deploy entire DEX infrastructure in seconds  
✅ **Comprehensive testing**: 20+ test cases covering all functionality  
✅ **Developer-friendly**: Modern Foundry toolchain with zero external dependencies  
✅ **Educational resources**: Learn AMM mechanics with detailed documentation  
✅ **International support**: Full English documentation for global developers  

Perfect for **DeFi developers**, **protocol researchers**, **educational institutions**, and **teams building AMM-based applications**.

## 🎯 Key Features & Improvements

### 🏗️ DevKit Components
- **UniswapV2Suite**: One-click DEX deployment with automated liquidity setup
- **Complete Protocol**: Factory, Router, Pair contracts with all AMM functionality
- **WETH9 Integration**: Native ETH/token swapping capabilities  
- **Testing Suite**: 20+ comprehensive tests covering edge cases
- **MockToken**: Custom ERC20 implementation optimized for testing

### ⚡ Technical Improvements
- **Solidity ^0.8.20**: Latest compiler features and optimizations
- **Foundry Framework**: Fast, modern development environment
- **Zero Dependencies**: No external libraries, fully self-contained
- **Dynamic InitCode**: Solves compilation environment address calculation issues
- **Gas Optimized**: Efficient implementations for lower transaction costs

### 🌍 Developer Experience
- **International Ready**: Complete English documentation
- **Educational**: Detailed explanations of AMM mechanics
- **Production Ready**: Battle-tested contracts suitable for mainnet
- **Easy Integration**: Simple APIs for rapid prototyping

## Contract Structure

- `UniswapV2Factory` - Factory contract for creating trading pairs
- `UniswapV2Router02` - Router contract providing trading interfaces
- `UniswapV2Pair` - Trading pair contract implementing AMM logic
- `UniswapV2ERC20` - LP token implementation
- `WETH9` - Official Wrapped ETH implementation supporting ETH/token swaps
- `MockToken` - Custom ERC20 implementation for testing

## 🚀 Quick Start - Deploy Your DEX in 3 Steps

### Step 1: Setup Environment

```bash
# Install Foundry framework
curl -L https://foundry.paradigm.xyz | bash
foundryup

# Clone the DevKit
git clone https://github.com/0xqige/uniswap-v2-devkit.git
cd uniswap-v2-devkit

# Compile contracts (zero dependencies!)
forge build
```

### Step 2: Test Everything Works

```bash
# Run comprehensive test suite (20+ tests)
forge test

# View detailed gas reports
forge test --gas-report

# Run with verbose logging
forge test -vvv
```

### Step 3: Deploy Your DEX

#### Option A: One-Click Deployment (Recommended)
```bash
# Deploy complete DEX infrastructure in seconds
forge script script/DeployUtils.s.sol --rpc-url $RPC_URL --broadcast
```

#### Option B: Manual Deployment
```bash
# Deploy individual contracts
forge script script/Deploy.s.sol --rpc-url $RPC_URL --broadcast
```

## 🌐 Network Deployment Options

### Local Development
```bash
# Start local Anvil node
anvil

# Deploy to local network (new terminal)
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --broadcast
```

### Testnet Deployment
```bash
# Deploy to Sepolia testnet
forge script script/Deploy.s.sol --rpc-url $SEPOLIA_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify

# Deploy to Goerli testnet  
forge script script/Deploy.s.sol --rpc-url $GOERLI_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
```

### Mainnet Deployment (Production)
```bash
# Deploy to Ethereum mainnet (be careful!)
forge script script/Deploy.s.sol --rpc-url $MAINNET_RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
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

## 🏗️ UniswapV2Suite - The Heart of the DevKit

The **UniswapV2Suite** is the flagship component of this DevKit, enabling developers to deploy and interact with a complete DEX ecosystem in minutes rather than hours.

### 🎯 Why UniswapV2Suite?

**Problem**: Setting up a complete DEX for testing typically requires:
- 10+ separate contract deployments
- Complex initialization sequences  
- Manual liquidity provisioning
- Error-prone configuration

**Solution**: UniswapV2Suite does it all in 2 function calls:
```solidity
// 1. Deploy entire DEX infrastructure
suite.deployDEX{value: 10 ether}(5 ether, 1000 ether);

// 2. Add liquidity to all trading pairs
suite.addInitialLiquidity(10 ether, 10 ether, 1 ether);
```

### ✨ Suite Features
- **🚀 One-click deployment**: Complete DEX in seconds, not hours
- **🏊 Auto liquidity**: Pre-populated trading pairs ready for testing
- **💱 Easy swaps**: Simplified swap functions for rapid prototyping  
- **🪙 Token minting**: Generate test tokens on demand
- **🛡️ Safe controls**: Emergency withdrawal functions for contract owner
- **📊 Rich querying**: Get all contract addresses and pair information

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

### 🔄 Auto-Generated Trading Pairs

UniswapV2Suite automatically creates a complete trading ecosystem:

| Pair | Purpose | Use Case |
|------|---------|----------|
| **TokenA/TokenB** | Token-to-token swaps | Basic AMM functionality |
| **TokenA/WETH** | Token-to-ETH trading | Native ETH integration |
| **TokenB/WETH** | Token-to-ETH trading | Multi-token ETH pairs |
| **TokenA/TokenC** | Complex routing | Multi-hop swap testing |

### 📈 Built for DeFi Development

**Perfect for:**
- 🧪 **Protocol Testing**: Comprehensive AMM testing environment
- 🎓 **Education**: Learn Uniswap mechanics hands-on
- 🏗️ **Rapid Prototyping**: Build DeFi apps faster
- 🔬 **Research**: Analyze AMM behavior and economics
- 📊 **Integration**: Test your contracts against real AMM logic

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

## 🤝 Contributing to Uniswap V2 DevKit

We welcome contributions from the DeFi community! Whether you're:
- 🐛 **Reporting bugs** or suggesting improvements
- 📚 **Improving documentation** for better developer experience  
- ✨ **Adding new features** or optimizations
- 🧪 **Writing more tests** for edge cases
- 🌍 **Translating** to other languages

Please check our [Contributing Guidelines](CONTRIBUTING.md) and feel free to open issues or pull requests.

## 📖 Learning Resources

### Foundry Framework
- [📘 Foundry Book](https://book.getfoundry.sh/) - Complete Foundry documentation
- [🔨 Forge Testing](https://book.getfoundry.sh/forge/tests) - Writing and running tests
- [📡 Cast CLI](https://book.getfoundry.sh/cast/) - Blockchain interactions
- [⚡ Anvil Local Node](https://book.getfoundry.sh/anvil/) - Local development

### Uniswap V2 Protocol
- [📋 Uniswap V2 Whitepaper](https://uniswap.org/whitepaper.pdf) - Protocol specification
- [💻 Original Implementation](https://github.com/Uniswap/v2-core) - Reference implementation
- [🎓 Uniswap Documentation](https://docs.uniswap.org/protocol/V2/introduction) - Protocol guide

### DeFi Development
- [🏗️ DeFi Development Guide](https://ethereum.org/en/defi/) - Getting started with DeFi
- [🔐 Smart Contract Security](https://consensys.github.io/smart-contract-best-practices/) - Security best practices

## 🔗 Related Projects

- **[Uniswap V3 DevKit](https://github.com/search?q=uniswap+v3+devkit)** - Next generation AMM toolkit
- **[DeFi Toolkit](https://github.com/search?q=defi+toolkit)** - Broader DeFi development tools
- **[AMM Research](https://github.com/search?q=amm+research)** - Academic and research projects

## ⭐ Star History & Community

If **Uniswap V2 DevKit** helps your project, please give us a star! ⭐

[![GitHub stars](https://img.shields.io/github/stars/0xqige/uniswap-v2-devkit.svg?style=social&label=Star)](https://github.com/0xqige/uniswap-v2-devkit)
[![GitHub forks](https://img.shields.io/github/forks/0xqige/uniswap-v2-devkit.svg?style=social&label=Fork)](https://github.com/0xqige/uniswap-v2-devkit/fork)

Join our community:
- 💬 [GitHub Discussions](https://github.com/0xqige/uniswap-v2-devkit/discussions) - Ask questions and share ideas
- 🐛 [Issues](https://github.com/0xqige/uniswap-v2-devkit/issues) - Report bugs and request features
- 🔄 [Pull Requests](https://github.com/0xqige/uniswap-v2-devkit/pulls) - Contribute code improvements

## 📄 License

This project is licensed under the **MIT License** - see the [LICENSE](LICENSE) file for details.

### Keywords
`uniswap-v2` `defi` `amm` `decentralized-exchange` `solidity` `foundry` `ethereum` `smart-contracts` `dex` `liquidity-pools` `automated-market-maker` `blockchain` `testing` `development-kit` `devkit`

---

**Built with ❤️ for the DeFi community by developers, for developers.**