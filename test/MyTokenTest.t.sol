// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test} from "forge-std/Test.sol";
import {DeployMyToken} from "../script/DeployMyToken.s.sol";
import {MyToken} from "../src/MyToken.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";

interface MintableToken {
    function mint(address, uint256) external;
}

contract MyTokenTest is StdCheats, Test {
    uint256 DUMMY_STARTING_AMOUNT = 100 ether;

    MyToken public myToken;
    DeployMyToken public deployer;
    address public deployerAddress;

    address dummy = makeAddr("dummy");
    address dumbo = makeAddr("dumbo");

    function setUp() public {
        deployer = new DeployMyToken();
        myToken = deployer.run();

        dummy = makeAddr("dummy");
        dumbo = makeAddr("dumbo");

        deployerAddress = vm.addr(deployer.deployerKey());
        vm.prank(deployerAddress);
        myToken.transfer(dummy, DUMMY_STARTING_AMOUNT);
    }

    function testDummyBalance() public {
        assertEq(DUMMY_STARTING_AMOUNT, myToken.balanceOf(dummy));
    }

    function testInitialSupply() public {
        assertEq(myToken.totalSupply(), deployer.INITIAL_SUPPLY());
    }

    function testUsersCantMint() public {
        vm.expectRevert();
        MintableToken(address(myToken)).mint(address(this), 1);
    }

    function testAllowancesWorks() public {
        uint256 initialAllowance = 1000;

        // Dummy approves Dumbo to spend tokens on his behalf
        vm.prank(dummy);
        myToken.approve(dumbo, initialAllowance);

        uint256 transferAmount = 500;

        vm.prank(dumbo);
        myToken.transferFrom(dummy, dumbo, transferAmount);

        assertEq(myToken.balanceOf(dumbo), transferAmount);
        assertEq(
            myToken.balanceOf(dummy),
            DUMMY_STARTING_AMOUNT - transferAmount
        );
    }

    function testTransferWithInsufficientBalance() public {
        uint256 amount = deployer.INITIAL_SUPPLY() + 1;
        vm.expectRevert();
        myToken.transfer(dummy, amount);
    }

    function testTransferFromWithoutApproval() public {
        uint256 amount = 100;
        vm.expectRevert();
        myToken.transferFrom(msg.sender, dumbo, amount);
    }
}
