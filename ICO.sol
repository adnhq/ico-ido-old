// SPDX-License-Identifier: MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ICO { 
    
    struct PurchaseLimit{
        uint256 amount;
        uint256 timeout;
    }

    uint256 public tokensPerAtto;
    uint256 public totalRaised;
    uint256 public hardCap;
    uint256 public saleStart;
    uint256 public saleEnd;

    IERC20 token;

    address public projectOwner;
    address public admin;

    bool public weighted;
    bool public paused;

    mapping(address => PurchaseLimit) public limits;

    event TokenPurchase(address indexed buyer, uint256 amount);
    event PriceUpdate(uint256 newPrice);

    modifier adminOnly {
        require(msg.sender == admin, "ICO: admin only");
        _;
    }

    modifier icoOngoing {
        require(block.timestamp>=saleStart && block.timestamp < saleEnd, "ICO: sale ended");
        _;
    }

    modifier icoEnded {
        require(block.timestamp >= saleEnd || totalRaised>=hardCap, "ICO: sale active");
        _;
    }

    constructor(
        address _admin,
        address _projectOwner, 
        address _tokenAddress, 
        uint256 _tokensPerAtto, 
        uint256 _hardCap, 
        uint256 _saleStart, 
        uint256 _saleEnd, 
        bool _weighted
    ) {
        bool valid = _projectOwner != address(0) && _tokenAddress != address(0) && 
            _saleStart > block.timestamp && _saleEnd > _saleStart && _tokensPerAtto > 0 && _hardCap > 0;

        require(valid, "ICO: constructor argument(s) invalid");

        admin = _admin;
        projectOwner = _projectOwner;
        tokensPerAtto = _tokensPerAtto;
        saleStart = _saleStart;
        saleEnd = _saleEnd;
        hardCap = _hardCap;
        weighted = _weighted;

        token = IERC20(_tokenAddress);
    }

    receive() external payable {
        buyTokens();
    }

    function buyTokens() public payable icoOngoing {
        require(!paused, "ICO: paused");
        require(msg.value > 0, "ICO: incorrect amount");
        require(block.timestamp > limits[msg.sender].timeout, "ICO: timed out");

        limits[msg.sender].amount += msg.value;

        uint256 refund;

        if(limits[msg.sender].amount > 50000e18){   
            refund = limits[msg.sender].amount - 50000e18;

            limits[msg.sender].timeout = block.timestamp + 60 seconds; 
            limits[msg.sender].amount = 0;
        }

        if(msg.value + totalRaised > hardCap) refund = msg.value + totalRaised - hardCap;

        uint256 spentAmount = refund > 0 ? msg.value - refund : msg.value;
        totalRaised += spentAmount;

        require(totalRaised <= hardCap, "ICO: hardcap reached");

        uint256 amount = weighted ? spentAmount * tokensPerAtto / getCurrentRatio() : spentAmount * tokensPerAtto;

        token.transfer(msg.sender, amount);
        if(refund > 0) payable(msg.sender).transfer(refund);
        
        emit TokenPurchase(msg.sender, amount);
    }

    function getCurrentRatio() public view returns (uint8) { 
        if(totalRaised <= hardCap/3) 
            return 1;
        else if(totalRaised > hardCap / 3 && totalRaised <= hardCap / 2) 
            return 2;
        else 
            return 3;
    }

    function updateTokenPrice() external adminOnly icoOngoing {
        require(weighted, "ICO: not weighted");
        tokensPerAtto /= getCurrentRatio();

        emit PriceUpdate(tokensPerAtto);
    } 

    function togglePause() external adminOnly {
        paused = !paused;
    }

    function transferAdminRole(address _newAdmin) external adminOnly {
        admin = _newAdmin;
    }

    function withdraw() external adminOnly icoEnded {
        (bool a_success, ) = payable(admin).call{value: address(this).balance * 10 / 100}("");
        require(a_success);

        (bool o_success, ) = payable(projectOwner).call{value: address(this).balance}("");
        require(o_success);
    }

    function withdrawTokens() external adminOnly icoEnded {
        token.transfer(projectOwner, token.balanceOf(address(this)));
    }

    function burnTokens() external adminOnly icoEnded {
        token.transfer(address(0), token.balanceOf(address(this)));
    }

}
