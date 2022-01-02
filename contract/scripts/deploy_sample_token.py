from brownie import accounts
from brownie import SampleToken


def main():
    account = accounts.load('deployment_account')
    st = SampleToken.deploy({'from': account})

    print(f'Deployed at {st}')
