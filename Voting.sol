// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";


contract Voting is Ownable {

    /* L'id de la proposition gagnante à l'issu du vote */
    uint winningProposalId;

    /* Liste des addresses Eth des votants */
    mapping (address => Voter) whitelist;

    /* Liste des propositions soumises par les votants */
    Proposal[] public propositions;

    /* etat courant du processus de vote*/
    WorkflowStatus public currentWorkflowStatus;

    /* Evenements à differents moments du processus de vote*/
    event VoterRegistered(address voterAddress); 
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);
    event ProposalRegistered(uint proposalId);
    event Voted (address voter, uint proposalId);

    /* Information d'un voteur */
    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    /* Informations d'une proposition */
    struct Proposal {
        string description;
        uint voteCount;
    }

    /* Valeurs possibles de états du processus de vote */
    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }


    /*
    Contructeur pour initialiser l'état du processus de vote
    */
    constructor () {
        currentWorkflowStatus = WorkflowStatus.RegisteringVoters;
    }

    /*
    L'administrateur du vote enregistre une liste blanche d'électeurs identifiés par leur adresse Ethereum.
    */
    function registerVoter (address _address) external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.RegisteringVoters,
            "Cannot register voters");
        require(!whitelist[_address].isRegistered, 
            "This address is already in the whitelist");

        whitelist[_address].isRegistered = true;
        emit VoterRegistered(_address); 
    }

    /*
    L'administrateur du vote commence la session d'enregistrement de la proposition.
    */
    function startProposalRegistration () external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.RegisteringVoters,
        "The Proposal Registration can not started yet");

        currentWorkflowStatus = WorkflowStatus.ProposalsRegistrationStarted;
        emit WorkflowStatusChange(WorkflowStatus.RegisteringVoters, currentWorkflowStatus);
    }

    /*
    Les électeurs inscrits sont autorisés à enregistrer leurs propositions pendant que la session d'enregistrement est active.
    */
    function registerProposal (string calldata _description) external {
        require(whitelist[msg.sender].isRegistered, "You are not a listed like a voter");
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
        "Proposal Registration not started yet");

        Proposal memory proposition = Proposal(_description, 0);
        propositions.push(proposition);
        emit ProposalRegistered(propositions.length - 1);
    }


    /*
    L'administrateur de vote met fin à la session d'enregistrement des propositions.
    */
    function endProposalRegistration () external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationStarted,
        "The proposal registration has not started");

        currentWorkflowStatus = WorkflowStatus.ProposalsRegistrationEnded;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationStarted, currentWorkflowStatus);
    }


    /*
    L'administrateur du vote commence la session de vote.
    */
    function startVotingSession () external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationEnded,
        "The Voting Session can't started");

        currentWorkflowStatus = WorkflowStatus.VotingSessionStarted;
        emit WorkflowStatusChange(WorkflowStatus.ProposalsRegistrationEnded, currentWorkflowStatus);
    }


    /*
    Les électeurs inscrits votent pour leur proposition préférée.
    */
    function voting (uint _proposalId) external {
        require(whitelist[msg.sender].isRegistered, "You are not a listed like a voter.");
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionStarted,
            "The voting session is not active"
        );
        require(!whitelist[msg.sender].hasVoted, "You have already voted");
        require(_proposalId < propositions.length, "Invalid proposal ID");

        whitelist[msg.sender].hasVoted= true;
        whitelist[msg.sender].votedProposalId = _proposalId;
        propositions[_proposalId].voteCount ++;

        emit Voted (msg.sender, _proposalId);
    }


    /*
    L'administrateur du vote met fin à la session de vote.
    */
    function endVotingSession () external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionStarted,
        "The Voting Session can't ended");

        currentWorkflowStatus = WorkflowStatus.VotingSessionEnded;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionStarted, currentWorkflowStatus);
    }

    /*
    L'administrateur du vote comptabilise les votes.
    */
    function countVotes () external onlyOwner {
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionEnded,
            "Cannot count votes yet");

        currentWorkflowStatus = WorkflowStatus.VotesTallied;
        emit WorkflowStatusChange(WorkflowStatus.VotingSessionEnded, currentWorkflowStatus);

        uint bestProposalVote = 0;
        uint bestProposalId = 0;    

        for (uint i = 0; i < propositions.length; i++) {
            if (propositions[i].voteCount > bestProposalVote) {
                bestProposalVote = propositions[i].voteCount;
                bestProposalId = i;
            }
        }
        winningProposalId = bestProposalId;
    }

    /*
    Tout le monde peut vérifier les derniers détails de la proposition gagnante.
    */
    function verifyWinnerProposalDetails () public view returns(uint){
        require(currentWorkflowStatus == WorkflowStatus.VotesTallied, "Votes have not been counted yet");
        return winningProposalId;
    }

}

