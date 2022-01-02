from brownie import accounts
from brownie import HardcoreBank, SampleToken
from brownie import convert
import brownie
import testlib
import math
import time


def test_createAccount_getAccount(deploy_erc1820_register):
    c = HardcoreBank.deploy({'from': accounts[0]})

    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = '0xdAC17F958D2ee523a2206206994597C13D831ec7'
    total_amount = 1e18
    monthly = 1e5

    c.createAccount(name, description, token, total_amount, monthly, {'from': accounts[1]})
    config_list = c.getAccounts({'from': accounts[1]})

    assert len(config_list) == 1
    assert c.isOwner(0, {'from': accounts[1]})
    assert c.isOwner(0, {'from': accounts[0]}) == False

    config_head = config_list[0]

    # config check
    assert config_head[0] == accounts[1]
    assert config_head[1] == name
    assert config_head[2] == description
    assert config_head[3] == token
    assert config_head[4] == total_amount
    assert config_head[5] == monthly

    # other account
    assert len(c.getAccounts({'from': accounts[0]})) == 0


def test_createAccount_getAccount_many(deploy_erc1820_register):
    c = HardcoreBank.deploy({'from': accounts[0]})

    # many account
    name = ['hoge','fuga', 'piyo']
    description = ['hogefuga', 'fugapiyo', 'piyohoge']
    token = [
        '0x2AC170958D2ee523a225620A994597C1AD831ec9',
        '0x2AC07095892ee523a225620A994797C1AD831ec2',
        '0x2AC170958D2ee523a225600A994597C1AD831ec8',
    ]
    total_amount = [1e19, 1e17, 9e18]
    monthly = [1e6, 1e4, 1e10]

    for i, (n, d, t, a, m) in enumerate(zip(name, description, token, total_amount, monthly)):
        c.createAccount(n, d, t, a, m, {'from': accounts[0]})
        accounts_list = c.getAccounts({'from': accounts[0]})

        assert len(accounts_list) == i+1

        config_head = accounts_list[i]
        assert config_head[0] == accounts[0]
        assert config_head[1] == name[i]
        assert config_head[2] == description[i]
        assert config_head[3] == token[i]
        assert config_head[4] == total_amount[i]
        assert config_head[5] == monthly[i]


def test_disable(deploy_erc1820_register):
    c = HardcoreBank.deploy({'from': accounts[0]})

    # many account
    name = ['hoge','fuga', 'piyo']
    description = ['hogefuga', 'fugapiyo', 'piyohoge']
    token = [
        '0x2AC170958D2ee523a225620A994597C1AD831ec9',
        '0x2AC07095892ee523a225620A994797C1AD831ec2',
        '0x2AC170958D2ee523a225600A994597C1AD831ec8',
    ]
    total_amount = [1e19, 1e17, 9e18]
    monthly = [1e6, 1e4, 1e10]

    # create accounts
    for (n, d, t, a, m) in zip(name, description, token, total_amount, monthly):
        c.createAccount(n, d, t, a, m, {'from': accounts[0]})
    accounts_list = c.getAccounts({'from': accounts[0]})
    assert len(accounts_list) == 3

    # disable
    c.disable(1, {'from': accounts[0]})

    # get accounts
    accounts_list = c.getAccounts({'from': accounts[0]})
    assert len(accounts_list) == 2
    assert name[1] not in [a[1] for a in accounts_list]


def test_tokenReceived(deploy_erc1820_register):
    st = SampleToken.deploy({'from': accounts[0]})
    c = HardcoreBank.deploy({'from': accounts[0]})

    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = st.address
    total_amount = 1e18
    monthly = 1e5

    c.createAccount(name, description, token, total_amount, monthly, {'from': accounts[1]})

    id = 0
    amount = 1e10
    st.send(c.address, amount, convert.to_bytes(id), {'from': accounts[0]})

    recv = c.tokensRecvList(id, {'from': accounts[1]})[0]
    assert recv[0] == accounts[0]
    assert recv[1] == amount


def test_tokenReceived_fail(deploy_erc1820_register):
    st = SampleToken.deploy({'from': accounts[0]})
    c = HardcoreBank.deploy({'from': accounts[0]})

    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = st.address
    total_amount = 1e18
    monthly = 1e5

    c.createAccount(name, description, token, total_amount, monthly, {'from': accounts[1]})

    id = 99999  # doesn't exists
    amount = 1e10
    with brownie.reverts():
        st.send(c.address, amount, convert.to_bytes(id), {'from': accounts[0]})

    with brownie.reverts():
        c.tokensRecvList(id, {'from': accounts[1]})

    assert len(c.tokensRecvList(0, {'from': accounts[1]})) == 0


def test_balanceOf(deploy_erc1820_register):
    st = SampleToken.deploy({'from': accounts[0]})
    c = HardcoreBank.deploy({'from': accounts[0]})

    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = st.address
    total_amount = 1e18
    monthly = 1e5

    c.createAccount(name, description, token, total_amount, monthly, {'from': accounts[1]})

    id = 0
    amount_0 = 1e10
    st.send(c.address, amount_0, convert.to_bytes(id), {'from': accounts[0]})
    amount_1 = 1e15
    st.send(c.address, amount_1, convert.to_bytes(id), {'from': accounts[0]})

    balance = c.balanceOf(id, {'from': accounts[1]})
    assert balance == (amount_0 + amount_1)


def test_balanceOf_multi(deploy_erc1820_register):
    st = SampleToken.deploy({'from': accounts[0]})
    c = HardcoreBank.deploy({'from': accounts[0]})

    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = st.address
    total_amount = 1e18
    monthly = 1e5

    c.createAccount(name, description, token, total_amount, monthly, {'from': accounts[1]})

    id = 0
    amount_0 = 1e10
    st.send(c.address, amount_0, convert.to_bytes(id), {'from': accounts[0]})  # 1/2
    balance = c.balanceOf(id, {'from': accounts[1]})
    assert balance == amount_0

    testlib.increaseTime(60*60*24*31) # skip 31days
    amount_1 = 1e15
    st.send(c.address, amount_1, convert.to_bytes(id), {'from': accounts[0]})  # 2/3
    balance = c.balanceOf(id, {'from': accounts[1]})
    assert balance == (amount_0 + amount_1)

    testlib.increaseTime(60*60*24*31)  # skip 31days
    amount_2 = 234
    st.send(c.address, amount_2, convert.to_bytes(id), {'from': accounts[0]})  # 3/23
    testlib.mine()
    balance = c.balanceOf(id, {'from': accounts[1]})
    assert balance == (amount_0+amount_1 + amount_2)

    testlib.increaseTime(60*60*24*30)  # skip 31days
    balance = c.balanceOf(id, {'from': accounts[1]})
    assert balance == math.ceil((amount_0+amount_1+amount_2) * 0.8)

    testlib.increaseTime(60*60*24*30)  # skip 31days
    balance = c.balanceOf(id, {'from': accounts[1]})
    assert balance == math.ceil(math.ceil((amount_0+amount_1+amount_2) * 0.8) * 0.8)


def test_balanceOf_over_targetAmount(deploy_erc1820_register):
    
    st = SampleToken.deploy({'from': accounts[0]})
    c = HardcoreBank.deploy({'from': accounts[0]})

    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = st.address
    total_amount = 1e18
    monthly = 1e5

    c.createAccount(name, description, token, total_amount, monthly, {'from': accounts[1]})

    id = 0
    amount_0 = total_amount // 2
    st.send(c.address, amount_0, convert.to_bytes(id), {'from': accounts[0]})

    testlib.increaseTime(60*60*24*20)  # skip 20 days

    amount_1 = total_amount // 2
    st.send(c.address, amount_1, convert.to_bytes(id), {'from': accounts[0]})

    testlib.increaseTime(60*60*24*600)  # skip many days...
    balance = c.balanceOf(id, {'from': accounts[1]})
    assert balance == amount_0 + amount_1


def test_collectedAmount(deploy_erc1820_register):
    st_1 = SampleToken.deploy({'from': accounts[0]})
    st_2 = SampleToken.deploy({'from': accounts[0]})

    c = HardcoreBank.deploy({'from': accounts[0]})
    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = st_1.address
    total_amount = 1e18
    monthly = 1e5
    c.createAccount(name, description, token, total_amount, monthly, {'from': accounts[1]})
    st_1.send(c.address, 1e10, convert.to_bytes(0), {'from': accounts[0]})

    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = st_2.address
    total_amount = 1e18
    monthly = 1e5
    c.createAccount(name, description, token, total_amount, monthly, {'from': accounts[1]})
    st_2.send(c.address, 1e10, convert.to_bytes(1), {'from': accounts[0]})

    name = 'Buy House'
    description = 'Saving up to buy a house'
    token = st_2.address
    total_amount = 1e18
    monthly = 1e5
    c.createAccount(name, description, token, total_amount, monthly, {'from': accounts[1]})
    st_2.send(c.address, 1e10, convert.to_bytes(2), {'from': accounts[0]})

    # isGrandOwner check
    with brownie.reverts():
        c.collectedAmount(st_1.address, {'from': accounts[1]})
    
    assert 0 == c.collectedAmount(st_1.address, {'from': accounts[0]})
    assert 0 == c.collectedAmount(st_2.address, {'from': accounts[0]})
    
    testlib.increaseTime(60*60*24*31)  # skip 31days
    assert math.floor(1e10*0.2) == c.collectedAmount(st_1.address, {'from': accounts[0]})
    assert math.floor(1e10*0.2*2) == c.collectedAmount(st_2.address, {'from': accounts[0]})
