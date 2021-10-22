//SPDX-License-Identifier: <SPDX-License>

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DivvydendPool is ReentrancyGuard {
    address public DivydendToken;
    address public admin;
    address public rewardTokenForSingle;
    address public rewardTokenOneForMixed;
    address public rewardTokenTwoForMixed;
    bool private mixedPayments = false; //mixedPayments default value is false
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;
    address[] private rewardees;

    event depositReward(address from, uint256 amount, bool mixedpayment);
    event withdrawreward(address to, bool withdrawStatus, bool mixedpayment);
    event adminSET(address newadmin);
    event newRewardToken(address newrewardToken);
    event newDivydendtoken(address newdivydendToken);

    mapping (address => bool) withdrawal;

    constructor(address _DivydendToken, address _admin) {
        //only 18 decimal tokens allowed, check token decimals before implementing them
        require(ERC20(_DivydendToken).decimals() == 18, " decimals not 18");
        DivydendToken = _DivydendToken;
        admin = _admin;
    }

    using SafeMath for uint256;

    modifier onlyAdmin() {
        require(admin == msg.sender, "not admin");
        _;
    }


                                         /*** DEPOSITS ***/


     function depositETH() public payable onlyAdmin {
        // mixedpayment is for mode of payment, if mixed, mark true, if not, make false
        if (mixedPayments == true) {
            emit depositReward(msg.sender, msg.value, true);
        } else {
            emit depositReward(msg.sender, msg.value, false);
        }
    }

    // lets admin pay in rewards for single payment only not mixed
    function DepositRewardForSinglePayment(uint256 amount) public onlyAdmin {
        require(
            mixedPayments == false,
            "use the deposit fnc for mixed payment"
        );
        IERC20(rewardTokenForSingle).transferFrom(
            msg.sender,
            address(this),
            amount
        );
        emit depositReward(msg.sender, amount, false);
    }

    // lets admin pay in rewards for first token in mixed payment format only
    function DepositRewardTokenOneMixed(uint256 amount) public onlyAdmin {
        require(
            mixedPayments == true,
            "use the deposit fnc for single payment"
        );
        if (
            rewardTokenOneForMixed != ETH /* 'cant deposit eth this way, use the depositETH() function'*/
        ) {
            IERC20(rewardTokenOneForMixed).transferFrom(
                msg.sender,
                address(this),
                amount
            );
            emit depositReward(msg.sender, amount, true);
        } else {
            revert("use the depositETH()");
        }
    }

    // lets admin pay in rewards for first token in mixed payment format only
    function DepositRewardTokenTwoMixed(uint256 amount) public onlyAdmin {
        require(
            mixedPayments == true,
            "use the deposit fnc for single payment"
        );
        if (
            rewardTokenTwoForMixed != ETH /* 'cant deposit eth this way, use the depositETH() function'*/
        ) {
            IERC20(rewardTokenTwoForMixed).transferFrom(
                msg.sender,
                address(this),
                amount
            );
            emit depositReward(msg.sender, amount, true);
        } else {
            revert("use the depositETH()");
        }
    }


                                      /*** WITHDRAWALS  ***/


    //lets token holders withdraw reward tokens
    function withdrawReward()
        external
        nonReentrant
        returns (
            uint256 rewardSingle,
            uint256 OneRewardPart,
            uint256 SecondRewardPart
        )
    {
        require(
            IERC20(DivydendToken).balanceOf(msg.sender) >= (1 * 10**18),
            "divy token bal low"
        );
        require(withdrawal[msg.sender] != true, 'cant withdraw twice');

        uint256 msgSenderStakeInSupply = (IERC20(DivydendToken).balanceOf(
            msg.sender
        ) * (1 * 10**18)) / IERC20(DivydendToken).totalSupply();

        if (mixedPayments == false) {
            uint256 poolRewardBal;
            if (rewardTokenForSingle == ETH) {
                poolRewardBal = address(this).balance;
                rewardSingle =
                (msgSenderStakeInSupply * poolRewardBal) /
                (1 * 10**18);
            if (rewardSingle != 0) {
                payable(msg.sender).transfer(rewardSingle);
                emit withdrawreward(msg.sender, true, false);
            } else {
                revert("no reward to claim");
            }
            } else {
                poolRewardBal = IERC20(rewardTokenForSingle).balanceOf(
                    address(this)
                );
                rewardSingle =
                    (msgSenderStakeInSupply * poolRewardBal) /
                    (1 * 10**18);
                if (rewardSingle != 0) {
                    IERC20(rewardTokenForSingle).transfer(
                        msg.sender,
                        rewardSingle
                    );
                    emit withdrawreward(msg.sender, true, false);
                } else {
                    revert("no reward to claim");
                }
            }
        } else if (mixedPayments == true) {
            uint256 poolRewardOneBal;
            uint256 poolRewardTwoBal;

            if (rewardTokenOneForMixed == ETH) {
                poolRewardOneBal = address(this).balance;
                OneRewardPart =
                    (msgSenderStakeInSupply * poolRewardOneBal) /
                    (1 * 10**18);

                if (OneRewardPart != 0) {
                    payable(msg.sender).transfer(OneRewardPart);
                    emit withdrawreward(msg.sender, true, true);
                } else {
                    revert("no reward token one to claim");
                }
            } else {
                poolRewardOneBal = IERC20(rewardTokenOneForMixed).balanceOf(
                    address(this)
                );

                OneRewardPart =
                    (msgSenderStakeInSupply * poolRewardOneBal) /
                    (1 * 10**18);

                if (OneRewardPart != 0) {
                    IERC20(rewardTokenOneForMixed).transfer(
                        msg.sender,
                        OneRewardPart
                    );
                    emit withdrawreward(msg.sender, true, true);
                } else {
                    revert("no reward token one to claim");
                }
            }
            if (rewardTokenTwoForMixed == ETH) {
                poolRewardTwoBal = address(this).balance;
                SecondRewardPart =
                    (msgSenderStakeInSupply * poolRewardTwoBal) /
                    (1 * 10**18);

                if (SecondRewardPart != 0) {
                    payable(msg.sender).transfer(SecondRewardPart);
                    emit withdrawreward(msg.sender, true, true);
                } else {
                    revert("no reward token two to claim");
                }
            } else {
                poolRewardTwoBal = IERC20(rewardTokenTwoForMixed).balanceOf(
                    address(this)
                );
                SecondRewardPart =
                    (msgSenderStakeInSupply * poolRewardTwoBal) /
                    (1 * 10**18);

                if (SecondRewardPart != 0) {
                    IERC20(rewardTokenTwoForMixed).transfer(
                        msg.sender,
                        SecondRewardPart
                    );
                    emit withdrawreward(msg.sender, true, true);
                } else {
                    revert("no reward token two to claim");
                }
            }
        }
        withdrawal[msg.sender] = true;
        rewardees.push(msg.sender);
    }

    function withdrawAccidentallySentTokens(uint256 amount, address Token)
        public
        onlyAdmin
    {
        IERC20(Token).transfer(admin, amount);
    }

    // call after a reward period to reset who can claim
    function resetWithdrawals() external onlyAdmin {
        for (uint256 index = 0; index < rewardees.length; index++) {
            delete withdrawal[rewardees[index]];
        }
    }


                                          /*** ADMIN SPECIFIC FUNCTIONS */


    // allows for change of admin address, do not set to address(0) unless you want to make contract ownerless
    function setAdmin(address newadmin) external onlyAdmin {
        admin = newadmin;
        emit adminSET(admin);
    }

    //set to true if dividend payout is going to be mixed i.e part eth/part usdc, set to false if it wont be mixed i.e only eth or only usdc
    //set rewardtokenoneformixed and rewardtokentwoformixed to address(0) if status is going to be false
    function setPaymentMode(
        bool status,
        address rewardtokenforsingle,
        address rewardtokenoneformixed,
        address rewardtokentwoformixed
    ) external onlyAdmin {
        _setPaymentMode(
            status,
            rewardtokenforsingle,
            rewardtokenoneformixed,
            rewardtokentwoformixed
        );
    }

    function _setPaymentMode(
        bool _status,
        address _rewardtokenforsingle,
        address _rewardtokenoneformixed,
        address _rewardtokentwoformixed
    ) internal {
        //mixedPayments defailt value is false
        mixedPayments = _status;

        if (mixedPayments == false) {
            rewardTokenOneForMixed = address(0);
            rewardTokenTwoForMixed = address(0);
            rewardTokenForSingle = _rewardtokenforsingle;
        } else {
            rewardTokenForSingle = address(0); // this represents reward for singe payment, set to address(0) since payment mode is changed

            if (_rewardtokenoneformixed == ETH) {
                rewardTokenOneForMixed = _rewardtokenoneformixed;
            } else {
                require(
                    ERC20(_rewardtokenoneformixed).decimals() == 18,
                    "decimal not 18"
                );
                rewardTokenOneForMixed = _rewardtokenoneformixed;
            }

            if (_rewardtokentwoformixed == ETH) {
                rewardTokenTwoForMixed = _rewardtokentwoformixed;
            } else {
                require(
                    ERC20(_rewardtokentwoformixed).decimals() == 18,
                    "decimal not 18"
                );
                rewardTokenTwoForMixed = _rewardtokentwoformixed;
            }
        }
    }

    // allows for chamge of reward token address in single format not mixed payment format
    function changerewardTokenSingle(address newrewardToken) external onlyAdmin {
        _changerewardToken(newrewardToken);
    }

    function _changerewardToken(address _newrewardToken) internal {
        require(
            ERC20(_newrewardToken).decimals() == 18,
            "decimal not 18"
        );
        require(_newrewardToken != address(0), "address(0) invalid");
        require(
            mixedPayments == false,
            "cant use, mixed payments is true"
        );

        rewardTokenForSingle = _newrewardToken;
        emit newRewardToken(rewardTokenForSingle);
    }

    // allows for chamge of reward token addresses in mixed paymennt format
    function changerewardTokensMixed(
        address newrewardTokenOne,
        address newrewardTokenTwo
    ) external onlyAdmin {
        _changerewardTokensMixed(newrewardTokenOne, newrewardTokenTwo);
    }

    function _changerewardTokensMixed(
        address _newrewardTokenOne,
        address _newrewardTokenTwo
    ) internal {
        require(
            ERC20(_newrewardTokenOne).decimals() == 18 ||
                ERC20(_newrewardTokenTwo).decimals() == 18,
            "decimal not 18"
        );
        require(
            _newrewardTokenOne != address(0) ||
                _newrewardTokenTwo != address(0),
            "address(0) invalid"
        );
        require(
            mixedPayments == true,
            "cant use fnc, mixed payments is false "
        );

        rewardTokenOneForMixed = _newrewardTokenOne;
        rewardTokenTwoForMixed = _newrewardTokenTwo;
        emit newRewardToken(rewardTokenForSingle);
    }

    //allows for change of DivydendToken address
    function changeDivydendToken(address newDivydendToken) external onlyAdmin {
        require(
            ERC20(newDivydendToken).decimals() == 18,
            "decimal not 18"
        );

        DivydendToken = newDivydendToken;
        emit newDivydendtoken(DivydendToken);
    }

}
