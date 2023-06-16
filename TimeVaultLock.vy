# @version ^0.3.9

# Importing required interfaces
from vyper.interfaces import ERC20
from vyper.interfaces import ERC20Detailed

# Implementing ERC20 and ERC20Detailed interfaces
implements: ERC20
implements: ERC20Detailed

# Transfer event
event Transfer:
    sender: indexed(address)
    receiver: indexed(address)
    value: uint256

# Approval event
event Approval:
    owner: indexed(address)
    spender: indexed(address)
    value: uint256

# Public state variables
name: public(String[64])
symbol: public(String[32])
decimals: public(uint8)

# Balances mapping
balanceOf: public(HashMap[address, uint256])

# Allowance mapping
allowance: public(HashMap[address, HashMap[address, uint256]])

# Total supply
totalSupply: public(uint256)

# Deposit time mapping
depositTime: public(HashMap[address, uint256])

# Initialize the contract
@external
def __init__():
    self.name = "Wrapped WEI"  
    self.symbol = "WEI"  
    self.decimals = 18

# Transfer tokens from the sender to the specified recipient
@external
def transfer(_to : address, _value : uint256) -> bool:
    self.balanceOf[msg.sender] -= _value  # Deduct tokens from the sender
    self.balanceOf[_to] += _value  # Add tokens to the recipient
    log Transfer(msg.sender, _to, _value)  # Emit the Transfer event
    return True

# Transfer tokens from a specified account to another account
@external
def transferFrom(_from : address, _to : address, _value : uint256) -> bool:
    self.balanceOf[_from] -= _value
    self.balanceOf[_to] += _value
    self.allowance[_from][msg.sender] -= _value
    log Transfer(_from, _to, _value)
    return True

# Approve the specified spender to spend the specified amount of tokens on behalf of the sender
@external
def approve(_spender : address, _value : uint256) -> bool:
    self.allowance[msg.sender][_spender] = _value
    log Approval(msg.sender, _spender, _value)
    return True

# Internal function to mint new tokens
@internal
def mint(_to: address, _value: uint256):
    assert _to != ZERO_ADDRESS  # Ensure the recipient address is not the zero address
    self.totalSupply += _value
    self.balanceOf[_to] += _value
    log Transfer(ZERO_ADDRESS, _to, _value)

# Internal function to burn tokens
@internal
def _burn(_address: address, _value: uint256):
    assert _address != ZERO_ADDRESS  # Ensure the address is not the zero address
    self.totalSupply -= _value
    self.balanceOf[_address] -= _value
    log Transfer(_address, ZERO_ADDRESS, _value)

# Burn tokens from the sender's account
@external
def burn(_value: uint256):
    self._burn(msg.sender, _value)

# Custom methods to deposit and withdraw

# Deposit ETH into the contract
@payable
@external
def deposit():
    if msg.value != 1:  # Ensure the deposited value is 1 wei
        raise "Invalid Deposit"
    if self.depositTime[msg.sender] != 0:  # Check if there is an existing deposit
        raise "Existing Deposit"

    self.depositTime[msg.sender] = block.timestamp  # Record the deposit time

# Withdraw deposited tokens from the contract
@external
def withdraw():
    if self.depositTime[msg.sender] == 0:  # Check if there is no existing deposit
        raise "Empty Deposit"

    lockedTime: uint256 = block.timestamp - self.depositTime[msg.sender]  # Calculate the locked time
    self.depositTime[msg.sender] = 0  # Reset the deposit time=
    self.mint(msg.sender, lockedTime)  # Mint tokens for the locked time

    send(msg.sender, 1)  # Transfer 1 wei to the sender