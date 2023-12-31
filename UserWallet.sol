// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity ^0.7.5;

import "./TransferHelper.sol";
import "./ERC20Interface.sol";
import "./UserWalletManager.sol";

contract UserWallet {
    event depositForwarded(address executer, uint256 value, bytes data);

    event tokenDepositForwarded(
        address tokenContractAddress,
        address executer,
        uint256 value,
        bytes data
    );

    mapping(address => bool) public signers;
    bool public initialized = false;
    address walletCreationAddress;

    function init(
        address[] calldata allowedSigners,
        address _walletCreationAddress
    ) external onlyUninitialized {
        require(allowedSigners.length == 3, "Invalid number of signers");
        walletCreationAddress = _walletCreationAddress;
        for (uint8 i = 0; i < allowedSigners.length; i++) {
            require(allowedSigners[i] != address(0), "Invalid signer");
            signers[allowedSigners[i]] = true;
        }
        initialized = true;
    }

    fallback() external payable {
        if (msg.value > 0) {
            UserWalletManager(walletCreationAddress).DepositDoneEvent(
                msg.value,
                address(this)
            );
        }
    }

    receive() external payable {
        if (msg.value > 0) {
            UserWalletManager(walletCreationAddress).DepositDoneEvent(
                msg.value,
                address(this)
            );
        }
    }

    modifier onlyUninitialized() {
        require(!initialized, "Contract already initialized");
        _;
    }

    function withdrawTokens(address tokenContractAddress) public {
        ERC20Interface instance = ERC20Interface(tokenContractAddress);
        address forwarderAddress = address(this);
        uint256 forwarderBalance = instance.balanceOf(forwarderAddress);
        require(forwarderBalance != 0, "No Balance");

        TransferHelper.safeTransfer(
            tokenContractAddress,
            UserWalletManager(walletCreationAddress).showColdWalletAddress(),
            forwarderBalance
        );
        emit tokenDepositForwarded(
            tokenContractAddress,
            msg.sender,
            forwarderBalance,
            msg.data
        );
    }

    function withdrawBnb() public {
        uint256 value = address(this).balance;
        if (value == 0) {
            return;
        }

        (bool success,) = UserWalletManager(walletCreationAddress)
        .showColdWalletAddress()
        .call{value : value}("");
        require(success, "Withdraw failed");
        emit depositForwarded(msg.sender, value, msg.data);
    }
}
