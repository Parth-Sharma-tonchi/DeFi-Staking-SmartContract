//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "forge-std/Script.sol";
import {Staking} from "../src/Staking.sol";
import {StakeToken} from "../src/StakeToken.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract DeployStaking is Script {
    Staking stContract;
    StakeToken stToken;
    RewardToken rToken;
    uint256 public constant INITIAL_SUPPLY = 1000000;

    function run() external returns (address) {
        vm.startBroadcast();
        stToken = new StakeToken(INITIAL_SUPPLY);
        rToken = new RewardToken(INITIAL_SUPPLY);
        stContract = new Staking(address(stToken), address(rToken));
        vm.stopBroadcast();
        return address(stContract);
    }
}
