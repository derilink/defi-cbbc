// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract CBBCToken is ERC20 {
    address public issuer;
    uint256 public expiry;
    uint256 public strike;
    bool public isBull;
    address public factory;

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call");
        _;
    }

    constructor(
        string memory _name,
        string memory _symbol,
        uint256 _strike,
        uint256 _expiry,
        bool _isBull,
        address _issuer
    ) ERC20(_name, _symbol) {
        strike = _strike;
        expiry = _expiry;
        isBull = _isBull;
        issuer = _issuer;
        factory = msg.sender;
    }

    function mint(address to, uint256 amount) external onlyFactory {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external onlyFactory {
        _burn(from, amount);
    }
}
