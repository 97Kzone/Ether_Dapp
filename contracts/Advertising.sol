// SPDX-License-Identifier: MIT
pragma solidity >=0.4.22;

// 광고 컨트랙
contract Advertising {
    address payable private owner; //배포할 때 쓸 계정

    constructor() {
        owner = payable(msg.sender);
    }

    // 변수와 매핑
    uint256 total_adv; // 총 등록된 광고 수 

    mapping(address => uint256) private _addr; // 주소 => 정수
    mapping(uint256 => AdvInfo) private _advs; // 정수 => 주소

    // ver 1 광고는 구조체다
    struct AdvInfo {
        address advertiser; // 광고주
        uint256 pot; // 광고비
        uint256 count; // 목표 클릭 수.. 인데 금액이 정확하게 1/N 이 안된다면 어쩌지?
    }

    //광고 이벤트
    event AddAdv(address addr, uint256 _pot, uint256 _count);

    // 광고 등록
    function addAdv(uint256 _pot, uint256 _count) public payable returns (bool res) {
        require(msg.value == _pot, "Not Enough ETH"); // 잔액이 광고비 만큼 있는지 확인

        AdvInfo memory a;
        a.advertiser = msg.sender;
        a.pot = _pot;
        a.count = _count;
        total_adv++;

        uint256 idx = _addr[msg.sender];
        _advs[idx] = a;
        
        emit AddAdv(msg.sender, _pot, _count);

        return true;
    }

    // 특정 사용자가 등록한 광고 조회 (생각해보니 한 사람이 여러개의 광고 등록 가능한데 어쩌지 큰일났다)
    function getMyAdv() public view returns (address advertiser, uint256 pot, uint256 count){
        AdvInfo memory a = _advs[_addr[msg.sender]];

        advertiser = a.advertiser;
        pot = a.pot;
        count = a.count;
    }

    // 등록된 광고 목록 (내 뜻대로 안됨)
    function getAllAdv() public view returns (AdvInfo[] memory) {
        AdvInfo[] memory temp = new AdvInfo[](total_adv);

        for (uint256 i = 0; i < total_adv; i++) {
            temp[i] = _advs[i];
        }

        return temp;
    }   

    // 등록된 광고는 수정이 가능해야 할까 ?
}