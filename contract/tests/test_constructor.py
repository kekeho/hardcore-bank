from os import kill
from brownie import accounts
from brownie import HardcoreBank


def test_init():
    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = '0xdAC17F958D2ee523a2206206994597C13D831ec7'
    total_amount = 1e18
    monthly = 1e5

    c = HardcoreBank.deploy(name, description, token, total_amount, monthly, {'from': accounts[0]})
    config = c.config()

    assert config[0] == accounts[0]
    assert config[1] == name
    assert config[2] == description
    assert config[3] == token
    assert config[4] == total_amount
    assert config[5] == monthly

