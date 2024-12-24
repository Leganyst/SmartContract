// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract Insurance {
    address public admin;
    ERC20 public insuranceToken;
    address _tokenAddress = 0xc952F0877f7f8992b4Afd4d95b7EC4c2aB7F7f4E;

    // Предопределённые интервалы (в секундах)
    uint constant ONE_MONTH = 30 days;
    uint constant THREE_MONTHS = 90 days;
    uint constant SIX_MONTHS = 180 days;
    uint constant TWELVE_MONTHS = 365 days;

    event Debug(string message);

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

    mapping(uint => InsuranceContract) public policies; // Хранилище договоров
    uint public nextPolicyId; // Счетчик уникальных id договоров

    event PolicyCreated(uint policyId, address indexed policyHolder, uint coverageAmount, uint startDate, uint endDate);
    event ClaimPaid(uint policyId, address indexed policyHolder, uint amount);

    constructor() {
        admin = msg.sender;
        insuranceToken = ERC20(_tokenAddress);
    }

    function createPolicy(
        address policyHolder,
        uint premium,
        uint coverageAmount,
        uint durationType // Теперь вместо "duration" используется тип (0, 1, 2, 3)
    ) public payable {
        // Обрабатываем требования к заключению договора
        emit Debug("Started create policy function");
        require(policyHolder != address(0), "Invalid policy holder address");
        emit Debug("Passed first require");
        
        require(durationType >= 0 && durationType <= 3, "Invalid duration type");
        emit Debug("Passed second require");

        require(insuranceToken.transferFrom(msg.sender, address(this), premium), "Token transfer failed");
        emit Debug("Passed third require");

        // Вычисляем дату старта и дату окончания страхового договора
        uint startDate = block.timestamp;
        uint endDate = block.timestamp + _getDuration(durationType);

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
        emit Debug("Passed first require in claim function");
        require(policy.isActive, "Policy is not active");
        emit Debug("Passed second require in claim function");
        require(!policy.isClaimed, "Claim already paid");
        emit Debug("Passed third require in claim function");
        require(block.timestamp <= policy.endDate, "Policy expired");
        emit Debug("Passed fourth require in claim function");

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

    // Приватная функция для получения времени действия полиса
    function _getDuration(uint durationType) private pure returns (uint) {
        if (durationType == 0) {
            return ONE_MONTH;
        } else if (durationType == 1) {
            return THREE_MONTHS;
        } else if (durationType == 2) {
            return SIX_MONTHS;
        } else if (durationType == 3) {
            return TWELVE_MONTHS;
        } else {
            revert("Invalid duration type");
        }
    }
}
