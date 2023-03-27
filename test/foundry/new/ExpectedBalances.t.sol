// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../../../contracts/lib/ConsiderationStructs.sol";
import {
    ExpectedBalances,
    ERC721TokenDump
} from "./helpers/ExpectedBalances.sol";
// import "./ExpectedBalanceSerializer.sol";
import "forge-std/Test.sol";
// import "forge-std/StdError.sol";
import { TestERC20 } from "../../../contracts/test/TestERC20.sol";

import { TestERC721 } from "../../../contracts/test/TestERC721.sol";

import { TestERC1155 } from "../../../contracts/test/TestERC1155.sol";

contract ExpectedBalancesTest is Test {
    TestERC20 internal erc20;
    TestERC721 internal erc721;
    TestERC1155 internal erc1155;

    ExpectedBalances internal balances;

    address payable internal alice = payable(address(0xa11ce));
    address payable internal bob = payable(address(0xb0b));

    function setUp() public virtual {
        balances = new ExpectedBalances();
        _deployTestTokenContracts();
    }

    function testAddTransfers() external {
        erc20.mint(alice, 500);
        erc721.mint(bob, 1);
        erc1155.mint(bob, 1, 100);
        vm.deal(alice, 1 ether);
        Execution[] memory executions = new Execution[](4);

        executions[0] = Execution({
            offerer: alice,
            conduitKey: bytes32(0),
            item: ReceivedItem(
                ItemType.NATIVE,
                address(0),
                0,
                0.5 ether,
                payable(bob)
            )
        });
        executions[1] = Execution({
            offerer: alice,
            conduitKey: bytes32(0),
            item: ReceivedItem(
                ItemType.ERC20,
                address(erc20),
                0,
                250,
                payable(bob)
            )
        });
        executions[2] = Execution({
            offerer: bob,
            conduitKey: bytes32(0),
            item: ReceivedItem(
                ItemType.ERC721,
                address(erc721),
                1,
                1,
                payable(alice)
            )
        });
        executions[3] = Execution({
            offerer: bob,
            conduitKey: bytes32(0),
            item: ReceivedItem(
                ItemType.ERC1155,
                address(erc1155),
                1,
                50,
                payable(alice)
            )
        });
        balances.addTransfers(executions);
        vm.prank(alice);
        erc20.transfer(bob, 250);

        vm.prank(bob);
        erc721.transferFrom(bob, alice, 1);

        vm.prank(bob);
        erc1155.safeTransferFrom(bob, alice, 1, 50, "");

        vm.prank(alice);
        bob.send(0.5 ether);

        balances.checkBalances();
    }

    function testCheckBalances() external {
        erc20.mint(alice, 500);
        erc721.mint(bob, 1);
        erc1155.mint(bob, 1, 100);
        vm.deal(alice, 1 ether);

        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.NATIVE,
                    address(0),
                    0,
                    0.5 ether,
                    payable(bob)
                )
            })
        );
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC20,
                    address(erc20),
                    0,
                    250,
                    payable(bob)
                )
            })
        );
        balances.addTransfer(
            Execution({
                offerer: bob,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC721,
                    address(erc721),
                    1,
                    1,
                    payable(alice)
                )
            })
        );
        balances.addTransfer(
            Execution({
                offerer: bob,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC1155,
                    address(erc1155),
                    1,
                    50,
                    payable(alice)
                )
            })
        );
        vm.prank(alice);
        erc20.transfer(bob, 250);

        vm.prank(bob);
        erc721.transferFrom(bob, alice, 1);

        vm.prank(bob);
        erc1155.safeTransferFrom(bob, alice, 1, 50, "");

        vm.prank(alice);
        bob.send(0.5 ether);

        balances.checkBalances();
    }

    // =====================================================================//
    //                            NATIVE TESTS                              //
    // =====================================================================//

    function testNativeInsufficientBalance() external {
        vm.expectRevert(stdError.arithmeticError);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.NATIVE,
                    address(0),
                    0,
                    alice.balance + 1,
                    payable(bob)
                )
            })
        );
    }

    function testNativeExtraBalance() external {
        vm.deal(alice, 0.5 ether);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.NATIVE,
                    address(0),
                    0,
                    0.5 ether,
                    payable(bob)
                )
            })
        );
        vm.deal(bob, 0.5 ether);
        vm.expectRevert("ExpectedBalances: Native balance does not match");
        balances.checkBalances();
    }

    function testNativeNotTransferred() external {
        vm.deal(alice, 0.5 ether);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.NATIVE,
                    address(0),
                    0,
                    0.5 ether,
                    payable(bob)
                )
            })
        );
        vm.expectRevert("ExpectedBalances: Native balance does not match");
        balances.checkBalances();
    }

    // =====================================================================//
    //                             ERC20 TESTS                              //
    // =====================================================================//

    function testERC20InsufficientBalance() external {
        vm.expectRevert(stdError.arithmeticError);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC20,
                    address(erc20),
                    0,
                    200,
                    payable(bob)
                )
            })
        );
    }

    function testERC20ExtraBalance() external {
        erc20.mint(alice, 10);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC20,
                    address(erc20),
                    0,
                    5,
                    payable(bob)
                )
            })
        );
        vm.prank(alice);
        erc20.transfer(bob, 5);
        erc20.mint(alice, 1);
        vm.expectRevert("ExpectedBalances: Token balance does not match");
        balances.checkBalances();
    }

    function testERC20NotTransferred() external {
        erc20.mint(alice, 10);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC20,
                    address(erc20),
                    0,
                    5,
                    payable(bob)
                )
            })
        );
        vm.expectRevert("ExpectedBalances: Token balance does not match");
        balances.checkBalances();
    }

    function testERC20MultipleSenders() external {
        erc20.mint(alice, 100);
        erc20.mint(bob, 200);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC20,
                    address(erc20),
                    0,
                    50,
                    payable(bob)
                )
            })
        );
        balances.addTransfer(
            Execution({
                offerer: bob,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC20,
                    address(erc20),
                    0,
                    50,
                    payable(alice)
                )
            })
        );
        balances.checkBalances();
    }

    // =====================================================================//
    //                            ERC721 TESTS                              //
    // =====================================================================//

    function testERC721InsufficientBalance() external {
        erc721.mint(bob, 1);
        vm.expectRevert("ExpectedBalances: sender does not own token");
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC721,
                    address(erc721),
                    1,
                    1,
                    payable(bob)
                )
            })
        );
    }

    function testERC721ExtraBalance() external {
        erc721.mint(alice, 1);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC721,
                    address(erc721),
                    1,
                    1,
                    payable(bob)
                )
            })
        );
        erc721.mint(alice, 2);
        vm.expectRevert(
            "ExpectedBalances: account has more than expected # of tokens"
        );
        balances.checkBalances();
    }

    function testERC721NotTransferred() external {
        erc721.mint(alice, 1);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC721,
                    address(erc721),
                    1,
                    1,
                    payable(bob)
                )
            })
        );
        erc721.mint(bob, 2);
        vm.prank(alice);
        erc721.transferFrom(alice, address(1000), 1);
        vm.expectRevert(
            "ExpectedBalances: account does not own expected token"
        );
        balances.checkBalances();
    }

    function testERC721MultipleIdentifiers() external {
        erc721.mint(alice, 1);
        erc721.mint(alice, 2);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC721,
                    address(erc721),
                    1,
                    1,
                    payable(bob)
                )
            })
        );
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC721,
                    address(erc721),
                    2,
                    1,
                    payable(bob)
                )
            })
        );
        vm.prank(alice);
        erc721.transferFrom(alice, bob, 1);
        vm.prank(alice);
        erc721.transferFrom(alice, bob, 2);
        balances.checkBalances();
    }

    // =====================================================================//
    //                            ERC1155 TESTS                             //
    // =====================================================================//

    function testERC1155InsufficientBalance() external {
        vm.expectRevert(stdError.arithmeticError);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC20,
                    address(erc20),
                    0,
                    200,
                    payable(bob)
                )
            })
        );
    }

    function testERC1155ExtraBalance() external {
        erc1155.mint(alice, 1, 10);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC1155,
                    address(erc1155),
                    1,
                    5,
                    payable(bob)
                )
            })
        );
        vm.prank(alice);
        erc1155.safeTransferFrom(alice, bob, 1, 5, "");
        erc1155.mint(alice, 1, 1);
        vm.expectRevert(
            "ExpectedBalances: account does not own expected balance for id"
        );
        balances.checkBalances();
    }

    function testERC1155NotTransferred() external {
        erc1155.mint(alice, 1, 10);
        balances.addTransfer(
            Execution({
                offerer: alice,
                conduitKey: bytes32(0),
                item: ReceivedItem(
                    ItemType.ERC1155,
                    address(erc1155),
                    1,
                    5,
                    payable(bob)
                )
            })
        );
        vm.expectRevert(
            "ExpectedBalances: account does not own expected balance for id"
        );
        balances.checkBalances();
    }

    /**
     * @dev deploy test token contracts
     */
    function _deployTestTokenContracts() internal {
        createErc20Token();
        createErc721Token();
        createErc1155Token();
    }

    function createErc20Token() internal {
        TestERC20 token = new TestERC20();
        erc20 = token;
        vm.label(address(token), string(abi.encodePacked("ERC20")));
    }

    function createErc721Token() internal {
        TestERC721 token = new TestERC721();
        erc721 = token;
        vm.label(address(token), string(abi.encodePacked("ERC721")));
    }

    function createErc1155Token() internal {
        TestERC1155 token = new TestERC1155();
        erc1155 = token;
        vm.label(address(token), string(abi.encodePacked("ERC1155")));
    }
}
