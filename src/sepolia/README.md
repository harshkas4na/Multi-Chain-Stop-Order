# Uniswap V2 Stop Order on Ethereum Sepolia

## Overview

The **Uniswap V2 Stop Order** on Ethereum Sepolia implements a reactive smart contract that monitors Uniswap V2 liquidity pools. When the exchange rate reaches a predefined threshold, the contract automatically executes asset sales, providing protection against price drops without requiring constant monitoring.

## Prerequisites

* Ethereum wallet with Sepolia ETH (for deployment and gas)
* REACT tokens on Kopli testnet (for the reactive contract)
* Tokens on Sepolia that are part of a Uniswap V2 pool

## Environment Setup

Set up the following environment variables:

```bash
export SEPOLIA_RPC="your-sepolia-rpc-url"
export SEPOLIA_PRIVATE_KEY="your-sepolia-private-key"
export REACTIVE_RPC="https://kopli-rpc.rnk.dev"
export REACTIVE_PRIVATE_KEY="your-reactive-private-key"
export CLIENT_WALLET="your-wallet-address"
export SEPOLIA_CALLBACK_PROXY_ADDR="0x33Bbb7D0a2F1029550B0e91f653c4055DC9F4Dd8"
```

**Faucet**: To receive REACT tokens on Kopli, send SepETH to the Reactive faucet at `0x9b9BB25f1A81078C544C829c5EB7822d747Cf434`.

## Installation

Install the necessary dependencies:

```bash
# Install OpenZeppelin contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Install Uniswap V2 contracts
forge install Uniswap/v2-core --no-commit
forge install Uniswap/v2-periphery --no-commit

# Install Reactive lib
forge install Reactive-Network/reactive-lib --no-commit
```

## Deployment Steps

### Step 1 — Find a Uniswap V2 Pair

Use the pair finder in the UI to identify an existing pair, or use a known pair address:

```bash
export UNISWAP_V2_PAIR_ADDR="0x1DD11fD3690979f2602E42e7bBF68A19040E2e25"
```

### Step 2 — Deploy Destination Contract

Deploy the callback contract on Ethereum Sepolia:

```bash
forge create --rpc-url $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY src/UniswapDemoStopOrderCallback.sol:UniswapDemoStopOrderCallback --value 0.1ether --constructor-args $SEPOLIA_CALLBACK_PROXY_ADDR 0xC532a74256D3Db42D0Bf7a0400fEFDbad7694008
```

Save the deployed contract address:

```bash
export CALLBACK_ADDR="deployed-contract-address"
```

### Step 3 — Deploy Reactive Contract

Choose your stop order parameters:
- `DIRECTION_BOOLEAN`: `true` to sell `token0` and buy `token1`; `false` for the reverse
- `COEFFICIENT`: Base value for price comparison (typically 1000)
- `THRESHOLD`: Trigger value (e.g., 950 for a 5% drop if coefficient is 1000)

```bash
forge create --rpc-url $REACTIVE_RPC --private-key $REACTIVE_PRIVATE_KEY src/UniswapDemoStopOrderReactive.sol:UniswapDemoStopOrderReactive --value 0.1ether --constructor-args $UNISWAP_V2_PAIR_ADDR $CALLBACK_ADDR $CLIENT_WALLET true 1000 950
```

### Step 4 — Authorize Token Spending

Determine which token you want to sell (token0 or token1 from the pair) and authorize the callback contract to spend it:

```bash
# Get token addresses from the pair
export TOKEN0_ADDR=$(cast call $UNISWAP_V2_PAIR_ADDR "token0()(address)" --rpc-url $SEPOLIA_RPC)
export TOKEN1_ADDR=$(cast call $UNISWAP_V2_PAIR_ADDR "token1()(address)" --rpc-url $SEPOLIA_RPC)

# Approve token spending (assuming you want to sell token0)
cast send $TOKEN0_ADDR "approve(address,uint256)" --rpc-url $SEPOLIA_RPC --private-key $SEPOLIA_PRIVATE_KEY $CALLBACK_ADDR 1000000000000000000
```

## Verification

Your stop order is now active. It will monitor the price of the selected pair and automatically execute when the threshold is met. You can verify:

- Check the deployed contracts on [Sepolia Etherscan](https://sepolia.etherscan.io/)
- Monitor reactive contract events on [Reactive Explorer](https://kopli.reactscan.net/)

## Contract Implementation

The implementation consists of two main contracts:

1. **UniswapDemoStopOrderCallback.sol** - Deployed on Sepolia:
   ```solidity
   // Import OpenZeppelin contracts
   import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
   
   // Import Uniswap contracts
   import "../../lib/v2-periphery/contracts/interfaces/IUniswapV2Router02.sol";
   import "../../lib/v2-core/contracts/interfaces/IUniswapV2Pair.sol";
   
   // Import Reactive contracts
   import "../../lib/reactive-lib/src/abstract-base/AbstractCallback.sol";
   
   contract UniswapDemoStopOrderCallback is AbstractCallback {
       // Contract implementation
   }
   ```

2. **UniswapDemoStopOrderReactive.sol** - Deployed on Kopli:
   ```solidity
   // Import Reactive contracts
   import "../../lib/reactive-lib/src/interfaces/IReactive.sol";
   import "../../lib/reactive-lib/src/abstract-base/AbstractReactive.sol";
   
   contract UniswapDemoStopOrderReactive is IReactive, AbstractReactive {
       // Contract implementation
   }
   ```