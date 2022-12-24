// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.12;
import "../utils/StrategyFixture.sol";
import "forge-std/console.sol";
import {TeleportDAI} from "../../TestTeleport.sol";
import {IGateWay} from "../../interfaces/IGateWay.sol";

// forge test -vv --match-contract TestTeleport --fork-url https://eth-mainnet.g.alchemy.com/v2/xHn7LvIz-aHYUZMTGDL9zFCm8j6L-EGH
contract TestTeleport is StrategyFixture {
    TeleportDAI public testTeleportContract;
    string public arbitrum_rpc_url = "https://rpc.ankr.com/arbitrum";
    uint256 public arbitrum_fork_id;

    IGateWay L2_GATEWAY = IGateWay(0x467194771dAe2967Aef3ECbEDD3Bf9a310C76C65);
    IERC20 public constant L2_DAI =
        IERC20(0xDA10009cBd5D07dd0CeCc66161FC93D7c9000da1);
    address public constant L1_COUNTER_PART =
        0xE4C6B60020504bc3489D6949D545893982Ba4122;
    address public constant TAPIR_TEST_ACC =
        0xe96d943096099199bE1D92583F4E014ED8D1A746;

    function testBasicTeleportL1toL2() external {
        _createFork();
        _deployTestTeleportContract();
        uint256 _amount = 1000 * 1e18; // 1K
        IERC20 _dai = IERC20(tokenAddrs["DAI"]);
        deal(tokenAddrs["DAI"], user, _amount);
        assertEq(_dai.balanceOf(user), _amount); // Exactly 1K

        startHoax(user);
        _dai.approve(address(testTeleportContract), type(uint256).max);
        testTeleportContract.teleport{value: 1 ether}(_amount);
        vm.stopPrank();

        vm.selectFork(arbitrum_fork_id);
        vm.startPrank(L1_COUNTER_PART);
        uint256 tapir_balance_arb_before = L2_DAI.balanceOf(TAPIR_TEST_ACC);
        console.log('Before bridge balance', tapir_balance_arb_before);
        assertEq(tapir_balance_arb_before, 0); // no funds before in ARB
        L2_GATEWAY.finalizeInboundTransfer(
            tokenAddrs["DAI"],
            user,
            TAPIR_TEST_ACC,
            _amount,
            ""
        );
        uint256 tapir_balance_arb_after = L2_DAI.balanceOf(TAPIR_TEST_ACC);
        assertTrue(tapir_balance_arb_after > tapir_balance_arb_before);
        console.log("After bridge balance", tapir_balance_arb_after);
    }

    function _deployTestTeleportContract() internal {
        vm.prank(management);
        testTeleportContract = new TeleportDAI();
    }

    function _createFork() internal returns (uint256) {
        arbitrum_fork_id = vm.createFork(arbitrum_rpc_url);
    }
}
