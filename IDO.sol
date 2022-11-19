// SPDX-License-Identifier: MIT

// IDO sample created for Stellaverse. 
// Roughly based on Artemis. Gas usage can be reduced considerably.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.7;

contract IDO {
    IERC20 constant STLA = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); //REPLACE ADDRESS LATER
    IERC20 public token;

    uint256 public fundingGoal;
    uint256 public tokensPerUnit;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalRaised;
    address public admin;
    address public projectOwner;

    uint256 public totalRaisedT1; 
    uint256 public totalRaisedT2; 
    uint256 public totalRaisedT3;

    uint256 public tierOneMaxCap;
    uint256 public tierTwoMaxCap;
    uint256 public tierThreeMaxCap;

    //total users per tier
    uint256 public totalUserInTierOne;
    uint256 public totalUserInTierTwo;
    uint256 public totalUserInTierThree;

    //max allocations per user in a tier
    uint256 public maxAllocaPerUserTierOne;
    uint256 public maxAllocaPerUserTierTwo;
    uint256 public maxAllocaPerUserTierThree;

    //min allocation per user in a tier
    uint256 public minAllocaPerUserTierOne;
    uint256 public minAllocaPerUserTierTwo;
    uint256 public minAllocaPerUserTierThree;

    bool public finalized;

    mapping(address => bool) private whitelistTierOne;
    mapping(address => bool) private whitelistTierTwo;
    mapping(address => bool) private whitelistTierThree;

    mapping(address => uint256) public tierOneContributions;
    mapping(address => uint256) public tierTwoContributions;
    mapping(address => uint256) public tierThreeContributions;

    modifier hasEnded {
        require(block.timestamp > endTime, "IDO: ido ended");
        _;
    }

    modifier adminOnly { 
        require(msg.sender == admin, "IDO: admin only");
        _;
    }

    constructor(
        address _adminAddress,
        address _tokenAddress,
        address _projectOwner,
        uint256 _fundingGoal,
        uint256 _tokensPerUnit,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _tierOneMaxCap,
        uint256 _tierTwoMaxCap,
        uint256 _tierThreeMaxCap
    ) {
        bool valid = _tokenAddress != address(0) && _startTime > block.timestamp && _startTime < _endTime;

        if(!valid) revert("IDO: invalid constructor args");

        admin = _adminAddress;
        token = IERC20(_tokenAddress);
        projectOwner = _projectOwner;
        fundingGoal = _fundingGoal;
        tokensPerUnit = _tokensPerUnit;
        startTime = _startTime;
        endTime = _endTime;

        tierOneMaxCap = _tierOneMaxCap;
        tierTwoMaxCap = _tierTwoMaxCap;
        tierThreeMaxCap = _tierThreeMaxCap;

        minAllocaPerUserTierOne = 1000; // SAMPLE VALUES
        minAllocaPerUserTierTwo = 2000;
        minAllocaPerUserTierThree = 3000;

        totalUserInTierOne = 2;
        totalUserInTierTwo = 2;
        totalUserInTierThree = 2;

        maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
        maxAllocaPerUserTierTwo = tierTwoMaxCap / totalUserInTierTwo;
        maxAllocaPerUserTierThree = tierThreeMaxCap / totalUserInTierThree;
    }

    receive() external payable {
        buyTokens();
    }

    function updateTierValues(
        uint256 _tierOneValue,
        uint256 _tierTwoValue,
        uint256 _tierThreeValue
    ) external adminOnly {

        tierOneMaxCap = _tierOneValue;
        tierTwoMaxCap = _tierTwoValue;
        tierThreeMaxCap = _tierThreeValue;
       
        maxAllocaPerUserTierOne = tierOneMaxCap / totalUserInTierOne;
        maxAllocaPerUserTierTwo = tierTwoMaxCap / totalUserInTierTwo;
        maxAllocaPerUserTierThree = tierThreeMaxCap / totalUserInTierThree;
    }

    function whiteListAddress(address _user) external adminOnly {
        uint256 balance = STLA.balanceOf(_user);

        if(balance < 10000e18) 
            revert("IDO: Insufficient STLA balance");
        else if(balance < 15000e18) 
            whitelistTierOne[_user] = true;
        else if(balance < 20000e18)
            whitelistTierTwo[_user] = true;
        else 
            whitelistTierThree[_user] = true;
    }

    function transferAdminRole(address _newAdmin) external adminOnly {
        admin = _newAdmin;
    }

    function checkTier(address _user) public view returns (uint8) {
        if(whitelistTierOne[_user]) 
            return 1;
        else if(whitelistTierTwo[_user]) 
            return 2;
        else if(whitelistTierThree[_user]) 
            return 3;
        else 
            return 0;
    } 
    
    function buyTokens() public payable {
        require(block.timestamp > startTime && block.timestamp < endTime, "IDO: sale not active");
        uint8 tier = checkTier(msg.sender);
        require(tier != 0);

        if(tier == 1) {
            tierOneContributions[msg.sender] += msg.value;
            require(
                tierOneContributions[msg.sender] >= minAllocaPerUserTierOne,
                "Amount must be higher"
            );
            require(
                totalRaisedT1 + msg.value <= tierOneMaxCap,
                "Exceeding tier 1 max cap"
            );
            require(
                tierOneContributions[msg.sender] <= maxAllocaPerUserTierOne,
                "Exceeding tier 1 investment limit"
            );

            totalRaisedT1 += msg.value;

        }else if(tier == 2) {
            tierTwoContributions[msg.sender] += msg.value;
            require(
                tierTwoContributions[msg.sender] >= minAllocaPerUserTierTwo,
                "Amount must be higher"
            );
            require(
                totalRaisedT2 + msg.value <= tierTwoMaxCap,
                "Exceeding tier 2 max cap"
            );
            require(
                tierTwoContributions[msg.sender] <= maxAllocaPerUserTierTwo,
                "Exceeding tier 2 investment limit"
            );

            totalRaisedT2 += msg.value;

        }else if(tier == 3) {
            tierThreeContributions[msg.sender] += msg.value;
            require(
                tierThreeContributions[msg.sender] >= minAllocaPerUserTierThree,
                "Amount must be higher"
            );
            require(
                totalRaisedT3 + msg.value <= tierThreeMaxCap,
                "Exceeding tier 3 max cap"
            );
            require(
                tierThreeContributions[msg.sender] <= maxAllocaPerUserTierThree,
                "Exceeding tier 3 investment limit"
            );

            totalRaisedT3 += msg.value;

        }else revert("IDO: not whitelisted");

        totalRaised += msg.value;

    }

    function claimTokens() external hasEnded {
        require(_goalReached(), "IDO: goal not reached");
        uint8 tier = checkTier(msg.sender);
        uint256 tokens;
    
        if(tier == 1) {
            require(tierOneContributions[msg.sender]>0);
            tokens = tierOneContributions[msg.sender]/tokensPerUnit;
            tierOneContributions[msg.sender] = 0;
        }else if(tier == 2){
            require(tierTwoContributions[msg.sender]>0);
            tokens = tierTwoContributions[msg.sender]/tokensPerUnit;
            tierTwoContributions[msg.sender] = 0;
        }else if(tier == 3){
            require(tierThreeContributions[msg.sender]>0);
            tokens = tierThreeContributions[msg.sender]/tokensPerUnit;
            tierThreeContributions[msg.sender] = 0;
        }else {
            revert("Not whitelisted");
        }

        token.transfer(msg.sender, tokens);

    }

    function claimRefund() external hasEnded {
        require(!_goalReached(), "IDO: goal not reached");
        require(tierOneContributions[msg.sender] > 0 
        || tierTwoContributions[msg.sender] > 0 
        || tierThreeContributions[msg.sender]>0 
        , "IDO: not contribution");

        uint8 tier = checkTier(msg.sender);
        uint256 refund;

        if(tier == 1) {
            refund = tierOneContributions[msg.sender];
            tierOneContributions[msg.sender] = 0;
        }else if(tier == 2) {
            refund = tierTwoContributions[msg.sender];
            tierTwoContributions[msg.sender] = 0;
        }else if(tier == 3) {
            refund = tierThreeContributions[msg.sender];
            tierThreeContributions[msg.sender] = 0;
        }else revert("Not whitelisted");
        
        payable(msg.sender).transfer(refund);
        
    }

    function endIDO() external adminOnly hasEnded {
        require(!finalized, "IDO ended");
        finalized = true;

        if(_goalReached()){
            (bool a_success, ) = payable(admin).call{value: address(this).balance * 10 / 100}("");
            require(a_success);
            (bool o_success, ) = payable(projectOwner).call{value: address(this).balance}("");
            require(o_success);
        }
    }

    function withdrawTokens() external adminOnly {
        require(finalized, "IDO: IDO is not over");

        token.transfer(projectOwner, token.balanceOf(address(this)));
    }

    function _goalReached() internal view returns (bool) {
        return totalRaised >= fundingGoal;
    }
}
