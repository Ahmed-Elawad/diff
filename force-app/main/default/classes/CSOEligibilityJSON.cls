/* 
   JSON for CSO Registration

   
  History
  -------
  12/14/2022 Dan Carmen        Update dsm emailAddress to email
  08/02/2023 Dan Carmen        Clean up code
  10/25/2023 Dan Carmen        Add poBoxIndicator

*/
public class CSOEligibilityJSON {
	
	public class LineItems {
		public ServiceAvailability serviceAvailability {get;set;} 
		public String entProductCode {get;set;} 
	}
    
	public class ServiceAvailability {
		public String serviceStartDate {get;set;} 
		public String serviceEndDate {get;set;} 
	}
	
	public class Misc {
		public String sourceOfBusiness {get;set;} 
		public String doingBusinessAs {get;set;} 
		public String numberOfEmployees {get;set;} 
	}
	
	public class ClientResource {
		public String tinType {get;set;} 
		public String tin {get;set;} 
		public String legalName {get;set;} 
		public LegalAddress legalAddress {get;set;} 
	}
    
	public class DSM {
        public String name {get;set;} 
        public String id {get;set;} 
        public String email {get;set;} 
    }
    
	public class LegalAddress {
		public String streetAddressOne {get;set;} 
		public String streetAddressTwo {get;set;} 
		public String city {get;set;} 
		public String stateProv {get;set;} 
		public String postalcode {get;set;} 
		public String countryCode {get;set;} 
        public Boolean poBoxIndicator {get;set;}
	}

	public class UserResource {
		public String contactId {get;set;} 
		public String email {get;set;} 
		public String firstName {get;set;} 
		public String lastName {get;set;} 
		public Telephone telephone {get;set;} 
	}
    
    public class Telephone {
		public String areaCode {get;set;} 
		public String number_Z {get;set;} // in json: number
		public String ext {get;set;} 
		public String countryCode {get;set;} 
	}
	
    public class SalesResource {
        public SalesRepDetail salesRepDetail{get;set;}
        public string quoteFileId {get;set;}
        public string quoteFileCertificateId {get;set;}
        public String sourceOfBusiness{get;set;}
 		public DSM districtSalesManager {get;set;}
    } // class SalesResource
    
    public class OnboardingDataResource {
		public Integer numberOfEmployees {get;set;} 
        public BankInfo referral{get;set;}
        public String previousPayrollMethod {get;set;}
        public Boolean dataExtractionNeeded {get;set;}
        public Date runEffectiveDate {get;set;}
        public Boolean hasPriorWages{get;set;}
    } // class OnboardingDataResource
    
    public class SalesRepDetail {
		public String repId {get;set;} 
		public String repName {get;set;} 
		public String repEmailAddress {get;set;} 
        public String repPhoneNumber{get;set;}
    } // class SalesRepDetail
    
    public class BankInfo {
        public String bankName{get;set;}
        public String bankId{get;set;}
        public String bankBic{get;set;}
        public String bankAba{get;set;}
        public Integer numberOfChecks{get;set;}
    } // class BankInfo
    
    public class ClientRegistrationResource2 {
        public Map<String,LineItems[]> bundleList{get;set;}
		public List<LineItems> additionalLineItems {get;set;} 
		public ClientResource clientResource {get;set;} 
		public UserResource userResource {get;set;} 
		public Misc misc {get;set;} 
        public SalesResource salesResource{get;set;}
        public OnboardingDataResource onboardingDataResource{get;set;}
        public string base64QuoteFile {get;set;}
	} // class ClientRegistrationResource
     
} // class CSOEligibilityJSON