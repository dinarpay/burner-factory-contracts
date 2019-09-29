pragma solidity ^0.5.0;

import "./RelayableERC777.sol";

contract VendableToken is RelayableERC777 {

  address public vendingMachine;
  uint256 public cap;
  uint256 public expirationTime;

  mapping(address => uint256) public lastActivity;

  constructor(
      address _vendingMachine,
      string memory _name,
      string memory _symbol,
      uint256 _cap,
      uint256 _expirationTime,
      address hubAddress
    ) public RelayableERC777(_name, _symbol, new address[](0), hubAddress) {
    vendingMachine = _vendingMachine;
    cap = _cap;
    expirationTime = _expirationTime;
  }

  modifier onlyVendingMachine {
    require(msg.sender == vendingMachine);
    _;
  }

  /**
   * @dev Function to mint tokens
   * @param to The address that will receive the minted tokens.
   * @param amount The amount of tokens to mint.
   * @return A boolean that indicates if the operation was successful.
   */
  function mint(address to, uint256 amount, bytes memory data) public onlyVendingMachine returns (bool) {
    require(totalSupply().add(amount) <= cap);
    _mint(to, to, amount, data, new bytes(0));
    return true;
  }

  function withdrawFromRelay() public onlyVendingMachine returns (uint256) {
    return _withdrawFromRelay();
  }

  function canRecover(address account) public view {
    return now - lastActivity[account] > expirationTime;
  }

  function recover(address account) public onlyVendingMachine returns (uint256) {
    require(canRecover(account));
    uint256 balance = balanceOf(account);
    RelayableERC777._move(vendingMachine, account, vendingMachine, balance, new bytes(0), new bytes(0));
  }

  function _move(
    address operator,
    address from,
    address to,
    uint256 amount,
    bytes memory userData,
    bytes memory operatorData
  ) internal {
    RelayableERC777._move(operator, from, to, amount, userData, operatorData);
    lastActivity[from] = now;
  }
}