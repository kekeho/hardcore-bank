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

`0xA1174cA95E9B7cbA9c4cDD89f5Af2d077b18761d` on Ropsten
