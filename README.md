# hardcore-bank

貯金を頑張っていきたいという機運があるので, 僕にちゃんと動機づけをしてくれる貯金箱を錬成する.

## status

他ブランチで開発中

## build

```sh
pipenv install
pipenv shell
brownie pm install OpenZeppelin/openzeppelin-contracts@4.4.1
brownie pm install kekeho/BokkyPooBahsDateTimeLibrary@1.02
```

## deploy

```sh
brownie run deploy
```

## testnet

`0xe47CC0a714e363B3765C8c4b0125C6Af3f7e6DfF` on Ropsten
