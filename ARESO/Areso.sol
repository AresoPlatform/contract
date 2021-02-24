pragma solidity ^0.5.0;

import "./ERC20.sol";
import "./ERC20Detailed.sol";


contract Areso is ERC20, ERC20Detailed {

    constructor() public ERC20Detailed("ARESO", "ASO", 6){
        _mint(msg.sender, 48000000 * (10**uint256(decimals())));
    }

}