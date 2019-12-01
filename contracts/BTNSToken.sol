pragma solidity ^0.5.0;

contract TokenAdmin {
    using SafeMath for uint256;
    address public ownerAddr;
    address public adminAddr;

    address public evangelistAddr = 0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c; // 布道者地址
    address public geekAddr = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C; // 极客地址
    address public contractAddr = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB; // 合约地址
    address public communityAddr = 0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB; // 社区地址

    bool public evangelist = true;
    bool public geek = true;

    uint public initTime;
    uint public unlockTime;
    uint public price = 500000; // 0.5 USDT

    uint public priceStep = 500000; // 价格步长
    uint public timeStep = 15552000; // 时间步长

    constructor() public {
        ownerAddr = msg.sender;
        adminAddr = msg.sender;
        initTime = block.timestamp;
        unlockTime = block.timestamp.add(timeStep);
    }

    /// @dev Black Lists
    mapping (address => bool) blackLists;

    modifier isOwner() {
        require(msg.sender == ownerAddr);
        _;
    }

    modifier isAdmin() {
        require(msg.sender == adminAddr);
        _;
    }

    modifier isNotBlackListed(address _addr){
        require(!blackLists[_addr]);
        _;
    }

    modifier isEvangelist() {
        require(msg.sender == evangelistAddr);
        _;
    }

    modifier isGeek() {
        require(msg.sender == geekAddr);
        _;
    }

    function setAdmin(address _newAdmin) external isOwner {
        require(_newAdmin != address(0));
        adminAddr = _newAdmin;
    }

    function addBlackList(address _addr) external isAdmin {
        blackLists[_addr] = true;
    }

    function removeBlackList(address _addr) external isAdmin {
        delete blackLists[_addr];
    }

    function getBlackListStatus(address _addr) external view returns (bool) {
        return blackLists[_addr];
    }

    function updateUnlockTime(uint nowPrice) external isAdmin {
        require(nowPrice.sub(price) >= priceStep);
        price = price.add(priceStep);
        unlockTime = unlockTime.add(timeStep);
    }

}

contract BTNSToken is TokenAdmin {
    using SafeMath for uint256;
    // Public variables of the token
    string public name = "BTNS token";
    string public symbol = "BTNS";
    uint8 public decimals = 18;
    uint256 public totalSupply = 210000000 * (10 ** uint256(decimals)); // 2.1 billion tokens;

    // This creates an array with all balances
    mapping (address => uint256) public _balances;
    mapping (address => mapping(address => uint256)) private _allowed;

    // This generates a public event on the blockchain that will notify clients
    event Transfer(address indexed from, address indexed to, uint256 value);

    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    // This notifies clients about the amount burnt
    event Burn(address indexed from, uint256 value);

    /**
      * Constructor function
      * Initializes contract with initial supply tokens to the creator of the contract
    */

    constructor() public {
        // 共振和算力 占80%
        _balances[contractAddr] = totalSupply.mul(8).div(10);
    }

    function balanceOf(address _owner) external view returns (uint256) {
        return _balances[_owner];
    }

    function allowance(address _owner, address _spender) external view returns (uint256) {
        return _allowed[_owner][_spender];
    }

    /**
     * Transfer tokens
     *
     * Send `_value` tokens to `_to` from your account
     *
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transfer(address _to, uint256 _value)
    public
    isNotBlackListed(_to)
    isNotBlackListed(msg.sender)
    returns (bool)
    {
        require(_value <= _balances[msg.sender] && _value > 0);

        _balances[msg.sender] = _balances[msg.sender].sub(_value);
        _balances[_to] = _balances[_to].add(_value);

        emit Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
     * Transfer tokens from other address
     *
     * Send `_value` tokens to `_to` on behalf of `_from`
     *
     * @param _from The address of the sender
     * @param _to The address of the recipient
     * @param _value the amount to send
     */
    function transferFrom(address _from, address _to, uint256 _value)
    public
    isNotBlackListed(_from)
    isNotBlackListed(_to)
    isNotBlackListed(msg.sender)
    returns (bool)
    {
        require(_value <= _balances[_from] && _value > 0);
        require(_value <= _allowed[_from][msg.sender]);

        _balances[_from] = _balances[_from].sub(_value);
        _balances[_to] = _balances[_to].add(_value);
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value);
        emit Transfer(_from, _to, _value);
        return true;

    }

    /**
     * Set allowance for other address
     *
     * Allows `_spender` to spend no more than `_value` tokens on your behalf
     *
     * @param _spender The address authorized to spend
     * @param _value the max amount they can spend
     */
    function approve(address _spender, uint256 _value)
    public
    isNotBlackListed(_spender)
    isNotBlackListed(msg.sender)
    returns (bool)
    {
        _allowed[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    /**
     * Destroy tokens
     *
     * Remove `_value` tokens from the system irreversibly
     *
     * @param _value the amount of money to burn
     */
    function burn(uint256 _value)
    public
    isNotBlackListed(msg.sender)
    returns (bool)
    {
        require(_balances[msg.sender] >= _value);   // Check if the sender has enough
        _balances[msg.sender] = _balances[msg.sender].sub(_value);   // Subtract from the sender
        totalSupply = totalSupply.sub(_value);                      // Updates totalSupply
        emit Burn(msg.sender, _value);
        return true;
    }

    /**
     * Destroy tokens from other account
     *
     * Remove `_value` tokens from the system irreversibly on behalf of `_from`.
     *
     * @param _from the address of the sender
     * @param _value the amount of money to burn
     */
    function burnFrom(address _from, uint256 _value)
    public
    isNotBlackListed(_from)
    isNotBlackListed(msg.sender)
    returns (bool)
    {
        require(_balances[_from] >= _value);                // Check if the targeted balance is enough
        require(_value <= _allowed[_from][msg.sender]);    // Check allowance
        _balances[_from] = _balances[_from].sub(_value);                         // Subtract from the targeted balance
        _allowed[_from][msg.sender] = _allowed[_from][msg.sender].sub(_value); // Subtract from the sender's allowance
        totalSupply = totalSupply.sub(_value);                                  // Update totalSupply
        emit Burn(_from, _value);
        return true;
    }

    function unlockEvangelist() public isEvangelist {
        require(evangelist);
        require(block.timestamp > unlockTime);
        evangelist = false;
        _balances[evangelistAddr] = totalSupply.mul(1).div(10);
    }

    function unlockGeek() public isGeek {
        require(geek);
        require(block.timestamp > unlockTime);
        geek = false;
        _balances[geekAddr] = totalSupply.mul(1).div(10);
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
