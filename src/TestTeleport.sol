// SPDX-License-Identifier: AGPL-3.0
// Feel free to change the license, but this is what we use
pragma solidity ^0.8.12;
pragma experimental ABIEncoderV2;

import {IGateWay} from "./interfaces/IGateWay.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract TeleportDAI {
    using SafeERC20 for IERC20;
    IGateWay public constant L1_DAI_GATEWAY =
        IGateWay(0xD3B5b60020504bc3489D6949d545893982BA3011);
    address public constant L1_DAI_ADDRESS =
        0x6B175474E89094C44Da98b954EedeAC495271d0F;
    address public constant TAPIR_TEST_ACC =
        0xe96d943096099199bE1D92583F4E014ED8D1A746;

    constructor() {
        IERC20(L1_DAI_ADDRESS).safeApprove(
            address(L1_DAI_GATEWAY),
            type(uint256).max
        );
    }

    function teleport(uint256 _daiAmount) external payable {
        uint256 maxGasSubmissionCost = 164412404923008;
        bytes memory emptyBytes = "";
        bytes memory data = abi.encode(maxGasSubmissionCost, emptyBytes);

        IERC20(L1_DAI_ADDRESS).safeTransferFrom(
            msg.sender,
            address(this),
            _daiAmount
        );

        L1_DAI_GATEWAY.outboundTransfer{value: msg.value}(
            L1_DAI_ADDRESS,
            TAPIR_TEST_ACC,
            IERC20(L1_DAI_ADDRESS).balanceOf(address(this)),
            60750,
            300000000,
            data
        );
    }
}
