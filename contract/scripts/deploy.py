from brownie import HardcoreBank
from brownie import accounts


def main():
    # erc1820
    account = accounts.load('deployment_account')
    account.transfer('0xa990077c3205cbDf861e17Fa532eeB069cE9fF96', 0.08e18)

    # deploy
    hb = HardcoreBank.deploy({'from': account})

    print(f'Deployed at {hb}')
