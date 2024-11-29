// SPDX-License-Identifier: MIT

pragma solidity ^0.8;
import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    address USER = makeAddr("user"); // user
    uint constant SEND_VAL = 0.1 ether;
    uint constant MIN_VAL = 5e18;
    uint constant START_BAL = 1000 ether;

    function setUp() external {
        // fundMe = new FundMe(0x90FbDd2951A4f1b7759f75Eb885b370ed8D14072);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, START_BAL);
    }

    function testMinDollarIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), MIN_VAL);
    }

    function testOwnerIsMessageSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testFundFailsWithoutEnoughETH() public {
        vm.expectRevert(); // Expect the next line to revert!
        // same as assert (This tx fails/reverts)
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.startPrank(USER); // Set the current tx sender to the user in the scope of this function
        fundMe.fund{value: SEND_VAL}();
        vm.stopPrank();

        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VAL);
    }

    function testAddsFunderToArrayOfFunders() public {
        vm.startPrank(USER); // Set the current tx sender to the user in the scope
        fundMe.fund{value: SEND_VAL}();
        vm.stopPrank();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VAL}();
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.startPrank(USER);
        vm.expectRevert();
        fundMe.withdraw();
        vm.stopPrank();
    }

    function testWithDrawWithASingleFunder() public funded {
        // Arrange
        uint startingOwnerBal = fundMe.getOwner().balance;
        uint startFundMeBal = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        uint endingOwnerBal = fundMe.getOwner().balance;
        uint endingFundMeBal = address(fundMe).balance;
        assertEq(endingFundMeBal, 0);
        assertEq(startFundMeBal + startingOwnerBal, endingOwnerBal);
    }

    function testWithdrawWithMultipleOwners() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // fund the fundME
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VAL); // same as using vm.prank and then vm.deal
            // vm.startPrank(address(i)); // Start a new prank
            // vm.deal(address(i), SEND_VAL); // Send ETH to address i
            fundMe.fund{value: SEND_VAL}();
            // vm.stopPrank();
        }

        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.withdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testPrintStorageData() public view {
        for (uint256 i = 0; i < 3; i++) {
            bytes32 value = vm.load(address(fundMe), bytes32(i));
            console.log("Value at location", i, ":");
            console.logBytes32(value);
        }
        console.log("PriceFeed address:", address(fundMe.getPriceFeed()));
    }

    function testCheaperWithdrawWithMultipleOwners() public funded {
        // Arrange
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1;
        // fund the fundME
        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            hoax(address(i), SEND_VAL); // same as using vm.prank and then vm.deal
            // vm.startPrank(address(i)); // Start a new prank
            // vm.deal(address(i), SEND_VAL); // Send ETH to address i
            fundMe.fund{value: SEND_VAL}();
            // vm.stopPrank();
        }

        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundMeBalance = address(fundMe).balance;

        // Act
        vm.startPrank(fundMe.getOwner());
        fundMe.cheaperWithdraw();
        vm.stopPrank();

        // Assert
        assert(address(fundMe).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
