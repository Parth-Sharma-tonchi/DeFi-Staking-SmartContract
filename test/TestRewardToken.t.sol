// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {RewardToken} from "../../src/RewardToken.sol";


contract TestRewardToken is Test{
    RewardToken rewardToken;
    uint256 initialSupply = 1000e18;
    address public immutable user = makeAddr("user");

    function setUp() public {
        rewardToken = new RewardToken(initialSupply);
    }

    function testRewardTokenSupply() public view {
        uint256 balance = rewardToken.balanceOf(address(this));
        assertEq(balance, initialSupply);
    }

    function testRewardTokenNameAndSymbol() public view {
        string memory name = rewardToken.name();
        string memory symbol = rewardToken.symbol();
        assertEq(name, "RewardToken");
        assertEq(symbol, "RT");
    }

    function testRewardTokenTransfer() public {
        uint256 amount = 100e18;
        // transfer amount to user. 
        rewardToken.transfer(user, amount);
        uint256 balanceUser = rewardToken.balanceOf(user);
        uint256 balanceSender = rewardToken.balanceOf(address(this));
        assertEq(balanceUser, amount);
        assertEq(balanceSender, initialSupply - amount);
    }
}
