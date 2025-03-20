// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Vault {
    IERC20 public usdc;
    address public factory;
    address public cbbcToken;
    uint256 public marginLevel;
    uint256 public lastMarginCallTime;
    uint256 public minMarginThreshold = 20; // 20% minimum margin ratio
    uint256 public marginCallDuration = 3 hours;

    modifier onlyFactory() {
        require(msg.sender == factory, "Only factory can call");
        _;
    }

    constructor(address _usdc, address _cbbcToken) {
        usdc = IERC20(_usdc);
        cbbcToken = _cbbcToken;
        factory = msg.sender;
    }

    function deposit(uint256 amount) external {
        usdc.transferFrom(msg.sender, address(this), amount);
        marginLevel += amount;
    }

    function withdraw(address to, uint256 amount) external onlyFactory {
        require(marginLevel >= amount, "Not enough margin");
        usdc.transfer(to, amount);
        marginLevel -= amount;
    }

    function checkMarginLevel(
        uint256 liability
    ) external onlyFactory returns (bool) {
        uint256 marginRatio = (marginLevel * 100) / liability;

        if (marginRatio < minMarginThreshold) {
            // Trigger margin call
            lastMarginCallTime = block.timestamp;
            return false; // Margin call triggered
        }
        return true; // Margin level sufficient
    }

    function handleMarginCall(uint256 liability) external onlyFactory {
        if (block.timestamp > lastMarginCallTime + marginCallDuration) {
            uint256 marginRatio = (marginLevel * 100) / liability;
            if (marginRatio < minMarginThreshold) {
                // Liquidate if margin call not fulfilled
                liquidate(liability);
            }
        }
    }

    function liquidate(uint256 liability) internal {
        if (marginLevel > liability) {
            // Payout token holders with remaining margin
            usdc.transfer(cbbcToken, liability);
        } else {
            // Pay whatever margin is available
            usdc.transfer(cbbcToken, marginLevel);
        }
        marginLevel = 0;
        // Burn tokens (handled by factory)
    }

    function balance() external view returns (uint256) {
        return usdc.balanceOf(address(this));
    }
}
