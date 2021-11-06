pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;


struct Purchase {
    uint id;
    string name;
    uint count;
    uint32 timestamp;
    bool isPurchased;
    uint price;
}

struct PurchaseStats {
    uint purchasedCount;
    uint unpurchasedCount;
    uint amount;
}

