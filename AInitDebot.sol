pragma ton-solidity >=0.35.0;
pragma AbiHeader expire;
pragma AbiHeader time;
pragma AbiHeader pubkey;

import "base/Debot.sol";
import "base/Terminal.sol";
import "base/AddressInput.sol";
import "base/Menu.sol";
import "base/Upgradable.sol";
import "base/Sdk.sol";

import "interfaces.sol";
import "structs.sol";

abstract contract AInitDebot is Debot, Upgradable {

    bytes m_icon;

    TvmCell m_purchaseListStateInit;
    address m_address;  
    PurchaseStats m_purchaseStats;
    uint256 m_masterPubKey; 
    address m_msigAddress;  

    uint32 INITIAL_BALANCE =  200000000;

    function start() public override {
        Terminal.input(tvm.functionId(savePublicKey),"Введите публичный ключ",false);
    }
    
    function setShoppingListStateInit(TvmCell code, TvmCell data) public {
        require(msg.pubkey() == tvm.pubkey(), 101);
        tvm.accept();
        m_purchaseListStateInit = tvm.buildStateInit(code, data);
    }

    function savePublicKey(string value) public {
        (uint res, bool status) = stoi("0x"+value);
        if (status) {
            m_masterPubKey = res;

            Terminal.print(0, "Проверяем существование списка покупок ... ");
            TvmCell deployState = tvm.insertPubkey(m_purchaseListStateInit, m_masterPubKey);
            m_address = address.makeAddrStd(0, tvm.hash(deployState));

            Terminal.print(0, format( "Ваш список покупок находится по адресу {}", m_address));
            Sdk.getAccountType(tvm.functionId(checkStatus), m_address);

        } else {
            Terminal.input(tvm.functionId(savePublicKey),"Что-то пошло не так, попробуйте снова!\nВведите публичный ключ:", false);
        }
    }

    function checkStatus(int8 acc_type) public {
        if (acc_type == 1) { 
            _getStat(tvm.functionId(setStat));

        } else if (acc_type == -1)  { 
            Terminal.print(0, "У Вас еще нет списка покупок, вы можете создать его за 0.2 тона");
            AddressInput.get(tvm.functionId(creditAccount),"Выберите кошелек и подпишите транзакции");

        } else  if (acc_type == 0) { 
            Terminal.print(0, format("Деплоим контракт, если произойдет ошибка, проверти баланс."));
            deploy();

        } else if (acc_type == 2) {  
            Terminal.print(0, format("Аккаунт {} заморожен", m_address));
        }
    }

    function creditAccount(address value) public {
        m_msigAddress = value;
        optional(uint256) pubkey = 0;
        TvmCell empty;
        ITransactable(m_msigAddress).sendTransaction{
            abiVer: 2,
            extMsg: true,
            sign: true,
            pubkey: pubkey,
            time: uint64(now),
            expire: 0,
            callbackId: tvm.functionId(waitBeforeDeploy),
            onErrorId: tvm.functionId(onErrorRepeatCredit) 
        }(m_address, INITIAL_BALANCE, false, 3, empty);
    }

    function onErrorRepeatCredit(uint32 sdkError, uint32 exitCode) public {
        creditAccount(m_msigAddress);
    }
    function waitBeforeDeploy() public  {
        Sdk.getAccountType(tvm.functionId(checkIfStatusIs0), m_address);
    }

    function checkIfStatusIs0(int8 acc_type) public {
        if (acc_type ==  0) {
            deploy();
        } else {
            waitBeforeDeploy();
        }
    }

    function deploy() private view {
            TvmCell image = tvm.insertPubkey(m_purchaseListStateInit, m_masterPubKey);
            optional(uint256) none;
            TvmCell deployMsg = tvm.buildExtMsg({
                abiVer: 2,
                dest: m_address,
                callbackId: tvm.functionId(onSuccess),
                onErrorId:  tvm.functionId(onErrorRepeatDeploy),
                time: 0,
                expire: 0,
                sign: true,
                pubkey: none,
                stateInit: image,
                call: {HasConstructorWithPubKey, m_masterPubKey}
            });
            tvm.sendrawmsg(deployMsg, 1);
    }
    function onErrorRepeatDeploy(uint32 sdkError, uint32 exitCode) public view {
        deploy();
    }

    function onError(uint32 sdkError, uint32 exitCode) public {
        Terminal.print(0, format("Operation failed. sdkError {}, exitCode {}", sdkError, exitCode));
        _menu();
    }
    function onSuccess() public view {
        _getStat(tvm.functionId(setStat));
    }

    function _getStat(uint32 answerId) internal view {
        optional(uint256) none;
        IShoppingList(m_address).getPurchaseStats{
            abiVer: 2,
            extMsg: true,
            sign: false,
            pubkey: none,
            time: uint64(now),
            expire: 0,
            callbackId: answerId,
            onErrorId: 0
        }();
    }

    function setStat(PurchaseStats purchaseStats) public {
        m_purchaseStats = purchaseStats;
        _menu();
    }

    function _menu() virtual internal;

     /// @notice Returns Metadata about DeBot.
    function getDebotInfo() public functionID(0xDEB) override view returns(
        string name, string version, string publisher, string key, string author,
        address support, string hello, string language, string dabi, bytes icon
    ) {
        name = "Shopping List DeBot";
        version = "0.2.0";
        publisher = "Gurov Andrey";
        key = "Shopping list manager";
        author = "Gurov Andrey";
        support = address.makeAddrStd(0, 0x66e01d6df5a8d7677d9ab2daf7f258f1e2a7fe73da5320300395f99e01dc3b5f); //вставил случайный адрес который был сохранен
        hello = "Hi, i'm a Shopping List DeBot.";
        language = "ru";
        dabi = m_debotAbi.get();
        icon = m_icon;
    }

    function getRequiredInterfaces() public view override returns (uint256[] interfaces) {
        return [ Terminal.ID, Menu.ID, AddressInput.ID];
    }

    function onCodeUpgrade() internal override {
        tvm.resetStorage();
    }
}