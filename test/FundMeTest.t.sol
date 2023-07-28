// SPDX-License-Identifier: MIT

pragma solidity ^0.8.19;

import {Test,console} from "forge-std/Test.sol";

import {FundMe} from "../src/FundMe.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;

    address USER = makeAddr("user");

    uint256 constant SEND_VALUE = 0.1 ether;

    function setUp() external{
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER,100e18);//100e18 is the starting balance we are giving to the user
    }

    // function testMinDollarIsFive() public {
    //     // console.log("HI");
    //     assertEq(fundMe.MINIMUM_USD(),5e18); 
    // }

    // function testOwnerIsMsgSender() public {
    //     assertEq(fundMe.i_owner(),msg.sender);
    // }

    function testPriceFeedVersionIsAccurate() public{
        uint256 version = fundMe.getVersion();
        assertEq(version,4);
    }
 
    function testFundFailsWithoutEnoughETH() public{
        vm.expectRevert();  //the next line should revert
        //assert(This tx fails/reverts)
        fundMe.fund();
    }

    function testFundUpdatesFundedDataStructure() public{
        vm.prank(USER);//The next tx will be sent5 by USER
        fundMe.fund{value:SEND_VALUE}();
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded,SEND_VALUE);
    }

    modifier funded(){
        vm.prank(USER);
        fundMe.fund{value:SEND_VALUE}();
        _;
    }

    function testAddsFunderToArrayOfFounders() public funded{
       
        address funder = fundMe.getFunder(0);
        assertEq(funder,USER);
    }

    function testOnlyOwnerCanWithdraw() public funded{
        vm.prank(USER);
        vm.expectRevert();
        fundMe.withdraw();
    }

    function testWithdrawWithASingleFounder() public funded{
        //Arrange
        uint startingOwnerBalance = fundMe.getOwner().balance;
        uint startingFundMeBalance = address(fundMe).balance;
        
        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();        

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance,0);
        assertEq(startingFundMeBalance+startingOwnerBalance,endingOwnerBalance);
    }

}

