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
    /**
      -klinik her hasta için yalnızca bir bekleyen fatura oluşturabilir ve yeni bir tane oluşturmaya çalışırsa 
      eskisini geçersiz kılar .
      -birden fazla klinikten birden fazla fatura oluşturulabilir.
     */
    mapping (address => mapping(bytes32 => Invoice)) pendingRequests; 
    modifier onlyClinic{
        require(clinicIds[msg.sender] != 0x0,"Only clinics call perform this operations"); //Bu işlemleri sadece Klinikler yapar.
        _;
    }

    modifier onlyPatient{
        require(patientCategories[msg.sender] != 0x0, "There is no patient registered with this address"); // Bu adrese kayıtlı hasta bulunmamaktadır.
        _;
    }


    /**
    * Bu Fonksiyon Kliniklerden çağrılabilir
    *zaten kayıtlı bir klinik varsa, sözleşme güvenlik nedeniyle tekrar kaydolmasına izin vermez
    
    */
    function registerClinic(bytes32 _clinicHash, address clinicAddress) public onlyOwner{
        clinicIds[clinicAddress] = _clinicHash;
    }




 
    
}