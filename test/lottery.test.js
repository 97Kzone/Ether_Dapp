const Lottery = artifacts.require("Lottery");
const { assert } = require('chai');
const assertRevert = require('./assertRevert');
const expectEvent = require('./expectEvent');

contract("Lottery", function([deployer, user1, user2]) {
    let lottery;
    let betAmount = 5 * (10 ** 15)
    let betAmountBN = new web3.utils.BN("5000000000000000");
    let bet_block_interval = 3


    beforeEach(async () => {
        console.log('Before each')
        lottery = await Lottery.new();
        
    })

    it('Basic test', async () => {
        console.log('Basic test')
        let owner = await lottery.owner();
        let value = await lottery.getSomeValue();

        console.log(`owner : ${owner}`);
        console.log(`value : ${value}`)
        assert.equal(10, 10)
    })

    it('getPot should return current pot', async () => {
       let pot = await lottery.getPot();
       assert.equal(pot, 0)
    })

    describe('Bet', function () {
        it('should fail when the bet money is not 0.005 ETH', async () => {
            await assertRevert(lottery.bet("0xab", {from : user1, value: betAmount}))  
        })

        it('should put the bet to the bet queue', async () => {
            // bet
            let receipt = await lottery.bet("0xab", {from : user1, value: betAmount})
            
            let pot = await lottery.getPot();
            assert.equal(pot, 0);

            // check contract balance == 0.005 ETH
            let contractBalance = await web3.eth.getBalance(lottery.address);
            assert.equal(contractBalance, betAmount)

            // check betinfo
            let currentBlockNumber = await web3.eth.getBlockNumber();
            let bet = await lottery.getBetInfo(0);

            assert.equal(bet.answerBlockNumber, currentBlockNumber + bet_block_interval);
            assert.equal(bet.bettor, user1);;
            assert.equal(bet.challenges, '0xab');

            // check log
            await expectEvent.inLogs(receipt.logs, 'BET');
        })
    })
    describe('Distribute', function() {
        describe("When the answer is Checkable", function () {
            it('answer match', async () => {
                // 두 글자 다 맞춤
                await lottery.setAnswerForTest('0xab1086d3782b6433c333f4ee451e2819132a3ec23bd333bf2897f91b1f7f9189', {from : deployer})
                
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 1 -> 4
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 2 -> 5
                await lottery.betAndDistribute('0xab', {from : user1, value : betAmount}) // 3 -> 6
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 4 -> 7
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 5 -> 8
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 6 -> 9

                let potBefore = await lottery.getPot();
                let userBalanceBefore = await web3.eth.getBalance(user1);

                let receipt7 = await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 7 -> 10 , 정답 확인
                
                let potAfter = await lottery.getPot();
                let userBalanceAfter = await web3.eth.getBalance(user1);

                assert.equal(potBefore.toString(), new web3.utils.BN('10000000000000000').toString());
                assert.equal(potAfter.toString(), new web3.utils.BN('0').toString());
                
                userBalanceBefore = new web3.utils.BN(userBalanceBefore);
                assert.equal(userBalanceBefore.add(potBefore).add(betAmountBN).toString(), new web3.utils.BN(userBalanceAfter).toString())
            })
            it('one word match', async () => {
                // 한 글자 맞춤
                await lottery.setAnswerForTest('0xab1086d3782b6433c333f4ee451e2819132a3ec23bd333bf2897f91b1f7f9189', {from : deployer})
                
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 1 -> 4
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 2 -> 5
                await lottery.betAndDistribute('0xaf', {from : user1, value : betAmount}) // 3 -> 6
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 4 -> 7
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 5 -> 8
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 6 -> 9

                let potBefore = await lottery.getPot();
                let userBalanceBefore = await web3.eth.getBalance(user1);

                let receipt7 = await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 7 -> 10 , 정답 확인
                
                let potAfter = await lottery.getPot();
                let userBalanceAfter = await web3.eth.getBalance(user1);

                assert.equal(potBefore.toString(), new web3.utils.BN('10000000000000000').toString());
                assert.equal(potAfter.toString(), potAfter.toString());
                
                userBalanceBefore = new web3.utils.BN(userBalanceBefore);
                assert.equal(userBalanceBefore.add(betAmountBN).toString(), new web3.utils.BN(userBalanceAfter).toString())
            })
            it('answer missmatch', async () => {
                // 다 못 맞춤
                await lottery.setAnswerForTest('0xab1086d3782b6433c333f4ee451e2819132a3ec23bd333bf2897f91b1f7f9189', {from : deployer})
                
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 1 -> 4
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 2 -> 5
                await lottery.betAndDistribute('0xef', {from : user1, value : betAmount}) // 3 -> 6
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 4 -> 7
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 5 -> 8
                await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 6 -> 9

                let potBefore = await lottery.getPot();
                let userBalanceBefore = await web3.eth.getBalance(user1);

                let receipt7 = await lottery.betAndDistribute('0xef', {from : user2, value : betAmount}) // 7 -> 10 , 정답 확인
                
                let potAfter = await lottery.getPot();
                let userBalanceAfter = await web3.eth.getBalance(user1);

                assert.equal(potBefore.add(betAmountBN).toString(), potAfter.toString());
                
                userBalanceBefore = new web3.utils.BN(userBalanceBefore);
                assert.equal(userBalanceBefore.toString(), new web3.utils.BN(userBalanceAfter).toString())
            })
        })
        describe("when the answer is not reveled", function () {
            
        })
        describe("When the answer is Block limit passed", function () {
            
        })
    })

    describe('isMatch', function () {
        let blockHash = '0xab1086d3782b6433c333f4ee451e2819132a3ec23bd333bf2897f91b1f7f9189'

        it("should be BettingResult.win when win", async () => {
            let matchingResult = await lottery.isMatch('0xab', blockHash)
            assert.equal(matchingResult, 1);
        })

        it("should be BettingResult.fail when fail", async () => {
            let matchingResult = await lottery.isMatch('0xcd', blockHash)
            assert.equal(matchingResult, 0);
        })

        it("should be BettingResult.draw when draw", async () => {
            let matchingResult = await lottery.isMatch('0xaf', blockHash)
            assert.equal(matchingResult, 2);

            matchingResult = await lottery.isMatch('0xfb', blockHash)
            assert.equal(matchingResult, 2);
        })
    })
});