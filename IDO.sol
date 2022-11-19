// SPDX-License-Identifier: MIT

// IDO sample created for Stellaverse. 
// Roughly based on Artemis. Gas usage can be reduced considerably.

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

pragma solidity 0.8.7;

contract IDO {
    IERC20 constant STLA = IERC20(0x6B175474E89094C44Da98b954EedeAC495271d0F); //REPLACE ADDRESS LATER
    IERC20 public token;

    address public constant ADMIN = 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4;
    address public projectOwner;
    bool public finalized;

    uint256 public fundingGoal;
    uint256 public tokensPerUnit;
    uint256 public startTime;
    uint256 public endTime;
    uint256 public totalRaised;
    
    uint256 public totalRaisedTierOne; 
    uint256 public totalRaisedTierTwo; 
    uint256 public totalRaisedTierThree;

    //total users per tier
    uint256 public totalUserInTierOne;
    uint256 public totalUserInTierTwo;
    uint256 public totalUserInTierThree;

    uint256 public maxCapTierOne;
    uint256 public maxCapTierTwo;
    uint256 public maxCapTierThree;

    //max allocations per user in a tier
    uint256 public maxAllocaPerUserTierOne;
    uint256 public maxAllocaPerUserTierTwo;
    uint256 public maxAllocaPerUserTierThree;

    //min allocation per user in a tier
    uint256 public minAllocaPerUserTierOne;
    uint256 public minAllocaPerUserTierTwo;
    uint256 public minAllocaPerUserTierThree;

    // Replace with struct to reduce gas costs

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
        require(msg.sender == ADMIN, "IDO: admin only");
        _;
    }

    constructor(
        address _token,
        address _projectOwner,
        uint256 _fundingGoal,
        uint256 _tokensPerUnit,
        uint256 _startTime,
        uint256 _endTime,
        uint256 _maxCapTierOne,
        uint256 _maxCapTierTwo,
        uint256 _maxCapTierThree
    ) {
        bool valid = _token != address(0) && _startTime > block.timestamp && _startTime < _endTime;

        if(!valid) revert("IDO: invalid constructor args");

        token = IERC20(_token);
        projectOwner = _projectOwner;
        fundingGoal = _fundingGoal;
        tokensPerUnit = _tokensPerUnit;
        startTime = _startTime;
        endTime = _endTime;

        maxCapTierOne = _maxCapTierOne;
        maxCapTierTwo = _maxCapTierTwo;
        maxCapTierThree = _maxCapTierThree;

        minAllocaPerUserTierOne = 1000; // SAMPLE VALUES
        minAllocaPerUserTierTwo = 2000;
        minAllocaPerUserTierThree = 3000;

        totalUserInTierOne = 2;
        totalUserInTierTwo = 2;
        totalUserInTierThree = 2;

        maxAllocaPerUserTierOne = maxCapTierOne / totalUserInTierOne;
        maxAllocaPerUserTierTwo = maxCapTierTwo / totalUserInTierTwo;
        maxAllocaPerUserTierThree = maxCapTierThree / totalUserInTierThree;
    }

    receive() external payable {
        buyTokens();
    }

    function updateTierValues(
        uint256 _tierOneValue,
        uint256 _tierTwoValue,
        uint256 _tierThreeValue
    ) external adminOnly {

        maxCapTierOne = _tierOneValue;
        maxCapTierTwo = _tierTwoValue;
        maxCapTierThree = _tierThreeValue;
       
        maxAllocaPerUserTierOne = maxCapTierOne / totalUserInTierOne;
        maxAllocaPerUserTierTwo = maxCapTierTwo / totalUserInTierTwo;
        maxAllocaPerUserTierThree = maxCapTierThree / totalUserInTierThree;
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
                totalRaisedTierOne + msg.value <= maxCapTierOne,
                "Exceeding tier 1 max cap"
            );
            require(
                tierOneContributions[msg.sender] <= maxAllocaPerUserTierOne,
                "Exceeding tier 1 investment limit"
            );

            totalRaisedTierOne += msg.value;

        }else if(tier == 2) {
            tierTwoContributions[msg.sender] += msg.value;
            require(
                tierTwoContributions[msg.sender] >= minAllocaPerUserTierTwo,
                "Amount must be higher"
            );
            require(
                totalRaisedTierTwo + msg.value <= maxCapTierTwo,
                "Exceeding tier 2 max cap"
            );
            require(
                tierTwoContributions[msg.sender] <= maxAllocaPerUserTierTwo,
                "Exceeding tier 2 investment limit"
            );

            totalRaisedTierTwo += msg.value;

        }else if(tier == 3) {
            tierThreeContributions[msg.sender] += msg.value;
            require(
                tierThreeContributions[msg.sender] >= minAllocaPerUserTierThree,
                "Amount must be higher"
            );
            require(
                totalRaisedTierThree + msg.value <= maxCapTierThree,
                "Exceeding tier 3 max cap"
            );
            require(
                tierThreeContributions[msg.sender] <= maxAllocaPerUserTierThree,
                "Exceeding tier 3 investment limit"
            );

            totalRaisedTierThree += msg.value;

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
        , "IDO: no contribution");

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
            (bool a_success, ) = payable(msg.sender).call{value: address(this).balance * 10 / 100}("");
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
