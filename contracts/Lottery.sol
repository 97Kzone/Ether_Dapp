// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22 <0.9.0;

// payable = 돈을 보낼 수 있게 해주는 용도
// byte X => bytes1 O
// payalbe 변수 = 다른 곳 사용 시 캐스팅 필요

contract Lottery {
    struct BetInfo {
        uint256 answerBlockNumber;
        address payable bettor;
        bytes1 challenges; // byte 사용불가
    }

    uint256 private _tail;
    uint256 private _head;
    mapping (uint256 => BetInfo) private _bets;

    address payable public owner;

    uint256 constant internal BLOCK_LIMIT = 256;
    uint256 constant internal BET_BLOCK_INTERVAL = 3;
    uint256 constant internal BET_AMOUNT = 5 * 10 ** 15;

    uint256 private _pot;
    bool private mode = false; // test = False
    bytes32 public answerForTest;

    enum BlockStatus {Checkable, NotRevealed, BlockLimitPassed}
    enum BettingResult {Fail, Win, Draw}

    event BET(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumber);
    event WIN(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumer);
    event FAIL(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumer);
    event DRAW(uint256 index, address bettor, uint256 amount, bytes1 challenges, bytes1 answer, uint256 answerBlockNumer);
    event REFUND(uint256 index, address bettor, uint256 amount, bytes1 challenges, uint256 answerBlockNumer);

    constructor() {
        owner = payable(msg.sender);
    }

    function getSomeValue() public pure returns (uint256 value) {
        return 5;
    }

    function getPot() public view returns (uint256 pot) {
        return _pot;
    }

    // Bet
    function bet(bytes1 challenges) public payable returns (bool result) {
        require(msg.value == BET_AMOUNT, "Not enough ETH");

        require(pushBet(challenges), "Fail to add a new Bet Info");

        emit BET(_tail-1, msg.sender, msg.value, challenges, block.number + BET_BLOCK_INTERVAL);

        return true;
    }

    // 베팅과 정답 체크를 한다.
    function betAndDistribute(bytes1 challenges) public payable returns (bool result) {
        bet(challenges);

        distribute();

        return true;
    }

    // Distribute
    function distribute() public {
        uint256 cur;
        uint256 transferAmount;

        BetInfo memory b;
        BlockStatus currentBlockStatus;
        BettingResult currentBettingResult;

        for(cur =_head; cur < _tail; cur++) {
            b = _bets[cur];
            currentBlockStatus = getBlockStatus(b.answerBlockNumber);
            // Checkable : answerBlockNumber < block.number < answerBlockNumber + block limit
            if(currentBlockStatus == BlockStatus.Checkable) {
                bytes32 answerBlockHash = getAnswerBlockHash(b.answerBlockNumber);
                currentBettingResult = isMatch(b.challenges, answerBlockHash);
                
                //if win, bettor get pot
                if (currentBettingResult == BettingResult.Win) {
                    transferAmount = transferAfterPayingFee(b.bettor, _pot + BET_AMOUNT);
                    _pot = 0;
                    emit WIN(cur, b.bettor, transferAmount, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                } 
                //if fail, pot get bettor's money
                if (currentBettingResult == BettingResult.Fail) {
                    _pot += BET_AMOUNT;
                    emit FAIL(cur, b.bettor, 0, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                } 

                //if draw, refund
                if (currentBettingResult == BettingResult.Draw) {
                    transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                    emit DRAW(cur, b.bettor, BET_AMOUNT, b.challenges, answerBlockHash[0], b.answerBlockNumber);
                } 
            }
            // Not Revealed : block.number <= answerBlcokNumber
            if(currentBlockStatus == BlockStatus.NotRevealed) {
                break;
            }
            // Block Limit passed : block.number >= answerBlockNumber + block limit
            if(currentBlockStatus == BlockStatus.BlockLimitPassed) {
                // refund
                transferAmount = transferAfterPayingFee(b.bettor, BET_AMOUNT);
                // emit refund
                emit REFUND(cur, b.bettor, BET_AMOUNT, b.challenges, b.answerBlockNumber);
            }
            // check the answer
            popBet(cur);
        }
        _head = cur;
    }

    function transferAfterPayingFee(address payable addr, uint256 amount) internal returns (uint256) {
        uint256 fee = 0;
        uint256 amountWithoutFee = amount - fee;

        addr.transfer(amountWithoutFee);
        owner.transfer(fee);

        // transfer = 가장 안전한 방법
        
        return amountWithoutFee;
    }

    function setAnswerForTest(bytes32 answer) public returns (bool result) {
        require(msg.sender == owner, "Only owner can set the answer");
        answerForTest = answer;
        return true;
    }

    function getAnswerBlockHash(uint256 answerBlockNumber) internal view returns (bytes32 answer) {
        return mode ? blockhash(answerBlockNumber) : answerForTest;
    }
    
    function isMatch(bytes1 challenges, bytes32 answer) public pure returns (BettingResult) {
        // challenges 0xab
        // answer 0xab.... 32 bytes

        bytes1 c1 = challenges;
        bytes1 c2 = challenges;

        bytes1 a1 = answer[0];
        bytes1 a2 = answer[0];
        
        // first word parsing
        c1 = c1 >> 4;
        c1 = c1 << 4;

        a1 = a1 >> 4;
        a1 = a1 << 4;
        
        // second word parsing
        c2 = c2 << 4;
        c2 = c2 >> 4;

        a2 = a2 << 4;
        a2 = a2 >> 4;

        if (a1 == c1 && a2 == c2) {
            return BettingResult.Win;
        }

        if (a1 == c1 || a2 == c2) {
            return BettingResult.Draw;
        }

        return BettingResult.Fail;
    }

    function getBlockStatus(uint256 answerBlockNumber) internal view returns (BlockStatus) {
        if(block.number > answerBlockNumber && block.number < BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.Checkable;
        }

        if(block.number <= answerBlockNumber) {
            return BlockStatus.NotRevealed;
        }

        if(block.number >= BLOCK_LIMIT + answerBlockNumber) {
            return BlockStatus.BlockLimitPassed;
        }

        return BlockStatus.BlockLimitPassed;
    }

    
    function getBetInfo(uint256 index) public view returns (uint256 answerBlockNumber, address bettor, bytes1 challenges) {
        BetInfo memory b = _bets[index];
        answerBlockNumber = b.answerBlockNumber;
        bettor = b.bettor;
        challenges = b.challenges;
    }

    function pushBet(bytes1 challenges) public returns (bool) {
        BetInfo memory b;
        b.bettor = payable(msg.sender);
        b.answerBlockNumber = block.number + BET_BLOCK_INTERVAL;
        b.challenges = challenges;

        _bets[_tail] = b;
        _tail++;

        return true;
    }

    function popBet(uint256 index) public returns (bool) {
        delete _bets[index];
        return true;
    }
}