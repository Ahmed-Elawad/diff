/*
* Test Class for WebBankLeadEmailHandler and WebBankLeadEmailHelper.  
*
* History
* --------
* 10/25/2013   Justin Stouffer created 
* 02/04/2015   Justin Stouffer Updated to add 401k for PNC Bank
   05/25/2015   Dan Carmen      Changes for testing to work in sandboxes with no data.
   08/19/2015   Dan Carmen      Changes for SRR.
   10/18/2019   Matt Fritschi  Test for Lead assignment to 401k Bank Centric Rep if the exist
   08/05/2021   Pujitha Madamanchi  Add MID tag
   11/25/2021   Pujitha Madamanchi  APR0127496: Citibank tags
   05/01/2023   Dan Carmen          Adjustment for Dupechecking
   06/14/2023	Shilpa Govindarajulu	INC3378498: Modified method testRefContactOwnerExisting to set CTCT_DUPE_RECORD to a referral contact instead of Contact
   09/28/2023   Dan Carmen          Clean up code

*/



@IsTest
public class WebBankLeadEmailTest {
    
    public static String MSG_TAG='node';
    public static String MSG_START='<'+MSG_TAG+'>';
    public static String MSG_END='</'+MSG_TAG+'>';
    
    public static void setupTags() {
        
    }
    
    /* do not need?
@IsTest(SeeAllData=false)
static void testNodes(){
string except;
messaging.Inboundemail email = new messaging.Inboundemail();
email.plainTextBody = '<node><Name>This Is a Test</Name></node>';
Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
try{
wBLEH.handleInboundEmail(email, env);
}
catch(webBankLeadEmailHandler.BankEmailException ex){
except=ex.getMessage();
}
system.assertEquals('Unable to Process Lead',except);

}
*/
    
    @IsTest(SeeAllData=false)
    static void testBlankEmail(){
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_END;
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        try{
            wBLEH.handleInboundEmail(email, env);
        }
        catch(webBankLeadEmailHandler.BankEmailException ex){
            except=ex.getMessage();
        }
        system.assertEquals('Empty Email Body',except);
        
    } // testBlankEmail
    
    @IsTest(SeeAllData=FALSE)
    static void testBadXML(){
        string except;
        messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = '<node>This is a bad message</node>';
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        try{
            wBLEH.handleInboundEmail(email, env);
        }
        catch(webBankLeadEmailHandler.BankEmailException ex){
            except=ex.getMessage();
        }
        system.assertEquals(true,except.startsWith('Unable to Parse XML'));
        
    } // testBadXML
    
    @IsTest(SeeAllData=FALSE)
    static void testBasicLeadCreation(){
        messaging.Inboundemail email = new messaging.Inboundemail();
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            
            email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('firstname','WebBankLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('zip','14543');
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('branchZip','14543');
        email.plainTextBody += addXML('MID','123456');
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, lastName, firstName, postalCode from lead 
                            where company = 'WebBankLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        
        system.assertEquals('WebBankLead',tLead[0].firstName);
        system.assertEquals('EmailTest',tLead[0].lastName);
        system.assertEquals('14543',tLead[0].postalCode);   
    }
    
    @IsTest(SeeAllData=FALSE)
    static void testBasicLeadSplitNameCreation(){
        messaging.Inboundemail email = new messaging.Inboundemail();
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            
            email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('firstname','');
        email.plainTextBody += addXML('lastname','WebBankLead EmailTest');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('zip','14543');
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('branchZip','14543');
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, lastName, firstName, postalCode from lead 
                            where company = 'WebBankLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        
        system.assertEquals('WebBankLead',tLead[0].firstName);
        system.assertEquals('EmailTest',tLead[0].lastName);
        system.assertEquals('14543',tLead[0].postalCode);   
    }
    
    @IsTest(SeeAllData=FALSE)
    static void test401kLeadCreation(){
        ZipCheckOwnerTest.setupZipsAndSegments(true);
        WebBankLeadHelper.CORE_DEFAULT_SEG = ZipCheckOwnerTest.coreSeg1.Name;
        
        Referral_Account__c ra1 = new Referral_Account__c(Name='UNB - CityCentre',
                                                          Bank_Branch_Number__c='12345',
                                                          Zip_Postal_Code__c=ZipCheckOwnerTest.zaCore1Seg1.Name);
        insert ra1;
        
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('firstname','WebBankLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('zip',ZipCheckOwnerTest.zaCore1Seg1.Name);
        email.plainTextBody += addXML('x401k','TRUE');
        email.plainTextBody += addXML('Clover','TRUE');
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('branchZip',ZipCheckOwnerTest.zaCore1Seg1.Name);
        email.plainTextBody += MSG_END;
        
        system.debug('JGS ' + email.plaintextbody);
        System.debug('test401kLeadCreation zipOwner='+ZipCheckOwnerTest.zaCore1Seg1.User__c);
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, lastName, firstName, postalCode, Bank_Product_Of_Interest__c from lead 
                            where company = 'WebBankLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];                   
        
        system.assertEquals('WebBankLead',tLead[0].firstName);
        system.assertEquals('EmailTest',tLead[0].lastName);
        system.assertEquals('401(k)',tLead[0].Bank_Product_Of_Interest__c);
        system.assertEquals(ZipCheckOwnerTest.zaCore1Seg1.Name,tLead[0].postalCode);  
    } // test401kLeadCreation
    
    @IsTest(SeeAllData=FALSE)
    static void test401kAndPayrollLeadCreation(){
        
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('firstname','WebBankLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('zip','14543');
        email.plainTextBody += addXML('payroll','TRUE');
        email.plainTextBody += addXML('x401k','TRUE');
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('branchZip','14543');
        email.plainTextBody += MSG_END;
        system.debug('JGS ' + email.plaintextbody);
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, lastName, firstName, postalCode, Bank_Product_Of_Interest__c from lead 
                            where company = 'WebBankLeadEmailTestCompany' 
                            and createdDate = TODAY];
        
        system.assert(tLead.size() == 2);                            
        system.assertEquals('WebBankLead',tLead[0].firstName);
        system.assertEquals('EmailTest',tLead[0].lastName);
        system.assertEquals('14543',tLead[0].postalCode);  
        system.assertEquals('WebBankLead',tLead[1].firstName);
        system.assertEquals('EmailTest',tLead[1].lastName);
        system.assertEquals('14543',tLead[1].postalCode); 
    }
    
    @IsTest(SeeAllData=FALSE)
    static void testBasicOwner(){
        user u1 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, FirstName, LastName from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('firstname','WebBankLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('salesRepFirstName',u1.FirstName);
        email.plainTextBody += addXML('salesRepLastName',u1.LastName);
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('zip','14543');
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('branchZip','14543');
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, ownerId from lead where 
                            company = 'WebBankLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        
        system.assertEquals(u1.id,tLead[0].ownerId);    
    } // testBasicOwner
    
    @IsTest(SeeAllData=FALSE)
    static void testCentricOwner(){
        campaign c1 = new campaign(Name = 'Bank Test Campaign');
        insert c1;
        user u1 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, FirstName, LastName 
                   from User where HR_Person_Id__c != null 
                   and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        
        Referral_Account__c ra1 = new Referral_Account__c(Name='UNB - CityCentre',
                                                          Bank_Branch_Number__c='12345',
                                                          Zip_Postal_Code__c='14543',
                                                          Bank_Centric_Rep__c=u1.id);
        
        insert ra1;
        
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('firstname','WebBankLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('branchZip','14543');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('campaignId',c1.id);
        email.plainTextBody += addXML('zip','14543');
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, ownerId from lead 
                            where company = 'WebBankLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        
        list<campaignMember> cMList = [Select id, CampaignId from CampaignMember where LeadID = :tLead[0].id];
        system.assertEquals(u1.id,tLead[0].ownerId);          
    }
    
    
    @IsTest(SeeAllData=FALSE)
    static void testRefContactOwnerExisting(){
        
        PaychexSettings__c ps = new PaychexSettings__c();
        ps.Name = 'ReferralSandboxEmails';
        ps.IsActive__c = true;
        ps.Attribute1__c='dcarmen@paychex.com;jcartwright@paychex.com';
        insert ps;
        
        ReferralObjectsSync.SKIP_SYNC=false;
        user u1 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, FirstName, LastName 
                   from User where HR_Person_Id__c != null 
                   and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        
        System.debug('testRefContactOwnerExisting u1='+u1);
        
        Referral_Account__c ra1 = new Referral_Account__c(ownerId=u1.id,
                                                          Name='UNB - CityCentre',
                                                          Bank_Branch_Number__c='12345',
                                                          Zip_Postal_Code__c='14543');
        
        Referral_Account__c ra2 = new Referral_Account__c(Name='UNB - CityCentre',
                                                          Bank_Branch_Number__c='123456',
                                                          Zip_Postal_Code__c='14543',
                                                          Bank_Centric_Rep__c=u1.id);
        
        Referral_Account__c[] refAcctList = new Referral_Account__c[]{ra1,ra2};
            insert refAcctList;
        System.debug('testRefContactOwnerExisting after refAcctList insert');
        
        Referral_Contact__c rc1 = new Referral_Contact__c(Referral_Account__c = ra1.Id,
                                                          Name = 'Test Banker',
                                                          Last_Name__c = 'Banker', 
                                                          First_Name__c = 'Test', 
                                                          Phone__c = '5555555555', 
                                                          Email__c = 'test.banker@paychex.com', 
                                                          OwnerId = ra1.OwnerId);
        insert rc1;
        System.debug('testRefContactOwnerExisting after rc1 insert');
        
        System.debug('testRefContactOwnerExisting before checkDupeBlocker');
        /*if (!checkDupeBlocker('Contact')) {
            // select the associated contact
            Contact ctct = [Select Id, Name, Ref_Contact_ID__c, Mirror_Ref_Ctct__c from Contact where Mirror_Ref_Ctct__c = :rc1.Id];
            System.debug('testRefContactOwnerExisting setting ctct='+ctct);
            WebBankLeadHelper.CTCT_DUPE_RECORD = ctct;
        }
        if (!checkDupeBlocker('Referral Contact')) {
            // select the associated contact
            Referral_Contact__c rc = [SELECT Id, First_Name__c, Last_Name__c, Email__c, Phone__c, OwnerId, Contact_ID__c,ReferralPartnerName__c,PrimaryReferralType__c,LeadSourceDefault__c,Referral_Account__c,Contact__c,Contact__r.AccountId,Employee_Number__c,End_Date__c FROM Referral_Contact__c WHERE Id = :rc1.Id];
            System.debug('testRefContactOwnerExisting setting referral ctct='+rc);
            WebBankLeadHelper.CTCT_DUPE_RECORD = rc;
        }
        System.debug('testRefContactOwnerExisting after checkDupeBlocker'); 
        */
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('firstname','WebBankLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('refEmployeeFirstName',rc1.First_Name__c);
        email.plainTextBody += addXML('refEmployeeLastName',rc1.Last_Name__c);
        email.plainTextBody += addXML('refEmployeePhone',rc1.Phone__c);
        email.plainTextBody += addXML('refEmployeeEmail',rc1.Email__c);
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('zip','14543');
        email.plainTextBody += addXML('branchZip','14543');
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, ownerId, Referral_Contact__c from lead 
                            where company = 'WebBankLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        System.assertEquals(1,tLead.size());
        
        list<Referral_Contact__c> rcs = [Select id, ownerId, Referral_Account__c 
                                         from Referral_Contact__c 
                                         where id = :rc1.id];
        System.assertEquals(1,rcs.size());
        
        system.assertEquals(rcs[0].ownerId,tLead[0].ownerId);
        system.assertEquals(rcs[0].Id,tLead[0].Referral_Contact__c);
        system.assertEquals(rcs[0].Referral_Account__c,ra1.id);
    } // testRefContactOwnerExisting
    
    
    @IsTest(SeeAllData=FALSE)
    static void testRefContactOwnerNew(){
        user u1 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, FirstName, LastName 
                   from User where HR_Person_Id__c != null 
                   and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE Limit 1];
        Referral_Account__c ra1 = new Referral_Account__c(ownerId=u1.id,
                                                          Name='UNB - CityCentre',
                                                          Bank_Branch_Number__c='12345',
                                                          Zip_Postal_Code__c='14543');
        insert ra1;
        
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('firstname','WebBankLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('refEmployeeFirstName','TestBank');
        email.plainTextBody += addXML('refEmployeeLastName','Employee');
        email.plainTextBody += addXML('refEmployeePhone','5555555555');
        email.plainTextBody += addXML('refEmployeeEmail','test.banker@paychex.com');
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('zip','14543');
        email.plainTextBody += addXML('branchZip','14543');
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLeads = [Select Id, ownerId, Referral_Contact__c from lead 
                             where company = 'WebBankLeadEmailTestCompany' 
                             and createdDate = TODAY Limit 1];
        list<Referral_Contact__c> rcs = [Select Id, ownerId 
                                         from Referral_Contact__c 
                                         where Referral_Account__c = :ra1.Id];
        
        system.debug('testRefContactOwnerNew tLeads='+tLeads.size()+' rcs='+rcs.size());
        system.assertEquals(rcs[0].ownerId,tLeads[0].ownerId);
        system.assertEquals(rcs[0].Id,tLeads[0].referral_contact__c);
    } // testRefContactOwnerNew
    
    @IsTest(SeeAllData=FALSE)
    static void testZipAssignOwner(){
        SOAREmailHandlerTest.createZipRules();
        list<Zip_Assignment__c> zas =[Select id, Name, user__c 
                                      from Zip_Assignment__c 
                                      where Sales_Org__c=:UserHelper.SO_CORE
                                      and createdDate = Today Limit 1];
        
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('firstname','WebBankLead');
        email.plainTextBody += addXML('lastname','EmailTest');
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('zip',zas[0].Name);
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select id, ownerId from lead 
                            where company = 'WebBankLeadEmailTestCompany' 
                            and createdDate = TODAY Limit 1];
        
        system.assertEquals(zas[0].user__c,tLead[0].ownerId);
    }
    
    @IsTest(SeeAllData=false)
    static void testDuplicateLead(){
        user u1 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, FirstName, LastName 
                   from User where HR_Person_Id__c != null 
                   and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE Limit 1];
        Referral_Account__c ra1 = new Referral_Account__c(ownerId=u1.id,
                                                          Name='UNB - CityCentre',
                                                          Bank_Branch_Number__c='12345',
                                                          Zip_Postal_Code__c='14543');
        insert ra1;
        Referral_Contact__c rc1 = new Referral_Contact__c(Referral_Account__c = ra1.Id,
                                                          Name = 'Test Banker',
                                                          Last_Name__c = 'Banker', 
                                                          First_Name__c = 'Test', 
                                                          Phone__c = '5555555555', 
                                                          Email__c = 'test.banker@paychex.com', 
                                                          OwnerId = ra1.OwnerId);
        insert rc1;
        
        Schema.RecordTypeInfo leadCoreRT = RecordTypeHelper.getRecordType('Core Lead Record Type', 'Lead'); //Get the Core Record Type.
        lead testLead1 = new lead(company = 'WebBankLeadEmailTestCompany'
                                  , postalcode = '14453'
                                  , lastName='TestLastName'
                                  , firstName = 'TestFirstName'
                                  , email = 'testLead1@testLead.com'
                                  , RecordTypeId = leadCoreRT.getRecordTypeId());
        
        insert testLead1;
        //WebBankLeadHelper.DUPE_OVERRIDE_ID = testLead1.Id;
        
        
        User testUser = DuplicateHelperTest.getDupeTestUser();
        System.runAs(testUser) {
            
        
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('bankName','UNB');
        email.plainTextBody += addXML('refEmployeeFirstName',rc1.First_Name__c);
        email.plainTextBody += addXML('refEmployeeLastName',rc1.Last_Name__c);
        email.plainTextBody += addXML('refEmployeePhone',rc1.Phone__c);
        email.plainTextBody += addXML('refEmployeeEmail',rc1.Email__c);
        email.plainTextBody += addXML('branchNumber','12345');
        email.plainTextBody += addXML('branchName','CityCentre');
        email.plainTextBody += addXML('branchZip','14543');
        email.plainTextBody += addXML('firstname',testLead1.FirstName);
        email.plainTextBody += addXML('lastname',testLead1.LastName);
        email.plainTextBody += addXML('company',testLead1.company);
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('email',testLead1.email);
        email.plainTextBody += addXML('zip',testLead1.PostalCode);
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select Id, ownerId, Exception_Reason__c, recordType.name, company
                            from lead 
                            where company = :testLead1.company
                            and recordType.name = :Label.RT_Pending_Leads
                            and createdDate = TODAY
                            Order by CreatedDate DESC
                            Limit 1];
        System.assertEquals(1,tLead.size());
        // check if there is a dupeblocker scenario setup
        //checkDupeBlocker('Lead');
        
        system.assertEquals('Lead Already Exists in Salesforce',tLead[0].Exception_Reason__c);
            
        }

    } // testDuplicateLead
    
    
    // make sure the query is building correctly.
    static testMethod void testFindPartnerBranch() {
        Referral_Account__c parentAcct = new Referral_Account__c(Name='Headquarters');
        insert parentAcct;
        
        Referral_Account__c childAcct1 = new Referral_Account__c(Name='Headquarters - Child1', Parent_Referral_Account__c=parentAcct.Id
                                                                 ,Bank_Branch_Number__c='B01', Zip_Postal_Code__c='12345');
        Referral_Account__c childAcct2 = new Referral_Account__c(Name='Headquarters - Child2', Parent_Referral_Account__c=parentAcct.Id
                                                                 ,Bank_Branch_Number__c='B02', Zip_Postal_Code__c='12346');
        Referral_Account__c[] childAccts = new Referral_Account__c[]{childAcct1,childAcct2};
            insert childAccts;
        
        PartnerWrapper partWrap = new PartnerWrapper();
        PartnerReferral__c partRef = new PartnerReferral__c();
        partWrap.partRef = partRef;
        
        partRef.BranchName__c = 'Child1';
        partRef.PartnerName__c = 'Headquarters';
        
        WebBankLeadHelper.findPartnerBranch(partWrap);
        System.assertEquals(null,partWrap.partnerBranch);
        
        partRef.BranchZip__c = childAcct1.Zip_Postal_Code__c;
        WebBankLeadHelper.findPartnerBranch(partWrap);
        System.assertEquals(true,partWrap.partnerBranch != null);
        System.assertEquals(childAcct1.Id, partWrap.partnerBranch.Id);
        
        partWrap.partnerBranch = null;
        partWrap.partnerHeadquarters = parentAcct;
        WebBankLeadHelper.findPartnerBranch(partWrap);
        System.assertEquals(true,partWrap.partnerBranch != null);
        System.assertEquals(childAcct1.Id, partWrap.partnerBranch.Id);
        
        partWrap.partnerBranch = null;
        partRef.BranchName__c = 'Child2';
        partRef.BranchZip__c = null;
        partRef.BranchNumber__c = childAcct2.Bank_Branch_Number__c;
        WebBankLeadHelper.findPartnerBranch(partWrap);
        System.assertEquals(true,partWrap.partnerBranch != null);
        System.assertEquals(childAcct2.Id, partWrap.partnerBranch.Id);
        
        partWrap.partnerBranch = null;
        partRef.BranchName__c = null;
        partRef.BranchZip__c = null;
        partRef.BranchNumber__c = childAcct2.Bank_Branch_Number__c;
        WebBankLeadHelper.findPartnerBranch(partWrap);
        System.assertEquals(false,partWrap.partnerBranch != null);
        //System.assertEquals(childAcct2.Id, partWrap.partnerBranch.Id);
        
        partWrap.partnerBranch = null;
        partRef.BranchName__c = null;
        partRef.BranchZip__c = childAcct2.Zip_Postal_Code__c;
        partRef.BranchNumber__c = childAcct2.Bank_Branch_Number__c;
        WebBankLeadHelper.findPartnerBranch(partWrap);
        System.assertEquals(false,partWrap.partnerBranch != null);
        //System.assertEquals(childAcct2.Id, partWrap.partnerBranch.Id);
        
        partWrap.partnerBranch = null;
        partWrap.partnerHeadquarters = null;
        partRef.BranchName__c = 'Child1';
        partRef.BranchZip__c = childAcct1.Zip_Postal_Code__c;
        partRef.BranchNumber__c = childAcct1.Bank_Branch_Number__c;
        WebBankLeadHelper.findPartnerBranch(partWrap);
        System.assertEquals(true,partWrap.partnerBranch != null);
        System.assertEquals(childAcct1.Id, partWrap.partnerBranch.Id);
        
        partWrap.partnerBranch = null;
        partWrap.partnerHeadquarters = null;
        partRef.BranchName__c = 'Child1';
        partRef.BranchZip__c = childAcct2.Zip_Postal_Code__c;
        partRef.BranchNumber__c = childAcct2.Bank_Branch_Number__c;
        WebBankLeadHelper.findPartnerBranch(partWrap);
        System.assertEquals(null,partWrap.partnerBranch);
        
    } // testFindPartnerBranch
    
    
    static testMethod void testSetOwner401kBankCentricRep()
    {
        User bcr = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, FirstName, LastName 
                            from User where HR_Person_Id__c != null 
                            and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
        
        Referral_Account__c parentAcct = new Referral_Account__c(Name='Headquarters');
        insert parentAcct;
        
        Referral_Account__c childAcct1 = new Referral_Account__c(Name='Headquarters - Child1', Parent_Referral_Account__c=parentAcct.Id
                                                                 ,Bank_Branch_Number__c='B01', Zip_Postal_Code__c='12345', Bank_Centric_Rep_401k__c=bcr.Id);
        insert childAcct1;
            
        Referral_Contact__c rc1 = new Referral_Contact__c(Referral_Account__c = childAcct1.Id,
                                                          Name = 'Test Banker',
                                                          Last_Name__c = 'Banker', 
                                                          First_Name__c = 'Test', 
                                                          Phone__c = '5555555555', 
                                                          Email__c = 'test.banker@paychex.com');
        insert rc1;
        System.debug('Testing Set Owner');
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('bankName','Headquarters');
        email.plainTextBody += addXML('refEmployeeFirstName',rc1.First_Name__c);
        email.plainTextBody += addXML('refEmployeeLastName',rc1.Last_Name__c);
        email.plainTextBody += addXML('refEmployeePhone',rc1.Phone__c);
        email.plainTextBody += addXML('refEmployeeEmail',rc1.Email__c);
        email.plainTextBody += addXML('branchNumber','B01');
        email.plainTextBody += addXML('branchName','Child1');
        email.plainTextBody += addXML('branchZip','12345');
        email.plainTextBody += addXML('firstname','TestFirstName');
        email.plainTextBody += addXML('lastname','TestLastName');
        email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
        email.plainTextBody += addXML('x401k','TRUE');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('email','testLead1@testLead.com');
        email.plainTextBody += addXML('zip','14453');
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<lead> tLead = [Select Id, ownerId,company
                            from lead 
                            where company = 'WebBankLeadEmailTestCompany'
                            Limit 1];
        
        System.assertEquals(1,tLead.size());
        // check if there is a dupeblocker scenario setup
        //checkDupeBlocker('Lead');
        System.assertEquals(bcr.Id, tLead[0].OwnerId);
    }

    static testMethod void testFindPartnerBranchWithVendorId() {
        User bcr = [Select Id, Name, Sales_Org__c, HR_Person_Id__c, FirstName, LastName 
                            from User where HR_Person_Id__c != null 
                            and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
                            
        Referral_Account__c parentAcct = new Referral_Account__c(Name='Headquarters',PartnerId__c ='54321');
        insert parentAcct;
        
        Referral_Account__c childAcct1 = new Referral_Account__c(Name='Headquarters - Child1', Parent_Referral_Account__c=parentAcct.Id
                                                                 ,Bank_Branch_Number__c='B01', Zip_Postal_Code__c='12345', Bank_Centric_Rep_401k__c=bcr.Id);
        insert childAcct1;
            
        Referral_Contact__c rc1 = new Referral_Contact__c(Referral_Account__c = childAcct1.Id,
                                                          Name = 'Test Banker',
                                                          Last_Name__c = 'Banker', 
                                                          First_Name__c = 'Test', 
                                                          Phone__c = '5555555555', 
                                                          Email__c = 'test.banker@paychex.com');
        insert rc1;
        System.debug('Testing Set Owner');
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            messaging.Inboundemail email = new messaging.Inboundemail();
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('bankName','Headquarters');
        email.plainTextBody += addXML('refEmployeeFirstName',rc1.First_Name__c);
        email.plainTextBody += addXML('refEmployeeLastName',rc1.Last_Name__c);
        email.plainTextBody += addXML('refEmployeePhone',rc1.Phone__c);
        email.plainTextBody += addXML('refEmployeeEmail',rc1.Email__c);
        email.plainTextBody += addXML('branchNumber','B01');
        email.plainTextBody += addXML('branchName','Child1');
        email.plainTextBody += addXML('branchZip','12345');
        email.plainTextBody += addXML('firstname','TestFirstName');
        email.plainTextBody += addXML('lastname','TestLastName');
        email.plainTextBody += addXML('company','WebBankLeadVendorIdTestCompany');
        email.plainTextBody += addXML('x401k','TRUE');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('email','testLead1@testLead.com');
        email.plainTextBody += addXML('zip','14453');
        email.plainTextBody += addXML('VendorId','54321');
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        list<PartnerReferral__c> partRef = [Select Id, Vendor_ID__c
                            from PartnerReferral__c 
                            where Company__c = 'WebBankLeadVendorIdTestCompany'
                            Limit 1];
        
        System.assertEquals(1,partRef.size());

        
    } // testFindPartnerBranchWithVendorId
    
    /* do we still need this one?
static testMethod void testDuplicateAccount(){
Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType('Core Account Record Type', 'Account');  //Get the Core Record Type.
account testAccount1 = [select name, billingstreet, billingcity, phone 
from account
where name = 'Paychex'
and billingstreet != NULL
and billingCity != NULL
and Phone != NULL 
and recordtypeId = :acctCorert.getRecordTypeId()
order by CreatedDate DESC
limit 1][0];

messaging.Inboundemail email = new messaging.Inboundemail();
email.plainTextBody = WebBankLeadEmailHandler.MSG_START;
email.plainTextBody += addXML('firstname','WebBankLead');
email.plainTextBody += addXML('lastname','EmailTest');
email.plainTextBody += addXML('company',testAccount1.name);
email.plainTextBody += addXML('refEmployeeEmail','');
email.plainTextBody += addXML('phone',testAccount1.phone);
email.plainTextBody += addXML('street',testAccount1.billingstreet);
email.plainTextBody += addXML('city',testAccount1.billingcity);
email.plainTextBody += addXML('zip','14514');
email.plainTextBody += WebBankLeadEmailHandler.MSG_END;

Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
wBLEH.handleInboundEmail(email, env);

list<lead> tLead = [Select id, ownerId, Exception_Reason__c, recordtype.name 
from lead 
where company = :testAccount1.name
and postalCode = '14514'
and firstName = 'WebBankLead'
and lastName = 'EmailTest'
and recordType.name = 'Pending Leads'
and createdDate = TODAY
Order by CreatedDate DESC
limit 1];         
system.assertEquals('Contact or P-C Already Exists in Salesforce.',tLead[0].Exception_Reason__c);
}*/
    
    static string addXML(string tag, string content){
        return '<' + tag + '>' + content + '</' + tag + '>\r\n';
    }


/*
User uCore = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE limit 1];
User uCore2 = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_CORE and Id != :uCore.Id limit 1];
User uMms = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_MMS limit 1];
User uHrs = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_401 limit 1];
User uPeo = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_PEO_ASO limit 1];
User uHnb = [Select Id, Name, Sales_Org__c, HR_Person_Id__c from User where HR_Person_Id__c != null and IsActive=true and Sales_Org__c=:UserHelper.SO_HNB limit 1];

messaging.Inboundemail email = new messaging.Inboundemail();
email.plainTextBody = '<note>';
email.plainTextBody += addXML('firstname','WebBankLead');
email.plainTextBody += addXML('lastname','EmailTest');
email.plainTextBody += addXML('salesRepFirstName','Sales');
email.plainTextBody += addXML('salesRepLastName','Rep');
email.plainTextBody += addXML('refEmployeeFirstName','Test');
email.plainTextBody += addXML('refEmployeeLastName','Banker');
email.plainTextBody += addXML('refEmployeePhone','5555555555');
email.plainTextBody += addXML('refEmployeeEmail','test.banker@paychex.com');
email.plainTextBody += addXML('bankName','UNB');
email.plainTextBody += addXML('branchNumber','12345');
email.plainTextBody += addXML('branchName','CityCentre');
email.plainTextBody += addXML('company','WebBankLeadEmailTestCompany');
email.plainTextBody += addXML('email','email@testing.com');
email.plainTextBody += addXML('phone','585-123-4568');
email.plainTextBody += addXML('street','10 Main St');
email.plainTextBody += addXML('city','Anytown');
email.plainTextBody += addXML('state','NY');
email.plainTextBody += addXML('zip','14543');
email.plainTextBody += '</note>\r\nThe information contained'; */
    
    
static testMethod void testCitiBankFields() {
       
       messaging.Inboundemail email = new messaging.Inboundemail();
        WebBankLeadEmailHandler.TAG_OPTIONS=new String[]{MSG_TAG};
            
        email.plainTextBody = MSG_START;
        email.plainTextBody += addXML('bankName','Headquarters');
        email.plainTextBody += addXML('branchNumber','B01');
        email.plainTextBody += addXML('branchName','Child1');
        email.plainTextBody += addXML('branchZip','12345');
        email.plainTextBody += addXML('firstname','TestFirstName');
        email.plainTextBody += addXML('lastname','TestLastName');
        email.plainTextBody += addXML('company','WebBankLeadVendorIdTestCompany');
        email.plainTextBody += addXML('x401k','TRUE');
        email.plainTextBody += addXML('refEmployeeEmail','');
        email.plainTextBody += addXML('email','testLead1@testLead.com');
        email.plainTextBody += addXML('zip','14453');
        email.plainTextBody += addXML('VendorId','54321');
        email.plainTextBody += addXML('Area','Miami South');
        email.plainTextBody += addXML('Division','New York City');
         email.plainTextBody += addXML('CustConsent','TRUE');
         email.plainTextBody += addXML('ConsentObtainedBy','Obtained Name');
        email.plainTextBody += addXML('CustConsentContactMethod','By Phone');
        email.plainTextBody += addXML('CustConsentPhone','845789562');
        email.plainTextBody += addXML('CustomerConsentName','Consent Name');
        email.plainTextBody += MSG_END;
        
        Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
        webBankLeadEmailHandler wBLEH = new webBankLeadEmailHandler();
        wBLEH.handleInboundEmail(email, env);
        
        PartnerReferral__c partRef = [Select Id, Vendor_ID__c
                                            ,Obtained_Consent__c
                                            ,Consent_Obtained_By__c
                                            ,Consent_to_Text_Date__c 
                                            ,Consent_Obtained_Method__c 
                                            ,Consent_Obtained_From__c
                                            ,Consent_Obtained_Phone__c
                                            ,Consent_Obtained_Date__c
                            from PartnerReferral__c 
                            where Company__c = 'WebBankLeadVendorIdTestCompany'
                            Limit 1];
        

        System.assertEquals('Yes',partRef.Obtained_Consent__c);
        System.assertEquals('By Phone',partRef.Consent_Obtained_Method__c );
        System.assertEquals('845789562',partRef.Consent_Obtained_Phone__c);
        System.assertEquals('Obtained Name',partRef.Consent_Obtained_By__c);
        System.assertEquals('Consent Name',partRef.Consent_Obtained_From__c);

        
    } // testFindPartnerBranchWithVendorId
     
}