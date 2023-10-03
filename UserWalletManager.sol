// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.7.5;

import "./UserWallet.sol";
import "./CloneFactory.sol";

contract UserWalletManager is CloneFactory {
    address public implementationAddress;

    event WalletCreationDone(address newWalletAddress);
    event depositDone(uint256 value, address to);

    mapping(address => address) changeOwnerAllowance;
    mapping(address => string) ownerName;
    mapping(string => address) ownerAddress;
    mapping(address => bool) changeColdWalletAddressAlowance;
    mapping(address => bool) isOwner;
    mapping(address => bool) isWalletOrNot;

    address[] walletAddresses;

    address walletCreationAddress = address(this);
    address[] allowedSigners;
    address coldWalletAddress;

    modifier onlyOwners() {
        require(isOwner[msg.sender], "Not An Owner");
        _;
    }

    constructor(
        address _implementationAddress,
        address _coldWalletAddress,
        address _owner1,
        address _owner2,
        address _owner3
    ) {
        implementationAddress = _implementationAddress;
        ownerName[_owner1] = "owner1";
        ownerAddress["owner1"] = _owner1;
        isOwner[_owner1] = true;

        ownerName[_owner2] = "owner2";
        ownerAddress["owner2"] = _owner2;
        isOwner[_owner2] = true;

        ownerName[_owner3] = "owner3";
        ownerAddress["owner3"] = _owner3;
        isOwner[_owner3] = true;

        coldWalletAddress = _coldWalletAddress;
        allowedSigners = [_owner1, _owner2, _owner3];
    }

    function showColdWalletAddress() public view returns (address) {
        return (coldWalletAddress);
    }

    function DepositDoneEvent(uint256 _value, address _to) external {
        require(isWalletOrNot[msg.sender] == true);
        emit depositDone(_value, _to);
    }

    function allowTochangeColdWalletAddress() public onlyOwners {
        changeColdWalletAddressAlowance[msg.sender] = true;
    }

    function changeColdWalletAddress(address _newColdWalletAddress) public onlyOwners {
        if (msg.sender == ownerAddress["owner1"]) {
            require(
                changeColdWalletAddressAlowance[ownerAddress["owner3"]] ==
                true ||
                changeColdWalletAddressAlowance[ownerAddress["owner2"]] ==
                true
            );
        } else if (msg.sender == ownerAddress["owner2"]) {
            require(
                changeColdWalletAddressAlowance[ownerAddress["owner3"]] ==
                true ||
                changeColdWalletAddressAlowance[ownerAddress["owner1"]] ==
                true
            );
        } else if (msg.sender == ownerAddress["owner3"]) {
            require(
                changeColdWalletAddressAlowance[ownerAddress["owner2"]] ==
                true ||
                changeColdWalletAddressAlowance[ownerAddress["owner1"]] ==
                true
            );
        }
        changeColdWalletAddressAlowance[ownerAddress["owner1"]] = false;
        changeColdWalletAddressAlowance[ownerAddress["owner2"]] == false;
        changeColdWalletAddressAlowance[ownerAddress["owner3"]] == false;
        coldWalletAddress = _newColdWalletAddress;
    }

    function allowToChangeOwner(address _targetedAddress) public onlyOwners {
        changeOwnerAllowance[msg.sender] = _targetedAddress;
    }

    function showAllWalletAddresses() public view returns (address[] memory) {
        return (walletAddresses);
    }

    function createWallet(bytes32 salt) external {
        bytes32 finalSalt = keccak256(abi.encodePacked(allowedSigners, salt));

        address payable clone = createClone(implementationAddress, finalSalt);
        UserWallet(clone).init(allowedSigners, walletCreationAddress);
        emit WalletCreationDone(clone);
        isWalletOrNot[clone] = true;
        walletAddresses.push(clone);
    }

    function changeOwner(address _owner, address _changeOwnerTo) public onlyOwners {

        if (msg.sender == _owner) {
            string memory OwnerName = ownerName[_owner];
            ownerAddress[OwnerName] = _changeOwnerTo;
            ownerName[_changeOwnerTo] = OwnerName;
            isOwner[_owner] = false;
            isOwner[_changeOwnerTo] = true;
        } else {
            if (msg.sender == ownerAddress["owner1"]) {
                require(
                    changeOwnerAllowance[ownerAddress["owner2"]] == _owner ||
                    changeOwnerAllowance[ownerAddress["owner3"]] == _owner
                );
            } else if (msg.sender == ownerAddress["owner2"]) {
                require(
                    changeOwnerAllowance[ownerAddress["owner1"]] == _owner ||
                    changeOwnerAllowance[ownerAddress["owner3"]] == _owner
                );
            } else if (msg.sender == ownerAddress["owner3"]) {
                require(
                    changeOwnerAllowance[ownerAddress["owner1"]] == _owner ||
                    changeOwnerAllowance[ownerAddress["owner2"]] == _owner
                );
            }
            string memory currentOwnerName = ownerName[_owner];
            ownerAddress[currentOwnerName] = _changeOwnerTo;
            ownerName[_changeOwnerTo] = currentOwnerName;
            isOwner[_owner] = false;
            isOwner[_changeOwnerTo] = true;
        }
    }

    function isOwnerOrNot(address _isOwner) public view returns (bool) {
        return (isOwner[_isOwner]);
    }
}
