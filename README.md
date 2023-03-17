# english-auction

This smart contract lets the deployer (seller) sell one NFT in an english auction style auction. The seller sets the NFT address and its id, with his desired starting price.

The seller then must call the function `startAuction()` and specify the duration of the auction (e.g. 7 days).

Bidders can then bid using the function `bid()` and specifying the amount of ETH they want to bid. Bidders can anytime withdraw their bid if they were outbid by other bidders using the `withdraw()` function.

Once the auction is over bids are halted and anyone can call the `endAuction()` function to end the auction. By calling the `endAuction()` function the NFT is transferred to the address with the highest bid and the amount highest bid is transferred to the seller. If no bids were made the NFT is transferred back to the seller (original owner).

## What is an English Auction

An English Auction starts by an auctioneer or seller announcing the suggested opening bid or reserve price for the item on sale. The buyers with interest in the item start placing bids on the item on sale. The buyer with the highest bid at any time is considered the one with a standing bid, which can only be displaced by a higher bid from the floor. If there are no higher bids than the standing bid, the auctioneer announces the winner, and the item is sold to the person with the standing bid at a price equal to their bid. If the reserve price is not met or no buyer places an economically fair bid, the seller can take the item off the market.
