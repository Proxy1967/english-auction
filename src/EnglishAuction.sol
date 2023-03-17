// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

interface IERC721 {
    function transferFrom(address _from, address _to, uint256 _nftId) external;
}

contract EnglishAuction {
    event AuctionStarted();
    event Bid(address indexed bidder, uint256 indexed amount);
    event Withdraw(address indexed bidder, uint256 indexed amount);
    event AuctionEnded(
        address indexed highestBidder,
        uint256 indexed highestBid
    );

    IERC721 public immutable nft;
    uint256 public immutable nftId;

    address payable public immutable seller;

    uint32 public endAt;
    bool public started;
    bool public ended;

    address public highestBidder;
    uint256 public highestBid;
    mapping(address => uint256) public bids;

    constructor(address _nft, uint256 _nftId, uint256 _startingBid) {
        nft = IERC721(_nft);
        nftId = _nftId;
        seller = payable(msg.sender);
        highestBid = _startingBid;
    }

    function startAuction(uint32 _auctionDuration) external {
        require(msg.sender == seller, "not seller");
        require(!started, "started");

        started = true;
        endAt = uint32(block.timestamp + _auctionDuration);

        nft.transferFrom(seller, address(this), nftId);

        emit AuctionStarted();
    }

    function bid() external payable {
        require(started, "not started");
        require(block.timestamp < endAt, "auction ended");
        require(msg.value > highestBid, "value < highest bid");

        // to keep track of total amount of ETH a user has bid
        // which is no longer the highest bid
        // used later for 'withdraw()'
        if (highestBidder != address(0)) {
            bids[highestBidder] += highestBid;
        }

        highestBid = msg.value;
        highestBidder = msg.sender;

        emit Bid(msg.sender, msg.value);
    }

    function withdraw() external {
        uint256 balance = bids[msg.sender];
        bids[msg.sender] = 0;

        (bool success, ) = msg.sender.call{value: balance}("");
        require(success, "withdraw failed");

        emit Withdraw(msg.sender, balance);
    }

    function endAuction() external {
        require(started, "not started");
        require(!ended, "ended");
        require(block.timestamp >= endAt, "not ended");

        ended = true;

        if (highestBidder != address(0)) {
            nft.transferFrom(address(this), highestBidder, nftId);
            (bool success, ) = seller.call{value: highestBid}("");
            require(success, "transfer failed");
        } else {
            nft.transferFrom(address(this), seller, nftId);
        }

        emit AuctionEnded(highestBidder, highestBid);
    }
}
