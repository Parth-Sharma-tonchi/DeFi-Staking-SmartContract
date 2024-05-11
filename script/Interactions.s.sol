//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {DevOpsTools} from "lib/foundry-devops/src/DevOpsTools.sol";
import {Staking} from "../src/Staking.sol";

contract staking is Script {
    uint256 public constant AMOUNT = 100e18;

    function run() external {
        address deployedStaking = DevOpsTools.get_most_recent_deployment("Staking", block.chainid);
        stake(deployedStaking);
    }

    function stake(address DeployedStaking) public {
        vm.startBroadcast();
        Staking(DeployedStaking).staking(AMOUNT);
        vm.stopBroadcast();
    }
}

contract unstake is Script {
    uint256 public constant AMOUNT = 100e18;

    function run() external {
        address deployedStaking = DevOpsTools.get_most_recent_deployment("Staking", block.chainid);
        withdraw(deployedStaking);
    }

    function withdraw(address DeployedStaking) public {
        vm.startBroadcast();
        Staking(DeployedStaking).unstake(AMOUNT);
        vm.stopBroadcast();
    }
}

contract withdrawRewards is Script {
    function run() external {
        address deployedStaking = DevOpsTools.get_most_recent_deployment("Staking", block.chainid);
        withdraw_Rewards(deployedStaking);
    }

    function withdraw_Rewards(address DeployedStaking) public {
        vm.startBroadcast();
        Staking(DeployedStaking).withdrawRewards();
        vm.stopBroadcast();
    }
}
