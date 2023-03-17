// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import {EnglishAuction} from "../../src/EnglishAuction.sol";
import {MyNFT} from "../../src/ERC721.sol";

contract Constructors is Test {
    MyNFT public nft;
    EnglishAuction public englishAuction;

    uint256 public nftId = 1;
    uint256 public startingBid = 10 wei;

    function test_NftMintCorrectly() public {
        nft = new MyNFT();

        nft.mint(address(this), nftId);

        assertEq(nft.ownerOf(nftId), address(this));
    }

    function test_EnglishAuctionConstructor() public {
        englishAuction = new EnglishAuction(address(nft), nftId, startingBid);

        assertEq(address(englishAuction.nft()), address(nft));
        assertEq(englishAuction.nftId(), nftId);
        assertEq(englishAuction.highestBid(), startingBid);
    }
}

contract StartAuction is Test {
    address alice = vm.addr(1);

    MyNFT public nft;
    EnglishAuction public englishAuction;

    uint256 public nftId = 1;
    uint256 public startingBid = 10 wei;
    uint32 auctionDuration = 1 minutes;

    function setUp() public {
        vm.label(alice, "Alice");
        nft = new MyNFT();
        nft.mint(address(this), nftId);
        englishAuction = new EnglishAuction(address(nft), nftId, startingBid);
    }

    function startAuction() public {
        nft.approve(address(englishAuction), nftId);
        englishAuction.startAuction(auctionDuration);
    }

    function test_StartAuction() public {
        startAuction();

        assertEq(englishAuction.started(), true);
        assertEq(englishAuction.endAt(), block.timestamp + auctionDuration);
        assertEq(nft.ownerOf(nftId), address(englishAuction));
    }

    function test_RevertIfNotSeller() public {
        vm.prank(alice);
        vm.expectRevert("not seller");
        englishAuction.startAuction(auctionDuration);
    }

    function test_RevertIfAuctionAlreadyStarted() public {
        nft.approve(address(englishAuction), nftId);
        englishAuction.startAuction(auctionDuration);

        vm.expectRevert("started");
        englishAuction.startAuction(auctionDuration);
    }
}

contract Bid is Test {
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    uint256 userAmount = 1 ether;

    MyNFT public nft;
    EnglishAuction public englishAuction;
    uint32 auctionDuration = 1 minutes;

    uint256 public nftId = 1;
    uint256 public startingBid = 10 wei;

    function setUp() public {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.deal(alice, userAmount);
        vm.deal(bob, userAmount);

        nft = new MyNFT();
        nft.mint(address(this), nftId);
        englishAuction = new EnglishAuction(address(nft), nftId, startingBid);
    }

    function startAuction() public {
        nft.approve(address(englishAuction), nftId);
        englishAuction.startAuction(auctionDuration);
    }

    function testFuzz_OneBidder(uint256 amount) public {
        amount = bound(amount, startingBid + 1 wei, userAmount);
        startAuction();
        vm.prank(alice);
        englishAuction.bid{value: amount}();

        assertEq(englishAuction.highestBid(), amount);
        assertEq(englishAuction.highestBidder(), alice);
    }

    function testFuzz_TwoBidders(
        uint256 aliceBidAmount,
        uint256 bobBidAmount
    ) public {
        aliceBidAmount = bound(aliceBidAmount, startingBid + 1 wei, 0.5 ether);
        bobBidAmount = bound(bobBidAmount, 0.5 ether + 1 wei, userAmount);
        startAuction();
        vm.prank(alice);
        englishAuction.bid{value: aliceBidAmount}();

        assertEq(englishAuction.highestBid(), aliceBidAmount);
        assertEq(englishAuction.highestBidder(), alice);

        vm.prank(bob);
        englishAuction.bid{value: bobBidAmount}();

        assertEq(englishAuction.highestBid(), bobBidAmount);
        assertEq(englishAuction.highestBidder(), bob);
    }

    function test_RevertIfAuctionNotStarted() public {
        vm.prank(alice);
        vm.expectRevert("not started");
        englishAuction.bid{value: 20 wei}();
    }

    function test_RevertIfAuctionEnded() public {
        startAuction();
        vm.prank(alice);
        skip(auctionDuration + 1);
        vm.expectRevert("auction ended");
        englishAuction.bid{value: 20 wei}();
    }

    function test_RevertIfMsgValueLessThanHighestBid() public {
        startAuction();
        vm.prank(alice);
        vm.expectRevert("value < highest bid");
        englishAuction.bid{value: 5 wei}();
    }
}

contract Withdraw is Test {
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address carol = vm.addr(3);
    uint256 userAmount = 1 ether;

    MyNFT public nft;
    EnglishAuction public englishAuction;
    uint32 auctionDuration = 1 minutes;

    uint256 public nftId = 1;
    uint256 public startingBid = 10 wei;

    function setUp() public {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(carol, "Carol");
        vm.deal(alice, userAmount);
        vm.deal(bob, userAmount);
        vm.deal(carol, userAmount);

        nft = new MyNFT();
        nft.mint(address(this), nftId);
        englishAuction = new EnglishAuction(address(nft), nftId, startingBid);
    }

    function startAuction() public {
        nft.approve(address(englishAuction), nftId);
        englishAuction.startAuction(auctionDuration);
    }

    // must call 'startAuction()' before
    function threePeopleBid() public {
        uint256 aliceBidAmount = 20 wei;
        uint256 bobBidAmount = 30 wei;
        uint256 carolBidAmount = 40 wei;

        vm.prank(alice);
        englishAuction.bid{value: aliceBidAmount}();

        vm.prank(bob);
        englishAuction.bid{value: bobBidAmount}();

        vm.prank(carol);
        englishAuction.bid{value: carolBidAmount}();
    }

    function test_Withdraw() public {
        startAuction();
        threePeopleBid();

        vm.prank(alice);
        englishAuction.withdraw();
        assertEq(alice.balance, userAmount);

        vm.prank(bob);
        englishAuction.withdraw();
        assertEq(bob.balance, userAmount);
    }
}

contract EndAuction is Test {
    address alice = vm.addr(1);
    address bob = vm.addr(2);
    address carol = vm.addr(3);
    uint256 userAmount = 1 ether;

    MyNFT public nft;
    EnglishAuction public englishAuction;
    uint32 auctionDuration = 1 minutes;

    uint256 public nftId = 1;
    uint256 public startingBid = 10 wei;

    function setUp() public {
        vm.label(alice, "Alice");
        vm.label(bob, "Bob");
        vm.label(carol, "Carol");
        vm.deal(alice, userAmount);
        vm.deal(bob, userAmount);
        vm.deal(carol, userAmount);

        nft = new MyNFT();
        nft.mint(address(this), nftId);
        englishAuction = new EnglishAuction(address(nft), nftId, startingBid);
    }

    // to receive ETH from `endAuction()`
    receive() external payable {}

    function startAuction() public {
        nft.approve(address(englishAuction), nftId);
        englishAuction.startAuction(auctionDuration);
    }

    // must call 'startAuction()' before
    function threePeopleBid() public {
        uint256 aliceBidAmount = 20 wei;
        uint256 bobBidAmount = 30 wei;
        uint256 carolBidAmount = 40 wei;

        vm.prank(alice);
        englishAuction.bid{value: aliceBidAmount}();

        vm.prank(bob);
        englishAuction.bid{value: bobBidAmount}();

        vm.prank(carol);
        englishAuction.bid{value: carolBidAmount}();
    }

    function test_EndAuction() public {
        startAuction();
        skip(auctionDuration);
        englishAuction.endAuction();
    }

    function test_EndAuctionTransferNftAndEth() public {
        startAuction();
        threePeopleBid();

        skip(auctionDuration);
        englishAuction.endAuction();
    }

    function test_EndAuctionWithNoBids() public {
        startAuction();
        skip(auctionDuration);
        englishAuction.endAuction();
    }

    function test_RevertIfAuctionNotStarted() public {
        vm.expectRevert("not started");
        skip(auctionDuration);
        englishAuction.endAuction();
    }

    function test_RevertWhenCalledSecondTime() public {
        startAuction();
        skip(auctionDuration);
        englishAuction.endAuction();
        vm.expectRevert("ended");
        englishAuction.endAuction();
    }

    function test_RevertIfAuctionNotEnded() public {
        startAuction();
        vm.expectRevert("not ended");
        englishAuction.endAuction();
    }
}
