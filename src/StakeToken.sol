//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract StakeToken is ERC20 {
    constructor(uint256 _initialSupply) ERC20("StakeToken", "ST") {
        _mint(msg.sender, _initialSupply);
    }
}
