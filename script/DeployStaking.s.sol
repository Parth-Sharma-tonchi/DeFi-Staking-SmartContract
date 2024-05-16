//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Script} from "lib/forge-std/src/Script.sol";
import {Staking} from "../src/Staking.sol";
import {StakeToken} from "../src/StakeToken.sol";
import {RewardToken} from "../src/RewardToken.sol";

contract DeployStaking is Script {
    Staking stContract;
    StakeToken stToken;
    RewardToken rToken;
    uint256 public constant INITIAL_SUPPLY = 1000e18;

    function run() external returns (address, address, address) {
        vm.startBroadcast(msg.sender);
        stToken = new StakeToken(INITIAL_SUPPLY);
        rToken = new RewardToken(INITIAL_SUPPLY);
        stToken.approve(msg.sender, INITIAL_SUPPLY);
        rToken.approve(msg.sender, INITIAL_SUPPLY);
        stContract = new Staking(address(stToken), address(rToken));
        stToken.approve(address(stContract), INITIAL_SUPPLY);
        rToken.approve(address(stContract), INITIAL_SUPPLY);
        vm.stopBroadcast();
        return (address(stContract), address(stToken), address(rToken));
    }
}
