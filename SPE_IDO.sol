/**
 *Submitted for verification at BscScan.com on 2021-09-13
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


interface IERC20 {

    function totalSupply() external view returns (uint256);

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);

    function allowance(address owner, address spender) external view returns (uint256);

    function approve(address spender, uint256 amount) external returns (bool);

    function burn(address addr_, uint amount_) external returns (bool);

    function transferFrom(
        address sender,
        address recipient,
        uint256 amount
    ) external returns (bool);

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

}

abstract contract Context {
    function _msgSender() internal view virtual returns (address) {
        return msg.sender;
    }

    function _msgData() internal view virtual returns (bytes calldata) {
        return msg.data;
    }
}

abstract contract Ownable is Context {
    address private _owner;

    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    constructor() {
        _setOwner(_msgSender());
    }

    function owner() public view virtual returns (address) {
        return _owner;
    }

    modifier onlyOwner() {
        require(owner() == _msgSender(), "Ownable: caller is not the owner");
        _;
    }

    function renounceOwnership() public virtual onlyOwner {
        _setOwner(address(0));
    }


    function transferOwnership(address newOwner) public virtual onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _setOwner(newOwner);
    }

    function _setOwner(address newOwner) private {
        address oldOwner = _owner;
        _owner = newOwner;
        emit OwnershipTransferred(oldOwner, newOwner);
    }
}

contract IDO is Ownable {
    IERC20 public Token;
    // uint public acc = 1e10;
    uint[9] public rate = [10,15,15,10,10,10,10,10,10];
    // uint[8] public rate = [10,15,15,10,10,10,10,10,10];

    uint public startTime;
    uint public claimTime;
    uint public round = 1;
    uint public lef = 30 days;
    struct UserInfo {
        uint counting;
        uint total;
        uint claimed;

    }

    mapping(address => UserInfo) public userInfo;

    event ClaimIDO(address indexed addr_, uint indexed claimamount_);

    modifier isOpen(){
        require(block.timestamp >= startTime,'not open');
        _;
    }
    modifier upDateTime(){
        if(block.timestamp >= claimTime + lef){
            claimTime += lef;
            round = check();
        }
        _;
    }


    function setToken(address com_) public onlyOwner {
        Token = IERC20(com_);
    }

    function setAmount(address addr_, uint amount_) public onlyOwner {
        userInfo[addr_].total = amount_;
    }

    function setStart(uint start_) onlyOwner public {
        startTime = start_;
        claimTime = start_;
    }

    function countingClaim(address addr_) public view isOpen returns (uint)  {
        uint out = 0;
        uint _round = round;
        if(block.timestamp >= claimTime + lef && round < 9){
            _round += (block.timestamp - claimTime)/lef;
            _round = _round > 9 ? 9: _round;
        }
        for(uint i =1; i <= _round;i ++){
            if (userInfo[addr_].counting == _round){
                break;
            }else if ( i < userInfo[addr_].counting){
                continue;
            }else{
                out += userInfo[addr_].total * rate[i - 1 ] / 100;
            }
        }
        return out;

    }

    function check()public view returns(uint) {
        uint _round = round;
        if(block.timestamp >= claimTime + lef && round < 9){
            _round += (block.timestamp - claimTime)/lef;
            _round = _round > 9 ? 9: _round;
        }
        return _round;
    }

    function claimIDO() public isOpen upDateTime{
        require(userInfo[msg.sender].total != 0, 'no amonut');
        require(userInfo[msg.sender].claimed < userInfo[msg.sender].total, 'claim over');
        require(userInfo[msg.sender].counting < round,'claimed');
        uint temp;
        temp = countingClaim(msg.sender);
        Token.transfer(msg.sender,temp);
        userInfo[msg.sender].counting = round;
        userInfo[msg.sender].claimed += temp;
        emit ClaimIDO(msg.sender, temp);

    }

    function claimLeftToken(address addr_) public onlyOwner {
        uint temp = Token.balanceOf(address(this));
        Token.transfer(addr_, temp);
    }
    function changeRoung(uint com_) public onlyOwner {
        round = com_;
    }


    function replaceInfo(address old_,address new_) public onlyOwner {
        require(userInfo[old_].total != 0, 'no amonut');
        UserInfo memory oldInfo = userInfo[old_];
        userInfo[new_] = oldInfo;
        userInfo[old_] = UserInfo({
        counting : 0,
        total : 0,
        claimed : 0
        });

    }


}