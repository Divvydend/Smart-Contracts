//SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.0;

import  "./openzeppelin/contracts/token/ERC20/IERC20.sol";
import './openzeppelin/contracts/utils/math/SafeMath.sol';
import  './openzeppelin/contracts/security/ReentrancyGuard.sol';

   contract DivvydendPool is ReentrancyGuard {
 
        address  public DivydendToken;
        address public admin;
        address public rewardToken;
        
        event depositReward (address from, uint amount);
        event  withdrawreward(address to, bool withdrawStatus);
        event adminSET(address newadmin);
        event newRewardToken( address newrewardToken);
        event newDivydendtoken(address newdivydendToken);
        
        
        
        constructor(address _DivydendToken, address _admin, address _rewardToken)  {
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
        function DepositReward( uint amount ) onlyAdmin public {
            
            require(IERC20(rewardToken).balanceOf(msg.sender) > 0 || IERC20(rewardToken).totalSupply() > amount, 'excess token amount');
           
            IERC20(rewardToken).transferFrom( msg.sender, address(this), amount);
            
            
            emit depositReward(msg.sender, amount);
        }
        
        //lets token holders withdraw reward tokens 
        
        function withdrawReward() nonReentrant public {
            require(IERC20(DivydendToken).balanceOf(msg.sender) > 0 , 'zero divy token balance');
            
            uint DivydendTokenSupply = IERC20(DivydendToken).totalSupply();
            uint msgsenderBal = IERC20(DivydendToken).balanceOf(msg.sender);
            
            uint msgSenderStakeInSupply = msgsenderBal/DivydendTokenSupply*100*10**18;
            
            IERC20(rewardToken).transfer(msg.sender, msgSenderStakeInSupply);
            
            emit withdrawreward(msg.sender, true);
        }
        
        // allows for change of admin address
    function setAdmin(address newadmin) onlyAdmin public{
        admin = newadmin;
        emit adminSET(admin);
    }
    
    
    // allows for chamge of reward token address 
    function changerewardToken( address newrewardToken) onlyAdmin public{
        rewardToken = newrewardToken;
        emit newRewardToken(rewardToken);
    }
    
    
    //allows for change of DivydendToken address
     function changeDivydendToken( address newDivydendToken) onlyAdmin public{
        DivydendToken = newDivydendToken;
         emit newDivydendtoken(DivydendToken);
    }
        
}