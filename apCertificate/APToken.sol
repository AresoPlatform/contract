pragma solidity ^0.5.0;

import "./ERC20.sol";

contract APToken is ERC20 {
    constructor () public {
        _mint(msg.sender, 10000000000 * (10 ** uint256(6)));
    }
}