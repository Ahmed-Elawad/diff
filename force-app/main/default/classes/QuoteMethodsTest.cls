/* 
   Test methods for the QuoteMethods 
   
  History
  -------
  05/25/2017 Cindy Freeman   Created
  03/06/2018 Carrie Marciano updated test to use asterisk for quote approvals
  06/08/2018 Cindy Freeman	 added test for getUserIM method
  06/08/2018 Justin Stouffer added test for Sales Approver fields
  11/09/2020 Carrie Marciano	commented out RunAs now that the only users with edit permissions are System Admin
 */

@isTest

public class QuoteMethodsTest {
    static testMethod void testQuoteMethods(){
    	QuoteMethods insQuotemethods = new QuoteMethods();
  	}
/*
    static testMethod void testQuoteUpdate() {
    
      List<User> testUserList = [Select Id, Name, HR_Person_ID__c, Zone__c, Sales_Org__c, SalesOfficeNumber__c, Cost_Center__c, District__c from User 
    				where Profile.Name Like 'MMS Sales%' and Sales_Org__c = 'MMS' and Zone__c='3' and IsActive=true limit 2];    				
      User testUser = testUserList.get(0);	 
      User testUser2 = testUserList.get(1);      
	  User testUser3 = [Select Id, Name, HR_Person_ID__c, Zone__c, Sales_Org__c, SalesOfficeNumber__c, Cost_Center__c, District__c from User 
    				where Profile.Name Like 'MMS Sales%' and Sales_Org__c = 'MMS' and IsActive=true and HR_Person_ID__c != NULL
    				and Id != :testUser.Id and Id != :testUser2.Id and Zone__c != :testUser2.Zone__c limit 1];
      User testUser4 = [Select Id from User where UserRole.ParentRoleId = NULL and IsActive=true and HR_Person_ID__c != NULL
    				and Id != :testUser.Id and Id != :testUser2.Id and Id != :testUser3.Id and Id != :UserInfo.getUserId() limit 1]; 
 
      insert new CPQApprover__c(Name='All',	Id__c=UserInfo.getUserId());
    				
	  List<UserIM_Mapping__c> uimList = new List<UserIM_Mapping__c>();    				
      uimList.add(new UserIM_Mapping__c(Name=testUser2.Zone__c,Zone_Name__c='EAST', HR_Person_ID__c=testUser2.HR_Person_ID__c));       
      uimList.add(new UserIM_Mapping__c(Name=testUser3.Zone__c,Zone_Name__c='WEST', HR_Person_ID__c=testUser3.HR_Person_ID__c));      
      insert uimList;

	  List<Organization_Structure__c> osList = new List<Organization_Structure__c>();
	  osList.add(new Organization_Structure__c(Name=testUser2.District__c,Sales_Office_Number__c=testUser2.SalesOfficeNumber__c,
	  				CostCenter__c=testUser2.Cost_Center__c, Sales_Org__c='MMS', Zone__c=testUser2.Zone__c));
      osList.add(new Organization_Structure__c(Name=testUser3.District__c,Sales_Office_Number__c=testUser3.SalesOfficeNumber__c,
      				CostCenter__c=testUser3.Cost_Center__c, Sales_Org__c='MMS', Zone__c=testUser3.Zone__c));      
      insert osList;
    
	  SBQQ__Quote__c q1;
        
      Opportunity opp1;
        
	  Schema.Recordtypeinfo mmsQRt = RecordTypeHelper.getRecordType('Quote', 'SBQQ__Quote__c');   
        
      //System.runAs(testUser){	
      // insert account 
    	Schema.RecordTypeInfo acctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
	    Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctMMSrt.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                //,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
	    insert acct1;  
	    Schema.RecordTypeInfo ctctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_CONTACT, ObjectHelper.OBJECT_CONTACT);
	    Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctMMSrt.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
		insert ctct1;                                
	     
	    // create Opportunity
	    Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,ObjectHelper.OBJECT_OPPTY);
        opp1 = new Opportunity(Name='Test MMS Opporty', RecordTypeId=mmsOpptyRt.getRecordTypeId(),AccountId=acct1.Id
                                         ,StageName='Qualified'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId()
                                         ,LeadSource = 'Cold Call'
                                         ,Payroll_Current_Prior_Method__c = 'ADP'
                                         ,Primary_Competition__c = 'ADP Payforce');
        insert opp1;                                                 
        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctct1.Id, OpportunityId=opp1.Id, IsPrimary=true);
        insert ocr1;	     
	          
	    // create quote
	    //Schema.Recordtypeinfo mmsQRt = RecordTypeHelper.getRecordType('MMS Quote', 'SBQQ__Quote__c');
	    q1 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.id, SBQQ__Status__c='Draft', Necessary_Approvers__c='*5*0*', 
	    										SBQQ__SalesRep__c = testUser.Id, Implementation_Manager__c=null, RecordTypeId=mmsQRt.getRecordTypeId());
	    insert q1;
	    
	    SBQQ__Quote__c updatedQ1 = [select Id, Implementation_Manager__c, SBQQ__SalesRep__r.Zone__c  from SBQQ__Quote__c where Id = :q1.Id];	
	    System.assertEquals(testUser2.Id, updatedQ1.Implementation_Manager__c);
	  //} // System.runAs
	  
		testUser.Cost_Center__c = testUser3.Cost_Center__c;
		testUser.District__c = testUser3.District__c;			    
	    testUser.Zone__c = testUser3.Zone__c;
	    update testUser;
	    
	    SBQQ__Quote__c updatedQ2 = [select Id, SBQQ__SalesRep__c, SBQQ__SalesRep__r.Zone__c, Implementation_Manager__c from SBQQ__Quote__c where Id = :q1.Id];  
	    System.assertEquals(testUser3.Id, updatedQ2.Implementation_Manager__c);
        
        q1 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.id, SBQQ__Status__c='Draft', Necessary_Approvers__c='*5*0*', 
                                SBQQ__SalesRep__c = testUser4.Id, Implementation_Manager__c=null, RecordTypeId=mmsQRt.getRecordTypeId());
       Test.startTest();
	    insert q1;
       Test.stopTest();
       
        q1 = [select Id, SBQQ__SalesRep__c, Sales_Approver_Level_1__c, Sales_Approver_Level_2__c, Sales_Approver_Level_3__c, Implementation_Manager__c from SBQQ__Quote__c where Id = :q1.Id];  
	    System.assertEquals(testUser4.Id, q1.SBQQ__SalesRep__c);
        System.assertEquals(UserInfo.getUserId(), q1.Sales_Approver_Level_1__c);
        System.assertEquals(UserInfo.getUserId(), q1.Sales_Approver_Level_2__c);
        System.assertEquals(UserInfo.getUserId(), q1.Sales_Approver_Level_3__c);
        	    
    } // testQuoteUpdate

    static testMethod void testGetUserIM() {
        User testUser = [Select Id, Name, HR_Person_ID__c from User where HR_Person_Id__c != null and UserRoleId != null and Profile.Name=:Utilities.PROF_SYS_ADMIN and IsActive=true limit 1];
        
      UserIM_Mapping__c uim = new UserIM_Mapping__c(Name='1',Zone_Name__c='EAST', HR_Person_ID__c=testUser.HR_Person_ID__c);      
      insert uim;
      UserIM_Mapping__c uim2 = new UserIM_Mapping__c(Name='2',Zone_Name__c='SOUTHEAST', HR_Person_ID__c=testUser.HR_Person_ID__c);      
      insert uim2;
      
     List<UserIM_Mapping__c> uIMList = UserIM_Mapping__c.getall().values();
     
     System.assertEquals(2,uIMList.size());
         
      Id im = QuoteMethods.getUserIM('1');      
      System.assertEquals(testUser.Id, im);
      
   } // testGetUserIM    

   static testMethod void testOppProductFields() {
      List<User> testUserList = [Select Id, Name, HR_Person_ID__c, Zone__c, Sales_Org__c, SalesOfficeNumber__c, Cost_Center__c, District__c from User 
               where Profile.Name Like 'MMS Sales%' and Sales_Org__c = 'MMS' and Zone__c='3' and IsActive=true limit 1];               
      User testUser = testUserList.get(0);    

      SBQQ__Quote__c q1;
        
      Opportunity opp1;
        
      Schema.Recordtypeinfo mmsQRt = RecordTypeHelper.getRecordType('Quote', 'SBQQ__Quote__c');   
        
      //System.runAs() { 
         // insert account 
         Schema.RecordTypeInfo acctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
         Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctMMSrt.getRecordTypeId()
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                //,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Phone = '555-1212'
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
         insert acct1;  
         Schema.RecordTypeInfo ctctMMSrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_CONTACT, ObjectHelper.OBJECT_CONTACT);
         Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctMMSrt.getRecordTypeId()
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
         insert ctct1;                                
        
         // create Opportunity
         Schema.RecordTypeInfo mmsOpptyRt = RecordTypeHelper.getRecordType(OpportunityCreateCase.RT_OPPTY_MMS,ObjectHelper.OBJECT_OPPTY);
         opp1 = new Opportunity(Name='Test MMS Opporty', RecordTypeId=mmsOpptyRt.getRecordTypeId(),AccountId=acct1.Id
                                         ,StageName='Qualified'
                                         ,CloseDate=Date.today().addDays(30)
                                         ,OwnerId=UserInfo.getUserId()
                                         ,LeadSource = 'Cold Call'
                                         ,Payroll_Current_Prior_Method__c = 'ADP'
                                         ,Primary_Competition__c = 'ADP Payforce');
         insert opp1;                                                 
         OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctct1.Id, OpportunityId=opp1.Id, IsPrimary=true);
         insert ocr1;      
             
         // create quote
         q1 = new SBQQ__Quote__c(SBQQ__Opportunity2__c = opp1.id, SBQQ__Status__c='Draft', Necessary_Approvers__c='*5*0*', 
                                    SBQQ__SalesRep__c = testUser.Id, Implementation_Manager__c=null, RecordTypeId=mmsQRt.getRecordTypeId()
                                    ,SBQQ__Primary__c=true
                                   ,Have_ASO__c=true,Have_PEO__c=false, Have_HR_Essentials__c=true, Include_Handbook__c=false);
         Test.startTest();
         insert q1;
         Test.stopTest();
         
         Opportunity checkOpp = [Select Id, Name, HR_Solutions_ASO__c, HR_Solutions_PEO__c, HR_Essentials__c, HR_Fundamentals__c 
                                   from Opportunity where Id = :opp1.Id];
         System.assertEquals(true,checkOpp.HR_Solutions_ASO__c);
         System.assertEquals(false,checkOpp.HR_Solutions_PEO__c);
         System.assertEquals(true,checkOpp.HR_Essentials__c);
         System.assertEquals(false,checkOpp.HR_Fundamentals__c);
         
         q1.Have_PEO__c=true;
         q1.Have_HR_Essentials__c=false;
         q1.Include_Handbook__c=true;
         
         QuoteMethods.SKIP_FUTURE=true;
         QuoteMethods.TRIGGER_AFTER_EXECUTED=false;
         QuoteMethods.quoteIdsProcessed.clear();
         update q1;
         
         checkOpp = [Select Id, Name, HR_Solutions_ASO__c, HR_Solutions_PEO__c, HR_Essentials__c, HR_Fundamentals__c 
                                   from Opportunity where Id = :opp1.Id];
         System.assertEquals(true,checkOpp.HR_Solutions_ASO__c);
         System.assertEquals(true,checkOpp.HR_Solutions_PEO__c);
         System.assertEquals(false,checkOpp.HR_Essentials__c);
         System.assertEquals(true,checkOpp.HR_Fundamentals__c);
         
                  
      //} // System.runAs
   } // testOppProductFields
*/
} // class QuoteMethodsTest