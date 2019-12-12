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

    mapping(address => uint256) public bootUpList; // 开机列表
    uint public bootUpAmount;   // 开机价

    mapping(address => uint256) public millList; // 用户挖矿列表
    mapping(uint256 => bool) public millTypeList; // 矿机类型列表

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
    uint public resonancePriceStep = 50000; // 共振价格步长

    address receiveUsdtAddress = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c;

    event RegisteredInvitation(address indexed from, uint256 indexed code);
    event Exchange(address indexed from, uint btnsAmount, uint usdtAmount, uint indexed iCode);
    event BootUp(address indexed user);
    event Mining(address indexed user, uint256 millType, uint256 time);
    event UpdateMining(address indexed user, uint256 millType, uint256 time);
    event StopMining(address indexed user);

    constructor() public{
        admin = msg.sender;
        millTypeList[1000] = true;
        millTypeList[5000] = true;
        millTypeList[10000] = true;
        millTypeList[50000] = true;
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

        bootUpAmount = BTNSBase.mul(20);
    }

    // 注册验证码
    function registeredInvitation() public{
        require(addressInvitation[msg.sender] == uint256(0), "registered");
        invitationCode += 1;
        addressInvitation[msg.sender] = invitationCode;
        emit RegisteredInvitation(msg.sender, invitationCode);
    }

    // 获得验证码
    function getInvitationCode() public view returns(uint256){
        return addressInvitation[msg.sender];
    }

    function exchangeEstimated(uint amount) external returns(uint) {
        require(amount < resonanceAmountLeft);
        return getTotalPrice(amount, 0);
    }

    //兑换
    function exchange(uint amount, uint iCode) public{
        require(amount <= resonanceAmountLeft, "resonance amount left < amount");
        uint usdtAmount = getTotalPrice(amount, 0);
        require(usdt.transferFrom(msg.sender, receiveUsdtAddress, usdtAmount), "transfer usdt fail");
        require(btns.transfer(msg.sender, amount), "transfer btns fail");
        updateLevelInfo(amount);
        resonanceAmountLeft = resonanceAmountLeft - amount;
        emit Exchange(msg.sender, amount, usdtAmount, iCode);
    }

    function eth() public payable{
    }

    // 开机
    function bootUp() public {
        require(bootUpList[msg.sender] == uint256(0), "has been bootUp");
        require(btns.transferFrom(msg.sender, address(this), bootUpAmount), "transfer btns fail");
        bootUpList[msg.sender] = bootUpAmount;
        emit BootUp(msg.sender);
    }

    // 挖矿
    function mining(uint millType) public {
        require(bootUpList[msg.sender] != uint256(0), "not bootUp");
        require(millTypeList[millType], "millType error");
        require(millList[msg.sender] == uint256(0), "is mining");
        require(btns.transferFrom(msg.sender, address(this), millType.mul(BTNSBase)), "transfer btns fail");
        millList[msg.sender] = millType;
        emit Mining(msg.sender, millType, block.timestamp);
    }

    // 升级矿机
    function updateMill(uint millType) public {
        require(millTypeList[millType], "millType error");
        require(millList[msg.sender] != uint256(0) && millType > millList[msg.sender], "not mining or millType need bigger than before ");
        uint256 temp = millType - millList[msg.sender];
        require(btns.transferFrom(msg.sender, address(this), temp.mul(BTNSBase)), "transfer btns fail");
        millList[msg.sender] = millType;
        emit UpdateMining(msg.sender, millType, block.timestamp);
    }

    // 关机
    function stopMining() public {
        require(millList[msg.sender] != uint256(0), "not mining");
        require(btns.transferFrom(address(this), msg.sender, millList[msg.sender].mul(BTNSBase)), "transfer btns fail");
        delete millList[msg.sender];
        emit StopMining(msg.sender);
    }

    // 分发社区奖
    function sendCommunityAward() public {

    }

    // 分发开机奖
    function sendBootUpAward() public {

    }

    // 分发挖矿产出
    function sendMiningAward() public {

    }

    function getTotalPrice(uint amount, uint level) internal returns(uint){
        if (amount > resonanceLevelAmount) {
            uint tmpPrice = level.mul(resonancePriceStep).add(resonancePrice);
            return resonanceLevelAmount.mul(resonancePrice.add(tmpPrice)).div(BTNSBase).add(getTotalPrice(amount.sub(resonanceLevelAmount), level + 1)) ;
        } else {
            return amount.mul(resonancePrice).div(BTNSBase);
        }
    }

    function updateLevelInfo(uint amount) internal{
        if (amount > resonanceLevelLeftAmount) {
            resonanceLevel = resonanceLevel + 1;
            resonancePrice = resonancePrice + resonancePriceStep;
            updateLevelInfo(amount - resonanceLevelAmount);
        } else if (amount == resonanceLevelLeftAmount){
            resonanceLevel = resonanceLevel + 1;
            resonancePrice = resonancePrice + resonancePriceStep;
            resonanceLevelLeftAmount = resonanceLevelAmount;
        }else {
            resonanceLevelLeftAmount = resonanceLevelLeftAmount - amount;
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
