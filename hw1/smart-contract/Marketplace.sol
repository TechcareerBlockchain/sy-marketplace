// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

contract Marketplace {
    struct Item {
        uint256 id;
        string name;
        uint256 price;
        address payable owner;
    }

    struct Store {
        uint256 id;
        address storeOwner;
        mapping(uint256 => Item) items;
        uint256 itemQuantity;
    }

    mapping(uint256 => Store) public stores;
    uint256 public storeCount;

    mapping(address => uint256) public balances;
    mapping(uint256 => mapping(address => bool)) public itemOwners;

    event ItemAdded(
        uint256 storeId,
        uint256 itemId,
        string itemName,
        uint256 price,
        address owner
    );
    event ItemPurchased(
        uint256 storeId,
        uint256 itemId,
        string itemName,
        uint256 price,
        address buyer
    );

    function createNewStore() external {
        storeCount++;
        Store storage newStore = stores[storeCount];
        newStore.id = storeCount;
        newStore.storeOwner = msg.sender;
        newStore.itemQuantity = 0;
    }

    function addItem(
        uint256 storeId,
        string memory itemName,
        uint256 price
    ) external {
        require(
            stores[storeId].storeOwner == msg.sender,
            "Oops! You're not the store owner. Only the owner can add items."
        );

        stores[storeId].itemQuantity++;
        uint256 itemId = stores[storeId].itemQuantity;
        stores[storeId].items[itemId] = Item(
            itemId,
            itemName,
            price,
            payable(msg.sender)
        );
        itemOwners[storeId][msg.sender] = true;

        emit ItemAdded(storeId, itemId, itemName, price, msg.sender);
    }

    function viewStoreItems(
        uint256 storeId
    ) external view returns (Item[] memory) {
        require(
            storeId <= storeCount && storeId > 0,
            "Aw, snap! We searched high and low, but couldn't find the store you're looking for."
        );

        Store storage store = stores[storeId];
        Item[] memory items = new Item[](store.itemQuantity);
        for (uint256 i = 1; i <= store.itemQuantity; i++) {
            items[i - 1] = store.items[i];
        }
        return items;
    }

    function purchaseItem(uint256 storeId, uint256 itemId) external payable {
        require(
            storeId <= storeCount && storeId > 0,
            "Aw, snap! We searched high and low, but couldn't find the store you're looking for."
        );

        Item storage item = stores[storeId].items[itemId];
        require(
            item.owner != address(0),
            "Uh-oh! This item seems to have vanished into thin air. Couldn't find it anywhere."
        );
        require(
            msg.value >= item.price,
            "Oops! Not enough ether sent to purchase this amazing item. Please send more!"
        );
        require(
            !itemOwners[storeId][msg.sender],
            "Oops! You already own this item. No need to buy it again!"
        );

        item.owner.transfer(item.price);
        balances[item.owner] += item.price;
        itemOwners[storeId][msg.sender] = true;
        item.owner = payable(msg.sender);

        emit ItemPurchased(storeId, itemId, item.name, item.price, msg.sender);
    }
}
