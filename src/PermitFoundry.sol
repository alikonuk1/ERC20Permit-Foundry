// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "lib/openzeppelin-contracts/contracts/token/ERC20/extensions/draft-IERC20Permit.sol";

contract PermitFoundry {
    error TRANSFER_UNSUCCESSFUL();

    /// @notice Mainnet address for the USDC token contract
    address public constant USDC = 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF;

    function sendUSDC(uint256 amount, uint8 v, bytes32 r, bytes32 s) external {
        IERC20Permit(USDC).permit(msg.sender, address(this), amount, (block.timestamp + 60), v, r, s);
        if (!IERC20(USDC).transferFrom(msg.sender, address(this), amount)) {
            revert TRANSFER_UNSUCCESSFUL();
        }
    }

    function withdrawUSDC() external {
        uint256 balance = IERC20(USDC).balanceOf(address(this));
        if (!IERC20(USDC).transfer(msg.sender, balance)) {
            revert TRANSFER_UNSUCCESSFUL();
        }
    }
}
