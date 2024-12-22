// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract InsuranceToken is ERC20 {
    constructor(uint256 initialSupply) ERC20("InsuranceToken", "ITKN") {
        _mint(msg.sender, initialSupply * 10 ** decimals()); // (1 миллион токенов в формате с 18 десятичными знаками)
    }
}