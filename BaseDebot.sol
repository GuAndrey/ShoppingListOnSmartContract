pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "base/Terminal.sol";
import "base/Menu.sol";
import "interfaces.sol";
import "structs.sol";
import "AInitDebot.sol";

contract BaseDebot is AInitDebot {
    
    function _menu() virtual internal override {
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
                MenuItem("Показать список продуктов","",tvm.functionId(showPurchases)),
                MenuItem("Удалить продукт","",tvm.functionId(deletePurchase))
            ]
        );
    }

    function showPurchases(uint32 index) public view {
        optional(uint256) none;
        IShoppingList(m_address).getPurchases{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(showPurchases_),
            onErrorId: 0
        }();
    }

    function showPurchases_( Purchase[] purchases ) public {

        if (purchases.length > 0 ) {
            Terminal.print(0, "Ваш список покупок:");

            for (uint32 i = 0; i < purchases.length; i++) {
                Purchase purchase = purchases[i];
                
                if (purchase.isPurchased) {
                    Terminal.print(0, format(
                        "{} \"{}\" в количестве {} была оплачена на сумму {}.\nВремя внесения покупки в список: {}",
                        purchase.id,
                        purchase.name, 
                        purchase.count,  
                        purchase.price,
                        purchase.timestamp)
                    );
                } else {
                    Terminal.print(0, format(
                        "{} \"{}\" в количестве {} еще не куплено.\nВремя внесения покупки в список: {}",
                        purchase.id,
                        purchase.name, 
                        purchase.count,  
                        purchase.timestamp)
                    );
                }
            }

        } else {
            Terminal.print(0, "Ваш список пуст");
        }

        _menu();
    } 

    function deletePurchase(uint32 index) public {
        if (m_purchaseStats.unpurchasedCount + m_purchaseStats.purchasedCount > 0) {
            Terminal.input(tvm.functionId(deletePurchase_), "Введите номер покупки:", false);
        } else {
            Terminal.print(0, "Список пуст");
            _menu();
        }
    }

    function deletePurchase_(string value) public view {
        (uint256 id, bool status) = stoi(value);
        optional(uint256) pubkey = 0;
        IShoppingList(m_address).deletePurchase{
                abiVer: 2,
                extMsg: true,
                sign: true,
                pubkey: pubkey,
                time: uint64(now),
                expire: 0,
                callbackId: tvm.functionId(onSuccess),
                onErrorId: tvm.functionId(onError)
            }(uint(id));
    }
}