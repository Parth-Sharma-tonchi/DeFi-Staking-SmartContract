//SPDX-License-Identifier: MIT

pragma solidity 0.8.20;

import {Test, console} from "@forge/std/Test.sol";
import {DeployStaking} from "../../script/DeployStaking.s.sol";
import {Staking} from "../../src/Staking.sol";
import {StakeToken} from "../../src/StakeToken.sol";
import {RewardToken} from "../../src/RewardToken.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestStaking is Test {
    DeployStaking public deployer;
    Staking public staking;
    address public stakingaddress;
    address public stakeToken;
    address public rewardToken;

    address public immutable user = makeAddr("user");
    uint256 public constant STARTING_USER_BALANCE = 100e18;

    //////// EVENT ////////////
    event DurationUpdated(uint256 duration);
    event RewardsUpdated(uint256 amount);
    event AmountStaked(address indexed user, uint256 amount);
    event Unstaked(address indexed user, uint256 amountToWithdraw);

    function setUp() external {
        deployer = new DeployStaking();
        (stakingaddress, stakeToken, rewardToken) = deployer.run();
        staking = Staking(stakingaddress);
        vm.deal(user, STARTING_USER_BALANCE);
    }

    modifier setDuration() {
        uint256 duration = 604800;
        vm.startPrank(address(this));
        staking.setDuration(duration);
        _;
    }

    modifier setReward() {
        uint256 amount = 100e18;
        vm.startPrank(address(this));
        IERC20(rewardToken).approve(address(staking), amount);
        staking.setReward(amount);
        vm.stopPrank();
        _;
    }

    modifier staked() {
        uint256 amountToStake = 10e18;
        IERC20(stakeToken).approve(user, amountToStake);
        IERC20(stakeToken).approve(staking.getOwner(), amountToStake);
        IERC20(stakeToken).transferFrom(address(this), user, amountToStake);
        uint256 startingUserBalance = IERC20(stakeToken).balanceOf(address(user));
        uint256 startingContractBalance = IERC20(stakeToken).balanceOf(address(staking));

        vm.startPrank(user);
        IERC20(stakeToken).approve(address(staking), 10e18);
        staking.staking(amountToStake);
        vm.stopPrank();
        _;
    }

    ////////////// Test Constructor ////////////////////
    function testInitializers() public view {
        assert(staking.getOwner() == address(this));
        assert(staking.getRewardToken() == rewardToken);
        assert(staking.getStakeToken() == stakeToken);
    }


    /////////////////// TEST MODIFIER ///////////////////////
    function testOnlyOwnerModifier() public {
        vm.startPrank(user);
        vm.expectRevert(Staking.Staking__NotAuthorized.selector);
        staking.setDuration(604800);
        vm.stopPrank();
    }

    ////////////// TEST SET DURATION ///////////////////
    function testRevertAtSetDuration() public {
        uint256 duration = 604800;
        vm.startPrank(address(address(this)));
        staking.setDuration(duration);
        vm.expectRevert(Staking.Staking__DurationNotFinishedYet.selector);
        staking.setDuration(duration);
        vm.stopPrank();
    }

    //////////// FUZZING ON SET DURATION /////////////////
    function testRevertAtSetDurationFuzz(uint256 _duration) public {
        uint256 duration = bound(_duration, 1, type(uint256).max-1);
        vm.startPrank(address(address(this)));
        staking.setDuration(duration);
        vm.expectRevert(Staking.Staking__DurationNotFinishedYet.selector);
        staking.setDuration(duration);
        vm.stopPrank();
    }

    function testSetDurationSetsStateVariables() public {
        uint256 duration = 604800;
        uint256 expectedDurationFinishedAt = duration + block.timestamp;
        vm.startPrank(address(this));
        staking.setDuration(duration);
        assertEq(expectedDurationFinishedAt, staking.getStakingFinishedAt());
        assertEq(duration, staking.getDuration());
    }

    function testSetDurationEmitEvent() public {
        uint256 duration = 604800;
        vm.startPrank(address(this));

        vm.expectEmit(true, false, false, false);
        emit DurationUpdated(duration);
        staking.setDuration(duration);
        vm.stopPrank();
    }

    /////////////// TEST SET REWARD ///////////////////
    function testRevertIfDurationIsZero() public {
        uint256 amount = 500e18;
        vm.startPrank(address(this));
        vm.expectRevert(Staking.Staking__SetsTheDurationFirst.selector);
        staking.setReward(amount);
        vm.stopPrank();
    }

    function testRewardRateIfDurationFinishsedAndTestEventEmitted() public setDuration {
        // SetUp
        uint256 duration = 604800;
        uint256 amount = 500e18;
        uint256 expectedRewardRate = amount / duration;
        uint256 startingContractBalance = IERC20(rewardToken).balanceOf(address(staking));

        vm.startPrank(address(this));
        vm.warp(block.timestamp + duration + 1);
        IERC20(rewardToken).approve(address(staking), amount);

        // test event emitted
        vm.expectEmit(true, false, false, false);
        emit RewardsUpdated(amount);
        staking.setReward(amount);

        // test state variables
        uint256 actualRewardRate = staking.getRewardRate();
        uint256 expectedRewardPerSecond = actualRewardRate / duration;
        assertEq(expectedRewardRate, actualRewardRate);
        assertEq(expectedRewardPerSecond, staking.getRewardPerSecond());

        // test external interactions
        uint256 endingContractBalance = IERC20(rewardToken).balanceOf(address(staking));
        assertEq(startingContractBalance + 500e18, endingContractBalance);

        vm.stopPrank();
    }

    ///////////////// TEST STAKING /////////////////////////
    function testChecksForStakingFunction() public setDuration {
        uint256 duration = 604800;
        uint256 amount = 10e18;
        vm.warp(block.timestamp + duration + 1);
        vm.startPrank(user);
        vm.expectRevert(Staking.Staking__CurrentlyNotStaking.selector);
        staking.staking(amount);
        vm.stopPrank();
    }

    function testZeroAddressChecks() public setDuration {
        vm.startPrank(user);
        vm.expectRevert(Staking.Staking__ShouldNotBeZero.selector);
        staking.staking(0);
        vm.stopPrank();
    }

    function testStakedAndEventEmited() public setDuration {
        // setup
        uint256 amountToStake = 10e18;
        IERC20(stakeToken).approve(user, amountToStake);
        IERC20(stakeToken).approve(staking.getOwner(), amountToStake);
        IERC20(stakeToken).transferFrom(address(this), user, amountToStake);
        uint256 startingUserBalance = IERC20(stakeToken).balanceOf(address(user));
        uint256 startingContractBalance = IERC20(stakeToken).balanceOf(address(staking));

        vm.startPrank(user);
        // test event emit
        IERC20(stakeToken).approve(address(staking), 10e18);
        vm.expectEmit(true, true, false, false);
        emit AmountStaked(user, amountToStake);
        staking.staking(amountToStake);

        //test state variabels
        assert(staking.getStakedUserAmount(user) > 0);

        // test external interactions
        uint256 endingUserBalance = IERC20(stakeToken).balanceOf(address(user));
        uint256 endingContractBalance = IERC20(stakeToken).balanceOf(address(staking));

        assertEq(startingUserBalance, endingUserBalance + amountToStake);
        assertEq(startingContractBalance + amountToStake, endingContractBalance);
        vm.stopPrank();
    }

    /////////////////// TEST UNSTAKE //////////////////////////
    function testUnstakeRevertZeroAddressChecks() public {
        vm.startPrank(user);
        vm.expectRevert(Staking.Staking__ShouldNotBeZero.selector);
        staking.unstake(0);
    }

    function testUnstakeRevertFailingChecks() public setDuration setReward staked {
        vm.startPrank(user);
        vm.expectRevert(Staking.Staking__NotEnoughToken.selector);
        staking.unstake(11e18);
    }

    function testUnstakeStateVariableAndEmitEvent() public setDuration setReward staked {
        uint256 amountToWithdraw = 5e18;

        IERC20(stakeToken).approve(address(staking), amountToWithdraw);
        vm.startPrank(user);
        uint256 startingUserStakedBalance = IERC20(stakeToken).balanceOf(user);
        //test emit events
        vm.expectEmit(true, false, false, false);
        emit Unstaked(user, amountToWithdraw);
        staking.unstake(amountToWithdraw);

        uint256 endingUserStakedBalance = IERC20(stakeToken).balanceOf(user);

        assertEq(startingUserStakedBalance + 5e18, endingUserStakedBalance);
        vm.stopPrank();
    }

    ////////////////// TEST WITHDRAW REWARDS //////////////////////
    function testChecksForWithdrawRewards() public setDuration {
        vm.startPrank(user);
        vm.expectRevert(Staking.Staking__DurationNotFinishedYet.selector);
        staking.withdrawRewards();
    }

    function testZeroChecksForWithdrawRewards() public setDuration staked {
        uint256 duration = 604800;
        vm.startPrank(user);
        vm.warp(block.timestamp + duration + 1);
        vm.expectRevert(Staking.Staking__ShouldNotBeZero.selector);
        staking.withdrawRewards();
        vm.stopPrank();
    }

    function testEmitEventAndTranfered() public setDuration setReward staked {
        uint256 duration = 604800;
        // vm.startPrank(address(staking));
        // IERC20(rewardToken).approve(address(user), 100e18);
        // vm.stopPrank();

        IERC20(rewardToken).approve(address(staking), 100e18);
        vm.startPrank(user);
        vm.warp(block.timestamp + duration + 1);
        uint256 startingUserBalance = IERC20(rewardToken).balanceOf(user);

        staking.withdrawRewards();
        uint256 endingUserBalance = IERC20(rewardToken).balanceOf(user);
        console.log(startingUserBalance);
        console.log(endingUserBalance);
        assert(startingUserBalance < endingUserBalance);
    }

    ///////////////// TEST CALCULATE FUNCTION UPDATION ////////////////////////
    function testRevertIfNotStaked() public setDuration setReward{
        vm.startPrank(user);
        staking.calculateReward(user);
        assert(staking.getReward(user) == 0);
        vm.stopPrank();
    }

    function testRewardVariableUpdated() public setDuration setReward staked{
        uint256 duration = 604800;
        vm.startPrank(user);
        vm.warp(block.timestamp + duration + 1);
        staking.calculateReward(user);
        assert(staking.getReward(user) > 0);
        assert(staking.getUserRewardUpdatedAt(user) == block.timestamp);
        vm.stopPrank();
    }    

    ///////////////////////// TEST GETTER FUNCTIONS //////////////////////////
    function testGetStakedUserAmount() public setDuration staked{
        vm.startPrank(user);
        assertEq(staking.getStakedUserAmount(user), 10e18);
    }

    function testGetStakeToken() public view {
        assertEq(staking.getStakeToken(), stakeToken);
    }

    function testGetRewardToken() public view {
        assertEq(staking.getRewardToken(), rewardToken);
    }    

    function testGetStakingFinishedAt() public setDuration{
        uint256 duration = 604800;
        assertEq(staking.getStakingFinishedAt(), duration+block.timestamp);
    }    

    function testGetRewardRate() public setDuration setReward{
        uint256 amount = 100e18;
        uint256 duration = 604800;
        uint256 expectedRewardRate = amount/duration;
        assertEq(expectedRewardRate, staking.getRewardRate());
    }

    function testDurationUpdated() public setDuration{
        assertEq(staking.getDuration(), block.timestamp + 604800 -1);
    }

    function testGetRewardPerSecond() public setDuration setReward{
        uint256 expectedRewardPerSecond = staking.getRewardRate()/staking.getDuration();
        assertEq(expectedRewardPerSecond, staking.getRewardPerSecond());
    }

    function testGetStakedAmount() public setDuration staked{
        vm.startPrank(user);
        assertEq(staking.getStakedAmount(user), 10e18);
    }

    // q  should do some more fuzzing, open invariant testing, handler invariant testing on the codebase.(Not mentioned in the problem statements)
}
