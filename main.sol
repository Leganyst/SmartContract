// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ERC20.sol";

contract PolicyContract {
    address public admin;
    ERC20 public policyToken;
    // Адрес контракта для токенов нужно подставлять в случае нового деплоя и взаимодействия клиента с другим адресом. В общем-то, на клиенте и
    // нашем контракте обязательно должны быть синхронизированы адреса контрактов токенов
    address _tokenContractAdress;
    uint256 public nextPolicyId = 0; 
    

    // Набор предопределенных интервалов
    // Для выбора интервала передается цифра от 0 до 3 включительно
    uint constant ONE_MONTH = 30 days;
    uint constant THREE_MONTH = 90 days;
    uint constant SIX_MONTH = 180 days;
    uint constant ONE_YEAR = 360 days;

    struct Policy {
        uint id; // уникальный идентификатор
        address policyHolder; // владелец договора
        uint payment; // Размер выплаты (в токенах)
        uint cost; // Стоимость взноса для заключения (в токенах)
        uint startDate; // Дата начала действия договора
        uint endDate; // дата окончания действия договора
        bool isActive; // Активен ли договор?
        bool isClaimed; // произведена ли выплата по договору
    }
    // Хранилище договоров, ключ - уникальный айди договора
    mapping(uint => Policy) public policies; 

    event Debug(string stringDebug);

    constructor() {
        // Делаем админа
        admin = msg.sender;
        // Указываем с каким токеном будем работать через адрес
        policyToken = ERC20(_tokenContractAdress);
        
        emit Debug("Constructor is completed");
    }


    function createPolicy(
        address policyHolder,
        uint payment,
        uint cost,
        uint typeDate // номер от 0 до 3 выбирает интервал
    ) public {
        emit Debug("Create policy started");
        require(policyHolder != address(0), "Invalid policy holder address");
        require(typeDate >= 0 && typeDate <= 3, "Invalid type date");
        require(policyToken.transferFrom(msg.sender, address(this), cost), "Cost tokens transfer failed");

        // Вычисляем дату старта и дату окончания страхового договора
        uint startDate = block.timestamp;
        uint endDate = block.timestamp + _getDuration(typeDate);

        policies[nextPolicyId] = Policy(
            nextPolicyId,
            policyHolder,
            payment,
            cost,
            startDate,
            endDate,
            true,
            false
        );

        emit Debug("Policy created");
        nextPolicyId++;

    }

    function getClaimed(uint policyId) public {
        // Достаем из хранилища необходимый полис
        Policy storage policy = policies[policyId];

        policy.isActive = false;
        policy.isClaimed = true;

        require(
            policyToken.transfer(policy.policyHolder, policy.payment), "Failed transfer payment policy tokens"
        );
        emit Debug("Policy payment claimed");
    }

    
    function getUserPolicies(address policiesHolder) public view returns(uint[] memory)  {
        // данная функция возвращает список договоров для пользователя
        uint countPolicies = 0;
        for (uint i = 0; i < nextPolicyId; i++)  {
            if (policies[i].policyHolder == policiesHolder) {
                countPolicies++;
            }

        }

        uint[] memory userPolicies = new uint[](countPolicies);
        uint index = 0;

        for (uint i = 0; i < nextPolicyId; i++) {
            if (policies[i].policyHolder == policiesHolder) {
                userPolicies[index] = policies[i].id;
                index++;
            }
        }

        return userPolicies;

    }


    function getUserPolicyInfo(address user, uint policyId) public view returns(
        uint id,
        uint payment,
        uint cost,
        uint startDate,
        uint endDate,
        bool isActive,
        bool isClaimed
        ) {
        
        require(policies[policyId].policyHolder != address(0), "Invalid policy holder address");
        Policy memory policy = policies[policyId];

        require(policy.policyHolder != user, "This not your policy");
        return (
            policy.id,
            policy.payment,
            policy.cost,
            policy.startDate,
            policy.endDate,
            policy.isActive,
            policy.isClaimed
        );
    }

    function _getDuration(uint typeDate) private pure returns (uint) {
        if (typeDate == 0) {
            return ONE_MONTH;
        } else if (typeDate == 1) {
            return THREE_MONTH;
        } else if (typeDate == 2) {
            return SIX_MONTH;
        } else if (typeDate == 3) {
            return ONE_YEAR;
        } else {
            return 0;
        }
    }

}