// Elm
let app = Elm.Main.init();


// web3
const web3 = new Web3(Web3.givenProvider);


let accounts;
ethereum.request(
    {'method': 'eth_requestAccounts'}
).then(a => {
    accounts = a;
})


// init
let hardcoreBank;
fetch('/abi/HardcoreBank.json')
    .then(resp => resp.json())
    .then(abi => {
        hardcoreBank = new web3.eth.Contract(abi, '0xe47CC0a714e363B3765C8c4b0125C6Af3f7e6DfF');
    })



function createAccount(json) {
    // TODO: decimalsをjson.tokenContractAddressから取得する
    hardcoreBank.methods.createAccount(
        json.subject, json.description, json.tokenContractAddress,
        String(json.targetAmount*1e18), String(json.monthlyRemittrance*1e18),)
        .send({'from': accounts[0]})
        .then(() => { app.ports.created.send("DONE")});
}


app.ports.createAccount.subscribe(createAccount);
