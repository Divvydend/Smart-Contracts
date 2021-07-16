//SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.0;

import  "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import './openzeppelin/contracts/utils/math/SafeMath.sol';
import  './openzeppelin/contracts/security/ReentrancyGuard.sol';

   contract DivvydendPool is ReentrancyGuard {
 
        IERC20  public DivydendToken;
        address public admin;
        IERC20 public rewardToken;
        
        event depositReward (address from, uint amount);
        event  withdrawreward(address to, bool withdrawStatus);
        event adminSET(address newadmin);
        event newRewardToken( IERC20 newrewardToken);
        event newDivydendtoken(IERC20 newdivydendToken);
        
        
        
        constructor(IERC20 _DivydendToken, address _admin, IERC20 _rewardToken)  {
            //only 18 decimal tokens allowed, check token decimals before implementing them 
            require(_DivydendToken.decimals() == 18 && _rewardToken.decimals() == 18, " decimals must be 18");
            DivydendToken = _DivydendToken;
            rewardToken = _rewardToken;
            admin = _admin;
          
        }
        
        using SafeMath for uint;
        
        modifier onlyAdmin(){
             require (admin == msg.sender, 'only admin can call');
             _;
        }
        
        // lets admin pay in rewards
        function DepositReward( uint amount ) onlyAdmin public nonReentrant{
            
            require(rewardToken.balanceOf(msg.sender) > 0 || rewardToken.totalSupply() > amount, 'excess token amount');
           
            rewardToken.transferFrom( msg.sender, address(this), amount);
            
            
            emit depositReward(msg.sender, amount);
        }
        
        //lets token holders withdraw reward tokens 
        
        function withdrawReward() nonReentrant public {
            require(DivydendToken.balanceOf(msg.sender) >= 1*10**18 , 'divy token balance too low');
            require(rewardToken.balanceOf(address(this)) >= 100*10*18, "reward token bal too low ");
            
            uint DivydendTokenSupply = DivydendToken.totalSupply();
            uint msgsenderBal = DivydendToken.balanceOf(msg.sender);
            
            uint msgSenderStakeInSupply = msgsenderBal * 100000000000000000000 / DivydendTokenSupply; 
            
            uint reward = msgSenderStakeInSupply * rewardToken.balanceOf(address(this)) / 100000000000000000000 ;
            rewardToken.transfer(msg.sender, reward);
            
            emit withdrawreward(msg.sender, true);
        }
        
        // allows for change of admin address
    function setAdmin(address newadmin) onlyAdmin public{
        admin = newadmin;
        emit adminSET(admin);
    }
    
    
    // allows for chamge of reward token address 
    function changerewardToken( IERC20 newrewardToken) onlyAdmin public{
        require(newrewardToken.decimals() == 18, "reward token decimal must be 18");
        rewardToken = newrewardToken;
        emit newRewardToken(rewardToken);
    }
    
    
    //allows for change of DivydendToken address
     function changeDivydendToken( IERC20 newDivydendToken) onlyAdmin public{
        require(newDivydendToken.decimals() == 18, "token decimal must be 18");
        DivydendToken = newDivydendToken;
         emit newDivydendtoken(DivydendToken);
    }
        
}