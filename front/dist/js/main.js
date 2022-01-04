// Elm
let app = Elm.Main.init();


// web3
const web3 = new Web3(Web3.givenProvider);
let accounts;
let hardcoreBank;
let erc777abi;


function createAccount(json) {
    // TODO: decimalsをjson.tokenContractAddressから取得する
    hardcoreBank.methods.createAccount(
        json.subject, json.description, json.tokenContractAddress,
        String(json.targetAmount*1e18), String(json.monthlyRemittrance*1e18),)
        .send({'from': accounts[0]})
        .then(() => { app.ports.created.send("DONE")});
}
app.ports.createAccount.subscribe(createAccount);


// type alias Account =
//     { id : BigInt.BigInt
//     , subject : String
//     , description : String
//     , contractAddress : Address
//     , tokenName : String
//     , tokenSymbol : String
//     , targetAmount : Float
//     , monthlyRemittrance : Float
//     , created : Int  -- timestamp
//     , balance : Int
//     }

function getAccounts() {
    _getAccounts();
}

async function _getAccounts() {
    let data = await hardcoreBank.methods.getAccounts().call({'from': accounts[0]})
    let result = new Array(data.length);
    for (let i = 0; i < data.length; i++) {
        const account = data[i];

        let balance = await hardcoreBank.methods.balanceOf(account[0]).call({'from': accounts[0]})

        let tokenContractAddress = account[4];
        let tokenContract = new web3.eth.Contract(erc777abi, tokenContractAddress);
        let tokenName = await tokenContract.methods.name().call();
        let tokenSymbol = await tokenContract.methods.symbol().call();
        result[i] = {
            'id': account[0],
            'subject': account[2],
            'description': account[3],
            'contractAddress': tokenContractAddress,
            'tokenName': tokenName,
            'tokenSymbol': tokenSymbol,
            'targetAmount': account[5],
            'monthlyRemittrance': account[6],
            'created': parseInt(account[7]),
            'balance': balance,
        }
    }

    app.ports.gotAccounts.send(result);
}
app.ports.getAccounts.subscribe(getAccounts);


function init() {
    _init();
}

async function _init() {
    let resp_bank = await fetch('/abi/HardcoreBank.json');
    let abi = await resp_bank.json();
    hardcoreBank = new web3.eth.Contract(abi, '0xdF65d56a30Bc2d84a03e929eC1Fc3924824429a8');

    let resp_token = await fetch('/abi/ERC777.json');
    erc777abi = await resp_token.json();

    _initWallet();
}


function _initWallet() {
    ethereum.request(
        {'method': 'eth_requestAccounts'}
    ).then(a => {
        accounts = a;
        getAccounts();
    })
}

// init
init();
