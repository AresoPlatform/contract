pragma solidity ^0.5.0;

contract Context {
    function _msgSender() internal view returns (address payable) {
        return msg.sender;
    }

    function _msgData() internal view returns (bytes memory) {
        this; 
        return msg.data;
    }
}

library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;

        return c;
    }
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

contract Ownable is Context {
    address private _owner;
    bool private _paused;

    constructor () internal {
         _paused = false;
        _owner = _msgSender();
    }
    function owner() public view returns (address) {
        return _owner;
    }
    modifier onlyOwner() {
        require(isOwner(), "Ownable: caller is not the owner");
        _;
    }
    function isOwner() public view returns (bool) {
        return _msgSender() == _owner;
    }
    modifier whenNotPaused() {
        require(!_paused, "Pausable: paused");
        _;
    }

    modifier whenPaused() {
        require(_paused, "Pausable: not paused");
        _;
    }
    
    function pause() public onlyOwner whenNotPaused {
        _paused = true;
    }

    function unpause() public onlyOwner whenPaused {
        _paused = false;
    }
}


interface IERC20 {
    function totalSupply() external view returns (uint256);
    function balanceOf(address account) external view returns (uint256);
    function transfer(address recipient, uint256 amount) external returns (bool);
    function mint(address account, uint amount) external;
    function allowance(address owner, address spender) external view returns (uint256);
    function approve(address spender, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);
}


library SafeERC20 {
    using SafeMath for uint256;

    function safeTransfer(IERC20 token, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transfer.selector, to, value));
    }

    function safeTransferFrom(IERC20 token, address from, address to, uint256 value) internal {
        callOptionalReturn(token, abi.encodeWithSelector(token.transferFrom.selector, from, to, value));
    }

    function safeApprove(IERC20 token, address spender, uint256 value) internal {
        require((value == 0) || (token.allowance(address(this), spender) == 0),
            "SafeERC20: approve from non-zero to non-zero allowance"
        );
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, value));
    }

    function safeIncreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).add(value);
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function safeDecreaseAllowance(IERC20 token, address spender, uint256 value) internal {
        uint256 newAllowance = token.allowance(address(this), spender).sub(value, "SafeERC20: decreased allowance below zero");
        callOptionalReturn(token, abi.encodeWithSelector(token.approve.selector, spender, newAllowance));
    }

    function callOptionalReturn(IERC20 token, bytes memory data) private {
        (bool success, bytes memory returndata) = address(token).call(data);
        require(success, "SafeERC20: low-level call failed");

        if (returndata.length > 0) { // Return data is optional
            require(abi.decode(returndata, (bool)), "SafeERC20: ERC20 operation did not succeed");
        }
    }
}

contract AsoLpPoolV1 is Ownable {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    ASOToken asoToken;
    PledgeStorage pledgeStorage;
    IERC20 public y;

    address public systemDev;
    address public blackHole;

    uint256 public lastRewardBlock;
    uint256 public pendingAso;
    uint256 public totalPledge;
    uint256 public startRewardBlock;
    uint256 public genesisTime;
    uint256 public ratioValue;
    uint256 public lpBlock;
    uint256 public block_2;
    uint256 public block_3;
    uint256 public block_4;
    uint256 public block_5;

    constructor() public {
        totalPledge = 0;
        lastRewardBlock = 26920892;
        pendingAso = 0;
        ratioValue = 0;
        startRewardBlock = 26056892;
        lpBlock = 864000;
        block_2 = 2592000;
        block_3 = 4320000;
        block_4 = 10512000;
        block_5 = 20512000;
        genesisTime = now;
    }
    

    function stakeLp(uint256 amount) internal {
        y.safeTransferFrom(msg.sender, address(this), amount);
    }

    function withdrawLp(uint256 amount) internal {
        y.safeTransfer(msg.sender, amount);
    }


    function exit() public whenNotPaused{
        if (block.number <= lastRewardBlock) return;
        uint256 amount;
        (,amount,,) = pledgeStorage.getPledgeInfo(msg.sender);
        if (amount <= 0) return;
        repealPledge(amount);
    }

    function repealPledge(uint256 _repealAmount) public whenNotPaused{
        if (block.number <= lastRewardBlock) return;
        if(_repealAmount == 0) return;

        uint256 availableAso;
        uint256 amount;
        uint256 deltRewards;
        uint256 ownerGains;
        (availableAso,amount,deltRewards,ownerGains) = pledgeStorage.getPledgeInfo(msg.sender);

        if (_repealAmount > amount){
            return;
        }

        if(amount == 0) return;

        if (block.number > lastRewardBlock) {
            _updateRewardInfo();
        }

        uint256 pending = amount.mul(ratioValue).div(1e12).sub(deltRewards);
        if(pending > 0) {
            availableAso = availableAso.add(pending);
        }

        totalPledge = totalPledge.sub(_repealAmount);
        amount = amount.sub(_repealAmount);
        deltRewards = amount.mul(ratioValue).div(1e12);
        pledgeStorage.setPledgeInfo(msg.sender,availableAso,amount,deltRewards,ownerGains);

        withdrawLp(_repealAmount);

    }

    function takeGain() public whenNotPaused{
 
        if (block.number <= lastRewardBlock) return;

        _updateRewardInfo();

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

        asoToken.transferByLp(msg.sender, practicalAmount);
        asoToken.transferByLp(systemDev, serviceAmount.mul(5).div(13));
        asoToken.transferByLp(blackHole, serviceAmount.mul(8).div(13));

        pledgeStorage.setPledgeInfo(msg.sender,0,amount,deltRewards,ownerGains);
    }


    function stake(uint256 _amount) public whenNotPaused {
        require(_amount > 0, "Cannot stake 0");
        require(block.number > (startRewardBlock+lpBlock), "lp no start");

        stakeLp(_amount);

        uint256 availableAso;
        uint256 amount;
        uint256 deltRewards;
        uint256 ownerGains;
        (availableAso,amount,deltRewards,ownerGains) = pledgeStorage.pushPledges(msg.sender);

        uint256 asosReadyToMinted = _updateRewardInfo();
        
        if (amount > 0) {
            uint256 pending = amount.mul(ratioValue).div(1e12).sub(deltRewards);
            if(pending > 0) {
                availableAso = availableAso.add(pending);
            }
        }
        if (totalPledge == 0){
            availableAso = availableAso.add(asosReadyToMinted);
        }
        amount = amount.add(_amount);
        totalPledge = totalPledge.add(_amount);

        deltRewards = amount.mul(ratioValue).div(1e12);

        pledgeStorage.setPledgeInfo(msg.sender,availableAso,amount,deltRewards,ownerGains);
    }

    function selectGain() public view returns (uint256) {
        uint256 currentBlock = block.number;

        uint256 availableAso;
        uint256 amount;
        uint256 deltRewards;
        (availableAso,amount,deltRewards,) = pledgeStorage.getPledgeInfo(msg.sender);

        if (currentBlock > lastRewardBlock && amount > 0) {
            uint256 _ratioValue = ratioValue;
            uint256 unmintedAso = _calculateReward(lastRewardBlock + 1, currentBlock);
            _ratioValue = _ratioValue.add(unmintedAso.mul(1e12).div(totalPledge));
            uint256 pending = amount.mul(_ratioValue).div(1e12).sub(deltRewards);
            return availableAso.add(pending);
        } else {
            return availableAso;
        }
    }

    function selectlpAmount() public view returns (uint256) {
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
        uint256 section_3  = 18 * 1e5;
        uint256 section_6  = 24 * 1e5;
        uint256 section_4  = 12 * 1e5;
        uint256 section_5  = 75 * 1e4;

        require(from <= to);

        if (to <= (startRewardBlock + block_2)) {
            return to.sub(from).add(1).mul(section_3);
        } else if (from > (startRewardBlock + block_2) && to <= (startRewardBlock + block_3)) {
            return to.sub(from).add(1).mul(section_6);
        } else if (from > (startRewardBlock + block_3) && to <= (startRewardBlock + block_4)) {
            return to.sub(from).add(1).mul(section_4);
        } else if(from > (startRewardBlock + block_4) && to <= (startRewardBlock + block_5)) {
            return to.sub(from).add(1).mul(section_5);
        } else if(from > (startRewardBlock + block_5)){
            return 0;
        } else {
            if (from <= (startRewardBlock + block_2) && to >= (startRewardBlock + block_2)) {
                return section_3.mul((startRewardBlock + block_2).sub(from).add(1)).add(section_6.mul(to.sub((startRewardBlock + block_2))));
            } else if (from <= (startRewardBlock + block_3) && to >= (startRewardBlock + block_3)) {
                return section_6.mul((startRewardBlock + block_3).sub(from).add(1)).add(section_4.mul(to.sub((startRewardBlock + block_3))));
            } else if (from <= (startRewardBlock + block_4) && to >= (startRewardBlock + block_4)) {
                return section_4.mul((startRewardBlock + block_4).sub(from).add(1)).add(section_5.mul(to.sub((startRewardBlock + block_4))));
            } else {
                return section_5.mul((startRewardBlock + block_5).sub(from).add(1));
            }
        }
    }

    function _updateRewardInfo() internal returns(uint256) {
        uint256 asosReadyToMinted = 0;
        uint256 currentBlock = block.number;

        if (currentBlock <= lastRewardBlock) return 0;

        asosReadyToMinted = _calculateReward(lastRewardBlock + 1, currentBlock);
        
        pendingAso = pendingAso.add(asosReadyToMinted);

        if (totalPledge > 0){
            ratioValue = ratioValue.add(asosReadyToMinted.mul(1e12).div(totalPledge));
        }
        lastRewardBlock = block.number;
        return asosReadyToMinted;
    }

    function getRewardsPerBlock() public view returns (uint256) {
        uint256 currentBlock = block.number;
        if(currentBlock <= lastRewardBlock){
            return 0;
        }
        uint256 section_3  = 18 * 1e5;
        uint256 section_6  = 24 * 1e5;
        uint256 section_4  = 12 * 1e5;
        uint256 section_5  = 75 * 1e4;

        if (currentBlock <= (startRewardBlock + block_2)) {
            return section_3;
        } else if (currentBlock > (startRewardBlock + block_2) && currentBlock <= (startRewardBlock + block_3)) {
            return section_6;
        } else if (currentBlock > (startRewardBlock + block_3) && currentBlock <= (startRewardBlock + block_4)) {
            return section_4;
        } else if (currentBlock > (startRewardBlock + block_4) && currentBlock <= (startRewardBlock + block_5)) {
            return section_5;
        } else {
            return 0;
        }


    }

    function getTotalPendingAso() public view returns (uint256) {
        uint256 currentBlock = block.number;

        if (currentBlock <= lastRewardBlock) return pendingAso;

        uint256 unmintedAso = _calculateReward(lastRewardBlock + 1, currentBlock);
        return pendingAso.add(unmintedAso);
    }


}