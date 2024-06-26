/* 
 * Start the FA referral process.
 *
 * History
 * -------
 * 1/04/2013 Cindy Freeman   Created
 * 05/06/2013 Cindy Freeman     Modified so all sales reps can submit referral from referral contact
 * 12/28/2015 Cindy Freeman     Added Language__c to LeadToConvert query
   01/26/2016 Dan Carmen        Change to select lead from ReferralQueries
 *
 */
 
public with sharing class FAReferralController {

    private Id refContactId = null;
    public Referral_Account__c refAcct{get;private set;}
    public Referral_Contact__c refCtct{get;private set;}
    
    private Id returnId = null;
    public String currentStep{get;set;}
    public Boolean oktoCreate {get; set;}
    public Boolean isError {get; set;}
    public static final String ERROR='ERROR';
    public static final Integer SEARCHLIMIT = 50;

    private soslResults selectedRslt {get; set;}
    public String selectedId {get; set;}    
    public String selectedObj {get; set;}
    public String selectedStep {get; set;}
    
    private Id leadId;
    private Id contactId;
    
    // used by convertLead method to share errors
    public String logErrorMsg {get; set;}           
    public Exception exceptionMsg {get; set;}   
    

    /* used to create new contact and account */
    public Contact newCT {get; set;}                // new contact
    public Account newAcct {get; set;}              // could be new account or existing account
    public Boolean canEditAcct {get; set;}
                
    /* used to sort results */
    public String sortField {get; set;}
    public String sortDir{get; set;}
        
    /** The person who entered the form. */
    public User runningUser{get;set;}   

    public List<soslResults> resultList{get; set;}  
    public class soslResults {
       public String obj{get;set;}
       public String objId{get; set;}
       public String acctId{get; set;}
       public String nameField{get;set;}
       public String firstNameField{get; set;}
       public String lastNameField{get; set;}
       public String companyField{get;set;}
       public String cityField{get;set;}
       public String zipField{get; set;}
       public String emailField{get; set;}
       public String phoneField{get; set;}
       public String clientNmbrField{get; set;}
       public String clientTypeField{get; set;}  
       public Double clientAssetField{get; set;}
       public Boolean selected{get; set;}     
    }
    
    public String searchName {get; set;}
    public String searchAcct {get; set;}
    public String searchEmail {get; set;}
    public String searchPhone {get; set;}
    public String searchZip {get; set;}
    public Integer rcdCnt {get; set;}
    
    
        
    /** Constructor. */
    public FAReferralController() {
        currentStep = 'STEPpreSearch';  
        oktoCreate = false;
        isError = false;
        Boolean okay = false;
        
        runningUser = [Select Id, Name, HR_Person_Id__c, Sales_Org__c, Profile.Name, UserRole.ParentRoleId, Title from User where Id=:UserInfo.getUserId()];
        
        refContactId = System.currentPageReference().getParameters().get('refcontactId');          
        returnId = refContactId;
        
        okay = retrieveRefCt(refContactId);
        
    }
        
    // query referral contact info in case we need.
    public Boolean retrieveRefCt(Id refctId) {          
        refCtct = [Select Id, Name, RecordTypeId, Referral_type__c, Sales_Org__c, Referral_Account__r.Id
                    from Referral_Contact__c where id = :refContactId];
        Boolean okay = retrieveRefAcct(refCtct.Referral_Account__r.Id);
        return okay;
    }   
    
    // query referral account info in case we need.
    public Boolean retrieveRefAcct(Id refacctId) {          
        refAcct = [Select Id, Name, RecordTypeId
                    from Referral_Account__c where id = :refacctId];
        return true;
    }

    
     public PageReference cancel() {                
        PageReference returnPr = new PageReference('/'+(returnId != null ? returnId : ''));
        return returnPr;                // go back to Referral Contact
     } // cancel

     public PageReference returnToSearch() {                            
        newAcct = null;                 // clear out new contact's account          
        currentStep='STEPsearch';
        isError = false;
        
        return null;
     } // cancelCreate
     
/* ------------------------- */      
    public PageReference nextStep() 
    {   Boolean okay = false;
        PageReference pg = null;        
        
        if (selectedStep == 'refer')                        // clicked on person's name
        {   if (selectedObj == 'Contact')
            {   pg = gotoIntReferral(selectedId);       
                currentStep = 'STEPrefer';
            }               
            else
            {   okay = convertLead(selectedId); 
                if (okay)
                {   pg = gotoIntReferral(contactId);    
                    currentStep = 'STEPrefer';
                }
                else
                {   isError = logError(exceptionMsg, logErrorMsg);   }              
            } // else selectedObj=Contact       
        } // selectedStep=refer         
        else if (selectedStep == 'createCt')                // clicked on account name but could be lead or contact 
        {   for (soslResults sr: resultList)
            {   if (sr.objId == selectedId)
                {   selectedRslt = sr;  }
            } // save selected record from search result
        
            if (selectedObj == 'Lead')
            {   okay = convertLead(selectedId);
                if (okay)                                   // converted Lead, set selected obj and id to the newly converted contact and account
                {   Contact c = [Select Id, Name, AccountId from Contact WHERE Id = :contactId];
                    selectedRslt = new soslResults();
                    selectedRslt.obj = 'Contact';
                    selectedRslt.objId = contactId;
                    selectedRslt.acctId = c.AccountId;                  
                }
                else
                {   isError = logError(exceptionMsg, logErrorMsg);   }
            } // selectedObj=Lead               

            // create new contact from selected account         
            newCT = new Contact();          
            newAcct = [Select Id, Name, AccountNumber, Bis_ID__c, Phone, NumberOfEmployees, X401K_Assets__c,
                        BillingStreet, BillingCity, BillingState, BillingPostalCode  
                        from Account where id = :selectedRslt.acctId];
            canEditAcct = (newAcct.Bis_ID__c != null && newAcct.Bis_ID__c != 0) ? false : true;
            newCT.AccountId = selectedRslt.acctId;
            newCT.Phone = newAcct.Phone;
            newCT.MailingStreet = newAcct.BillingStreet;
            newCT.MailingCity = newAcct.BillingCity;
            newCT.MailingState = newAcct.BillingState;
            newCT.MailingPostalCode = newAcct.BillingPostalCode;
            newCT.Use_Zip_Assignment_Rules__c = true;
            newCt.LeadSource = Label.LeadSource_ReferralFA;             
            currentStep = 'STEPcreateCT';
            isError = false;
            
            pg = null;                          
        } // selectedStep=createCt
                            
        return pg;
    }  // nextStep

/* ------------------------- */
    public PageReference createAandC()                          //clicked on Create New P-C and Contact button
    {   Boolean okay = false;
        PageReference pg;
        
        newAcct = new Account();
        newCt = new Contact();
        currentStep = 'STEPcreateAC';
        isError = false;
        pg = null;
        
        return pg;
    } // createAandC

/* ------------------------- */
    public PageReference saveRcds()
    {   Boolean okay = false;
        PageReference pg;
    
        // in case we need to rollback create/update
        Savepoint sp = Database.SetSavepoint();
         
        if (currentStep == 'STEPcreateAC')
        {   try {
                newAcct.Type = 'Prospect';
                newAcct.Lead_Source__c = 'Referral - Financial Advisor';
                newAcct.Use_Zip_Assignment_Rules__c = true;
                insert newAcct;
            
                newCT.AccountId = newAcct.Id;
                if ((newCt.MailingStreet == null || newCt.MailingStreet.length() == 0) && newAcct.BillingStreet != null)
                {   newCt.MailingStreet = newAcct.BillingStreet;
                    newCt.MailingCity = newAcct.BillingCity;
                    newCt.MailingState = newAcct.BillingState;
                    newCt.MailingPostalCode = newAcct.BillingPostalCode;
                }
                insert newCt;               
            }
            catch (exception e) {
                ApexPages.addMessages(e);
                Database.rollback(sp);
                isError = true;
                pg = null;                  
            }
        } // currentStep=STEPcreateAC               
        else
        {   try {
                if (canEditAcct)
                {   update newAcct;     }
                if ((newCt.MailingStreet == null || newCt.MailingStreet.length() == 0) && newAcct.BillingStreet != null)
                {   newCt.MailingStreet = newAcct.BillingStreet;
                    newCt.MailingCity = newAcct.BillingCity;
                    newCt.MailingState = newAcct.BillingState;
                    newCt.MailingPostalCode = newAcct.BillingPostalCode;
                }
                insert newCt;               
            }
            catch (exception e) {   
                ApexPages.addMessages(e);
                Database.rollback(sp);
                isError = true;
                pg = null;              
            }
        } // else STEPcreateCt

        if (!isError)
        {   selectedObj = 'Contact';
            selectedId = newCt.Id;
            currentStep = 'STEPrefer';
            pg = gotoIntReferral(selectedId);
        }
                        
        return pg;
    }  // saveRcds
                     
     
/* ------------------------- */
    public PageReference runSearch() 
    {   PageReference pg = null;
        oktoCreate = false;
        isError = false;
        rcdcnt = 0;     
        
        String searchAcctFlds = searchAcct + searchZip;     
        String searchPersonFlds = searchName + searchEmail + searchPhone;
        System.debug('**CMF ** entering runSearch, searchAcctFlds='+searchAcctFlds+', searchPersonFlds='+searchPersonFlds+'.');
                
        if (searchAcctFlds != null && searchAcctFlds.length() > 0)
        {   if ((searchZip != null && searchZip.length() > 0) && (searchAcct == Null || searchAcct.length() == 0))
            {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'You must enter an Account name along with the zipcode.'));
                isError = true;
                resultList = new List<soslResults>();
                return pg;
            }       
            else            
            {   rcdcnt = runSearchAcct();   }   
        }
        else if (searchPersonFlds != null && searchPersonFlds.length() > 0)     
        {   rcdcnt = runSearchPerson(); }
        else    // missing search criteria
        {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Please enter data to search'));
            isError = true;
            resultList = new List<soslResults>();
            return pg;
        }       

        if (rcdcnt == 0)
        {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'No records found, please edit your search data.'));
            isError = true;
            oktoCreate = true;
        }
        else if (rcdcnt >= SEARCHLIMIT)
        {   ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Search returned over ' + SEARCHLIMIT + ' records.  Please add criteria to limit your search.'));
            isError = true;
            resultList = new List<soslResults>();
        }
        else
        {   currentStep = 'STEPsearch';
            isError = false;
            oktoCreate = true;  
        }  
        System.debug('**CMF ** leaving runSearch, currentStep='+currentStep+',isError='+isError+',oktoCreate='+oktoCreate);
        return pg;     
    } // runSearch



    private Integer runSearchPerson()
    {   Set<Id> foundIds = new Set<Id>();
        Integer resultCnt = 0;        
        resultList = new List<soslResults>();
 System.debug('**CMF ** entering runSearchPerson,searchName='+searchName+',searchEmail='+searchEmail+',searchPhone='+searchPhone+'.');       
        if (searchName != Null && searchName.length() > 0)
        {   List<List<SObject>> searchList;
            if (searchEmail.length() > 0 && searchPhone.length() > 0)
            {   searchList = [FIND :searchName IN NAME FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name, Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                WHERE EMAIL = :searchEmail AND PHONE = :searchPhone limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE EMAIL = :searchEmail AND PHONE = :searchPhone AND IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson1, searchList.size='+searchList.size());                     
            }
            else if (searchEmail.length() > 0)
            {   searchList = [FIND :searchName IN NAME FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name, Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                WHERE EMAIL = :searchEmail limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE EMAIL = :searchEmail AND IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson2, searchList.size='+searchList.size());
            }
            else if (searchPhone.length() > 0)
            {   searchList = [FIND :searchName IN NAME FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name,  Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                WHERE PHONE = :searchPhone limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE PHONE = :searchPhone AND IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson3, searchList.size='+searchList.size());         
            }
            else
            {   searchList = [FIND :searchName IN NAME FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name,  Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson4, searchList.size='+searchList.size());                     
            }
            List<Contact> ctcts = searchList[0];
            for (Contact ct : ctcts) 
            {   soslResults sf = new soslResults();
                sf.obj = 'Contact';
                sf.objId = ct.Id;
                sf.acctId = ct.AccountId;
                sf.nameField = ct.Name;
                sf.firstNameField = ct.FirstName;
                sf.lastNameField = ct.LastName;
                sf.companyField = ct.Account.Name;  
                sf.cityField = ct.Account.BillingCity;
                sf.zipField = ct.Account.BillingPostalCode;
                sf.clientNmbrField = ct.Account.AccountNumber;
                sf.clientTypeField = ct.Account.Type;
                sf.clientAssetField = ct.Account.X401K_Assets__c;                   
                sf.emailField = ct.Email;
                sf.phoneField = ct.Phone;
                resultList.add(sf);
                resultCnt ++;
                foundIds.add(ct.Id);
            } //for contacts
            List<Lead> leeds = searchList[1];
            for (Lead ld : leeds) {
                soslResults sf = new soslResults();
                sf.obj = 'Lead';
                sf.objId = ld.Id;
                sf.nameField = ld.Name;
                sf.firstNameField = ld.FirstName;
                sf.lastNameField = ld.LastName;
                sf.companyField = ld.Company;
                sf.cityField = ld.City;
                sf.zipField = ld.PostalCode;
                sf.emailField = ld.email;
                sf.phoneField = ld.phone;
                resultList.add(sf);
                resultCnt ++;
                foundIds.add(ld.Id);
            } //for leeds
        } //searchName
       
        Boolean foundIt = false; 
        if (searchEmail != Null && searchEmail.length() > 0)
        {   List<List<SObject>> searchList;
            if (searchName.length() > 0 && searchPhone.length() > 0)
            {   searchList = [FIND :searchEmail IN EMAIL FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, Account.Name, AccountId, Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                WHERE NAME = :searchName AND PHONE = :searchPhone limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE NAME = :searchName AND PHONE = :searchPhone AND IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson5, searchList.size='+searchList.size());                     
            }
            else if (searchName.length() > 0)
            {   searchList = [FIND :searchEmail IN EMAIL FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name, Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                WHERE NAME = :searchName limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE NAME = :searchName AND IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson6, searchList.size='+searchList.size());                     
            }
            else if (searchPhone.length() > 0)
            {   searchList = [FIND :searchemail IN EMAIL FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name,  Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                WHERE PHONE = :searchPhone limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE PHONE = :searchPhone AND IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson7, searchList.size='+searchList.size());                     
            }
            else
            {   searchList = [FIND :searchEmail IN EMAIL FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name,  Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson8, searchList.size='+searchList.size());                     
            }
            List<Contact> ctcts = searchList[0];
            for (Contact ct : ctcts) 
            {   foundIt = foundIds.contains(ct.Id);
                if (!foundIt)
                {   soslResults sf = new soslResults();
                    sf.obj = 'Contact';
                    sf.objId = ct.Id;
                    sf.acctId = ct.AccountId;
                    sf.nameField = ct.Name;
                    sf.firstNameField = ct.FirstName;
                    sf.lastNameField = ct.LastName;
                    sf.companyField = ct.Account.Name;  
                    sf.cityField = ct.Account.BillingCity;
                    sf.zipField = ct.Account.BillingPostalCode;
                    sf.clientNmbrField = ct.Account.AccountNumber;
                    sf.clientTypeField = ct.Account.Type;
                    sf.clientAssetField = ct.Account.X401K_Assets__c;                   
                    sf.emailField = ct.Email;
                    sf.phoneField = ct.Phone;
                    resultList.add(sf);
                    resultCnt ++;
                    foundIds.add(ct.Id);
                } //foundIt
            } // for contacts    
            List<Lead> leeds = searchList[1];
            for (Lead ld : leeds) 
            {   foundIt = foundIds.contains(ld.Id);
                if (!foundIt)
                {   soslResults sf = new soslResults();
                    sf.obj = 'Lead';
                    sf.objId = ld.Id;
                    sf.nameField = ld.Name;
                    sf.firstNameField = ld.FirstName;
                    sf.lastNameField = ld.LastName;
                    sf.companyField = ld.Company;
                    sf.cityField = ld.City;
                    sf.zipField = ld.PostalCode;
                    sf.emailField = ld.email;
                    sf.phoneField = ld.phone;
                    resultList.add(sf);
                    resultCnt ++;
                    foundIds.add(ld.Id);
                } //foundIt
            } // for leeds
        } //searchEmail
        
        if (searchPhone != Null && searchPhone.length() > 0)
        {   List<List<SObject>> searchList;
            if (searchEmail.length() > 0 && searchName.length() > 0)
            {   searchList = [FIND :searchPhone IN PHONE FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name,  Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                WHERE EMAIL = :searchEmail AND NAME = :searchName limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE EMAIL = :searchEmail AND NAME = :searchName AND IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson9, searchList.size='+searchList.size());                     
            }
            else if (searchEmail.length() > 0)
            {   searchList = [FIND :searchPhone IN PHONE FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name,  Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                WHERE EMAIL = :searchEmail limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE EMAIL = :searchEmail AND IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson10, searchList.size='+searchList.size());                    
            }
            else if (searchName.length() > 0)
            {   searchList = [FIND :searchPhone IN PHONE FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name, Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                WHERE NAME = :searchName limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE NAME = :searchName AND IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson11, searchList.size='+searchList.size());                    
            }
            else
            {   searchList = [FIND :searchPhone IN PHONE FIELDS RETURNING
                     Contact (Id, FirstName, LastName, Name, AccountId, Account.Name, Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE IsConverted = FALSE limit :SEARCHLIMIT)];
System.debug('**CMF ** searchPerson12, searchList.size='+searchList.size());                    
            }

            List<Contact> ctcts = searchList[0];
            for (Contact ct : ctcts) 
            {   foundIt = foundIds.contains(ct.Id);
                if (!foundIt)
                {   soslResults sf = new soslResults();
                    sf.obj = 'Contact';
                    sf.objId = ct.Id;
                    sf.acctId = ct.AccountId;
                    sf.nameField = ct.Name;                 
                    sf.firstNameField = ct.FirstName;
                    sf.lastNameField = ct.LastName;
                    sf.companyField = ct.Account.Name;  
                    sf.cityField = ct.Account.BillingCity;
                    sf.zipField = ct.Account.BillingPostalCode;
                    sf.clientNmbrField = ct.Account.AccountNumber;
                    sf.clientTypeField = ct.Account.Type;
                    sf.clientAssetField = ct.Account.X401K_Assets__c;                   
                    sf.emailField = ct.Email;
                    sf.phoneField = ct.Phone;
                    resultList.add(sf);
                    resultCnt ++;
                    foundIds.add(ct.Id);
                } //foundIt
            } // for contacts    
            List<Lead> leeds = searchList[1];
            for (Lead ld : leeds) 
            {   foundIt = foundIds.contains(ld.Id);
                if (!foundIt)
                {   soslResults sf = new soslResults();
                    sf.obj = 'Lead';
                    sf.objId = ld.Id;
                    sf.nameField = ld.Name;
                    sf.firstNameField = ld.FirstName;
                    sf.lastNameField = ld.LastName;
                    sf.companyField = ld.Company;
                    sf.cityField = ld.City;
                    sf.zipField = ld.PostalCode;
                    sf.emailField = ld.email;
                    sf.phoneField = ld.phone;
                    resultList.add(sf);
                    resultCnt ++;
                    foundIds.add(ld.Id);
                } //foundIt
            } // for leeds
        } //searchEmail    
            
        return resultCnt;     
    } // runSearchPerson

    private Integer runSearchAcct()
    {   Integer resultCnt = 0;        
        resultList = new List<soslResults>();
System.debug('**CMF ** entering runSearchAcct,searchAcct='+searchAcct+',searchZip='+searchZip+'.');              
        if (searchAcct != Null && searchAcct.length() > 0)
        {   List<List<SObject>> searchList;
            if (searchZip.length() > 0)
            {   searchList = [FIND :searchAcct IN NAME FIELDS RETURNING
                     Account (Id, Name, BillingStreet, BillingCity, BillingState, BillingPostalCode, AccountNumber, Type, X401K_Assets__c  WHERE BILLINGPOSTALCODE = :searchZIP limit :SEARCHLIMIT)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone WHERE POSTALCODE = :searchZIP limit :SEARCHLIMIT)];
System.debug('**CMF ** searchAccount1, searchList.size='+searchList.size());                    
            }
            else
            {   searchList = [FIND :searchAcct IN NAME FIELDS RETURNING
                     Account (Id, Name, Website)
                    ,Lead(Id, FirstName, LastName, Name, Company, City, PostalCode, Email, Phone)];
System.debug('**CMF ** searchAccount2, searchList.size='+searchList.size());                    
            }
            List<Account> accts = searchList[0];
            // only list Sales Contacts
            List<Contact> ctcts = [Select Id, FirstName, LastName, Name, AccountId, Account.Name, 
                                    Account.BillingCity, Account.BillingPostalCode, Account.AccountNumber, Account.Type, Account.X401K_Assets__c, Email, Phone 
                                    from Contact 
                                    WHERE Account.Id in :accts and Sales_Contact__c = true limit :SEARCHLIMIT];
                for (Contact ct:ctcts)
                {   soslResults sf = new soslResults();
                    sf.obj = 'Contact';
                    sf.objId = ct.Id;
                    sf.acctId = ct.AccountId;
                    sf.nameField = ct.Name;
                    sf.firstNameField = ct.FirstName;
                    sf.lastNameField = ct.LastName;
                    sf.companyField = ct.Account.Name;  
                    sf.cityField = ct.Account.BillingCity;
                    sf.zipField = ct.Account.BillingPostalCode;
                    sf.clientNmbrField = ct.Account.AccountNumber;
                    sf.clientTypeField = ct.Account.Type;
                    sf.clientAssetField = ct.Account.X401K_Assets__c;
                    sf.emailField = ct.Email;
                    sf.phoneField = ct.Phone;
                    resultList.add(sf);
                    resultCnt ++;
                } // for contacts    
            //}
            List<Lead> leeds = searchList[1];
            for (Lead ld : leeds) 
            {   soslResults sf = new soslResults();
                sf.obj = 'Lead';
                sf.objId = ld.Id;
                sf.nameField = ld.Name;
                sf.firstNameField = ld.FirstName;
                sf.lastNameField = ld.LastName;
                sf.companyField = ld.Company;
                sf.cityField = ld.City;
                sf.zipField = ld.PostalCode;
                sf.emailField = ld.email;
                sf.phoneField = ld.phone;
                resultList.add(sf);
                resultCnt ++;
            } // for leeds
        } //search    
            
        return resultCnt;     
    } // runSearchAcct

                   
/* ------------------------- */
    private PageReference gotoIntReferral(Id ctId) {
        PageReference intRefPage = Page.Referral;
        intRefPage.setRedirect(true);
        intRefPage.getParameters().put('contactid', ctId);
        intRefPage.getParameters().put('refType', 'Internal Referral');
        intRefPage.getParameters().put('refContact', refContactId);
        intRefPage.getParameters().put('startedFrom', 'Referral Contact');
        if (UserHelper.WHOLESALER_TITLES_SET.contains(runningUser.Title))
        {   intRefPage.getParameters().put('noRefOptyNeeded', 'true');  }
        else
        {   intRefPage.getParameters().put('noRefOptyNeeded', 'false'); }
        return intRefPage;
         
    }   
                  
/* ------------------------- */ 
   public Boolean logError(Exception e, String errorMsg) {
      if (e != null && errorMsg == null) {
         ApexPages.addMessages(e);
      }
      if (errorMsg != null) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMsg));
      }
      return true;
   } // logError
 
/* ------------------------- */
    public PageReference sortRecords() {
        if (sortDir == Null || sortDir == 'desc')
        {   sortDir = 'asc';    }
        else
        {   sortDir = 'desc';   }

        List<Object> sortValues = new List <Object>();
        Map<Object, List<soslResults>> presortRcds = new Map<Object, soslResults[]>();
        List<soslResults> sortedRcds = new List<soslResults>();
        Object sortKey;
                                      
        for (soslResults rec: resultList)
        {   sortKey = (sortField== 'nameField') ? rec.lastNameField + ' ' + rec.firstNameField : rec.companyField;
            List <soslResults> temprcds = presortRcds.get(sortKey);
            if (temprcds == Null)              // is Key in preSort already?       
            {   temprcds = new List<soslResults>();                    
                presortRcds.put(sortKey,temprcds);                                      
                sortValues.add(sortKey);                            
            }
            temprcds.add(rec);
        }            
        sortValues.sort();
        if (sortDir == 'asc') {
            for (Object val: sortValues) {              
                sortedRcds.addAll(presortRcds.get(val));
            }
        }
        else  {      //sort desc                
            for(integer i = sortValues.size()-1; i >= 0; i--){
                sortedRcds.addAll(presortRcds.get(sortValues[i]));
            }
        }  
        
        resultList = sortedRcds;
                
        return null;
    }           
                               
/* ------------------------- 
    If user selects a lead or the lead's account, this will convert the lead to an account and contact
*/ 
    private Boolean convertLead(String leadIdString) {
        logErrorMsg = '';
        Id leadId = (ID)leadIdString;
        CreateOppAndMeeting coam = new CreateOppAndMeeting(UserHelper.SO_401);
        coam.selectedCompany = '000000000000000';       
        coam.leadId = leadId;
        Set<Id> leadIdSet = new Set<Id>{leadId};
        Lead[] leads = ReferralQueries.selectLeads(leadIdSet, null);
        if (leads != null && !leads.isEmpty()) {
           coam.leadToConvert=leads[0];
        } else {
            logErrorMsg = 'No Lead record was found - can not proceed! Please try again. If the problem continues, contact SFDC Support.';
            return false;
        }
        /*
        try {
            coam.leadToConvert = [SELECT Id,Name,Company, IsConverted
                                ,Owner.Username,Owner.Name
                                ,Street,phone,city,state,FirstName,LastName
                                ,LeadSource,PostalCode,MobilePhone,Current_Prior_Method__c
                                ,Bank_Lead_ID__c
                                ,Hold_Out__c,Hold_Out_Expiration__c
                                ,Additional_Referring_Name__c
                                ,Email
                                ,NumberOfEmployees
                                ,Client_Referral__c
                                ,Client_Referral__r.Id
                                ,Client_Referral__r.Name
                                ,Referral_Contact__c
                                ,Referral_Contact__r.Id
                                ,Referral_Contact__r.Name
                                ,Frequency__c,Local_Competitors__c
                                ,Primary_Competition__c,Mthd_Lead_Rcvd__c
                                ,Language__c
                                ,(Select Id, CampaignId
                                    from CampaignMembers
                                   where Campaign.IsActive=true
                                   order by Campaign.StartDate desc
                                   limit 1)
                            FROM Lead where id = :leadId];
       } catch (QueryException qe) 
       {    exceptionMsg = qe;
            logErrorMsg = 'No Lead record was found - can not proceed! Please try again. If the problem continues, contact SFDC Support.';
            return false;
       }
       */
       Boolean convertSuccess = coam.handleLeadConvert();
       if (convertSuccess == null || !convertSuccess)
       {    return false;   }
       else     
       {    contactId = coam.contactId; 
            return convertSuccess;        
       }
        
    } // convertLead    
                  
                   
}