pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "base/Terminal.sol";
import "base/Menu.sol";
import "interfaces.sol";
import "structs.sol";
import "BaseDebot.sol";

contract DebotForAddPurchase is BaseDebot {
    
    string private namePurchase;

    function _menu() internal override {
        string sep = '----------------------------------------';
        Menu.select(
            format(
                "У Вас {} неоплаченных товаров, {} оплаченных товаров, Всего оплаченно на сумму {}",
                    m_purchaseStats.unpurchasedCount,
                    m_purchaseStats.purchasedCount,
                    m_purchaseStats.amount
            ),
            sep,
            [
                MenuItem("Добавить продукт","",tvm.functionId(addPurchase)),
                MenuItem("Показать список продуктов","",tvm.functionId(showPurchases)),
                MenuItem("Удалить продукт","",tvm.functionId(deletePurchase))
            ]
        );
    }

    function addPurchase(uint32 index) public {
        Terminal.input(tvm.functionId(addPurchase_), "Введите название товара:", false);
    }

    function addPurchase_(string value) public {
        namePurchase = value;
        Terminal.input(tvm.functionId(addPurchase__), "Введите количество товара:", false);
    }

    function addPurchase__(string value) public  {
        (uint count, bool status) = stoi(value);
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).addPurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }( namePurchase,  count);
    }
}