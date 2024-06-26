/** Extraction Request Trigger methods Test class.

* History
* -------
01/27/2022 Reetesh Pandey       Created

*/
@isTest(seeAllData=false)
public class ExtractionRequestTriggerMethodsTest {
    @istest
    public static void testUpdateER() {
        Test.startTest();
        Extraction_Request__c erU= [select id,ownerId,owner.name,Contact_name__c,Contact_name__r.Name,Contact_Email__c,
                                    case__c,Case__r.CaseNumber,status__c,Sales_Rep_Name__c,CreatedBy.Name from  Extraction_Request__c limit 1];
        
        erU.OwnerId=[select id from user where username like 'testUser1_ERTest@test.com' limit 1].Id;
        erU.Status__c='Closed - Client Unresponsive';
        update erU;
        Extraction_Request__c erU1=[select id, status__c from Extraction_Request__c where id = :erU.Id];
        System.assertEquals(erU1.Status__c,'Closed - Client Unresponsive');
        Test.stopTest();
        
    }
    @istest
    public static void testUpdateER1() {
        Test.startTest();
        Extraction_Request__c erU= [select id,ownerId,owner.name,Contact_name__c,Contact_name__r.Name,Contact_Email__c,
                                    case__c,Case__r.CaseNumber,status__c,Sales_Rep_Name__c,CreatedBy.Name,Reassign_to_Queue__c from  Extraction_Request__c limit 1];
        
        erU.Reassign_to_Queue__c=true;        
        update erU;
        Extraction_Request__c erU1=[select id, Reassign_to_Queue__c from Extraction_Request__c where id = :erU.Id];
        System.assertEquals(erU1.Reassign_to_Queue__c,false);
        Test.stopTest();
        
    }
    @testSetup
    public static void testDataSetUp(){
        
        Profile prof=[select id from Profile where name like 'System Administrator' limit 1];
        
        User u2 = new User();
        u2.username='testUser1_ERTest@test.com';
        u2.Sales_Org__c='MMS';
        u2.License_Type__c='MMS';
        u2.LastName='testMMSUser';
        u2.Email='test@test.com';
        u2.Alias='testER';
        u2.TimeZoneSidKey='America/New_York';
        u2.LocaleSidKey='sq_AL';
        u2.EmailEncodingKey='UTF-8';
        u2.ProfileId=prof.id;
        u2.LanguageLocaleKey='en_US';
        u2.Title = 'ER Test';
        insert u2;
        
        
        Account ac = new Account();
        ac.RecordTypeId =[select id from RecordType where name ='MMS Account Record Type' limit 1].Id;
        ac.Name ='Test Account';
        ac.Federal_ID_Number__c ='FedIdNum'; 
        ac.AccountNumber='TestAcc01';
        ac.NumberOfEmployees=10;
        insert ac;
        
        Contact con = new Contact();
        con.AccountId = ac.Id;
        con.Email = 'testCon@test.com'; 
        con.LastName='ERTestCon';
        con.RecordTypeId = [select id from RecordType where name ='MMS Contact Record Type' limit 1].id;    
        insert con;
        
        Opportunity op= new Opportunity();
        op.AccountId = ac.Id;
        op.Service_Location__c ='Advantage Operations Providence 0609';        
        op.StageName =label.OppStage_Won;
        op.CloseDate =system.today();
        op.name='TestOppER';
        insert op;
        
        Case cs= new Case();
        cs.RecordTypeId =[Select id from RecordType where Name='MPSC Implementation Data Collection' limit 1].Id;
        cs.Status ='New';
        cs.Opportunity__c = op.Id;
        cs.Contact_Name__c = con.id;
        cs.Contact_Email__c = con.Email;
        insert cs;
        
        Extraction_Request__c er= new Extraction_Request__c();
        er.Contact_name__c=con.Id;       
        er.case__c=cs.Id; 
        er.status__c='New';
        er.Account__c = ac.Id;
        er.Additional_Information__c ='Test Data';
        er.X1099_Employees__c='Yes';
        er.Contact_Email__c=con.Email;
        er.Date_final_payroll_processed__c = System.today();
        er.ERTC__c ='Yes';
        er.Number_of_IDs__c ='7';
        er.Payroll_Current_Prior_Method__c ='ADP Workforce Now';
        er.Per_pay_period_extraction_required__c='Yes';
        er.Opportunity__c = op.id;
        er.Service_Location__c= op.Service_Location__c;
        er.Federal_ID_Number__c = ac.Federal_ID_Number__c;
        
        insert er;
        
        
    }
    
}