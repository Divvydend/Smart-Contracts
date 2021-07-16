const { assert } = require("console");
const { isMainThread } = require("worker_threads");


const DivvydendPoolContract = artifacts.require('DivvydendPool');
const DivvydendTokenContract = artifacts.require('DivvydendToken');
const RewardTokenContract = artifacts.require('RewardToken')

contract('DivvydendPool', function (accounts) {

    const owner = accounts[0];
    const initial_supply = '1000000000000000000000'

    before(async () => {
        // deploy the smart contract in test environment 
        DivvydendToken = await DivvydendTokenContract.new(owner, initial_supply);
        RewardToken = await RewardTokenContract.new(owner, initial_supply);
        //get the token smart contract address 
        DivvydendTokenAddress = DivvydendToken.address;
        RewardTokenAddress = RewardToken.address;

        DivvydendPool = await DivvydendPoolContract.new(DivvydendTokenAddress, owner, RewardTokenAddress);
        // get smart contract address 
        DivvydendPoolAddress = DivvydendPool.address;
    });

    describe('let admin pay in rewards', async () => {
        it('should call deposit reward function in pool smart contract ', async () => {
            var amount =  '100000000000000000000'
            await RewardToken.approve(DivvydendPoolAddress, amount);
            await DivvydendPool.DepositReward(amount);

            const RWDpoolBal = await RewardToken.balanceOf(DivvydendPoolAddress)

            assert(RWDpoolBal.toString() === amount.toString(), 'NO reward token deposit')

        })
    })

    describe('let token holders withdraw rewards', async () => {
        it('should call withdraw reward function in pool smart contract ', async () => {
            
            await DivvydendToken.transfer(accounts[1], '10000000000000');
            const accOneDivvyBal = await DivvydendToken.balanceOf(accounts[1]);
            console.log(accOneDivvyBal.toString(), 'acc one bal')

            const holderRWDBalBeforeRwd = await RewardToken.balanceOf(accounts[1]);
            console.log(holderRWDBalBeforeRwd.toString(), 'acc one bal before claiming rwd')

            const RWDBaloFDivvy = await RewardToken.balanceOf(DivvydendPoolAddress);
            console.log(RWDBaloFDivvy.toString(), 'divypool contract rwd bal');
          
            await DivvydendPool.withdrawReward({from: accounts[1]});

            const holderRWDBalafterRwd = await RewardToken.balanceOf(accounts[1]);
            
console.log(holderRWDBalafterRwd.toString(), 'acc one bal before claiming rwd');
            assert(holderRWDBalBeforeRwd.toString() !== holderRWDBalafterRwd.toString(), 'rwd not paid ');

        })
    })
})