-include .env

.PHONY: all test clean deploy fund help install snapshot format anvil scopefile

DEFAULT_ANVIL_KEY := 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80
SEPOLIA_RPC_URL := https://eth-sepolia.g.alchemy.com/v2/th8vbYaTiZTUbszaP1N7HpONtmDqIthz
PRIVATE_KEY := 850b3c1c3cf6a3f3edd582e0943b71d64889ff537e961349f14feec50fd63683
all: remove install build

# Clean the repo
clean  :; forge clean

# Remove modules
remove :; rm -rf .gitmodules && rm -rf .git/modules/* && rm -rf lib && touch .gitmodules && git add . && git commit -m "modules"

install :; forge install foundry-rs/forge-std --no-commit && forge install openzeppelin/openzeppelin-contracts --no-commit && forge install openzeppelin/openzeppelin-contracts-upgradeable --no-commit 

# Update Dependencies
update:; forge update

build:; forge build

test :; forge test 

snapshot :; forge snapshot

format :; forge fmt

anvil :; anvil -m 'test test test test test test test test test test test junk' --steps-tracing --block-time 1

deploy sepolia :; forge script script/DeployStaking.s.sol --rpc-url SEPOLIA_RPC_URL --private-key PRIVATE_KEY --verify --broadcast

stake sepolia :; forge script script/Interactions.s.sol:staking --rpc-url SEPOLIA_RPC_URL --private-key PRIVATE_KEY --verify --broadcast

unstake sepolia :; forge script script/Interactions.s.sol:unstake --rpc-url SEPOLIA_RPC_URL --private-key PRIVATE_KEY --verify --broadcast

withdrawRewards sepolia :; forge script script/Interactions.s.sol:withdrawRewards --rpc-url SEPOLIA_RPC_URL --private-key PRIVATE_KEY --verify --broadcast