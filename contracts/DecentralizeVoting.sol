// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract VotingSystem {
    address public owner;
    bool public votingOpen;

    mapping(address => bool) public voters;
    mapping(string => uint256) public votesReceived;

    event VoterRegistered(address indexed voter);
    event CandidateAdded(string indexed candidate);
    event VoteCasted(address indexed voter, string indexed candidate);

    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }

    modifier onlyRegisteredVoter() {
        require(voters[msg.sender], "Only registered voters can call this function");
        _;
    }

    modifier votingIsOpen() {
        require(votingOpen, "Voting is not open");
        _;
    }

    modifier votingIsClosed() {
        require(!votingOpen, "Voting is still open");
        _;
    }

    constructor() {
        owner = msg.sender;
        votingOpen = true;
    }

    function registerToVote() external votingIsOpen {
        require(!voters[msg.sender], "Already registered to vote");
        voters[msg.sender] = true;
        emit VoterRegistered(msg.sender);
    }

    function addCandidate(string memory candidate) external onlyOwner votingIsOpen {
        require(bytes(candidate).length > 0, "Candidate name cannot be empty");
        votesReceived[candidate] = 0;
        emit CandidateAdded(candidate);
    }

    function castVote(string memory candidate) external onlyRegisteredVoter votingIsOpen {
        require(bytes(candidate).length > 0, "Candidate name cannot be empty");
        require(votesReceived[candidate] != type(uint256).max, "Invalid candidate");

        voters[msg.sender] = false; // Mark the voter as voted
        votesReceived[candidate]++;

        emit VoteCasted(msg.sender, candidate);
    }

    function closeVoting() external onlyOwner votingIsOpen {
        votingOpen = false;
    }

    function getVotesForCandidate(string memory candidate) external view votingIsClosed returns (uint256) {
        require(bytes(candidate).length > 0, "Candidate name cannot be empty");
        return votesReceived[candidate];
    }
}
