//SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DivvydendPool is ReentrancyGuard {
    address public DivydendToken;
    address public admin;
    address public rewardToken;
    address public rewardTokenOneForMixed;
    address public rewardTokenTwoForMixed;
    bool private mixedPayments = false; //mixedPayments default value is false
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    event depositReward(address from, uint256 amount, bool mixedpayment);
    event withdrawreward(address to, bool withdrawStatus, bool mixedpayment);
    event adminSET(address newadmin);
    event newRewardToken(address newrewardToken);
    event newDivydendtoken(address newdivydendToken);

    constructor(
        address _DivydendToken,
        address _admin
    ) {
        //only 18 decimal tokens allowed, check token decimals before implementing them
        require(
            ERC20(_DivydendToken).decimals() == 18,
            " decimals must be 18"
        );
        DivydendToken = _DivydendToken;
        admin = _admin;
    }

    using SafeMath for uint256;

    modifier onlyAdmin() {
        require(admin == msg.sender, "only admin can call");
        _;
    }

    // lets admin pay in rewards for single payment only not mixed
    function DepositRewardForSinglePayment(uint256 amount) public onlyAdmin {
        require(mixedPayments == false, 'cant deposit, use the deposit function for mixed payment');
        IERC20(rewardToken).transferFrom(msg.sender, address(this), amount);
        emit depositReward(msg.sender, amount, false);
    }

    // lets admin pay in rewards for first token in mixed payment format only 
     function DepositRewardTokenOneMixed( uint amount) public onlyAdmin {
         require(mixedPayments == true, 'cant deposit, use the deposit function for single payment');
            if(rewardTokenOneForMixed == ETH /* 'cant deposit eth this way, use the depositETH() function'*/){ 
           IERC20(rewardTokenOneForMixed).transferFrom(msg.sender, address(this), amount);
          emit depositReward(msg.sender, amount, true);
            }
     }

     function depositETH(bool mixedpayment) public payable onlyAdmin{
         // mixedpayment is for mode of payment, if mixed, mark true, if not, make false
         if (mixedpayment == true) { 
         emit depositReward(msg.sender, msg.value, true);
         } else {
          emit depositReward(msg.sender, msg.value, false);
         }
     }

    // lets admin pay in rewards for first token in mixed payment format only 
     function DepositRewardTokenTwoMixed( uint amount) public onlyAdmin{
         require(mixedPayments == true, 'cant deposit, use the deposit function for single payment');
         if(rewardTokenTwoForMixed == ETH /* 'cant deposit eth this way, use the depositETH() function'*/){ 
         IERC20(rewardTokenTwoForMixed).transferFrom(msg.sender, address(this), amount);
          emit depositReward(msg.sender, amount, true);
         }
     }

    //lets token holders withdraw reward tokens
    function withdrawReward() public nonReentrant {
        require(
            IERC20(DivydendToken).balanceOf(msg.sender) >= 1 * 10**18,
            "divy token balance too low"
        );
        uint256 DivydendTokenSupply = IERC20(DivydendToken).totalSupply();
        uint256 msgsenderBal = IERC20(DivydendToken).balanceOf(msg.sender);
        uint256 msgSenderStakeInSupply = (msgsenderBal *
            100000000000000000000) / DivydendTokenSupply;

        if (mixedPayments == false) {
            uint256 poolRewardBal;
            if (rewardToken == ETH) {
                poolRewardBal = address(this).balance;
            } else {
                poolRewardBal = IERC20(rewardToken).balanceOf(address(this));
            }
            uint256 reward = (msgSenderStakeInSupply * poolRewardBal) /
                100000000000000000000;
            if (reward != 0) {
                IERC20(rewardToken).transfer(msg.sender, reward);
                emit withdrawreward(msg.sender, true, false);
            } else {
                revert("no reward to claim");
            }
        } 
        else if (mixedPayments == true) {
            uint256 poolRewardOneBal;
            uint256 poolRewardTwoBal;

            if (rewardTokenOneForMixed == ETH) {
                poolRewardOneBal = address(this).balance;
                uint256 OneRewardPart = (msgSenderStakeInSupply *
                    poolRewardOneBal) / 100000000000000000000;

                if (OneRewardPart != 0) {
                    payable(msg.sender).transfer( OneRewardPart);
                    emit withdrawreward(msg.sender, true, true);
                } else {
                    revert("no reward token one to claim");
                }
            } else {
                poolRewardOneBal = IERC20(rewardTokenOneForMixed).balanceOf(address(this));

                uint256 OneRewardPart = (msgSenderStakeInSupply *
                    poolRewardOneBal) / 100000000000000000000;

                if (OneRewardPart != 0) {
                    IERC20(rewardTokenOneForMixed).transfer(msg.sender, OneRewardPart);
                    emit withdrawreward(msg.sender, true, true);
                } else {
                    revert("no reward token one to claim");
                }
            }
            if (rewardTokenTwoForMixed == ETH) {
                poolRewardTwoBal = address(this).balance;
                uint256 SecondRewardPart = (msgSenderStakeInSupply *
                    poolRewardTwoBal) / 100000000000000000000;

                if (SecondRewardPart != 0) {
                    payable(msg.sender).transfer( SecondRewardPart);
                    emit withdrawreward(msg.sender, true, true);
                } else {
                    revert("no reward token two to claim");
                }
            } else {
                poolRewardTwoBal = IERC20(rewardTokenOneForMixed).balanceOf(address(this));
                    uint256 SecondRewardPart = (msgSenderStakeInSupply *
                    poolRewardTwoBal) / 100000000000000000000;

                if (SecondRewardPart != 0) {
                   IERC20(rewardTokenOneForMixed).transfer(msg.sender, SecondRewardPart);
                    emit withdrawreward(msg.sender, true, true);
                } else {
                    revert("no reward token two to claim");
                }

            }
        }
    }

    // allows for change of admin address, do not set to address(0) unless you want to make contract ownerless
    function setAdmin(address newadmin) public onlyAdmin {
        admin = newadmin;
        emit adminSET(admin);
    }

    //set to true if dividend payout is going to be mixed i.e part eth/part usdc, set to false if it wont be mixed i.e only eth or only usdc
//set rewardtokenoneformixed and rewardtokentwoformixed to address(0) if status is going to be false  
    function setMixedPayments(bool status, address rewardtokenoneformixed, address rewardtokentwoformixed ) public onlyAdmin {
        _setMixedPayments(status, rewardtokenoneformixed, rewardtokentwoformixed);
    }

    function _setMixedPayments(bool _status, address _rewardtokenoneformixed, address _rewardtokentwoformixed ) internal {
        //mixedPayments defailt value is false
        mixedPayments = _status;

        if (_status == false) {
            rewardTokenOneForMixed = address(0);
            rewardTokenTwoForMixed = address(0);
        } else {
            rewardToken = address(0); // this represents reward for singe payment, set to address(0) since payment mode is changed

            if( rewardtokenoneformixed == ETH) {
            rewardTokenOneForMixed = rewardtokenoneformixed;
            } else{ 
            require(
            ERC20(rewardtokenoneformixed).decimals() == 18,
            "token decimal must be 18"
            );
            rewardTokenOneForMixed = rewardtokenoneformixed;
            }

            if( rewardtokentwoformixed == ETH) {
            rewardTokenTwoForMixed = rewardtokentwoformixed;
            } else{
                 require(
                  ERC20(rewardtokentwoformixed).decimals() == 18,
                  "token decimal must be 18"
                );
                 rewardTokenTwoForMixed = rewardtokentwoformixed;
            }
        }
    }
    // allows for chamge of reward token address in single format not mixed payment format
    function changerewardToken(address newrewardToken) public onlyAdmin {
        _changerewardToken(newrewardToken);
    }

    function _changerewardToken(address _newrewardToken) internal {
        require(
            ERC20(newrewardToken).decimals() == 18,
            "reward token decimal must be 18"
        );
        require( newrewardToken != address(0), 'cant set to address(0)');
        _setMixedPayments(false, address(0), address(0));
        rewardToken = newrewardToken;
        emit newRewardToken(rewardToken);
    }

    //allows for change of DivydendToken address
    function changeDivydendToken(address newDivydendToken) public onlyAdmin {
        require(
            ERC20(newDivydendToken).decimals() == 18,
            "token decimal must be 18"
        );
        DivydendToken = newDivydendToken;
        emit newDivydendtoken(DivydendToken);
    }

    function withdrawAccidentallySentTokens( uint amount, address Token) public onlyAdmin{
        IERC20(Token).transfer(admin, amount);
    }
}

