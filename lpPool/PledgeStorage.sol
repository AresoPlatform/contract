pragma solidity ^0.5.0;


contract AsoLpPoolData {

    address private factory;
    address private _owner;

    constructor() public {
        _owner = msg.sender;
    }

    modifier onlyFactory() {
        require(msg.sender == factory, "Caller is not the factory");
        _;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }

    function isOwner() public view returns (bool) {
        return msg.sender == _owner;
    }

    struct Pledge {
        uint256 amount; 
        uint256 availableAso; 
        address useraddress; 
        uint256 lockTime; 
        uint256 ownerGains; 
        uint256 deltRewards;
    }

    mapping(address => Pledge) public pledges;
    address[] public pledgeList;


    function pushPledges(address useraddress) public onlyFactory returns(uint256,uint256,uint256,uint256) {
        if (pledges[useraddress].useraddress == address(0)) {
            pledges[useraddress].availableAso = 0;
            pledges[useraddress].useraddress = useraddress;
            pledges[useraddress].amount = 0;
            pledges[useraddress].deltRewards = 0;
            pledges[useraddress].ownerGains = 0;
            pledges[useraddress].lockTime = now;
            pledgeList.push(useraddress);
        }
        return (pledges[useraddress].availableAso,pledges[useraddress].amount,pledges[useraddress].deltRewards,pledges[useraddress].ownerGains);
    }

    function getPledgeInfo(address useraddress) public view returns(uint256,uint256,uint256,uint256){
        return (pledges[useraddress].availableAso,pledges[useraddress].amount,pledges[useraddress].deltRewards,pledges[useraddress].ownerGains);
    }

    function setPledgeInfo(address useraddress,uint256 _availableAso,uint256 _amount,uint256 _deltRewards,uint256 _ownerGains) public onlyFactory returns(bool){

        pledges[useraddress].availableAso = _availableAso;
        
        if(_ownerGains > 0) {
            pledges[useraddress].ownerGains = _ownerGains;
        }
        pledges[useraddress].amount = _amount;

        pledges[useraddress].deltRewards = _deltRewards;
        return true;
    }

    function getPledgeListLength() public view returns (uint256) {
        return pledgeList.length;
    }
    
    function getFactory() public view returns (address) {
        return factory;
    }
}
