//SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./IERC20.sol";

    //Events
    contract CrowdFund {
    event Launch(  uint id, address indexed creator,uint goal, uint32 startAt,uint32 endAt);
    event Cancel(uint id);
    event Pledge(uint indexed id, address indexed caller, uint amount);
    event Unpledge(uint indexed id, address indexed caller, uint amount);
    event Claim(uint _id);
    event Refund(uint indexed id, address indexed caller, uint amount);

    // Campaign information
    struct Campaign { address creator; uint goal; uint pledged; uint32 startAt; uint32 endAt; bool claimed;}
 
    //State variables for campaign details
    IERC20 public immutable token;
    uint public count;
    mapping(uint => Campaign) public campaigns;
    mapping(uint => mapping(address => uint)) public pledgedAmount;


    //constructor is calls with  address
    constructor(address _token) { 
        token = IERC20(_token);
    }

    //launching a campaign
    function launch( uint _goal,  uint32 _startAt, uint32 _endAt ) external {
        require(_startAt >= block.timestamp, "start time < now");  
        require(_endAt >= _startAt, "end time < start at"); 
        require(_endAt <= block.timestamp + 90 days, "end time > max duration"); 
        
        count += 1;  

        campaigns[count] = Campaign({  
            creator: msg.sender,  
            goal: _goal,
            pledged: 0,
            startAt: _startAt,
            endAt: _endAt,
            claimed: false
        });
        emit Launch(count, msg.sender, _goal, _startAt, _endAt);
        }
  
  


    //cancellation
    function cancel(uint _id) external {
        Campaign memory campaign = campaigns[_id]; //command the coding to retain this information.


        require(msg.sender == campaign.creator, "not creator.");
        require(block.timestamp < campaign.startAt, "started.");

        delete campaigns[_id];
        emit Cancel(_id);
    }

   
   

    //pledge fund to campiagn 
    function pledge(uint _id, uint _amount) external { 
        Campaign storage campaign = campaigns[_id]; 

        require(block.timestamp >= campaign.startAt, "not started.");
        require(block.timestamp <= campaign.endAt, "ended");


        campaign.pledged += _amount;
        pledgedAmount[_id][msg.sender] += _amount;
        token.transferFrom(msg.sender, address(this), _amount);

        emit Pledge(_id, msg.sender, _amount);
    }




    //unpledge fund 
    function unpledge(uint _id, uint _amount) external { 
        Campaign storage campaign = campaigns[_id];

        require(block.timestamp <= campaign.endAt, "ended");

        campaign.pledged -= _amount;
        pledgedAmount[_id][msg.sender] -= _amount;
        token.transfer(msg.sender, _amount);

        emit Unpledge(_id, msg.sender, _amount);

    }

    
    //claim tokens if all ok
    function claim(uint _id) external {
        Campaign storage campaign = campaigns[_id];

        require(msg.sender == campaign.creator, "not creator");
        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged >= campaign.goal, "pledged < goal");
        require(!campaign.claimed, "claimed");

        campaign.claimed = true;
        token.transfer(msg.sender, campaign.pledged);
        
        emit Claim(_id);
    }



    // refund tokens
    function refund(uint _id) external {
        Campaign storage campaign = campaigns[_id];
        

        require(block.timestamp > campaign.endAt, "not ended");
        require(campaign.pledged < campaign.goal, " goal > pledged ");

        uint bal = pledgedAmount[_id][msg.sender];
        pledgedAmount[_id][msg.sender] = 0;
        token.transfer(msg.sender, bal);

        emit Refund(_id, msg.sender, bal);
    }
}