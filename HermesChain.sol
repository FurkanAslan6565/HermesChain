// SPDX-License-Identifier: MIT

//EK-2A hasta Kategorisi Faturalandırma süreci

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Hermes is Ownable{
    uint256 invoiceCreated; 
    mapping( bytes32 => uint256) _prices; // Mevzuata karşılık gelen fiyat  ornek (keccak256 (S00010  = > 100  fiyatlama  yapıldı.)
    // mapping (address => address) _operators;  // Yalnızca izin verilen operatörler fatura oluşturabilir
    mapping (address => bytes32) clinicIds; // Yalnızca kayıtlı klinikler kayıtlı adreslerle fatura oluşturabilir
    mapping (address => bytes32 ) patientCategories; // Hasta kaydedildi ise bunu kullanacağız
    mapping (address => Invoice[]) patientPastInvoices; // Bunu zincir üzerinde depolamak verimli değil ama biz MVP aşaması için saklıyoruz 
    mapping (bytes32 => Invoice) invoiceRecordsById; // Bunu zincir üzerinde depolamak verimli değil ama biz MVP aşaması için saklıyoruz 
    event InvocieCreated(address indexed patient, bytes32 indexed clinic, uint256 timestamp);
    event InvocieAccepted(address indexed patient, bytes32 indexed clinic, uint256 timestamp);
    //event InvociePaid(address indexed patient, bytes32 indexed clinic, uint256 timestamp);

    enum Status {
        Pending, Accepted, Rejected
    }
    struct Invoice {
        bytes32 invoiceId;
        bytes32 typeOfPatient;
        uint256 amount;
        address patient;
        Status status;
    }
} 
// 