pragma solidity ^0.5.0;

contract Token {
    uint256 public totalSupply;
    string public name;
    uint8 public decimals;
    string public symbol;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;
    function transfer(address _to, uint256 _value) public returns (bool success);
    function approve(address _spender, uint256 _value) public returns (bool success);
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
}

contract BTNS {
    using SafeMath for uint256;

    address admin;

    Token public btns;
    //    Token usdt = Token(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    Token public usdt = Token(0x1dC6663aD0B97b94426A309788E44ecd9499b026);

    mapping(address => uint256) addressInvitation;
    uint256 invitationCode = 9999;

    bool hasSetBTNS = false;
    address public BTNSAddress;
    uint public BTNSDecimals;
    uint public BTNSBase;
    uint public resonanceAmount;            // 共振数量
    uint public resonanceAmountLeft;        // 共振数量剩余
    uint public resonanceLevel;             // 共振等级
    uint public resonancePrice;             // 共振当前价格
    uint public resonanceLevelLeftAmount;   // 共振当前等级剩余数量
    uint public resonanceLevelAmount;       // 共振每层数量
    uint public resonancePriceStep = 50000;// 共振价格步长


    event RegisteredInvitation(address indexed from, uint256 indexed code);
    event Exchange(address indexed from, uint btnsAmount, uint usdtAmount);

    constructor() public{
        admin = msg.sender;
    }

    function setBTNS(address btnsAddress) public{
        require(!hasSetBTNS);
        require(msg.sender == admin);
        btns = Token(btnsAddress);
        BTNSDecimals = uint256(btns.decimals());
        BTNSBase = 10 ** BTNSDecimals;
        uint256 totalSupply = btns.totalSupply();
        resonanceAmount = totalSupply.mul(3).div(10);
        resonanceAmountLeft = totalSupply.mul(3).div(10);
        BTNSAddress = btnsAddress;
        resonanceLevel = 0;
        resonancePrice = 500000;
        resonanceLevelAmount = resonanceAmount.div(6);
        resonanceLevelLeftAmount = resonanceAmount.div(6);
        hasSetBTNS = true;
    }

    function registeredInvitation() public{
        require(addressInvitation[msg.sender] == uint256(0));
        invitationCode += 1;
        addressInvitation[msg.sender] = invitationCode;
        emit RegisteredInvitation(msg.sender, invitationCode);
    }

    function getInvitationCode() public view returns(uint256){
        return addressInvitation[msg.sender];
    }

    function exchangeEstimated(uint amount) external returns(uint) {
        require(amount < resonanceAmountLeft);
        return getTotalPrice(amount, 0);

    }

    function exchange(uint amount) public{
        require(amount < resonanceAmountLeft);
        uint usdtAmount = getTotalPrice(amount, 0);
        require(usdt.transferFrom(msg.sender, address(this), usdtAmount));
        btns.transfer(msg.sender, amount);
        emit Exchange(msg.sender, amount, usdtAmount);
    }

    function eth() public payable{
    }

    function getTotalPrice(uint amount, uint level) internal returns(uint){
        if (amount > resonanceLevelAmount) {
            uint tmpPrice = level.mul(resonancePriceStep).add(resonancePrice);
            return resonanceLevelAmount.mul(resonancePrice.add(tmpPrice)).div(BTNSBase).add(getTotalPrice(resonanceLevelAmount.sub(amount), level + 1)) ;
        } else {
            return amount.mul(resonancePrice).div(BTNSBase);
        }
    }
}


library SafeMath {
    function add(uint a, uint b) internal pure returns (uint c) {
        c = a + b;
        require(c >= a);
        return c;
    }

    function sub(uint a, uint b) internal pure returns (uint c) {
        require(b <= a);
        c = a - b;
        return c;
    }

    function mul(uint a, uint b) internal pure returns (uint c) {
        c = a * b;
        require(a == 0 || c / a == b);
        return c;
    }

    function div(uint a, uint b) internal pure returns (uint c) {
        require(b > 0);
        c = a / b;
        require(a == b * c + a % b);
        return c;
    }
}
