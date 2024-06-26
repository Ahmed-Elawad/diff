/* 
   Test methods for Tarmika Bridge 

   
  History
  -------
  12/22/2022 Carrie Marciano        Created

*/
@isTest
public class PCQuoteDataMethodsTest {
	public static String [] dqSalesOrgs = Label.PCQuoteDataSalesOrg.split(',');
    public static ID pcRT = Label.PCQuoteDataRecordTypeId;
    
    static testMethod void testQuoteStartSF() {
    	User userPC = [SELECT Id, Email FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:dqSalesOrgs LIMIT 1];
        PermissionSet ps = [SELECT Id FROM PermissionSet WHERE Name = 'Access_to_P_C_Quote_Data_PC_Rep' Limit 1];
        PermissionSetAssignment[] uPSA = [Select Id from PermissionSetAssignment where AssigneeId=:userPC.Id and PermissionSetId=:ps.Id LIMIT 1];
        system.debug('testQuoteStartSF uPSA: '+uPSA);
        if(uPSA == null){
        	PermissionSetAssignment psa = new PermissionSetAssignment(AssigneeId = userPC.Id, PermissionSetId = ps.Id);
        	insert psa;    
        }
                    
        System.RunAs(userPC){
            Account acct = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913'
                                   ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
            insert acct;
                
            Contact ctct = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct.id);
            insert ctct;
            
            Opportunity opp = new Opportunity(Name='PC OPP', AccountId=acct.Id, RecordTypeId = pcRT, OpportunityType__c = 'BOP (Business Owners Package)', HNBF_Sales_Type__c = 'New Case', CloseDate=Date.today().addDays(7), StageName = 'Discovery', Probability = 40);
            insert opp;
            Test.startTest();
            //initial insert of P&C Quote Data as if created by TarmikaBridgeController
            PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Opportunity__c = opp.Id, Prospect_Client__c=acct.Id, Opportunity_Type__c=opp.OpportunityType__c,Prospect_Client_Name__c=acct.Name,
                                                         Prospect_Client_Street__c=acct.ShippingStreet, Prospect_Client_City__c=acct.ShippingCity, Prospect_Client_State__c=acct.ShippingState,
                                                         Prospect_Client_Postal_Code__c=acct.ShippingPostalCode, Contact_First_Name__c=ctct.FirstName, Contact_Last_Name__c=ctct.LastName,
                                                         Contact_Phone_Number__c=ctct.Phone, Contact_Email_Address__c=ctct.Email);
            insert pcqD;
            
            PC_Quote_Data__c iPCQD = [Select Id, Opportunity__c, Prospect_Client_Name__c from PC_Quote_Data__c Where Id =:pcqD.Id];
            System.assertEquals(acct.Name, iPCQD.Prospect_Client_Name__c);
            System.assertEquals(opp.Id, iPCQD.Opportunity__c);
            
            //updating P&C Quote Data with inital response from Tarmika - update Account fields
            pcqD.Tarmika_Request_Number__c = '0000064541';
            pcqD.Insured_Name__c = 'ACCT1';
            pcqD.Business_Entity__c = 'LLC';
            pcqD.Business_Classification__c = 'Retail Trade';
            pcqD.NAICS_Code__c = '445566-789';
            pcqD.Carrier_1_Name__c = 'LibertyMutual';
            pcqD.Carrier_1_Line_of_Business__c = 'BOP';
            pcqD.Carrier_1_Quote_Number__c = '65642804';
            pcqD.Carrier_1_Quote_Request_Id__c = '0000057705';
            pcqD.Carrier_1_Quote_Status__c = 'Accept';
            pcqD.Carrier_1_Total_Premium__c = 7368.22;
            update pcqD;
            
            PC_Quote_Data__c uPCQD = [Select Id, Opportunity__c, Prospect_Client__c, Prospect_Client__r.Organization_Type__c, Prospect_Client__r.NAICS_Code__c, Carrier_1_Name__c, 
                           Tarmika_Request_Number__c from PC_Quote_Data__c Where Id =:pcqD.Id];
            System.assertEquals('LibertyMutual', uPCQD.Carrier_1_Name__c);
            System.assertEquals('0000064541', uPCQD.Tarmika_Request_Number__c);
            System.assertEquals('LLC', uPCQD.Prospect_Client__r.Organization_Type__c);
                
            //updating P&C Quote Data with 'Quoted' response from Tarmika - update opportunity Stage/Probability
            pcqD.Carrier_1_Quote_Status__c = 'Quoted';
            update pcqD;
            
            PC_Quote_Data__c uPCQD2 = [Select Id, Opportunity__c, Opportunity__r.Probability, Prospect_Client__c, Prospect_Client__r.Organization_Type__c, Prospect_Client__r.NAICS_Code__c, Carrier_1_Name__c, 
                           Tarmika_Request_Number__c, Carrier_1_Quote_Status__c from PC_Quote_Data__c Where Id =:pcqD.Id];
            System.assertEquals('Quoted', uPCQD2.Carrier_1_Quote_Status__c);
            System.assertEquals(50, uPCQD2.Opportunity__r.Probability);
                          
            Test.stopTest();
            
        }
    }
    
    static testMethod void testQuoteStartTarmika() {
        User userPC = [SELECT Id, Email FROM User WHERE isActive = true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:dqSalesOrgs LIMIT 1];
    	PC_Quote_Data__c pcqD = new PC_Quote_Data__c(Prospect_Client_Name__c='Test Acct',
                                                    Prospect_Client_Street__c='123 Main Street', Prospect_Client_City__c='Rochester', Prospect_Client_State__c='NY',
                                                    Prospect_Client_Postal_Code__c='14609', Contact_First_Name__c='Test', Contact_Last_Name__c='Guy',
                                                    Contact_Phone_Number__c='555-555-5555', Contact_Email_Address__c='testguy@nothing.com', Tarmika_Request_Number__c='0000065299',
                                                    Agent_Name__c=userPC.Email, Insured_Name__c='Test Acct', FEIN_Number__c='123456-789', Business_Entity__c='INDIVIDUAL', 
            										Business_Classification__c='Construction', NAICS_Code__c='238210', Carrier_1_Name__c='LibertyMutual',Carrier_1_Line_of_Business__c='BOP',
                                                    Carrier_1_Quote_Number__c = '123456789', Carrier_1_Quote_Request_Id__c = '0000057705', Carrier_1_Quote_Status__c = 'Accept',Carrier_1_Total_Premium__c = 7368.22);
        insert pcqD;
        
        PC_Quote_Data__c iPCQD = [Select Id, Prospect_Client_Name__c, Tarmika_Request_Number__c from PC_Quote_Data__c Where Id =:pcqD.Id];
        System.assertEquals('0000065299', iPCQD.Tarmika_Request_Number__c);
        System.assertEquals('Test Acct', iPCQD.Prospect_Client_Name__c);
         
    }
}