# Pangolin Stop Order on Avalanche C-Chain

## Overview

The **Pangolin Stop Order** on Avalanche C-Chain implements a reactive smart contract that monitors Pangolin liquidity pools. When the exchange rate reaches a predefined threshold, the contract automatically executes asset sales, providing protection against price drops without requiring constant monitoring.

## Prerequisites

* Avalanche wallet with AVAX (for deployment and gas)
* REACT tokens on Kopli testnet (for the reactive contract)
* Tokens on Avalanche that are part of a Pangolin pool

## Environment Setup

Set up the following environment variables:

```bash
export AVALANCHE_RPC="https://api.avax.network/ext/bc/C/rpc"
export AVALANCHE_PRIVATE_KEY="your-avalanche-private-key"
export REACTIVE_RPC="https://kopli-rpc.rnk.dev"
export REACTIVE_PRIVATE_KEY="your-reactive-private-key"
export CLIENT_WALLET="your-wallet-address"
export AVALANCHE_CALLBACK_PROXY_ADDR="0x8578E2eD8E54714C60a24bD99708F247c3F57e0F"
```

**Faucet**: To receive REACT tokens on Kopli, send SepETH to the Reactive faucet at `0x9b9BB25f1A81078C544C829c5EB7822d747Cf434`.

## Installation

Install the necessary dependencies:

```bash
# Install OpenZeppelin contracts
forge install OpenZeppelin/openzeppelin-contracts --no-commit

# Install Pangolin contracts
forge install pangolindex/exchange-contracts --no-commit

# Install Reactive lib
forge install Reactive-Network/reactive-lib --no-commit
```

## Deployment Steps

### Step 1 — Find a Pangolin Pair

Use the pair finder in the UI to identify an existing pair, or use a known pair address:

```bash
export PANGOLIN_PAIR_ADDR="0x9ee0a4e21bd333a6bb2ab298194320b8daa26516"  # Example: WAVAX-USDT pair
```

Some popular Avalanche pairs:
- WAVAX-USDT: `0x9ee0a4e21bd333a6bb2ab298194320b8daa26516`

### Step 2 — Deploy Destination Contract

Deploy the callback contract on Avalanche C-Chain:

```bash
forge create --rpc-url $AVALANCHE_RPC --private-key $AVALANCHE_PRIVATE_KEY src/PangolinDemoStopOrderCallback.sol:PangolinDemoStopOrderCallback --value 0.1ether --constructor-args $AVALANCHE_CALLBACK_PROXY_ADDR 0xE54Ca86531e17Ef3616d22Ca28b0D458b6C89106
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
forge create --rpc-url $REACTIVE_RPC --private-key $REACTIVE_PRIVATE_KEY src/PangolinDemoStopOrderReactive.sol:PangolinDemoStopOrderReactive --value 0.1ether --constructor-args $PANGOLIN_PAIR_ADDR $CALLBACK_ADDR $CLIENT_WALLET true 1000 950
```

### Step 4 — Authorize Token Spending

Determine which token you want to sell (token0 or token1 from the pair) and authorize the callback contract to spend it:

```bash
# Get token addresses from the pair
export TOKEN0_ADDR=$(cast call $PANGOLIN_PAIR_ADDR "token0()(address)" --rpc-url $AVALANCHE_RPC)
export TOKEN1_ADDR=$(cast call $PANGOLIN_PAIR_ADDR "token1()(address)" --rpc-url $AVALANCHE_RPC)

# Approve token spending (assuming you want to sell token0)
cast send $TOKEN0_ADDR "approve(address,uint256)" --rpc-url $AVALANCHE_RPC --private-key $AVALANCHE_PRIVATE_KEY $CALLBACK_ADDR 1000000000000000000
```

## Verification

Your stop order is now active. It will monitor the price of the selected pair and automatically execute when the threshold is met. You can verify:

- Check the deployed contracts on [Snowtrace](https://snowtrace.io/)  
- Monitor reactive contract events on [Reactive Explorer](https://kopli.reactscan.net/)

## Network-Specific Notes

- Avalanche offers typically lower transaction fees than Ethereum Mainnet
- Avalanche C-Chain is EVM-compatible, making it similar to work with as Ethereum
- The Pangolin DEX follows similar principles to Uniswap V2, with nearly identical interfaces
- Gas prices may fluctuate during periods of network congestion

## Contract Implementation

The implementation consists of two main contracts:

1. **PangolinDemoStopOrderCallback.sol** - Deployed on Avalanche:
   ```solidity
   // Import OpenZeppelin contracts
   import "../../lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
   
   // Import Pangolin contracts
   import "../../lib/exchange-contracts/contracts/pangolin-periphery/interfaces/IPangolinRouter.sol";
   import "../../lib/exchange-contracts/contracts/pangolin-core/interfaces/IPangolinPair.sol";
   
   // Import Reactive contracts
   import "../../lib/reactive-lib/src/abstract-base/AbstractCallback.sol";
   
   contract PangolinDemoStopOrderCallback is AbstractCallback {
       // Contract implementation
   }
   ```

2. **PangolinDemoStopOrderReactive.sol** - Deployed on Kopli:
   ```solidity
   // Import Reactive contracts
   import "../../lib/reactive-lib/src/interfaces/IReactive.sol";
   import "../../lib/reactive-lib/src/abstract-base/AbstractReactive.sol";
   
   contract PangolinDemoStopOrderReactive is IReactive, AbstractReactive {
       // Contract implementation with AVALANCHE_CHAIN_ID
   }
   ```

## Troubleshooting

If you encounter issues with Avalanche transactions:
- Ensure you have enough AVAX for gas
- Check if you're using the C-Chain RPC endpoint (not P-Chain or X-Chain)
- Verify token approvals were completed successfully
- Consider increasing gas limits for complex transactions