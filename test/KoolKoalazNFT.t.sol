// SPDX-License-Identifier: AGPL-3.0-only
pragma solidity 0.8.15;

import "../src/KoolKoalazNFT.sol";
import "forge-std/Test.sol";

contract KoolKoalazNFTTest is Test {
    address alice = address(1);
    KoolKoalazNFT nft;

    function setUp() public {
        nft = new KoolKoalazNFT();

        vm.label(address(this), "Owner");
        vm.label(nft.revenueTreasury(), "RevenueTreasury");
        vm.label(nft.premintTreasury(), "PremintTreasury");
        vm.label(alice, "Alice");
        vm.label(address(nft), "NFT");

        _startMint();
    }

    function _startMint() private {
        vm.warp(nft.mintStartTimestamp() + 1);
    }

    function testDeployment() public {
        assertEq(nft.balanceOf(nft.premintTreasury()), 150);
        assertEq(nft.totalSupply(), 150);
        assertEq(nft.softCapSupply(), 1111);
    }

    function testMintWithExactPayment() public {
        vm.deal(alice, 0.5 ether);
        vm.prank(alice);
        nft.mint{value: 0.5 ether}(1);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.revenueTreasury().balance, 0.5 ether);
        assertEq(alice.balance, 0);

        vm.deal(alice, 0.4 ether);
        nft.addWhitelistSpots(alice, 1);
        vm.prank(alice);
        nft.mint{value: 0.4 ether}(1);
        assertEq(nft.balanceOf(alice), 2);
        assertEq(nft.whitelistSpots(alice), 0);
        assertEq(nft.revenueTreasury().balance, 0.9 ether);
        assertEq(alice.balance, 0);

        vm.deal(alice, 1.8 ether);
        nft.addWhitelistSpots(alice, 2);
        vm.prank(alice);
        nft.mint{value: 1.8 ether}(4);
        assertEq(nft.balanceOf(alice), 6);
        assertEq(nft.whitelistSpots(alice), 0);
        assertEq(nft.revenueTreasury().balance, 2.7 ether);
        assertEq(alice.balance, 0);

        vm.deal(alice, 2 ether);
        nft.addWhitelistSpots(alice, 10);
        vm.prank(alice);
        nft.mint{value: 2 ether}(5);
        assertEq(nft.balanceOf(alice), 11);
        assertEq(nft.whitelistSpots(alice), 5);
        assertEq(nft.revenueTreasury().balance, 4.7 ether);
        assertEq(alice.balance, 0);
    }

    function testMintWithExcessPayment() public {
        vm.deal(alice, 2 ether);
        vm.prank(alice);
        nft.mint{value: 2 ether}(2);
        assertEq(nft.balanceOf(alice), 2);
        assertEq(nft.revenueTreasury().balance, 1 ether);
        assertEq(alice.balance, 1 ether);

        nft.addWhitelistSpots(alice, 2);
        vm.prank(alice);
        nft.mint{value: 1 ether}(2);
        assertEq(nft.balanceOf(alice), 4);
        assertEq(nft.whitelistSpots(alice), 0);
        assertEq(nft.revenueTreasury().balance, 1.8 ether);
        assertEq(alice.balance, 0.2 ether);

        vm.deal(alice, 2 ether);
        nft.addWhitelistSpots(alice, 2);
        vm.prank(alice);
        nft.mint{value: 2 ether}(4);
        assertEq(nft.balanceOf(alice), 8);
        assertEq(nft.whitelistSpots(alice), 0);
        assertEq(nft.revenueTreasury().balance, 3.6 ether);
        assertEq(alice.balance, 0.2 ether);
    }

    function testMintWithInsufficientPayment() public {
        nft.addWhitelistSpots(alice, 1);
        vm.prank(alice);
        vm.expectRevert(MintPriceNotPaid.selector);
        nft.mint(1);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.revenueTreasury().balance, 0);
        assertEq(alice.balance, 0);
        assertEq(nft.whitelistSpots(alice), 1);

        vm.deal(alice, 0.5 ether);
        vm.prank(alice);
        vm.expectRevert(MintPriceNotPaid.selector);
        nft.mint(2);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.revenueTreasury().balance, 0);
        assertEq(alice.balance, 0.5 ether);

        nft.addWhitelistSpots(alice, 1);
        vm.prank(alice);
        vm.expectRevert(MintPriceNotPaid.selector);
        nft.mint(2);
        assertEq(nft.balanceOf(alice), 0);
        assertEq(nft.revenueTreasury().balance, 0);
        assertEq(alice.balance, 0.5 ether);
        assertEq(nft.whitelistSpots(alice), 2);
    }

    function testMintWithSoftCapSupplyReached() public {
        uint256 mintableSupply = 1111 - 150;
        vm.deal(alice, mintableSupply * 0.5 ether);
        vm.prank(alice);
        vm.expectRevert(SoftCapSupplyReached.selector);
        nft.mint{value: alice.balance}(mintableSupply + 1);
    }

    function testIncreaseSoftCapSupply() public {
        nft.increaseSoftCapSupply(2222, 500);
        assertEq(nft.softCapSupply(), 3333);
        assertEq(nft.balanceOf(nft.premintTreasury()), 650);

        vm.expectRevert(MaxSupplyReached.selector);
        nft.increaseSoftCapSupply(4444, 666);
    }

    function testSetMintPrice() public {
        nft.setMintPrice(1 ether);
        assertEq(nft.mintPrice(), 1 ether);

        vm.deal(alice, 1 ether);
        vm.prank(alice);
        nft.mint{value: 1 ether}(1);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.revenueTreasury().balance, 1 ether);
        assertEq(alice.balance, 0);
    }

    function testSetWhitelistMintPrice() public {
        nft.setWhitelistMintPrice(1 ether);
        assertEq(nft.whitelistMintPrice(), 1 ether);

        vm.deal(alice, 1 ether);
        nft.addWhitelistSpots(alice, 1);
        vm.prank(alice);
        nft.mint{value: 1 ether}(1);
        assertEq(nft.balanceOf(alice), 1);
        assertEq(nft.revenueTreasury().balance, 1 ether);
        assertEq(alice.balance, 0);
    }

    function testSetBaseURI() public {
        string memory uri = "https://example.com/";
        string memory tokenUri = "https://example.com/0";
        nft.setBaseURI(uri);
        assertEq(
            keccak256(abi.encodePacked(nft.tokenURI(0))),
            keccak256(abi.encodePacked(tokenUri))
        );
    }

    function testSetEmptyURI() public {
        vm.expectRevert(EmptyURI.selector);
        nft.setBaseURI("");
    }

    function testSetBaseURIUnauthorized() public {
        vm.prank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.setBaseURI("https://example.com/");
    }

    function testMintingPaused() public {
        nft.pause();
        vm.deal(address(alice), 3 ether);
        vm.expectRevert("Pausable: paused");
        vm.prank(alice);
        nft.mint{value: 3 ether}(6);
        assertEq(nft.balanceOf(alice), 0);

        nft.unpause();
        vm.prank(alice);
        nft.mint{value: 0.5 ether}(1);
        assertEq(nft.balanceOf(alice), 1);
    }

    function testPauseUnpause() public {
        nft.pause();
        nft.unpause();
        vm.startPrank(alice);
        vm.expectRevert("Ownable: caller is not the owner");
        nft.pause();
        vm.expectRevert("Ownable: caller is not the owner");
        nft.unpause();
        vm.stopPrank();
    }

    function testMintingNotStarted() public {
        vm.warp(nft.mintStartTimestamp()-3600);
        vm.deal(alice, 3 ether);
        vm.expectRevert(MintingNotStartedYet.selector);
        vm.prank(alice);
        nft.mint{value: 3 ether}(6);
        assertEq(nft.balanceOf(alice), 0);
        _startMint();
        vm.prank(alice);
        nft.mint{value: 3 ether}(6);
        assertEq(nft.balanceOf(alice), 6);
    }

    function testAddWhitelistSpots() public {
        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        nft.addWhitelistSpots(alice, 1);
        assertEq(nft.whitelistSpots(alice), 0);

        nft.addWhitelistSpots(alice, 1);
        assertEq(nft.whitelistSpots(alice), 1);
    }

    function testRemoveWhitelistSpots() public {
        nft.addWhitelistSpots(alice, 42);

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        nft.removeWhitelistSpots(alice, 1);
        assertEq(nft.whitelistSpots(alice), 42);

        vm.expectRevert(NotEnoughWhitelistSpots.selector);
        nft.removeWhitelistSpots(alice, 43);
        assertEq(nft.whitelistSpots(alice), 42);

        nft.removeWhitelistSpots(alice, 11);
        assertEq(nft.whitelistSpots(alice), 31);
    }

    function testClearWhitelistSpots() public {
        nft.addWhitelistSpots(alice, 42);

        vm.expectRevert("Ownable: caller is not the owner");
        vm.prank(alice);
        nft.clearWhitelistSpots(alice);
        assertEq(nft.whitelistSpots(alice), 42);

        nft.clearWhitelistSpots(alice);
        assertEq(nft.whitelistSpots(alice), 0);
    }

    function testRoyalty() public {
        (address receiver, uint256 amount) = nft.royaltyInfo(0, 100);
        assertEq(receiver, nft.revenueTreasury());
        assertEq(amount, 10);

        (receiver, amount) = nft.royaltyInfo(1, 0);
        assertEq(receiver, nft.revenueTreasury());
        assertEq(amount, 0);

        (receiver, amount) = nft.royaltyInfo(nft.maxSupply() - 1, 123456);
        assertEq(receiver, nft.revenueTreasury());
        assertEq(amount, 12345);
    }
}
