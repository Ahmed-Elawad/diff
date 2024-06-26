/**
 * Test method for WebIconRegistrationEmailHandler and WebIconRegistrationEmailHelper
 * 
 * History
 * --------
 * 07/17/2015   Carrie Marciano   created
   12/28/2022   Dan Carmen        Change to use SF Duplicate Management

 */
@isTest
public class WebIconRegistrationEmailTest {
    @testSetup
    static void setupData() {
        setupTestData();       
    } // setupData
    
    static testMethod void testBlankEmail(){
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = 'The information contained';
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webIconRegistrationEmailHandler wIREH = new webIconRegistrationEmailHandler();
        try{
            wIREH.handleInboundEmail(email, env);
        }
        catch(webIconRegistrationEmailHandler.IconRegistrationEmailException ex){
            except=ex.getMessage();
        }
        system.assertEquals('Empty Email Body',except);   
    } 
  
    //existing account, contact, reseller, asset
    static testMethod void testAssetCreationExistingRecords(){
        //setupTestData();       
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('CompanyName','Test Account1');
        email.plainTextBody += addXML('IconType','End User');
        email.plainTextBody += addXML('street','123 Main Street');
        email.plainTextBody += addXML('city','Rochester');
        email.plainTextBody += addXML('state','NY');
        email.plainTextBody += addXML('zip','10000');
        email.plainTextBody += addXML('firstname','WebIconReg');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('email','someone@paychex.com');
        email.plainTextBody += addXML('ProductName','RTC-1000');
        email.plainTextBody += addXML('ClockSerialNumber','123456789');
        email.plainTextBody += addXML('SoftwareVersion','4.0.1');
        email.plainTextBody += addXML('Reseller','Florida Time Clock, Inc.');
        email.plainTextBody += '</node>';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webIconRegistrationEmailHandler wIREH = new webIconRegistrationEmailHandler();
        wIREH.handleInboundEmail(email, env);
        
        list<asset> tAsset = [Select id, Name, Additional_Clock_Serial_Number_s__c, Parent_Main_Clock_Serial_Number__c, Account.Name, Contact.Name from asset 
                            where Name = 'RTC-1000' and Account.Name = 'Test Account1' and createdDate = TODAY Limit 1];
                            
        system.assertEquals('RTC-1000',tAsset[0].Name);
        system.assertEquals('Test Account1',tAsset[0].Account.Name);
        system.assertEquals('WebIconReg EmailTest',tAsset[0].Contact.Name);   
    }
   
   //new account, new contact, existing reseller, new asset
    static testMethod void testAssetCreationNewRecords(){      
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('CompanyName','testAssetCreationNewRecords');
        email.plainTextBody += addXML('IconType','End User');
        email.plainTextBody += addXML('street','59 Elm Street');
        email.plainTextBody += addXML('city','Rochester');
        email.plainTextBody += addXML('state','NY');
        email.plainTextBody += addXML('zip','14609');
        email.plainTextBody += addXML('firstname','WebIconReg');
        email.plainTextBody += addXML('lastname','EmailTest2');
        email.plainTextBody += addXML('email','someone@paychex.com');
        email.plainTextBody += addXML('ProductName','RTC-1000');
        email.plainTextBody += addXML('ClockSerialNumber','123456789');
        email.plainTextBody += addXML('SoftwareVersion','4.0.1');
        email.plainTextBody += addXML('Reseller','Florida Time Clock, Inc.');
        email.plainTextBody += '</node>';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webIconRegistrationEmailHandler wIREH = new webIconRegistrationEmailHandler();
        wIREH.handleInboundEmail(email, env);
        
        list<asset> tAsset = [Select id, Name, Additional_Clock_Serial_Number_s__c, Parent_Main_Clock_Serial_Number__c, Account.Name, Contact.Name from asset 
                            where Parent_Main_Clock_Serial_Number__c = '123456789' and Account.Name = 'testAssetCreationNewRecords' and createdDate = TODAY Limit 1];
                            
        system.assertEquals('RTC-1000',tAsset[0].Name);
        system.assertEquals('testAssetCreationNewRecords',tAsset[0].Account.Name);
        system.assertEquals('WebIconReg EmailTest2',tAsset[0].Contact.Name);   
    } // testAssetCreationNewRecords
    
    //no account, new contact, existing reseller, new asset
    static testMethod void testAssetCreationMissingAccount(){      
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('CompanyName','');
        email.plainTextBody += addXML('firstname','WebIconReg');
        email.plainTextBody += addXML('lastname','EmailTest2');
        email.plainTextBody += addXML('email','someone@paychex.com');
        email.plainTextBody += addXML('ProductName','RTC-1000');
        email.plainTextBody += addXML('ClockSerialNumber','123456789');
        email.plainTextBody += addXML('SoftwareVersion','4.0.1');
        email.plainTextBody += addXML('Reseller','Florida Time Clock, Inc.');
        email.plainTextBody += '</node>';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webIconRegistrationEmailHandler wIREH = new webIconRegistrationEmailHandler();
        wIREH.handleInboundEmail(email, env);
        
        list<asset> tAsset = [Select id, Name, Additional_Clock_Serial_Number_s__c, Parent_Main_Clock_Serial_Number__c, Account.Name, Contact.Name from asset 
                            where Name = 'RTC-1000' and Parent_Main_Clock_Serial_Number__c = '123456789' and createdDate = TODAY Limit 1];
                            
        ErrorLog__c[] errlogList = [Select Id, ClassName__c, Description__c from ErrorLog__c where CreatedDate = TODAY and ClassName__c = 'WebIconRegistrationEmailHelper'];
        System.assertEquals(errlogList.size(), 1);
        System.assertEquals(errlogList.get(0).Description__c,'Prospect-Client not found and not created. No contact, asset or service contract entered.');   
    }
    
    //existing account, missing contact, existing reseller, new asset
    static testMethod void testAssetCreationMissingContact(){      
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('CompanyName','Test Account2');
        email.plainTextBody += addXML('IconType','End User');
        email.plainTextBody += addXML('street','59 Elm Street');
        email.plainTextBody += addXML('city','Rochester');
        email.plainTextBody += addXML('state','NY');
        email.plainTextBody += addXML('zip','14609');
        email.plainTextBody += addXML('firstname','');
        email.plainTextBody += addXML('lastname','');
        email.plainTextBody += addXML('email','');
        email.plainTextBody += addXML('ProductName','RTC-1000');
        email.plainTextBody += addXML('ClockSerialNumber','123456789');
        email.plainTextBody += addXML('SoftwareVersion','4.0.1');
        email.plainTextBody += addXML('Reseller','Florida Time Clock, Inc.');
        email.plainTextBody += '</node>';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webIconRegistrationEmailHandler wIREH = new webIconRegistrationEmailHandler();
        wIREH.handleInboundEmail(email, env);
        
        list<asset> tAsset = [Select id, Name, Additional_Clock_Serial_Number_s__c, Parent_Main_Clock_Serial_Number__c, Account.Name, Contact.Name from asset 
                            where Name = 'RTC-1000' and Parent_Main_Clock_Serial_Number__c = '123456789' and Account.Name = 'Test Account2' and createdDate = TODAY Limit 1];
                            
        ErrorLog__c[] errlogList = [Select Id, ClassName__c, Description__c from ErrorLog__c where CreatedDate = TODAY and ClassName__c = 'WebIconRegistrationEmailHelper'];
        //System.assertEquals(errlogList.size(), 1);
        System.assertEquals(errlogList.get(0).Description__c,'Contact not found and not created.  No asset or service contract entered.');   
    }
    
    //existing account, existing contact, existing reseller, no asset
    static testMethod void testAssetCreationMissingAsset(){
        //setupTestData();       
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('CompanyName','Test Account1');
        email.plainTextBody += addXML('IconType','End User');
        email.plainTextBody += addXML('street','123 Main Street');
        email.plainTextBody += addXML('city','Rochester');
        email.plainTextBody += addXML('state','NY');
        email.plainTextBody += addXML('zip','10000');
        email.plainTextBody += addXML('firstname','WebIconReg');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('email','someone@paychex.com');
        email.plainTextBody += addXML('ProductName','');
        email.plainTextBody += addXML('ClockSerialNumber','');
        email.plainTextBody += addXML('SoftwareVersion','');
        email.plainTextBody += addXML('Reseller','Test Reseller');
        email.plainTextBody += '</node>';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webIconRegistrationEmailHandler wIREH = new webIconRegistrationEmailHandler();
        wIREH.handleInboundEmail(email, env);
        
        list<asset> tAsset = [Select id, Name, Additional_Clock_Serial_Number_s__c, Parent_Main_Clock_Serial_Number__c, Account.Name, Contact.Name from asset 
                            where Account.Name = 'Test Account1' and createdDate = TODAY Limit 1];
                            
        ErrorLog__c[] errlogList = [Select Id, ClassName__c, Description__c from ErrorLog__c where CreatedDate = TODAY and ClassName__c = 'WebIconRegistrationEmailHelper'];
        //System.assertEquals(errlogList.size(), 1);
        System.assertEquals(errlogList.get(0).Description__c,'Asset not found and not created.  No service contract entered.');   
    }
    
    //existing account, existing contact, existing reseller, no asset
    static testMethod void testAssetCreationMissingReseller(){
        //setupTestData();       
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('CompanyName','Test Account1');
        email.plainTextBody += addXML('IconType','End User');
        email.plainTextBody += addXML('street','123 Main Street');
        email.plainTextBody += addXML('city','Rochester');
        email.plainTextBody += addXML('state','NY');
        email.plainTextBody += addXML('zip','10000');
        email.plainTextBody += addXML('firstname','WebIconReg');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('email','someone@paychex.com');
        email.plainTextBody += addXML('ProductName','RTC-1000');
        email.plainTextBody += addXML('ClockSerialNumber','123456789');
        email.plainTextBody += addXML('SoftwareVersion','4.0.1');
        email.plainTextBody += addXML('Reseller','');
        email.plainTextBody += '</node>';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webIconRegistrationEmailHandler wIREH = new webIconRegistrationEmailHandler();
        wIREH.handleInboundEmail(email, env);
        
        list<asset> tAsset = [Select id, Name, Additional_Clock_Serial_Number_s__c, Parent_Main_Clock_Serial_Number__c, Account.Name, Contact.Name from asset 
                            where Name = 'RTC-1000' and Account.Name = 'Test Account1' and createdDate = TODAY Limit 1];
                            
        ErrorLog__c[] errlogList = [Select Id, ClassName__c, Description__c from ErrorLog__c where CreatedDate = TODAY and ClassName__c = 'WebIconRegistrationEmailHelper'];
        //System.assertEquals(errlogList.size(), 1);
        System.assertEquals(errlogList.get(0).Description__c,'Reseller not found and not created.');   
    }
   
    //existing account, contact, reseller, update asset
    static testMethod void testAssetCreationDiffSerialAsset(){
        //setupTestData();       
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>';
        email.plainTextBody += addXML('CompanyName','Test Account1');
        email.plainTextBody += addXML('IconType','End User');
        email.plainTextBody += addXML('street','123 Main Street');
        email.plainTextBody += addXML('city','Rochester');
        email.plainTextBody += addXML('state','NY');
        email.plainTextBody += addXML('zip','10000');
        email.plainTextBody += addXML('firstname','WebIconReg');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('email','someone@paychex.com');
        email.plainTextBody += addXML('phone','555-1212');
        email.plainTextBody += addXML('ProductName','RTC-1000');
        email.plainTextBody += addXML('ClockSerialNumber','7897897890');
        email.plainTextBody += addXML('SoftwareVersion','6.0.1');
        email.plainTextBody += addXML('NumOfEmployees','9');
        email.plainTextBody += addXML('numOfClocks','3');
        email.plainTextBody += addXML('Reseller','Test Reseller');
        email.plainTextBody += '</node>';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webIconRegistrationEmailHandler wIREH = new webIconRegistrationEmailHandler();
        wIREH.handleInboundEmail(email, env);
        
        list<asset> tAsset = [Select id, Name, Additional_Clock_Serial_Number_s__c, Parent_Main_Clock_Serial_Number__c, SW_Version__c, Product_Employee_Count__c, Number_of_Clocks__c, Account.Name, Contact.Name from asset 
                            where Name = 'RTC-1000' and Parent_Main_Clock_Serial_Number__c = '7897897890'  and Account.Name = 'Test Account1' and createdDate = TODAY Limit 1];                   
        system.debug('JGS tAsset' + tAsset);
        
        system.assertEquals('RTC-1000',tAsset[0].Name);
        system.assertEquals(9,tAsset[0].Product_Employee_Count__c);
        system.assertEquals('6.0.1',tAsset[0].SW_Version__c);
        system.assertEquals(3,tAsset[0].Number_of_Clocks__c);
        system.assertEquals('7897897890',tAsset[0].Parent_Main_Clock_Serial_Number__c);
        system.assertEquals('Test Account1',tAsset[0].Account.Name);
        system.assertEquals('WebIconReg EmailTest',tAsset[0].Contact.Name);   
    }
    
    public static void setupTestData() {               
     /*   // populate custom setting
        ESRtracking_settings__c esrSetting = new ESRtracking_settings__c();
        esrSetting.Name = 'ESR settings';
        esrSetting.Campaign_Name__c = 'ESR test campaign';
        esrSetting.Case_Record_Type__c = 'ESR Case Record Type';
        esrSetting.isActive__c = true;
        esrSetting.Log_All_Emails__c = true;
        esrSetting.OwnerID__c = goodQ.Id;
        insert esrSetting;  */
        
        // create Account
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId(), type = 'Core Client', Bis_ID__c = 123456
                                ,BillingStreet='123 Main Street', BillingCity='Rochester', BillingState='NY'
                                ,BillingPostalCode = '10000', AccountNumber = '83-1234567', Do_Not_Call__c = true                                
                                ,Phone = '555-1212', Email_Opt_Out__c = true, AnnualRevenue = 25, NumberOfEmployees = 5, Icon_Type__c = 'End User');
        insert acct1;
        
        // create Contact
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        Contact con1 = new Contact(Firstname = 'WebIconReg', Lastname = 'EmailTest', recordtypeId = ctctCorert.getRecordTypeId()
                                ,Phone = '585-555-1212', Email = 'fLast2@abc.com', DoNotCall = false
                                ,HasOptedOutOfEmail = false, Sensitivity_Icon__c = TRUE, AccountId=acct1.Id); 
        insert con1;
                                
        // create Reseller
        Account acct2 = new Account (name = 'Test Reseller',Icon_Type__c = 'Reseller'
                                ,recordtypeId = acctCorert.getRecordTypeId(), type = 'Core Client', BillingPostalCode = '10000' );
        insert acct2; 
         
        // create Asset
        Id rcdTypeId;
        Map<String, Schema.RecordTypeInfo> rtMap = Asset.SObjectType.getDescribe().getRecordTypeInfosByName();
        //Schema.RecordTypeInfo assetRT = RecordTypeHelper.getRecordTypeInfosByName('Icon Asset Record Type', 'Asset'); 
        Schema.RecordTypeInfo assetRT = rtMap.get('Icon Asset Record Type');
        rcdTypeId=assetRT.getRecordTypeId();
        Asset asst1 = new Asset (name = 'RTC-1000', accountId = acct1.Id, contactId = con1.Id, recordtypeId = rcdTypeId, Icon_Product__c = 'RTC-1000', Parent_Main_Clock_Serial_Number__c = '7897897890');
        insert asst1; 
        system.debug('*** CLM *** setupTestData asst1: '+asst1);                                
    } // setupTestData
    
    static string addXML(string tag, string content){
        return '<' + tag + '>' + content + '</' + tag + '>\r\n';
    }
}