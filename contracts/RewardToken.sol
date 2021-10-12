
//SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.0;

import  "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract RewardToken is ERC20 {
    
    address owner;
    string Name = 'reward token';
    string Symbol = 'RWD';

 constructor( address _owner, uint256 initialSupply) ERC20(Name, Symbol){
        
        owner =_owner;
        _mint(owner, initialSupply);
        
    }

      modifier onlyOwner() {
            require(owner == msg.sender, 'caller is not admin'); 
            _;
      }

    function setOwner(address _owner) external onlyOwner {
        owner = _owner;
    }

    function mint(address recipient, uint256 amount) external onlyOwner {
        _mint(recipient, amount);
    }

    function burn(address recipient, uint256 amount) external onlyOwner {
        _burn(recipient, amount);
    }
}

