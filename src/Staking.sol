//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

/**
 * @title Staking Smart contract allows user to stake and earn reward token based on it.
 * @author Parth Sharma
 * @notice To interact with protocol, you must deploy the code through anvil and test network and then run interaction script. This contract code is not production ready now. We should have to conduct security reviews over the contract code.
 */
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Staking {
    ////////////// ERROR ///////////////
    error Staking__NotAuthorized();
    error Staking__DurationNotFinishedYet();
    error Staking__NotEnoughToken();
    error Staking__ShouldNotBeZero();
    error Staking__SetsTheDurationFirst();
    error Staking__CurrentlyNotStaking();
    error Staking__DurationOutdated();

    ////////////// EVENTs //////////////
    event RewardsUpdated(uint256 amount);
    event DurationUpdated(uint256 duration);
    event AmountStaked(address indexed staker, uint256 amount);
    event Unstaked(address indexed staker, uint256 amount);
    event RewardsClaimed(address indexed staker, uint256 reward);

    ///////////// CONSTANTS AND IMMUTABLE /////////////////////
    address public immutable i_owner; // owner of the contract.
    uint256 public constant PRECISION = 1e18;

    ////////////// State Variables /////////////////
    IERC20 public s_stakeToken; //Token to stake
    IERC20 public s_rewardToken; //Token to recieve as reward
    uint256 public s_rewardPerSecond; // reward rate per second.
    uint256 public s_rewardRate; // rate of reward based on staking amount
    uint256 public s_duration; // duration of the stake
    uint256 public s_finishedAt; // instance where the duration end.
    uint256 public s_updatedAt; // q can we initialize it here.
    // Staking Balances of user
    mapping(address => uint256) public s_stakedUserAmount;
    //Rewards earned by user
    mapping(address => uint256) public s_rewards;
    // last time reward updated
    mapping(address => uint256) public s_userRewardUpdatedAt;

    //////////////// Constructor //////////////////////////
    constructor(address _stakeToken, address _rewardToken) {
        s_stakeToken = IERC20(_stakeToken);
        s_rewardToken = IERC20(_rewardToken);
        i_owner = msg.sender;
    }

    /////////////////// Modifiers ///////////////////////////////
    modifier onlyOwner() {
        if (msg.sender != i_owner) {
            revert Staking__NotAuthorized();
        }
        _;
    }

    /**
     * @dev This External function allows only the owner to set the period of the staking. It updates the storage variables. The function follows CEI(checks, effects, external interactions).
     * @param _duration  Duration of the Staking to earn reward.
     */
    function setDuration(uint256 _duration) external onlyOwner {
        // checks whether the duration is finished or not
        if (block.timestamp < s_finishedAt) {
            revert Staking__DurationNotFinishedYet();
        }
        if(_duration <= 0 || _duration > type(uint256).max){
            revert Staking__ShouldNotBeZero();
        }
        s_duration = _duration;
        s_updatedAt = block.timestamp;
        s_finishedAt = block.timestamp + s_duration;
        emit DurationUpdated(_duration);
    }

    /**
     * @dev This function allows only owner to set the reward for the staking contract. It updates s_rewardRate variable and further s_rewardPerSecond. This fucntion follows CEI.
     * @param _amount AMount of the reward token to deposit inside the contract.
     */
    function setReward(uint256 _amount) external onlyOwner {
        // checks/effects
        if (s_duration == 0) {
            revert Staking__SetsTheDurationFirst();
        }

        if (block.timestamp >= s_finishedAt) {
            // should I need to do following check to prevent owner to  set reward according to previous time duration.
            // if(s_updatedAt != block.timestamp){
            //     revert Staking__DurationOutdated();
            // }
            s_rewardRate = _amount / s_duration;
        } else {
            // e Using safeMath library is best practice, but the calculation of decimal precision here not so complicated.
            uint256 rewardsLeft = s_rewardRate * (s_finishedAt - block.timestamp);
            s_rewardRate = (rewardsLeft + _amount) / s_duration;
        }

        s_rewardPerSecond = s_rewardRate / s_duration;
        emit RewardsUpdated(_amount);

        // External interactions
        // q should we do it??
        s_rewardToken.transferFrom(msg.sender, address(this), _amount);

        if ((s_rewardRate * s_duration) > s_rewardToken.balanceOf(address(this))) {
            revert Staking__NotEnoughToken();
        }
    }

    /**
     * @dev The function allows user to stake the s_stakeToken into the contract and update and calculate the reward until this block.timestamp. It follows CEI. It allows user to stake only during duration period.
     * @param _amount Amount to stake by a user in the contract
     */
    function staking(uint256 _amount) external {
        //checks
        if (s_finishedAt < block.timestamp) {
            revert Staking__CurrentlyNotStaking();
        }
        if (_amount == 0) {
            revert Staking__ShouldNotBeZero();
        }
        //effects
        calculateReward(msg.sender);
        s_stakedUserAmount[msg.sender] += _amount;
        emit AmountStaked(msg.sender, _amount);
        //Interactions
        s_stakeToken.transferFrom(msg.sender, address(this), _amount);
    }

    /**
     * @dev This function allows user to withdraw their funds. Follows CEI. This function invoked calculateReward(address) which calculates and update the reward at this block.timestamp.
     * @param _amountToWithdraw staked Amount To withdraw from contract to caller of the function.
     */
    function unstake(uint256 _amountToWithdraw) external {
        //Checks
        if (_amountToWithdraw == 0) {
            revert Staking__ShouldNotBeZero();
        }
        if (_amountToWithdraw > s_stakedUserAmount[msg.sender]) {
            revert Staking__NotEnoughToken();
        }
        //effects
        calculateReward(msg.sender);
        s_stakedUserAmount[msg.sender] -= _amountToWithdraw;
        emit Unstaked(msg.sender, _amountToWithdraw);
        //External Interaction
        // Can use transferFrom.
        s_stakeToken.transfer(msg.sender, _amountToWithdraw);
    }

    /**
     * @dev This function allows user to take out all the associated reward funds. The function follows CEI to avoid the risk of reentrancy attack vector.
     * @notice The function is intended to withdraw funds only once the duration is finished.If there is anything missed please suggest, sir.
     */
    function withdrawRewards() external {
        // checks
        if (block.timestamp < s_finishedAt) {
            revert Staking__DurationNotFinishedYet();
        }
        // effects
        calculateReward(msg.sender);
        uint256 reward = getReward(msg.sender);
        if (reward == 0) {
            revert Staking__ShouldNotBeZero();
        }
        emit RewardsClaimed(msg.sender, reward);

        //Interactions
        s_rewardToken.transfer(msg.sender, reward);
    }

    // Calculate the reward based on reward per second.
    /**
     * @dev The function is intended to calculate reward based on reward per second(which also calculated from rewardRate) instead of reward per Token.
     * @param _account Address of the user want to calculate reward received.
     */
    function calculateReward(address _account) public {
        // Math calculations for calculating rewards
        /* amountStaked = 100
           timePassed(block.timestamp - s_userRewardUpdatedAt[_account]) = 100 sec 
           s_rewardPerSecond(amount/duration) = 1000/7 days 
           reward = 100 * 100 * 1000/604800 == 16.53 reward token each 100 sec untill setReward recalled by owner to change the rewardRate. 
         */
        // e Using safeMath library is best practice, but the calculation of decimal precision here not so complicated.

        uint256 amountStaked = s_stakedUserAmount[_account];
        if (amountStaked > 0) {
            s_rewards[_account] +=
                amountStaked * (block.timestamp - s_userRewardUpdatedAt[_account]) * s_rewardPerSecond / PRECISION;

            s_userRewardUpdatedAt[_account] = block.timestamp;
        } 
    }

    /**
     * @dev getter function allows user to get the values of the state variables.
     * @param _account Address of the amount to get rewards
     */
    function getReward(address _account) public view returns (uint256) {
        return s_rewards[_account];
    }
    
    function getUserRewardUpdatedAt(address _account) public view returns (uint256) {
        return s_userRewardUpdatedAt[_account];
    }
    
    function getStakedAmount(address _account) public view returns (uint256) {
        return s_stakedUserAmount[_account];
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }

    function getStakeToken() public view returns (address) {
        return address(s_stakeToken);
    }

    function getRewardToken() public view returns (address) {
        return address(s_rewardToken);
    }

    function getStakingFinishedAt() public view returns (uint256) {
        return s_finishedAt;
    }

    function getDuration() public view returns (uint256) {
        return s_duration;
    }

    function getRewardRate() public view returns (uint256) {
        return s_rewardRate;
    }

    function getRewardPerSecond() public view returns (uint256) {
        return s_rewardPerSecond;
    }

    function getStakedUserAmount(address user) public view returns (uint256) {
        return s_stakedUserAmount[user];
    }
}
