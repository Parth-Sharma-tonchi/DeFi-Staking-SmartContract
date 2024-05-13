// SPDX-License-Identifier: MIT
pragma solidity 0.8.20;

import {Test} from "forge-std/Test.sol";
import {StakeToken} from "../../src/StakeToken.sol";

contract TestStakeToken is Test {
    StakeToken stakeToken;
    uint256 initialSupply = 1000e18;
    address public immutable user = makeAddr("user");

    function setUp() public {
        stakeToken = new StakeToken(initialSupply);
    }

    function testStakeTokenSupply() public view {
        uint256 balance = stakeToken.balanceOf(address(this));
        assertEq(balance, initialSupply);
    }

    function testStakeTokenNameAndSymbol() public view {
        string memory name = stakeToken.name();
        string memory symbol = stakeToken.symbol();
        assertEq(name, "StakeToken");
        assertEq(symbol, "ST");
    }

    function testStakeTOkenTransfer() public {
        uint256 amount = 100e18;
        // transfer amount to user.
        stakeToken.transfer(user, amount);
        uint256 balanceUser = stakeToken.balanceOf(user);
        uint256 balanceSender = stakeToken.balanceOf(address(this));
        assertEq(balanceUser, amount);
        assertEq(balanceSender, initialSupply - amount);
    }
}
