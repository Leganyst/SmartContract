// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;


import "./ERC20.sol";

contract Insurance {
    address public admin;
    ERC20 public insuranceToken;


    struct InsuranceContract {
        uint id; // Уникальный айди договора
        address policyHolder; // Адрес человека с которым заключен договор
        uint premium; // Страховая премия (сумма) - сумма для заключения договора
        uint coverageAmount; // Сумма страховой выплаты
        uint startDate; // Дата заключения договора
        uint endDate; // Дата окончания договора
        bool isActive; // Статус действия договора
        bool isClaimed; // Было ли уже выплачена страховая выплата
    }

    mapping (uint => InsuranceContract) public policies; // Хранилище договоров
    uint public nextPolicyId; // Счетчик уникальных id договоров

    event PolicyCreated(uint policyId, address indexed policyHolder, uint coverageAmount, uint startDate, uint endDate);
    event ClaimPaid(uint policyId, address indexed policyHolder, uint amount);

    constructor() {
        admin = msg.sender; // msg.sender - адрес юзера развертывающего контракт
    }


    function createPolicy(
        address policyHolder,
        uint premium,
        uint coverageAmount,
        uint duration
    ) public payable {
        // Обрабатываем требования к заключению договора
        require(policyHolder != address(0), "Invalid policy holder adress");
        require(duration > 0, "Duration must be greater than zero");
        require(insuranceToken.transferFrom(msg.sender, address(this), premium), "Tokem transfer failed");

        // Вычисляем дату старта и дату окончания страхового договора
        uint startDate = block.timestamp;
        uint endDate = block.timestamp + duration;

        // Создаем запись в нашей структуре хранения договоров
        policies[nextPolicyId] = InsuranceContract(
            nextPolicyId,
            policyHolder,
            premium,
            coverageAmount,
            startDate,
            endDate,
            true,
            false
        );
    
        // Логгируем
        emit PolicyCreated(nextPolicyId, policyHolder, coverageAmount, startDate, endDate);
        // Инкрементируем айди для следующего страхового договора
        nextPolicyId++;
    }

    
    function claim(uint policyId) public {
        InsuranceContract storage policy = policies[policyId];

        require(policy.policyHolder == msg.sender, "Not the policy holder");
        require(policy.isActive, "Policy is not active");
        require(!policy.isClaimed, "Claim already paid");
        require(block.timestamp <= policy.endDate, "Policy expired");

        policy.isActive = false;
        policy.isClaimed = true;

        require(
            insuranceToken.transfer(policy.policyHolder, policy.coverageAmount), "Token transfer failed"
        );

        emit ClaimPaid(policyId, policy.policyHolder, policy.coverageAmount);
    }

    function getUserPolicies(address user) public view returns (uint[] memory) {
        uint count = 0;
        for (uint i = 0; i < nextPolicyId; i++) {
            if (policies[i].policyHolder == user) {
                count++;
            }
        }

        uint[] memory userPolicies = new uint[](count);
        uint index = 0;

        for (uint i = 0; i < nextPolicyId; i++) {
            if (policies[i].policyHolder == user) {
                userPolicies[index] = policies[i].id;
                index++;
            }
        }
    
        return userPolicies;
    }


    function getUserPolicyInfo(address user, uint policyId) public view returns (
        uint id,
        address policyHolder,
        uint premium,
        uint coverageAmount,
        uint startDate,
        uint endDate,
        bool isActive,
        bool isClaimed
    ) {
        require(policies[policyId].policyHolder != address(0), "Policy does not exist");

        InsuranceContract memory policy = policies[policyId];
    
        require(user == policy.policyHolder, "You are not the owner of this policy");
        return ( 
            policy.id, // id
            user,      // policy holder address
            policy.premium,   // premium amount
            policy.coverageAmount,// coverage amount
            policy.startDate,    // start date
            policy.endDate,       // end date
            policy.isActive,     // active status
            policy.isClaimed      // is claimed 
        );
    }   
}