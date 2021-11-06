pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "interfaces.sol";
import "structs.sol";

contract ShoppingList is HasConstructorWithPubKey, IShoppingList{

    mapping(uint => Purchase) private m_purchase;

    uint256 private m_ownerPubkey;

    uint32 private m_count = 0;

    constructor(uint256 pubkey) HasConstructorWithPubKey(pubkey) public {
        require(pubkey != 0, 120);
        tvm.accept();
        m_ownerPubkey = pubkey;
    }

    modifier onlyOwner() {
        require(msg.pubkey() == m_ownerPubkey, 101);
        _;
    }

    function addPurchase(string name, uint count) external override onlyOwner {
        tvm.accept();
        m_count++;
        m_purchase[m_count] = Purchase(
            m_count,
            name,
            count,
            now,
            false,
            0
        );
    }

    function deletePurchase(uint id) external override onlyOwner {
        require(m_purchase.exists(id), 102);
        tvm.accept();
        delete m_purchase[id];
    }

    function getPurchases() external override view returns(Purchase[] purchases){
        for ((uint id, Purchase purchase) : m_purchase){
            purchases.push(purchase);
        }
    }

    function getPurchaseStats() external override view returns(PurchaseStats purchaseStats){
        purchaseStats = PurchaseStats(0,0,0);
        
        for ((uint id, Purchase purchase) : m_purchase){
            if (purchase.isPurchased) {
                purchaseStats.purchasedCount += purchase.count;
                purchaseStats.amount += purchase.price;
            } else {
                purchaseStats.unpurchasedCount += purchase.count;
            }
        }
    }

    function buy(uint id, uint price) external override onlyOwner {
        require(m_purchase.exists(id), 102);
        tvm.accept();
        m_purchase[id].isPurchased = true;
        m_purchase[id].price = price;
    }
    
}