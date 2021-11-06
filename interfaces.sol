pragma ton-solidity >= 0.35.0;
pragma AbiHeader expire;
pragma AbiHeader pubkey;

import "structs.sol";

interface IShoppingList {

    function addPurchase(string name, uint count) external;
    function deletePurchase(uint id) external;
    function getPurchases() external view returns(Purchase[] purchases);
    function getPurchaseStats() external view returns(PurchaseStats purchaseStats);
    function buy(uint id, uint price) external;

}

interface ITransactable {

    function sendTransaction(address dest, uint128 value, bool bounce, uint8 flags, TvmCell payload) external;

}

//Решил не выносить один контракт в отдельный файл, но другого названия для файла не придумал, хотя надо было бы
abstract contract HasConstructorWithPubKey{

    constructor(uint256 pubkey) public {}

}