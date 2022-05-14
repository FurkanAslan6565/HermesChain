# HermesChain
Sağlık Hizmetlerinde  Akıllı fatura Denetim Sistemi
# Biz Kimiz 
HermesChain,  mevcut sağlık sistemlerini merkezi(siz) bir altyapıya  taşımak amacıyla blok zincir veya blok zincir tabanlı teknolojileri kullanarak bu hizmetin hem alınması hem de verilmesi sırasında oluşan sorunları önemli ölçüde  azaltmayı amaçlayan bir sağlık hizmeti platformudur.

## Sağlık ekosistemi 

***Öncelikle kısaca hastanede fatura sistemleri nasıl işliyor inceleyelim.
Ardından hastane de işleyen bu sürecin faturalandırma sürecini yazdığımız kodlarla ayrıntılı bir şekilde açıklayacağız.***
<br>
#### FATURA İŞ AKIŞ ŞEMASI
![FATURA İŞ AKIŞ ŞEMASI](https://github.com/FurkanAslan6565/HermesChain/blob/main/docs/Akissemasi.png)
<br>
### VERİ DİYAGRAMI
![FATURA İŞ AKIŞ ŞEMASI](https://github.com/FurkanAslan6565/HermesChain/blob/main/docs/Sa%C4%9Fl%C4%B1kBakanl%C4%B1%C4%9F%C4%B1.png)

#### KISACA

[Sağlık Bakanlığı](https://www.resmigazete.gov.tr/eskiler/2017/07/20170713-3.htm)
>(1) Uluslararası sağlık turizmi sağlık tesisleri tarafından, sağlık turizmi 
kapsamında hizmet alanlar için ilgili mevzuatına göre satış fişi veya fatura düzenlenmesi 
zorunludur. 
Satış fişi veya fatura ekinde hastaya sunulan sağlık hizmetinin ayrıntılı dökümünü ve 
birim fiyatlarını gösteren belge düzenlenir.
Hasta, hikayesi ve sosyal güvence durumuna göre farklı kapsamda ele alınır. Sağlık 
Bakanlığı her yıl hasta kapsamlarına göre SUT fiyatlarını belirler, sağlık tesisleri ise hastayı 
alındığı kapsam için belirenmiş olan SUT fiyat listesine göre faturalandırır. Sağlık 
Bakanlığı’nın yönetmeliklerine göre “sağlık turisti” kapsamına alınan hasta grupları (EK-2A) 
kapsamında faturalandırılan hastalar:



```
    mapping( bytes32 => uint256) _prices; 
    // Mevzuata karşılık gelen fiyat  ornek (keccak256 (S00010  = > 100  fiyatlama  yapıldı.)
```
[Sağlık Bakanlığı](https://www.resmigazete.gov.tr/eskiler/2017/07/20170713-3.htm)
> 1. Sigorta şirketinin bilgisi dahilinde bulunduğu ülkeden başka bir ülkeye tedavi olmaya 
gelen hastalar. Bu hastalar ülkeye sigorta şirketinin bilgisi dahilinde geldiği için ödeme 
süreçlerinde en az problem yaşanılan hasta grubu bu gruptur. Bu gruba mensup hastalara
kısaca “sağlık turisti” denilebilir


> 4. Genel Sağlık Sigortası’ndan yararlanılmaması halinde ülkemizde oturma izni almış ve
geçici T.C. Kimlik Numarasına sahip olan yabancı uyruklu hastalara sunulan sağlık
hizmetleri, “Sağlık Turizmi ve Turistin Sağlığı Kapsamında Sunulan Sağlık Hizmetleri
Fiyat Listesi” (Ek-2A) üzerinden ücretlendirilir. Ülkemizde bulunan yabancı temsilcilik
ve elçiliklerde görev yapan yabancı uyruklu kişiler de bu madde kapsamında
değerlendirilir. 

   <br>
   

## Hastaneler de 2 kategoriye ayrılır 
 | A ROL GRUBU HASTANELER | B ROL GRUBU HASTANELER |
|--|--|
| fiyatın max 3 katı kadar | fiyatın max 2 katı kadar |
``` 
mapping (address => bytes32) groupA_clinicIds; 
// Yalnızca kayıtlı  klinikler kayıtlı adreslerle fatura oluşturabilir A rol grubu hastaneler
mapping (address => bytes32) groupB_clinicIds; 
// Yalnızca kayıtlı  klinikler kayıtlı adreslerle fatura oluşturabilir B rol grubu hastaneler & ADMS
```
Hastane kategorilerinin işlemlerinin gerçekleşeceği fonksiyon
```
function registerClinic(bytes32 _clinicHash, address clinicAddress, bool groupA) public onlyOwner{
        if(groupA)
            groupA_clinicIds[clinicAddress] = _clinicHash;
        else
            groupB_clinicIds[clinicAddress] = _clinicHash;
    }
``` 

## Faturalandırma Aşamasında Dikkat Edilecek Hususlar:
➢ Düzenlenen faturanın içeriğinin gerçeği yansıtmaması  <br>
➢ Hastaya ait pasaport ve sigorta şirketi kayıtlarının eksik yapılması  <br>
➢ Gerekli belgelerin eksik alınması veya hiç alınmaması <br>
➢ Girilen tıbbi hizmet kodları ile anamnez ve epikriz uyumunun sağlanmaması <br>
➢ Yapılan işin her aşamasının ilgili kişilerce kontrolünün yapılmaması <br>

``` 
    mapping( bytes32 => uint256) _prices; // Mevzuata karşılık gelen fiyat ornek -> (keccak256 (S00010  = > 100  fiyatlama yapıldı.)
    // mapping (address => address) _operators; 
    // Yalnızca izin verilen operatörler fatura oluşturabilir
    mapping (address => bytes32) groupA_clinicIds; 
    // Yalnızca kayıtlı  klinikler kayıtlı adreslerle fatura oluşturabilir A rol grubu hastaneler
    mapping (address => bytes32) groupB_clinicIds; 
    // Yalnızca kayıtlı  klinikler kayıtlı adreslerle fatura oluşturabilir B rol grubu hastaneler & ADMS
    mapping (address => bytes32 ) patientCategories; 
    // Hasta kateforilerini belirle
    mapping (address => Invoice[]) patientPastInvoices;
    // Bunu zincir üzerinde depolamak verimli değil ama biz MVP aşaması için saklıyoruz 
    mapping (bytes32 => Invoice) invoiceRecordsById; 
    // Bunu zincir üzerinde depolamak verimli değil ama biz MVP aşaması için saklıyoruz 
```
```
struct Invoice {
        bytes32 invoiceId;
        bytes32 typeOfPatient;
        uint256 amount;
        address patient;
        Status status;
    }

```

 ```modifier onlyClinic{
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
    /**
    * Bu işlev klinik tarafından çağrılabilir
    * Clinic, hasta kategorisi sınırının 3 katından fazla fatura oluşturamaz
    * eğer hastalar ilk kez gelirse, kategorisi kaydedilecektir
    * İşlev, kullanıcının o kategoriye ait olup olmadığını kontrol eder
    * PatientAddress fatura sahibi
    
    */
```

