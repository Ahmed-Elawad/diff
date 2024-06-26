/*
 * This class processes Icon Web Registrations that come in through the WebIconRegistrationEmailHandler.  
 *
 * History
 * --------
 * 06/26/2014   Carrie Marciano   created 
 * 06/27/2016   Josh Cartwright   updated to include Connection Type 
   12/28/2022   Dan Carmen        Change to use SF Duplicate Management

 */
 
public with sharing class WebIconRegistrationEmailHelper {
 public class iWebReg {
        public string CompanyName;
        public string iconType;
        public string street;
        public string city;
        public string state;
        public string zip;
        public string country;
        public integer NumOfEmployees;
        public string firstName;
        public string lastName;
        public string fullName;   
        public string phone;
        public string fax;
        public string email;
        public string contactRole;
        public string productName;
        public string clockSerialNumber;
        public string softwareVersion;
        public integer numOfClocks;
        public string additionalSerialNum;
        public string reseller;
        public string myPlainText;
        public string connectionType; 
    } // Update with the correct xml tags

   public static void processIWebReg(List<iWebReg> IWRList) {
        system.debug('*** CLM *** enter processIWebReg');
        Contact foundCtct;
        Account foundAcct;  
        Account foundReseller;
        Asset foundAsset;
        ServiceContract foundServiceContract;

        for (iWebReg IWR: IWRList){
            system.debug('*** CLM *** IWR.CompanyName before foundAcct: '+IWR.CompanyName);
            foundAcct = findAcct(IWR);
            system.debug('*** CLM *** back after foundAcct: '+ foundAcct);
            if (foundAcct == null){
                system.debug('*** CLM *** foundAcct == null');
                logError('Prospect-Client not found and not created. No contact, asset or service contract entered.', IWR.myPlainText);  
                forwardEmail('Could not find or create Prospect-Client record, please search in Salesforce.  If found update the contact, product & service and service contract.  If not found create prospect-client, contact, product & service and service contract.  Below is the registration information.  ' + '\r' + '\r' + IWR.myPlainText, 'Prospect-Client not found and not created');           
                break;
            }           
            foundCtct = findCtct(foundAcct, IWR);
            system.debug('*** CLM *** back after foundCtct: '+ foundCtct);
            if (foundCtct == null){
                system.debug('*** CLM *** foundCtct == null');
                logError('Contact not found and not created.  No asset or service contract entered.', IWR.myPlainText);
                forwardEmail('Could not find or create Contact record, please search in Salesforce.  If found update the contact, then add product & service and service contract.  If not found create contact, then add product & service and service contract.  Below is the registration information.  ' + '\r' + '\r' + IWR.myPlainText, 'Contact not found and not created');             
                break;
            }
            foundReseller = findReseller(IWR);
            system.debug('*** CLM *** back after foundReseller: '+ foundReseller);
            if (foundReseller == null){
                system.debug('*** CLM *** foundReseller == null');
                logError('Reseller not found and not created.', IWR.myPlainText);
                forwardEmail('Could not find Reseller account, please search in Salesforce.  If found update product & service, if not found contact Icon support to create Reseller account.  Once that is done, then update product & service.  Below is the registration information.  ' + '\r' + '\r' + IWR.myPlainText, 'Reseller not found');             
                //break;
            }
            if(IWR.productName != null){
                foundAsset = findAsset(foundAcct, IWR);
                system.debug('*** CLM *** back after foundAsset: '+ foundAsset);
                if (foundAsset == null){
                    system.debug('*** CLM *** before new asset create');
                    foundAsset = insertAsset(foundAcct, foundCtct, foundReseller, IWR);
                 } 
             }
             if (IWR.productName == null || foundAsset == null){
                system.debug('*** CLM *** foundAsset == null');
                logError('Asset not found and not created.  No service contract entered.', IWR.myPlainText);
                forwardEmail('Could not find or create Product & Service record, please search in Salesforce.  If found update the product & service and service contract.  If not found create product & service and service contract.  Below is the registration information.  ' + '\r' + '\r' + IWR.myPlainText, 'Product & Service not found and not created');             
                break;
             }
             foundServiceContract = findServiceContract(foundAcct, foundCtct, foundAsset);
             system.debug('*** CLM *** back after foundServiceContract: '+ foundServiceContract);
             if (foundServiceContract == null){ 
                 system.debug('*** CLM *** before new service contract create');
                 foundServiceContract = insertServiceContract(foundAcct, foundCtct, foundAsset);  
                 if (foundServiceContract == null){
                     system.debug('*** CLM *** foundServiceContract == null');
                     logError('Service Contract not found and not created.', IWR.myPlainText);
                     forwardEmail('Could not find or create Service Contract record, please search in Salesforce.  If found update the service contract.  If not found create service contract.  Below is the registration information.  ' + '\r' + '\r' + IWR.myPlainText, 'Service Contract not found and not created');             
                     break;
                 }
             }                     
        }  
            
    } // processIWebReg 
    
    /* try to find the account */    
    private static Account findAcct (iWebReg IWR){
        Id rcdTypeId;
        Schema.RecordTypeInfo acctRT = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account'); 
        rcdTypeId=acctRT.getRecordTypeId();
        if (IWR.CompanyName != null){
            system.debug('*** CLM *** findAcct IWR.CompanyName: '+IWR.CompanyName);
            Account tempAcct = new Account(recordtypeId = rcdTypeId, Name = IWR.CompanyName, Icon_Type__c = IWR.iconType, 
                                           BillingStreet = IWR.street, BillingCity = IWR.city, BillingState = IWR.state,
                                           BillingPostalCode = IWR.zip, BillingCountry = IWR.country,
                                           Use_Zip_Assignment_Rules__c=TRUE);
            system.debug('*** CLM *** tempAcct: '+tempAcct.Name);
            List<Id> matchedIdList = new List<Id>();  
            DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new Account[]{tempAcct});
            DuplicateHelper.DupeResult result = results[0];
            if (result.hasResults && !result.acctIds.isEmpty()) {
               matchedIdList.addAll(result.acctIds);
            }
            /*
            system.debug('*** CLM *** Else not Test in findAcct');
                for (CRMfusionDBR101.DB_Api.Matches matchSet : CRMfusionDBR101.DB_Api.findMatches(tempAcct) )
                {   for (Id i : matchSet.matchedIds )
                    {   if(i.getSobjectType() == Schema.Account.SObjectType)
                        {   matchedIdList.add(i);   }
                    }               
                } // for 
            if(Test.isRunningTest()){
				Map<id,account> testAccounts = new Map<id,account>([Select Id from Account where Name = :IWR.CompanyName
                                                                                                and Icon_Type__c = :IWR.iconType
                                                                                                and BillingStreet = :IWR.street
                                                                                                and BillingCity = :IWR.city
                                                                                                and BillingState = :IWR.state
                                                                                                and BillingPostalCode = :IWR.zip]);
                matchedIdList.addAll(testAccounts.keySet());
            }
            */
            if ( matchedIdList.isEmpty())
            {   system.debug('*** CLM *** matchedIdList isEmpty insert tempAcct: '+tempAcct.Name);
                insert tempAcct;            
                System.debug('findAcct newAcct Id='+tempAcct.id);
                return tempAcct;
            }
            else   
            {   List<Account> matchedAcctList = [Select Id, Name, Icon_Type__c, BillingStreet, BillingCity, BillingState, BillingPostalCode, BillingCountry 
                                                    from Account where Id in :matchedIdList];  
                system.debug('*** CLM *** matchedIdList not Empty use matchedAcctList: '+matchedAcctList.get(0));                                           
                if (matchedAcctList.size() > 0)
                {   return matchedAcctList.get(0);  }               
            } // else
        }    
        return null;
    }  // findAcct  
    
    /* try to find the contact on the account, if no matches create one */
    private static Contact findCtct (Account foundAcct, iWebReg IWR){
        Id rcdTypeId;
        Schema.RecordTypeInfo ctctRT = RecordTypeHelper.getRecordType('Service Administrative Contact Record Type', 'Contact');
        rcdTypeId=ctctRT.getRecordTypeId();
        if(IWR.firstname != null && IWR.lastname != null){
            system.debug('*** CLM *** findCtct IWR.firstName IWR.lastName: '+ IWR.firstName + ' ' + IWR.lastName);
            Contact tempCtct = new Contact(recordtypeId = rcdTypeId, FirstName = IWR.firstName, LastName = IWR.lastName, 
                                            Sensitivity_Icon__c = TRUE,AccountId = foundAcct.Id,email = IWR.email, phone = IWR.phone, fax = IWR.fax);
            List<Id> matchedIdList = new List<Id>();  
            DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new Contact[]{tempCtct});
            DuplicateHelper.DupeResult result = results[0];
            if (result.hasResults && !result.ctctIds.isEmpty()) {
               matchedIdList.addAll(result.ctctIds);
            }
            /*
            system.debug('*** CLM *** Else not Test in findCtct');
            for (CRMfusionDBR101.DB_Api.Matches matchSet : CRMfusionDBR101.DB_Api.findMatches(tempCtct) )
              {   for (Id i : matchSet.matchedIds )
                  {   if(i.getSobjectType() == Schema.Contact.SObjectType)
                      {   matchedIdList.add(i);   }
                  }               
              } // for       
            */
            System.debug('findCtct matchedIdList='+matchedIdList);
            if ( matchedIdList.isEmpty() )
            {   system.debug('*** CLM *** matchedIdList isEmpty insert tempCtct: '+ tempCtct.FirstName +' ' +tempCtct.LastName);
                insert tempCtct;            
                return tempCtct;
            }
            else
            {   List<Contact> matchedCtctList = [Select Id, FirstName, LastName, Email, Phone, Account.Id 
                                                    from Contact where Id in :matchedIdList and AccountId = :foundAcct.Id];         
                system.debug('*** CLM *** matchedIdList not Empty use matchedCtctList: '+(!matchedCtctList.isEmpty() ? matchedCtctList.get(0).Id : 'No Record'));
                if (matchedCtctList.size() > 0)
                {   return matchedCtctList.get(0);  }               
            } // else
        }    
        return null;
                           
    } // findCtct       
 
    /* try to find the reseller account */
    private static Account findReseller (iWebReg IWR){
        Account fReseller;
        Id rcdTypeId;
        Schema.RecordTypeInfo acctRT = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account'); 
        rcdTypeId=acctRT.getRecordTypeId();
        system.debug('*** CLM *** findReseller IWR.Reseller: '+IWR.Reseller);
        String query = 'Select Id, Name FROM Account WHERE Name = \'' + IWR.Reseller + '\' AND RecordTypeId = \'' + rcdTypeId + '\'  limit 100';
        system.debug('*** CLM *** findReseller query: '+query);
        list<Account> resellerList = Database.query(query);
        system.debug('*** CLM *** findReseller Resellers found: '+ resellerList.size());
        if(!resellerList.isEmpty() && resellerList.size() == 1){                    
            fReseller = resellerList[0];
            system.debug('*** CLM *** findReseller fReseller: '+ resellerList[0].Name);
            return fReseller;
        }
            
        return null;
    }  // findReseller  
    
    /* try to find the asset */
    private static Asset findAsset (Account foundAcct, iWebReg IWR){
        Asset fAsset;
        Id rcdTypeId;
        Map<String, Schema.RecordTypeInfo> rtMap = Asset.SObjectType.getDescribe().getRecordTypeInfosByName();
        system.debug('*** CLM *** rtMap : '+rtMap.size() );
        Schema.RecordTypeInfo assetRT = rtMap.get('Icon Asset Record Type');
        rcdTypeId=assetRT.getRecordTypeId();
        system.debug('*** CLM *** findAsset IWR.productName: '+IWR.productName);
        String query = 'Select Id, Name, Additional_Clock_Serial_Number_s__c, Parent_Main_Clock_Serial_Number__c FROM Asset WHERE Name = \'' + IWR.productName + '\' AND AccountId = \'' + foundAcct.Id + '\' AND Product_End_Date__c = null AND RecordTypeId = \'' + rcdTypeId + '\' ORDER BY CreatedDate DESC LIMIT 100';
        system.debug('*** CLM *** findAsset query: '+query);
        list<Asset> assetList =  Database.query(query);
        system.debug('*** CLM *** findAsset Assets found: '+ assetList.size());
        if(!assetList.isEmpty()){
            for (Asset eAsset : assetList){ 
                system.debug('*** CLM *** findAsset clockSerialNumber: '+ IWR.clockSerialNumber);
                system.debug('*** CLM *** findAsset eAsset.Parent_Main_Clock_Serial_Number__c: '+ eAsset.Parent_Main_Clock_Serial_Number__c);
                system.debug('*** CLM *** findAsset eAsset.Additional_Clock_Serial_Number_s__c: '+ eAsset.Additional_Clock_Serial_Number_s__c);
                if ((eAsset.Parent_Main_Clock_Serial_Number__c != null && IWR.clockSerialNumber == eAsset.Parent_Main_Clock_Serial_Number__c) || (eAsset.Additional_Clock_Serial_Number_s__c != null && eAsset.Additional_Clock_Serial_Number_s__c.contains(IWR.clockSerialNumber))){                    
                    eAsset.Product_Employee_Count__c = IWR.NumOfEmployees;
                    eAsset.SW_Version__c = IWR.softwareVersion;
                    eAsset.Number_of_Clocks__c = IWR.numOfClocks;
                    
                    if(IWR.ConnectionType != null ){
                    	 eAsset.Connection_Type__c = IWR.ConnectionType;
                    }//if(IWR.ConnectionType)
                    
                    fAsset = eAsset;
                    system.debug('*** CLM *** findAsset matches Parent_Main_Clock_Serial_Number__c e or Additional_Clock_Serial_Number_s__c, Asset.Name: '+ eAsset.Name);
                    update fAsset;
                    return fAsset;
                    break;
                } 
            }
        }    
        return null;
    }  // findAsset 
    
    /* create new asset */
    private static Asset insertAsset (Account foundAcct, Contact foundCtct, Account foundReseller, iWebReg IWR){
        Id rcdTypeId;
        Map<String, Schema.RecordTypeInfo> rtMap = Asset.SObjectType.getDescribe().getRecordTypeInfosByName();
        system.debug('*** CLM *** rtMap : '+rtMap.size() );
        Schema.RecordTypeInfo assetRT = rtMap.get('Icon Asset Record Type');
        //Schema.RecordTypeInfo assetRT = RecordTypeHelper.getRecordType('Icon Asset Record Type', 'Asset');
        rcdTypeId=assetRT.getRecordTypeId();
        List<Asset> newAssetList = new List<Asset>();
                    
        system.debug('*** CLM *** rcdTypeId: '+rcdTypeId);
        system.debug('*** CLM *** foundCtct.Id: '+foundCtct.Id);
        system.debug('*** CLM *** foundAcct.Id: '+foundAcct.Id);
        system.debug('*** CLM *** IWR.productName: '+IWR.productName);
        system.debug('*** CLM *** IWR.productName: '+IWR.productName);
        system.debug('*** CLM *** system.today():'+system.today());
        system.debug('*** CLM *** IWR.NumOfEmployees: '+IWR.NumOfEmployees);
        system.debug('*** CLM *** IWR.clockSerialNumber: '+IWR.clockSerialNumber);
        system.debug('*** CLM *** IWR.softwareVersion: '+IWR.softwareVersion);
        system.debug('*** CLM *** IWR.numOfClocks: '+IWR.numOfClocks);
        system.debug('*** CLM *** IWR.additionalSerialNum: '+IWR.additionalSerialNum);
        system.debug('*** CLM *** IWR.reseller: '+IWR.reseller);
        Asset newAsset = new Asset(RecordTypeId = rcdTypeId
                                , ContactId = foundCtct.Id
                                , AccountId = foundAcct.Id
                                , Icon_Product__c = IWR.productName
                                , Name =  IWR.productName
                                , Description = 'Web Registration'
                                , InstallDate = system.today()
                                , Product_Employee_Count__c = IWR.NumOfEmployees
                                , Parent_Main_Clock_Serial_Number__c = IWR.clockSerialNumber
                                , SW_Version__c = IWR.softwareVersion
                                , Number_of_Clocks__c = IWR.numOfClocks
    //                            , Connection_Type__c = (IWR.ConnectionType != null ?  IWR.ConnectionType : '')
                                , Additional_Clock_Serial_Number_s__c = IWR.additionalSerialNum
                                );
        If(foundReseller != NULL){
            newAsset.Reseller_Account__c = foundReseller.Id;
        }
//JC Added Connection Type        
        if(IWR.ConnectionType != null ){
              newAsset.Connection_Type__c = IWR.ConnectionType;
          }//if(IWR.ConnectionType)
        
        system.debug('*** CLM *** before add asset to newAssetList'); 
        newAssetList.add(newAsset);     
        system.debug('*** CLM *** after add asset to newAssetList');             
       
        //Insert assets   
        if (!newAssetList.isEmpty() && newAssetList.size() == 1){
            system.debug('*** CLM *** newAssetList size: '+ newAssetList.size());
            insert newAssetList[0]; 
            return newAssetList[0]; 
        }       
            
        return null;
    }  // findAsset
    
    /* find the service contract */
    private static ServiceContract findServiceContract (Account foundAcct, Contact foundCtct, Asset foundAsset){
        ServiceContract fSC;
        Id rcdTypeId;
        //Map<String, Schema.RecordTypeInfo> rtMap = ServiceContract.SObjectType.getDescribe().getRecordTypeInfosByName();
        //system.debug('*** CLM *** rtMap : '+rtMap.size() );
        //Schema.RecordTypeInfo scRT = rtMap.get('Icon Service Contract Record Type');
        Schema.RecordTypeInfo scRT = RecordTypeHelper.getRecordType('Icon Service Contract Record Type', 'ServiceContract');
        system.debug('*** CLM *** got Service Contract record type, scRT: '+ scRT);
        rcdTypeId=scRT.getRecordTypeId();
        system.debug('*** CLM *** findServiceContract before query foundAsset: '+ foundAsset);
        String query = 'Select Id, Name FROM ServiceContract WHERE Product_and_Service__c = \'' + foundAsset.Id + '\' AND AccountId = \'' + foundAcct.Id + '\' AND ContactId = \'' + foundCtct.Id + '\'AND Status = \'Active\' ORDER BY CreatedDate DESC LIMIT 1';
        system.debug('*** CLM *** findServiceContract query: '+query);
        list<ServiceContract> scList =  Database.query(query);
        system.debug('*** CLM *** findServiceContract found: '+ scList.size());
        if(!scList.isEmpty()){                    
            fSC = scList[0];
            system.debug('*** CLM *** findServiceContract fSC: '+ scList[0].Name);
            return fSC;
        }
            
        return null;
    }  // findServiceContract
    
    /* create new service contract */
    private static ServiceContract insertServiceContract (Account foundAcct, Contact foundCtct, Asset foundAsset){
        Id rcdTypeId;
        //Map<String, Schema.RecordTypeInfo> rtMap = ServiceContract.SObjectType.getDescribe().getRecordTypeInfosByName();
        //system.debug('*** CLM *** rtMap : '+rtMap.size() );
        //Schema.RecordTypeInfo scRT = rtMap.get('Icon Service Contract Record Type');
        Schema.RecordTypeInfo scRT = RecordTypeHelper.getRecordType('Icon Service Contract Record Type', 'ServiceContract');
        rcdTypeId=scRT.getRecordTypeId();
        List<ServiceContract> newSCList = new List<ServiceContract>();
                    
        ServiceContract newSC = new ServiceContract(RecordTypeId = rcdTypeId
                                , Icon_Support_Contract_Name__c = '30-Day Gold Trial'
                                , Name = '30-Day Gold Trial'
                                , Description = 'Web Registration'
                                , AccountId = foundAcct.Id
                                , ContactId = foundCtct.Id                                
                                , Product_and_Service__c = foundAsset.Id
                                , StartDate = system.today()
                                , EndDate = system.today()+30
                                );
       
        system.debug('*** CLM *** before add SC to newSCList'); 
        newSCList.add(newSC);     
        system.debug('*** CLM *** after add SC to newSCList');             
        
        //Insert service contracts   
        if (!newSCList.isEmpty() && newSCList.size() == 1){
            system.debug('*** CLM *** newSCList size: '+ newSCList.size());
            insert newSCList[0]; 
            return newSCList[0]; 
        }       
            
        return null;
    }  // insertServiceContract   
    
    
    /** save error and email in Error Log object */
    public static void logError(String errMsg, String emailBody) { 
        system.debug('*** CLM *** in logError');      
        ErrorLog__c err = new ErrorLog__c();
        err.ClassName__c = 'WebIconRegistrationEmailHelper';
        err.Description__c = errMsg;
        system.debug('*** CLM *** in logError err.Description: ' + err.Description__c);
        insert err;
        system.debug('*** CLM *** in logError after insert err');  
        if (emailBody != null)
        {   Attachment attach = new Attachment();
            attach.Body = Blob.valueOf(emailBody);  
            attach.Name = 'WebIconRegistrationEmailHelper';             
            attach.ParentID = err.id;
            insert attach;
        }
    } // logError
         
    /* method to send error email to person listed in custom setting*/
    public static void forwardEmail (String p_email, String p_subj) {
         EmailAddresses__c iconEmail = EmailAddresses__c.getInstance('Icon Web Registration Failures'); 
   
         if (iconEmail != null && iconEmail.Email__c != null){
                Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
                mail.setToAddresses (new String[]{iconEmail.Email__c});
                //String[] addressList = iconEmail.Email__c;
                //mail.setToAddresses(addressList);
                mail.setSubject ('Icon Web Registration Failure - '+p_subj);                
                mail.setPlainTextBody(p_email);
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
         }
        
    } // forwardEmail

}