// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import {IERC721} from "node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ERC721Holder} from "node_modules/@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import {ReentrancyGuard} from "node_modules/@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract NFTBank is ReentrancyGuard, ERC721Holder {
    struct rentData {
        address collection;
        uint id;
        uint startDate;
    }

    struct nftData {
        address owner;
        uint rentFeePerDay;
        uint startRentFee;
    }
    mapping(address => mapping(uint => nftData)) public nfts;
    mapping(address => mapping(uint => uint)) public collectedFee;
    rentData[] public rentNFTs;

    error WrongETHValue();
    error YouAreNotOwner();

    function addNFT(address collection, uint id, uint rentFeePerDay, uint startRentFee) external {
        nfts[collection][id] = nftData({
            owner: msg.sender,
            rentFeePerDay: rentFeePerDay,
            startRentFee: startRentFee
        });
        IERC721(collection).safeTransferFrom(msg.sender, address(this), id);
    }

    function getBackNft(address collection, uint id, address payable transferFeeTo) external {
        if (msg.sender != nfts[collection][id].owner) revert YouAreNotOwner(); //NOTE - only owner can get back their NFTs
        IERC721(collection).safeTransferFrom(address(this), msg.sender, id); //NOTE - transfering the ownership of the NFT back to the original owner
        transferFeeTo.transfer(collectedFee[collection][id]); //@audit-issue transfering the collected fees to anyone owner asked.
    }

    function rent(address collection, uint id) external payable {
        IERC721(collection).safeTransferFrom(address(this), msg.sender, id);
        if (msg.value != nfts[collection][id].startRentFee)
            revert WrongETHValue();
        rentNFTs.push(rentData({
                collection: collection,
                id: id,
                startDate: block.timestamp
            })
        );
    }

    function refund(address collection, uint id) external payable nonReentrant {
        IERC721(collection).safeTransferFrom(msg.sender, address(this), id);
        rentData memory rentedNft = rentData({
            collection: address(0),
            id: 0,
            startDate: 0
        });
        for (uint i; i < rentNFTs.length; i++) {
            if (rentNFTs[i].collection == collection && rentNFTs[i].id == id) {
                rentedNft = rentNFTs[i];
            }
        }
        
        uint daysInRent = (block.timestamp - rentedNft.startDate) / 86400 > 1 // NOTE - getting the number of renting days  
            ? (block.timestamp - rentedNft.startDate) / 86400                   //NOTE - and it will mark 1 day if it's less than 1 day
            : 1;

        uint amount = daysInRent * nfts[collection][id].rentFeePerDay;
        if (msg.value != amount) revert WrongETHValue();

        uint index;
        for (uint i; i < rentNFTs.length; i++) {
            if (rentNFTs[i].collection == collection && rentNFTs[i].id == id) {
                index = i;
            }
        }
        
        collectedFee[collection][id] += amount;
        payable(msg.sender).transfer(nfts[rentNFTs[index].collection][rentNFTs[index].id].startRentFee);
        rentNFTs[index] = rentNFTs[rentNFTs.length - 1];
        rentNFTs.pop();
    }
}

