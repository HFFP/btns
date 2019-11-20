pragma solidity ^0.5.0;

contract BTNS {
    mapping(address => uint256) addressInvitation;
    uint256 invitationCode = 9999;

    event RegisteredInvitation(address indexed from, uint256 indexed code);

    constructor() public{
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

}
