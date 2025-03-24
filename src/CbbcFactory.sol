// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./CBBCToken.sol";
import "./Vault.sol";

contract CBBCFactory {
    address public usdc;

    event CBBCIssued(address indexed token, address indexed issuer);
    event MarginCallTriggered(address indexed token);
    event Liquidation(address indexed token);

    constructor(address _usdc) {
        usdc = _usdc;
    }

    function createCBBC(
        string memory name,
        string memory symbol,
        uint256 strike,
        uint256 expiry,
        bool isBull
    ) external {
        CBBCToken token = new CBBCToken(
            name,
            symbol,
            strike,
            expiry,
            isBull,
            msg.sender
        );
        Vault issuerVault = new Vault(usdc, address(token));
        Vault buyerVault = new Vault(usdc, address(token));

        emit CBBCIssued(address(token), msg.sender);
    }

    function settle(address tokenAddress) external {
        CBBCToken token = CBBCToken(tokenAddress);
        Vault issuerVault = Vault(token.issuerVault());
        Vault buyerVault = Vault(token.buyerVault());

        uint256 liability = calculatePayout();

        // 1. Check margin level
        bool sufficientMargin = issuerVault.checkMarginLevel(liability);
        if (!sufficientMargin) {
            emit MarginCallTriggered(tokenAddress);
        }

        // 2. Handle margin call (if timeout exceeded)
        issuerVault.handleMarginCall(liability);

        // 3. Burn tokens after settlement
        token.burn(address(this), token.totalSupply());
        emit Liquidation(tokenAddress);
    }

    function calculatePayoff(
        address tokenAddress
    ) internal pure returns (uint256) {
        // Example payoff calculation
        // Use pyth to get the underlying price
        // if (tokenAddress == "BULL") {
        //     payoff = min(tokenAddress.strike - pyth.price(tokenAddress.underlying),0);
        // } else {
        //     payoff = min(pyth.price(tokenAddress.underlying) - tokenAddress.strike,0);
        // }
        // return payoff;
    }
}
