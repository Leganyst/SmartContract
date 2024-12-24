// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract PolicyToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("PolicyToken", "PLTKN") {
        _mint(msg.sender, initialSupply * 10 ** decimals()); // (1 миллион токенов в формате с 18 десятичными знаками)
    }
}