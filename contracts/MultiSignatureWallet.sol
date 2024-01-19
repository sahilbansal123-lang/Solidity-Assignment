// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract MultiSigWallet {
    address[] public owners;
    mapping(address => bool) public isOwner;
    uint256 public requiredApprovals;

    struct Transaction {
        address to;
        uint256 value;
        bytes data;
        bool executed;
    }

    Transaction[] public transactions;
    mapping(uint256 => mapping(address => bool)) public approvals;

    event OwnershipAdded(address indexed newOwner);
    event OwnershipRemoved(address indexed removedOwner);
    event TransactionSubmitted(uint256 indexed txIndex, address indexed to, uint256 value, bytes data);
    event TransactionApproved(uint256 indexed txIndex, address indexed approver);
    event TransactionCanceled(uint256 indexed txIndex);

    modifier onlyOwner() {
        require(isOwner[msg.sender], "Not an owner");
        _;
    }

    modifier transactionExists(uint256 txIndex) {
        require(txIndex < transactions.length, "Transaction does not exist");
        _;
    }

    modifier notExecuted(uint256 txIndex) {
        require(!transactions[txIndex].executed, "Transaction already executed");
        _;
    }

    modifier notApproved(uint256 txIndex) {
        require(!approvals[txIndex][msg.sender], "Transaction already approved by this owner");
        _;
    }

    constructor(address[] memory _owners, uint256 _requiredApprovals) {
        require(_owners.length > 0, "Owners list cannot be empty");
        require(_requiredApprovals > 0 && _requiredApprovals <= _owners.length, "Invalid number of required approvals");

        for (uint256 i = 0; i < _owners.length; i++) {
            address owner = _owners[i];
            require(owner != address(0), "Invalid owner address");
            require(!isOwner[owner], "Duplicate owner address");

            owners.push(owner);
            isOwner[owner] = true;

            emit OwnershipAdded(owner);
        }

        requiredApprovals = _requiredApprovals;
    }

    function addOwner(address newOwner) external onlyOwner {
        require(newOwner != address(0), "Invalid owner address");
        require(!isOwner[newOwner], "Owner already exists");

        owners.push(newOwner);
        isOwner[newOwner] = true;

        emit OwnershipAdded(newOwner);
    }

    function removeOwner(address removedOwner) external onlyOwner {
        require(isOwner[removedOwner], "Owner does not exist");

        isOwner[removedOwner] = false;

        for (uint256 i = 0; i < owners.length; i++) {
            if (owners[i] == removedOwner) {
                owners[i] = owners[owners.length - 1];
                owners.pop();
                break;
            }
        }

        emit OwnershipRemoved(removedOwner);
    }

    function submitTransaction(address to, uint256 value, bytes calldata data) external onlyOwner {
        require(to != address(0), "Invalid destination address");

        Transaction memory newTransaction = Transaction({
            to: to,
            value: value,
            data: data,
            executed: false
        });

        uint256 txIndex = transactions.length;
        transactions.push(newTransaction);
        emit TransactionSubmitted(txIndex, to, value, data);
    }

    function approveTransaction(uint256 txIndex) external onlyOwner transactionExists(txIndex) notExecuted(txIndex) notApproved(txIndex) {
        require(txIndex < transactions.length, "Transaction does not exist");
        require(!transactions[txIndex].executed, "Transaction already executed");

        approvals[txIndex][msg.sender] = true;

        emit TransactionApproved(txIndex, msg.sender);

        if (getApprovalCount(txIndex) >= requiredApprovals) {
            executeTransaction(txIndex);
        }
    }

    function cancelTransaction(uint256 txIndex) external onlyOwner transactionExists(txIndex) notExecuted(txIndex) {
        transactions[txIndex].executed = true;

        emit TransactionCanceled(txIndex);
    }

    function getApprovalCount(uint256 txIndex) public view returns (uint256) {
        uint256 count = 0;

        for (uint256 i = 0; i < owners.length; i++) {
            if (approvals[txIndex][owners[i]]) {
                count++;
            }
        }

        return count;
    }

    function executeTransaction(uint256 txIndex) internal {
        require(txIndex < transactions.length, "Transaction does not exist");
        require(!transactions[txIndex].executed, "Transaction already executed");
        require(getApprovalCount(txIndex) >= requiredApprovals, "Not enough approvals");

        transactions[txIndex].executed = true;

        (bool success, ) = transactions[txIndex].to.call{value: transactions[txIndex].value}(transactions[txIndex].data);
        require(success, "Transaction execution failed");
    }
}