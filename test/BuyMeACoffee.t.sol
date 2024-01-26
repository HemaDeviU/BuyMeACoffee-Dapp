//SPDX-License-Identifier:MIY
pragma solidity ^0.8.19;
import {BuyMeACoffee} from "../src/BuyMeACoffee.sol";
import {DeployBuyMeACoffee} from "../script/DeployBuyMeACoffee.s.sol";
import {HelperConfig} from "../script/HelperConfig.s.sol";
import {Test, console} from "forge-std/Test.sol";
import {StdCheats} from "forge-std/StdCheats.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract BuyMeACoffeeTest is StdCheats, Test {
    BuyMeACoffee public buyMeC;
    HelperConfig public helperConfig;

    address public constant USER = address(1);
    // address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    function setUp() external {
        DeployBuyMeACoffee deployBuyMeC = new DeployBuyMeACoffee();
        (buyMeC, helperConfig) = deployBuyMeC.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testPriceFeedSetCorrectly() public {
        address retrivedPriceFeed = address(buyMeC.getPriceFeed());
        address expectedPriceFeed = helperConfig.activeNetworkConfig();
        assertEq(retrivedPriceFeed, expectedPriceFeed);
    }

    /*
    function testminimumusd() public {
        assertEq(buyMeC.i_MINIMUM_USD(), 5e18);
    }

    function testownerismsgsender() public {
        assertEq(buyMeC.getOwner(), msg.sender);
    } 

    function testPriceFeedVersionIsAccurate() public {
        uint256 version = buyMeC.getVersion();
        assertEq(version, 4);
    } */

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert();
        buyMeC.fund();
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        buyMeC.fund{value: SEND_VALUE}();
        uint256 amountFunded = buyMeC.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayofFunders() public {
        vm.prank(USER);
        buyMeC.fund{value: SEND_VALUE}();
        address funder = buyMeC.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        buyMeC.fund{value: SEND_VALUE}();
        assert(address(buyMeC).balance > 0);
        _;
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        buyMeC.withdraw();
    }

    function testWithDrawWithASingleFunder() public funded {
        uint256 startingFundMeBalance = address(buyMeC).balance;
        uint256 startingOwnerBalance = buyMeC.getOwner().balance;

        //uint256 gasStart = gasleft();
        //vm.txGasPrice(GAS_PRICE);
        vm.startPrank(buyMeC.getOwner());
        buyMeC.withdraw();
        vm.stopPrank();
        //uint256 gasEnd = gasleft();
        //uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        //console.log(gasUsed);
        uint256 endingFundMeBalance = address(buyMeC).balance;
        uint256 endingOwnerBalance = buyMeC.getOwner().balance;
        assertEq(endingFundMeBalance, 0);
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 2;
        for (
            uint160 i = startingFunderIndex;
            i < numberOfFunders + startingFunderIndex;
            i++
        ) {
            hoax(address(i), SEND_VALUE);
            buyMeC.fund{value: SEND_VALUE}();
        }
        uint256 startingFundMeBalance = address(buyMeC).balance;
        uint256 startingOwnerBalance = buyMeC.getOwner().balance;
        vm.startPrank(buyMeC.getOwner());
        buyMeC.withdraw();
        vm.stopPrank();

        assert(address(buyMeC).balance == 0);
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                buyMeC.getOwner().balance
        );
        assert(
            (numberOfFunders + 1) * SEND_VALUE ==
                buyMeC.getOwner().balance - startingOwnerBalance
        );
    }
}
