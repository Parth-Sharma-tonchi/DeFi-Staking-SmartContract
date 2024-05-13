## DeFi Staking SmartContract

** 
 * @title Staking Smart contract allows user to stake and earn reward token based on it.
 * @author Parth Sharma
 * @notice To interact with protocol, you must deploy the code through anvil and test network and then run interaction script. This contract code is not production ready now. We should have to conduct security reviews over the contract code.
**

### Foundry
#### Foundry Framework Used:
Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Description

An staking smart contract on any EVM network
that allows users to stake one token and earn reward tokens periodically. This
contract will focus on depositing and withdrawing staked tokens and the reward
tokens and calculation of staking rewards.

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/DeployStaking.s.sol --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Interact
#### stake
```shell
$ forge script script/Interactions.s.sol:staking --rpc-url <your_rpc_url> --private-key <your_private_key>
```
#### unstake
```shell
$ forge script script/Interactions.s.sol:unstake --rpc-url <your_rpc_url> --private-key <your_private_key>
```
#### Get Rewards
```shell
$ forge script script/Interactions.s.sol:withdrawRewards --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast
`To interact using foundry use ```cast``` instead of above commands: `

```shell
$ cast <subcommand>
```
