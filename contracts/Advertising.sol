// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22;

// 광고 컨트랙 ver1.0 광고는 구조체다
contract Advertising {
    address payable private owner; //배포할 때 쓸 계정

    constructor() {
        owner = payable(msg.sender);
    }

    // 광고 구조체
    struct AdvInfo {
        string title; // 광고제목 
        string comment; // 광고내용
        uint256 pot; // 광고비
        uint256 count; // 목표 클릭 수.. 인데 금액이 정확하게 1/N 이 안된다면 어쩌지?
        uint256 reward; // 1회 시청 시 리워드 금액
    }

    // 변수와 매핑
    uint256 total_adv; // 총 등록된 광고 수 
    uint256 total_person; // 등록한 광고주 수
    AdvInfo[] AllAdv;

    mapping(address => AdvInfo[]) private _advs; // 1개의 주소의 등록된 광고를 매핑
    mapping(uint256 => AdvInfo) private _adv_dict; // 모든 광고
    
    //광고 이벤트
    event AddAdv(address addr, string _title, uint256 _pot, uint256 _count); // 광고 추가되면 이벤트 발생시켜서 내역 확인
    event howmuch(uint256 val); // 송금 확인용 이벤트
    event test(AdvInfo info);

    // 광고 등록
    function addAdv(string memory _title, string memory _comment, uint256 _pot, uint256 _count) public payable returns (bool res) {
        require(msg.value > _pot, "Not Enough ETH"); // 잔액이 광고비 만큼 있는지 확인

        AdvInfo memory a;

        a.title = _title;
        a.comment = _comment;
        a.pot = _pot;
        a.count = _count;
        a.reward = _pot / _count;

        if (_advs[msg.sender].length == 0) // 처음 광고 등록하면 광고주 명단에 박제
        { 
            total_person++;
        }

        _advs[msg.sender].push(a);
        AllAdv.push(a);
        total_adv++;

        emit AddAdv(msg.sender, _title, _pot, _count);

        return true;
    }

    // 특정 사용자가 등록한 광고 조회 
    function getMyAdv() public view returns (AdvInfo[] memory res){
        AdvInfo[] memory a = _advs[msg.sender];
        return a;
    }

    // 등록된 광고 목록 
    function getAllAdv() public view returns (AdvInfo[] memory) {
        return AllAdv;
    }   

    // 등록한 광고주는 몇명일까 ?
    function getAllperson() public view returns (uint256) {
        return total_person;
    }
    
    // 광고 시청 시 리워드 지급
    function callReward(uint256 idx) public returns(string memory) {
        AdvInfo memory a = AllAdv[idx];
        uint256 _cnt = a.count;
        uint256 _rwd = a.reward;
        uint256 _pot = a.pot;
        address payable addr = payable(msg.sender);

        require(_cnt > 1, "Expired advertising");

        (bool sent, ) = addr.call{value: _rwd}("");

        require(sent, "Fail to transfer reward");
        AllAdv[idx].pot = _pot - _rwd;

        emit test(AllAdv[idx]);

        return "Reward Completed";
    }

    // 등록된 광고는 수정이 가능해야 할까 ?
}