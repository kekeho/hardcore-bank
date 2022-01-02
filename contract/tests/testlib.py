from brownie import web3
import requests


erc1820_register = '0x1820a4B7618BdE71Dce8cdc73aAB6C95905faD24'

def get_deployed_contract():
    erc1820abi = '[{"constant":false,"inputs":[{"name":"_addr","type":"address"},{"name":"_interfaceHash","type":"bytes32"},{"name":"_implementer","type":"address"}],"name":"setInterfaceImplementer","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_addr","type":"address"}],"name":"getManager","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":false,"inputs":[{"name":"_addr","type":"address"},{"name":"_newManager","type":"address"}],"name":"setManager","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_interfaceName","type":"string"}],"name":"interfaceHash","outputs":[{"name":"","type":"bytes32"}],"payable":false,"stateMutability":"pure","type":"function"},{"constant":false,"inputs":[{"name":"_contract","type":"address"},{"name":"_interfaceId","type":"bytes4"}],"name":"updateERC165Cache","outputs":[],"payable":false,"stateMutability":"nonpayable","type":"function"},{"constant":true,"inputs":[{"name":"_addr","type":"address"},{"name":"_interfaceHash","type":"bytes32"}],"name":"getInterfaceImplementer","outputs":[{"name":"","type":"address"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_contract","type":"address"},{"name":"_interfaceId","type":"bytes4"}],"name":"implementsERC165InterfaceNoCache","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"constant":true,"inputs":[{"name":"_contract","type":"address"},{"name":"_interfaceId","type":"bytes4"}],"name":"implementsERC165Interface","outputs":[{"name":"","type":"bool"}],"payable":false,"stateMutability":"view","type":"function"},{"anonymous":false,"inputs":[{"indexed":true,"name":"addr","type":"address"},{"indexed":true,"name":"interfaceHash","type":"bytes32"},{"indexed":true,"name":"implementer","type":"address"}],"name":"InterfaceImplementerSet","type":"event"},{"anonymous":false,"inputs":[{"indexed":true,"name":"addr","type":"address"},{"indexed":true,"name":"newManager","type":"address"}],"name":"ManagerChanged","type":"event"}]'
    c = web3.eth.contract(address=erc1820_register, abi=erc1820abi)
    return c


def mine(address='localhost', port=8545):
    # force mine
    mine_call = {
        "jsonrpc": "2.0",
        "method": "evm_mine",
    }
    resp = requests.post(f'http://{address}:{port}', json=mine_call)
    assert resp.status_code == 200


def increaseTime(seconds: int, address='localhost', port=8545):
    mine(address, port)

    # call evm_increaseTime
    time_call = {
        "jsonrpc": "2.0",
        "method": "evm_increaseTime",
        "params": [seconds,]
    }
    resp = requests.post(f'http://{address}:{port}', json=time_call)
    assert resp.status_code == 200

    mine()
