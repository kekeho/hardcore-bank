from brownie import accounts
from brownie import HardcoreBank

import testlib


def test_init_owner(deploy_erc1820_register):
    c = HardcoreBank.deploy({'from': accounts[0]})

    # owner check
    assert c.isOwner({'from': accounts[0]}) == True
    assert c.isOwner({'from': accounts[1]}) == False
 
def test_init_registory(deploy_erc1820_register):
    c = HardcoreBank.deploy({'from': accounts[0]})

    # registory check
    register = testlib.get_deployed_contract()
    keccak256_erc777tokensrecipient = '0xb281fc8c12954d22544db45de3159a39272895b169a852b314f9cc762e44c53b'
    assert c.address == register.functions.getInterfaceImplementer(c.address, keccak256_erc777tokensrecipient).call()
