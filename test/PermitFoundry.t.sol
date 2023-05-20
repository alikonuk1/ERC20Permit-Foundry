// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "forge-std/Test.sol";
import "../src/PermitFoundry.sol";

contract PermitFoundryTest is Test {
    PermitFoundry public permitFoundry;
    /// Mainnet address for the USDC token contract.
    address public constant USDC = 0xa2327a938Febf5FEC13baCFb16Ae10EcBc4cbDCF;
    // Create an instance of the ERC20 interface for the USDC token.
    IERC20 internal constant usdc = IERC20(USDC);
    // Create an instance of the ERC20Permit interface for the USDC token.
    IERC20Permit internal constant usdcPermit = IERC20Permit(USDC);

    // Define addresses.
    address deployer;
    address alice;

    // Define private keys.
    uint256 deployerPk;
    uint256 alicePk;

    // The `setUp` function is used to initialize the test environment.
    function setUp() public {
        // Generate address and private key.
        (alice, alicePk) = makeAddrAndKey("Alice");

        // Distribute USDC tokens.
        deal(USDC, address(alice), 999 * 10e6);

        // Deploy the contract as deployer.
        vm.startPrank(deployer);
        permitFoundry = new PermitFoundry();
        vm.stopPrank();
    }

    // This test checks the ability to send USDC using the `PermitFoundry` contract.
    function test_sendUSDC() public {
        // Check the initial balances.
        assertEq(usdc.balanceOf(alice), 999 * 10e6);
        assertEq(usdc.balanceOf(address(permitFoundry)), 0);

        // Create permit hashes for the actors to approve the `PermitFoundry` contract to spend their USDC.
        // The arguments to the `keccak256` function form the data for the permit.
        // The `DOMAIN_SEPARATOR` is a value that prevents replay attacks across different domains.
        bytes32 permitHash = keccak256(
            abi.encodePacked(
                "\x19\x01",
                usdcPermit.DOMAIN_SEPARATOR(),
                keccak256(
                    abi.encode(
                        keccak256("Permit(address owner,address spender,uint256 value,uint256 nonce,uint256 deadline)"),
                        address(alice), // Owners address
                        address(permitFoundry), // Spenders address
                        3 * 10e6, // Amount to spend
                        usdcPermit.nonces(address(alice)), // Nonce
                        (block.timestamp + 60) // Deadline
                    )
                )
            )
        );

        // Sign the permit hash with the private key of the owner.
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(alicePk, permitHash);

        // Start a "prank" as Alice and execute the `sendUSDC` function with Alice's signature.
        // This simulates Alice sending USDC through the `PermitFoundry` contract.
        vm.startPrank(alice);
        permitFoundry.sendUSDC(3 * 10e6, v, r, s);
        vm.stopPrank();

        // Check the balances after sending USDC.
        // The balance of alice should be reduced by the amounts sent, and the `PermitFoundry` contract should hold the total amount.
        assertEq(usdc.balanceOf(alice), 996 * 10e6);
        assertEq(usdc.balanceOf(address(permitFoundry)), 3 * 10e6);
    }

    function test_withdrawUSDC() public {
        deal(USDC, address(permitFoundry), 333 * 10e6);
        assertEq(usdc.balanceOf(address(permitFoundry)), 333 * 10e6);
        assertEq(usdc.balanceOf(address(alice)), 999 * 10e6);

        vm.startPrank(alice);
        permitFoundry.withdrawUSDC();
        vm.stopPrank();

        assertEq(usdc.balanceOf(address(permitFoundry)), 0);
        assertEq(usdc.balanceOf(address(alice)), 1332 * 10e6); // 999 + 333 = 1332
    }
}
