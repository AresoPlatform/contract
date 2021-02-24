pragma solidity ^0.5.0;

import "./SafeMath.sol";
import "./Ownable.sol";

contract AsoPoolV1 is Ownable {
    using SafeMath for uint256;

    ASOToken asoToken;
    PledgeStorage pledgeStorage;

    address public apAddress;
    address public systemDev;
    address public blackHole;

    uint256 public lastRewardBlock;
    uint256 public pendingAso;
    uint256 public totalPledge;
    uint256 public startRewardBlock;
    uint256 public genesisTime;
    uint256 public totalAmount;
    uint256 public ratioValue;
    


    constructor() public {
        totalPledge = 0;
        lastRewardBlock = 0;
        pendingAso = 0;
        startRewardBlock = 0;
        totalAmount = 48000000 * (10**uint256(6));
        genesisTime = now;
    }

    function totalSupply() public view returns (uint256) {
        return totalAmount;
    }


    modifier onlyApAddress() {
        require(msg.sender == apAddress, "Caller is not the minter");
        _;
    }

    function balanceOf(address account) public view returns (uint256){
        return asoToken.balanceOf(account);
    }

    function updateBlock() public onlyOwner {
        if (block.number > lastRewardBlock) {
            _updateRewardInfo();
        }
    }

    function takeGain() public whenNotPaused{
 
        if (lastRewardBlock == 0) return;

        if (block.number > lastRewardBlock) {
            _updateRewardInfo();
        }

        uint256 availableAso;
        uint256 amount;
        uint256 deltRewards;
        uint256 ownerGains;
        (availableAso,amount,deltRewards,ownerGains) = pledgeStorage.getPledgeInfo(msg.sender);

        uint256 pending = amount.mul(ratioValue).div(1e12).sub(deltRewards);
        if(pending > 0) {
            availableAso = availableAso.add(pending);
        }

        deltRewards = amount.mul(ratioValue).div(1e12);


        if (availableAso == 0) return;
        uint256 practicalAmount = availableAso.mul(87).div(100);
        uint256 serviceAmount = availableAso.mul(13).div(100);
        ownerGains = ownerGains.add(practicalAmount);

        asoToken.transferByOwner(msg.sender, practicalAmount);
        asoToken.transferByOwner(systemDev, serviceAmount.mul(5).div(13));
        asoToken.transferByOwner(blackHole, serviceAmount.mul(8).div(13));

        pledgeStorage.setPledgeInfo(msg.sender,0,amount,deltRewards,ownerGains);
    }

    function pledgeDo(address useraddress, uint256 _amount) public whenNotPaused onlyApAddress {
        if (_amount == 0) return;

        if (lastRewardBlock == 0) {
            lastRewardBlock = block.number;
            startRewardBlock = block.number;
        }

        pledgeStorage.pushPledges(useraddress);

        _updateRewardInfo();

        uint256 availableAso;
        uint256 amount;
        uint256 deltRewards;
        uint256 ownerGains;
        (availableAso,amount,deltRewards,ownerGains) = pledgeStorage.getPledgeInfo(useraddress);
        
        if (amount > 0) {
            uint256 pending = amount.mul(ratioValue).div(1e12).sub(deltRewards);
            if(pending > 0) {
                availableAso = availableAso.add(pending);
            }
        }
        amount = amount.add(_amount);
        totalPledge = totalPledge.add(_amount);

        deltRewards = amount.mul(ratioValue).div(1e12);

        pledgeStorage.setPledgeInfo(useraddress,availableAso,amount,deltRewards,ownerGains);
    }

    function selectGain() public view returns (uint256) {
        uint256 currentBlock = block.number;
        if (lastRewardBlock == 0) return 0;

        uint256 availableAso;
        uint256 amount;
        uint256 deltRewards;
        (availableAso,amount,deltRewards,) = pledgeStorage.getPledgeInfo(msg.sender);

        if (currentBlock > lastRewardBlock) {
            uint256 _ratioValue = ratioValue;
            uint256 unmintedAso = _calculateReward(lastRewardBlock + 1, currentBlock);
            _ratioValue = _ratioValue.add(unmintedAso.mul(1e12).div(totalPledge));
            uint256 pending = amount.mul(_ratioValue).div(1e12).sub(deltRewards);
            return availableAso.add(pending);
        } else {
            return availableAso;
        }
    }

    function selectPrincipal() public view returns (uint256) {
        uint256 amount;
        (,amount,,) = pledgeStorage.getPledgeInfo(msg.sender);
        return amount;
    }

    function selectTotalGain() public view returns (uint256) {
        uint256 ownerGains;
        (,,,ownerGains) = pledgeStorage.getPledgeInfo(msg.sender);
        return ownerGains;
    }

    function getPledgeListLength() public view returns (uint256) {
        return pledgeStorage.getPledgeListLength();
    }


    function _calculateReward(uint256 from, uint256 to) public view returns (uint256) {
        uint256 section_1  = 12 * 1e6;
        uint256 section_2  = 42 * 1e5;
        uint256 section_3  = 12 * 1e5;
        uint256 section_6  = 6 * 1e5;
        uint256 section_4  = 3 * 1e5;
        uint256 section_5  = 0;

        require(from <= to);

        if (to <= (startRewardBlock + 864000)) {
            return to.sub(from).add(1).mul(section_1);
        } else if (from > (startRewardBlock + 864000) && to <= (startRewardBlock + 1728000)) {
            return to.sub(from).add(1).mul(section_2);
        } else if (from > (startRewardBlock + 1728000) && to <= (startRewardBlock + 2592000)) {
            return to.sub(from).add(1).mul(section_3);
        } else if (from > (startRewardBlock + 2592000) && to <= (startRewardBlock + 4320000)) {
            return to.sub(from).add(1).mul(section_6);
        } else if (from > (startRewardBlock + 4320000) && to <= (startRewardBlock + 10512000)) {
            return to.sub(from).add(1).mul(section_4);
        } else if(from > (startRewardBlock + 10512000)) {
            return 0;
        } else {
            if (from <= (startRewardBlock + 864000) && to >= (startRewardBlock + 864000)) {
                return section_1.mul((startRewardBlock + 864000).sub(from).add(1)).add(section_2.mul(to.sub((startRewardBlock + 864000))));
            } else if (from <= (startRewardBlock + 1728000) && to >= (startRewardBlock + 1728000)) {
                return section_2.mul((startRewardBlock + 1728000).sub(from).add(1)).add(section_3.mul(to.sub((startRewardBlock + 1728000))));
            } else if (from <= (startRewardBlock + 2592000) && to >= (startRewardBlock + 2592000)) {
                return section_3.mul((startRewardBlock + 2592000).sub(from).add(1)).add(section_6.mul(to.sub((startRewardBlock + 2592000))));
            } else if (from <= (startRewardBlock + 4320000) && to >= (startRewardBlock + 4320000)) {
                return section_6.mul((startRewardBlock + 4320000).sub(from).add(1)).add(section_4.mul(to.sub((startRewardBlock + 4320000))));
            } else {
                return section_4.mul((startRewardBlock + 10512000).sub(from).add(1));
            }
        }
    }

    function _updateRewardInfo() internal {
        uint256 asosReadyToMinted = 0;
        uint256 currentBlock = block.number;

        if (lastRewardBlock == 0) return;
        if (currentBlock <= lastRewardBlock) return;

        asosReadyToMinted = _calculateReward(lastRewardBlock + 1, currentBlock);
        
        pendingAso = pendingAso.add(asosReadyToMinted);

        ratioValue = ratioValue.add(asosReadyToMinted.mul(1e12).div(totalPledge));

        lastRewardBlock = block.number;
    }

    function getRewardsPerBlock() public view returns (uint256) {
        if(startRewardBlock == 0){
            return 0;
        }
        uint256 currentBlock = block.number;
        uint256 section_1  = 12 * 1e6;
        uint256 section_2  = 42 * 1e5;
        uint256 section_3  = 12 * 1e5;
        uint256 section_6  = 6 * 1e5;
        uint256 section_4  = 3 * 1e5;
        uint256 section_5  = 0;

        if (currentBlock <= (startRewardBlock + 864000)) {
            return section_1;
        } else if (currentBlock > (startRewardBlock + 864000) && currentBlock <= (startRewardBlock + 1728000)) {
            return section_2;
        } else if (currentBlock > (startRewardBlock + 1728000) && currentBlock <= (startRewardBlock + 2592000)) {
            return section_3;
        } else if (currentBlock > (startRewardBlock + 2592000) && currentBlock <= (startRewardBlock + 4320000)) {
            return section_6;
        } else if (currentBlock > (startRewardBlock + 4320000) && currentBlock <= (startRewardBlock + 10512000)) {
            return section_4;
        } else {
            return section_5;
        } 


    }


    function getTotalPendingAso() public view returns (uint256) {
        uint256 currentBlock = block.number;

        if (lastRewardBlock == 0) return 0;

        uint256 unmintedAso = _calculateReward(lastRewardBlock + 1, currentBlock);
        return pendingAso.add(unmintedAso);
    }

    function getApAddress() public view returns (address) {
        return apAddress;
    }

}
