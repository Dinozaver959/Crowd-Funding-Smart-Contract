// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


/** 
 * @title CrowdFund
 * @dev Implements crowdfunding platform for ERC20 tokens
 */
contract CrowdFund {

    struct Project {
        address owner;           // owner of the project
        uint deadline;           // deadline for raising funds
        uint goal;               // the amount to raise
        uint amountRaised;       // total amount raised so far
        address erc20Token;      // contract address of the ERC20 token that we are raising in
    }    

    uint numberOfProject;
    mapping (uint => Project) projects;
    mapping (uint => mapping(address => uint)) donations;    // mapping of donations for each user of each project
    
    event TokensDonated(address indexed from, uint indexed project, uint256 amount, address erc20Token);
    event TokensWithdrawenByOwner(address indexed by, uint indexed project, uint256 amount, address erc20Token);
    event TokensWithdrawenByUser(address indexed by, uint indexed project, uint256 amount, address erc20Token);
    


    ////////////////////////////////  
    //          Modifiers         //
    ////////////////////////////////

    function _onlyOwner(uint project) private view {
        require(projects[project].owner == msg.sender, "not project owner");
    }
    modifier onlyOwner(uint project){
        _onlyOwner(project);
        _;
    }

    function _fundingGoalReached(uint project) private view {
        require(projects[project].amountRaised >= projects[project].goal, "Funding goal has not been reached");
    }
    modifier fundingGoalReached(uint project){
        _fundingGoalReached(project);
        _;
    }

    function _fundingGoalNotReached(uint project) private view {
        require(
            projects[project].amountRaised < projects[project].goal && 
            block.timestamp > projects[project].deadline,
            "Funding goal has actually been reached"
        );
    }
    modifier fundingGoalNotReached(uint project){
        _fundingGoalNotReached(project);
        _;
    }

    function _withInDeadLine(uint project) private view {
        require(projects[project].deadline >= block.timestamp, "Deadline for crowdfunding has passed");
    }
    modifier withInDeadLine(uint project){
        _withInDeadLine(project);
        _;
    }



    ///////////////////////////////////////  
    //          Setter Functions         //
    ///////////////////////////////////////

    /**
    * @notice Function to create a new project
    */
    function startNewCrowdFund (
        uint _timeForCrowdFunding,         // in seconds from now
        uint _goal,
        address _erc20Token
    ) external {
        projects[numberOfProject] = Project(msg.sender, block.timestamp + _timeForCrowdFunding, _goal, 0, _erc20Token);
        ++numberOfProject;
    }

    /**
    * @notice Function for donating to the project
    */
    function donate (
        uint project,               // 0-indexed project to donate to
        uint amountToDonate         // amount to donate
    ) external withInDeadLine(project) {

        // get the ERC20 token address for the crowdfunding
        address erc20Token = projects[project].erc20Token;

        require(IERC20(erc20Token).balanceOf(msg.sender) >= amountToDonate, "balance too low");      
        require(IERC20(erc20Token).allowance(msg.sender, address(this)) >= amountToDonate, "allowance too low");

        // update balance of user AND balance of the project
        donations[project][msg.sender] += amountToDonate;
        projects[project].amountRaised += amountToDonate;

        // transfer ERC20
        IERC20(erc20Token).transferFrom(msg.sender, address(this), amountToDonate);

        // emit event
        emit TokensDonated(msg.sender, project, amountToDonate, erc20Token);
    }

    /**
    * @notice Function for withdrawing funds by the owner for a successfully crowdfunded project
    */
    function withdrawOwner (uint project) external onlyOwner(project) fundingGoalReached(project) {

        // get the ERC20 token address for the crowdfunding
        address erc20Token = projects[project].erc20Token;

        uint amount = projects[project].amountRaised;

        // set balance to 0
        projects[project].amountRaised = 0;

        // transfer ERC20 to owner
        IERC20(erc20Token).transfer(msg.sender, amount);

        // emit event
        emit TokensWithdrawenByOwner(msg.sender, project, amount, erc20Token);  
    }

    /**
    * @notice Function for withdrawing funds by the user for an unsuccessfully crowdfunded project
    */
    function withdrawUser (uint project) external fundingGoalNotReached(project) {

        // get the ERC20 token address for the crowdfunding
        address erc20Token = projects[project].erc20Token;

        // get amount
        uint amountDonatedByUser = donations[project][msg.sender];

        // set balance to 0
        donations[project][msg.sender] = 0;
        // optionally: (note, we can keep the total amount raised by the project as a reference
        // note that owner cannot withdraw, only users can, so it doesn't change anything)
        // projects[project].amountRaised -= amountDonatedByUser;

        // transfer ERC20 to user
        IERC20(erc20Token).transfer(msg.sender, amountDonatedByUser);

        // emit event
        emit TokensWithdrawenByUser(msg.sender, project, amountDonatedByUser, erc20Token);  
    }



    ///////////////////////////////////////  
    //          Getter Functions         //
    ///////////////////////////////////////

    /**
    * @notice Function gets the time remainig for the crowdfunding of a project
    */
    function TimeRemaining(uint project) external view returns(uint) {

        return (projects[project].deadline > block.timestamp ? (projects[project].deadline - block.timestamp) : 0);
    }

    /**
    * @notice Function returns bool flag whether goal has been reached
    */
    function HasTheGoalBeenReached(uint project) external view returns(bool) {
        return (projects[project].amountRaised >= projects[project].goal ? true : false);       
    }

    /**
    * @notice Function gets the amount raised by a project
    */
    function AmountRaisedByTheProject(uint project) external view returns(uint) {
        return projects[project].amountRaised;       
    }

    /**
    * @notice Function gets amount donated by the user for the project
    */
    function AmountDonatedByUserForTheProject(uint project, address user) external view returns(uint) {
        return donations[project][user];       
    }

    /**
    * @notice Function gets the project details
    */
    function GetProjectDetails(uint project) external view returns(Project memory) {
        return projects[project];       
    }
}