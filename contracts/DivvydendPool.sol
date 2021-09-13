//SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.0;

import  "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import '@openzeppelin/contracts/utils/math/SafeMath.sol';
import  '@openzeppelin/contracts/security/ReentrancyGuard.sol';

   contract DivvydendPool is ReentrancyGuard {
 
        IERC20  public DivydendToken;
        address public admin;
        IERC20 public rewardToken;
        
        event depositReward (address from, uint amount);
        event  withdrawreward(address to, bool withdrawStatus);
        event adminSET(address newadmin);
        event newRewardToken( IERC20 newrewardToken);
        event newDivydendtoken(IERC20 newdivydendToken);
        
        
        
        constructor(address _DivydendToken, address _admin, address _rewardToken)  {
            //only 18 decimal tokens allowed, check token decimals before implementing them 
            require(ERC20(_DivydendToken).decimals() == 18 && ERC20(_rewardToken).decimals() == 18, " decimals must be 18");
            DivydendToken = IERC20(_DivydendToken);
            rewardToken = IERC20(_rewardToken);
            admin = _admin;
          
        }
        
        using SafeMath for uint;
        
        modifier onlyAdmin(){
             require (admin == msg.sender, 'only admin can call');
             _;
        }
        
        // lets admin pay in rewards
        function DepositReward( uint amount ) onlyAdmin public nonReentrant{
           IERC20(rewardToken).transferFrom( msg.sender, address(this), amount);
            emit depositReward(msg.sender, amount);
        }
        
        //lets token holders withdraw reward tokens 
        
        function withdrawReward() nonReentrant public {
            require(IERC20(DivydendToken).balanceOf(msg.sender) >= 1*10**18 , 'divy token balance too low');
            
            uint DivydendTokenSupply = IERC20(DivydendToken).totalSupply();
            uint msgsenderBal = IERC20(DivydendToken).balanceOf(msg.sender);
            
            uint msgSenderStakeInSupply = msgsenderBal * 100000000000000000000 / DivydendTokenSupply; 
            uint reward = msgSenderStakeInSupply * IERC20(rewardToken).balanceOf(address(this)) / 100000000000000000000 ;
            
            if (reward != 0){
            IERC20(rewardToken).transfer(msg.sender, reward); 
            emit withdrawreward(msg.sender, true);
            } 
            else {
                revert('no reward to claim');
            }
        }
        
        // allows for change of admin address
    function setAdmin(address newadmin) onlyAdmin public{
        admin = newadmin;
        emit adminSET(admin);
    }
    
    
    // allows for chamge of reward token address 
    function changerewardToken( address newrewardToken) onlyAdmin public{
        require(ERC20(newrewardToken).decimals() == 18, "reward token decimal must be 18");
        rewardToken = IERC20(newrewardToken);
        emit newRewardToken(rewardToken);
    }
    
    
    //allows for change of DivydendToken address
     function changeDivydendToken(address newDivydendToken) onlyAdmin public{
        require(ERC20(newDivydendToken).decimals() == 18, "token decimal must be 18");
        DivydendToken = IERC20(newDivydendToken);
         emit newDivydendtoken(DivydendToken);
    }
        
}