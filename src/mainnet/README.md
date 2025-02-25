# Uniswap V2 Stop Order on Ethereum Mainnet

## Overview

The **Uniswap V2 Stop Order** on Ethereum Mainnet implements a reactive smart contract that monitors Uniswap V2 liquidity pools. When the exchange rate reaches a predefined threshold, the contract automatically executes asset sales, providing protection against price drops without requiring constant monitoring.

## Prerequisites

* Ethereum wallet with ETH (for deployment and gas)
* REACT tokens on Kopli testnet (for the reactive contract)
* Tokens on Mainnet that are part of a Uniswap V2 pool

## Environment Setup

Set up the following environment variables:

```bash
export MAINNET_RPC="your-mainnet-rpc-url"
export MAINNET_PRIVATE_KEY="your-mainnet-private-key"
export REACTIVE_RPC="https://kopli-rpc.rnk.dev"
export REACTIVE_PRIVATE_KEY="your-reactive-private-key"
export CLIENT_WALLET="your-wallet-address"
export MAINNET_CALLBACK_PROXY_ADDR="0x3D0662664D8A0630Db6A7F33F8E5B4A86ce3348F"
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
export UNISWAP_V2_PAIR_ADDR="0xa478c2975ab1ea89e8196811f51a7b7ade33eb11"  # Example: DAI-WETH pair
```

Some popular Mainnet pairs:
- DAI-WETH: `0xa478c2975ab1ea89e8196811f51a7b7ade33eb11`
- USDC-WETH: `0xb4e16d0168e52d35cacd2c6185b44281ec28c9dc`
- USDT-WETH: `0x0d4a11d5eeaac28ec3f61d100daf4d40471f1852`

### Step 2 — Deploy Destination Contract

Deploy the callback contract on Ethereum Mainnet:

```bash
forge create --rpc-url $MAINNET_RPC --private-key $MAINNET_PRIVATE_KEY src/UniswapDemoStopOrderCallback.sol:UniswapDemoStopOrderCallback --value 0.1ether --constructor-args $MAINNET_CALLBACK_PROXY_ADDR 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D
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
export TOKEN0_ADDR=$(cast call $UNISWAP_V2_PAIR_ADDR "token0()(address)" --rpc-url $MAINNET_RPC)
export TOKEN1_ADDR=$(cast call $UNISWAP_V2_PAIR_ADDR "token1()(address)" --rpc-url $MAINNET_RPC)

# Approve token spending (assuming you want to sell token0)
cast send $TOKEN0_ADDR "approve(address,uint256)" --rpc-url $MAINNET_RPC --private-key $MAINNET_PRIVATE_KEY $CALLBACK_ADDR 1000000000000000000
```

## Verification

Your stop order is now active. It will monitor the price of the selected pair and automatically execute when the threshold is met. You can verify:

- Check the deployed contracts on [Etherscan](https://etherscan.io/)
- Monitor reactive contract events on [Reactive Explorer](https://kopli.reactscan.net/)

## Security Considerations

When operating on Mainnet, consider these additional security precautions:

1. **Start small**: Test with small amounts before committing significant funds
2. **Gas costs**: Be aware of Mainnet gas costs for contract deployment and token approvals
3. **Slippage impact**: High-value trades may experience more slippage than expected
4. **Contract audits**: Consider reviewing the contract code thoroughly before deployment

## Contract Implementation

The implementation consists of two main contracts:

1. **UniswapDemoStopOrderCallback.sol** - Deployed on Mainnet:
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