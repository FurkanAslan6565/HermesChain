// SPDX-License-Identifier: MIT

//EK-2A hasta Kategorisi Faturalandırma süreci

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Hermes is Ownable{
    uint256 invoiceCreated; 
    mapping( bytes32 => uint256) _prices; // Mevzuata karşılık gelen fiyat ornek -> (keccak256 (S00010  = > 100  fiyatlama yapıldı.)
    // mapping (address => address) _operators;  // Yalnızca izin verilen operatörler fatura oluşturabilir
    mapping (address => bytes32) groupA_clinicIds; // Yalnızca kayıtlı  klinikler kayıtlı adreslerle fatura oluşturabilir A rol grubu hastaneler
    mapping (address => bytes32) groupB_clinicIds; // Yalnızca kayıtlı  klinikler kayıtlı adreslerle fatura oluşturabilir B rol grubu hastaneler & ADMS
    mapping (address => bytes32 ) patientCategories; // Hasta kateforilerini belirle
    mapping (address => Invoice[]) patientPastInvoices; // Bunu zincir üzerinde depolamak verimli değil ama biz MVP aşaması için saklıyoruz 
    mapping (bytes32 => Invoice) invoiceRecordsById; // Bunu zincir üzerinde depolamak verimli değil ama biz MVP aşaması için saklıyoruz 
    event InvocieCreated(address indexed patient, bytes32 indexed clinic, uint256 timestamp);
    event InvocieAccepted(address indexed patient, bytes32 indexed clinic, uint256 timestamp);
    //event InvociePaid(address indexed patient, bytes32 indexed clinic, uint256 timestamp);
    
     /*
    A ROL GRUBU HASTANELER 
     -  3 katına kadar tavan iyat belirleyebilir 
    B ROL GRUBU HASTANELER & ADSM
     - 2 Katına kadar tavan fiyat belirleyebilir.
    
    */
    


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
    /*
    A ROL GRUBU HASTANELER 
     -  3 katına kadar tavan iyat belirleyebilir 
    B ROL GRUBU HASTANELER & ADSM
     - 2 Katına kadar tavan fiyat belirleyebilir.
    
    */
    modifier onlyClinic(bool groupA){
        if(groupA)
            require(groupA_clinicIds[msg.sender] != 0x0 ,"Only clinics can perform this operations"); //Bu operasyonları sadece klinikler yapar
        else
            require(groupB_clinicIds[msg.sender] != 0x0 ,"Only clinics can perform this operations"); // Bu operasynları sadece kilikler yapar
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
   function registerClinic(bytes32 _clinicHash, address clinicAddress, bool groupA) public onlyOwner{
        if(groupA)
            groupA_clinicIds[clinicAddress] = _clinicHash;
        else
            groupB_clinicIds[clinicAddress] = _clinicHash;
    }
    /**
    * Bu işlev klinik tarafından çağrılabilir
    * Clinic, hasta kategorisi sınırının 3 katından fazla fatura oluşturamaz
    * eğer hastalar ilk kez gelirse, kategorisi kaydedilecektir
    * İşlev, kullanıcının o kategoriye ait olup olmadığını kontrol eder
    * PatientAddress adres fatura sahibi
    
    */
   function createInvoice(address patientAddress, uint256 amount, bytes32 patientCategory, bool groupA) public onlyClinic(groupA){
        if(patientCategories[patientAddress] == 0){
            patientCategories[patientAddress] = patientCategory; 
        }else{
            require(patientCategories[patientAddress] == patientCategory, "Patient can't be charged for this category");
        }
        uint256 co = 2;
        if(groupA)
            co = 3;
        unchecked{
            require(_prices[patientCategory] * co >= amount, "Patient can't be charged this amount");
        }

        Invoice memory newInvoice = Invoice(
            keccak256(abi.encodePacked(msg.sender, patientAddress, amount, block.timestamp, block.number)),
            patientCategory,
            amount,
            patientAddress,
            Status.Pending
        );

        if(groupA){
            pendingRequests[patientAddress][groupA_clinicIds[msg.sender]] = newInvoice;
            emit InvocieCreated(patientAddress, groupA_clinicIds[msg.sender], amount);
        }else{
            pendingRequests[patientAddress][groupB_clinicIds[msg.sender]] = newInvoice;
            emit InvocieCreated(patientAddress, groupB_clinicIds[msg.sender], amount);
        }
        

    }

   // Faturayı onayla
    /**
    *  Bu fonksiyon hasta tarafından çağrılabilir
    * Fatura önceden oluşturulmuş olmalıdır
    * Fatura durumu beklemede olmalıdır
    * İşlev faturayı kabul eder veya reddeder ve onu arşivle
    */
    function approveInvoice(bytes32 _clinicHash, bool approveReject) public onlyPatient{
        require(pendingRequests[msg.sender][_clinicHash].invoiceId != 0x0, "Invoice can't found" ); //Fatura alındı
        require(pendingRequests[msg.sender][_clinicHash].status == Status.Pending, "Invoice can't be accepted"); //Fatura kabul edilemez
        if(approveReject){
            pendingRequests[msg.sender][_clinicHash].status = Status.Accepted;
        }else{
            pendingRequests[msg.sender][_clinicHash].status = Status.Rejected;
        }
        archiveInvoice(_clinicHash);
    }

    function archiveInvoice(bytes32 _clinicHash) internal {
        
        patientPastInvoices[msg.sender].push(pendingRequests[msg.sender][_clinicHash]);

        //Kimliği olan faturayı kaydet
        invoiceRecordsById[pendingRequests[msg.sender][_clinicHash].invoiceId] = pendingRequests[msg.sender][_clinicHash] ;

        
        pendingRequests[msg.sender][_clinicHash] = Invoice(0x0, 0x0, 0, address(0), Status.Pending);
        emit InvocieAccepted(msg.sender, _clinicHash, pendingRequests[msg.sender][_clinicHash].amount);
    }

   
    // Fiyat ve kategoriyi ayarla
    function setPrice(bytes32 categoryHash, uint256 amount) external onlyOwner{
        _prices[categoryHash] = amount;
    }
    
    // Kullanıcı kategorisini değiştir.
    function setUsersCategory(address patient, bytes32 newCategory) external onlyOwner{
        patientCategories[patient] = newCategory;
    }

    // Kimliğe göre fatura al
    function getInvoiceById(bytes32 id) external view returns(Invoice memory){
        return invoiceRecordsById[id];
    }

    // Hasta tarafındna fatura al
    function getInvoiceByPatient(address patient, uint256 index) external view returns(Invoice memory){
        return patientPastInvoices[patient][index];
    }

    // Faturayı öde (Daha sonra hermes jetonu ile uygulanacaktır)

    // TEST FONKSİYONU
    function getHash(string memory message) external pure returns(bytes32){
        return keccak256(abi.encodePacked(message));
    }
    
}
    





 
    
