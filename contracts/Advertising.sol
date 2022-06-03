// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22;

// 광고 컨트랙
contract Advertising {
    address payable private owner; //배포할 때 쓸 계정

    constructor() {
        owner = payable(msg.sender);
    }

    // ver 1 광고는 구조체다
    struct AdvInfo {
        string comment; // 광고내용...초라하다
        uint256 pot; // 광고비
        uint256 count; // 목표 클릭 수.. 인데 금액이 정확하게 1/N 이 안된다면 어쩌지?
    }

    // 변수와 매핑
    uint256 total_adv; // 총 등록된 광고 수 

    mapping(address => AdvInfo[]) private _advs; //주소 => 구조체 list
    

    //광고 이벤트
    event AddAdv(address addr, uint256 _pot, uint256 _count); // 광고 추가되면 이벤트 발생시켜서 내역 확인

    // 광고 등록
    function addAdv(string memory _comment, uint256 _pot, uint256 _count) public payable returns (bool res) {
        require(msg.value == _pot, "Not Enough ETH"); // 잔액이 광고비 만큼 있는지 확인

        AdvInfo memory a;

        a.comment = _comment;
        a.pot = _pot;
        a.count = _count;
        total_adv++;

        _advs[msg.sender].push(a);
        
        emit AddAdv(msg.sender, _pot, _count);

        return true;
    }

    // 특정 사용자가 등록한 광고 조회 
    function getMyAdv() public view returns (AdvInfo[] memory res){
        AdvInfo[] memory a = _advs[msg.sender];
        return a;
    }

    // 등록된 광고 목록 (다음 목표)
    // function getAllAdv() public view returns (AdvInfo[] memory) {
    // }   

    // 등록된 광고는 수정이 가능해야 할까 ?
}