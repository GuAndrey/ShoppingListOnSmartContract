pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "base/Terminal.sol";
import "base/Menu.sol";
import "interfaces.sol";
import "structs.sol";
import "BaseDebot.sol";

contract DebotForBuy is BaseDebot {

    uint private idPurchase;

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
                MenuItem("Купить продукт","",tvm.functionId(buy)),
                MenuItem("Показать список продуктов","",tvm.functionId(showPurchases)),
                MenuItem("Удалить продукт","",tvm.functionId(deletePurchase))
            ]
        );
    }

    function buy(uint32 index) public {
        Terminal.input(tvm.functionId(buy_), "Введите номер товара:", false);
    }

    function buy_(string value) public {
        (uint256 id, ) = stoi(value);
        idPurchase = id;
        Terminal.input(tvm.functionId(buy__), "Введите цену товара:", false);
    }

    function buy__(string value) public view {
        (uint256 price, ) = stoi(value);
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).buy{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }( uint(idPurchase),  uint(price));
    }
}