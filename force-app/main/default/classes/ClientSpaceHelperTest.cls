/* Test Methods for ClientSpaceHelper

  History
  -------
  07/12/2019 Dan Carmen        Created
  09/10/2019 Dan Carmen        Add methods for Task,Event,Opportunity
  01/30/2020 Dan Carmen        If a record is deleted, mark the work queue as completed and deleted.
  08/21/2020 Dan Carmen        Don't update the closeDate on the Opportunity
  05/18/2021 Dan Carmen        Update to not use "Not Sold" in the code - added another field on the Metadate Type to indicate lost - OpptyLost__c.
  07/01/2021 Jake Hinds        Check if runningUser is null
  07/02/2021 Jake Hinds		   Changing ownerMatchesAcct to prioritize nsc
  09/13/2021 Matt Fritschi	   Clear parent PEO Checklist value if Sales Parent on Account gets cleared. 
  06/06/2023 Josh Cartwright   upated NSC select to select PEO Sales org instead of NSC (NSC was recently removed)


*/
@isTest
public class ClientSpaceHelperTest {
   
   public static String TASK_RT='Prism PEO Task Record Type';
   public static String EVENT_RT='Prism PEO Event Record Type';
   // public static String OPP_RT='Prism PEO Opportunity Record Type';
   // public static String OPP_FSS_RT='Prism PEO Opportunity FSS Record Type';
   public static String OPP_RT='PEO Opportunity Record Type';
   public static String OPP_FSS_RT='PEO Opportunity FSS Record Type';
   
   @testSetup
   public static void setupTestData() {
      TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
      TriggerMethodsTest.createTriggerSetting('AccountBefore', true, false, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('ContactBefore', true, false, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('AccountAfter', false, true, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('TaskAfter', false, true, false, true, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('EventCheckType', false, true, false, true, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('OpptyAfter', false, true, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);

      TriggerMethodsTest.createTriggerSetting('AccountDelete', false, false, false, true, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('ContactDelete', false, false, false, true, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);

      TriggerMethodsTest.createTriggerSetting('ReferencePEOMedicalUWTrigger', false, true, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('ReferencePEOUpdate', false, true, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      
      TriggerMethodsTest.createTriggerSetting('PEOOnboardingChecklist', true, true, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      TriggerMethodsTest.createTriggerSetting('PEOOnboardingMedicalQuestionnaire', true, true, false, false, new String[]{'ClientSpaceHelper'}, classes, TriggerMethods.INTERFACE_C);
      
      insert classes;
      
      RecordType__c[] recordTypes = new RecordType__c[]{};

      recordTypes.add(new RecordType__c(Name=TASK_RT,ObjectName__c=ObjectHelper.OBJECT_TASK,RecordTypeName__c=TASK_RT, Sales_Org__c='PEO',UseForClientSpace__c=true));
      recordTypes.add(new RecordType__c(Name=EVENT_RT,ObjectName__c=ObjectHelper.OBJECT_EVENT,RecordTypeName__c=EVENT_RT, Sales_Org__c='PEO',UseForClientSpace__c=true));
      recordTypes.add(new RecordType__c(Name=OPP_RT,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OPP_RT, Sales_Org__c='PEO',UseForClientSpace__c=true,CSOtherInfoUpdate__c=true,CSStatusUpdate__c=true));
      recordTypes.add(new RecordType__c(Name=OPP_FSS_RT,ObjectName__c=ObjectHelper.OBJECT_OPPTY,RecordTypeName__c=OPP_FSS_RT, Sales_Org__c='PEO',UseForClientSpace__c=true,CSOtherInfoUpdate__c=true,CSStatusUpdate__c=true));
      recordTypes.add(new RecordType__c(Name=RecordTypeHelper.CORE_ACCOUNT,ObjectName__c=ObjectHelper.OBJECT_ACCOUNT,RecordTypeName__c=RecordTypeHelper.CORE_ACCOUNT, Sales_Org__c=UserHelper.SO_CORE));
      insert recordTypes;
   } // setupTestData
    
   public static User getTestCSUser() {
      User csUser = [Select Id, Name, HR_Person_Id__c from User where CSUserId__c != null and HR_Person_Id__c != null and IsActive=true and UserRoleId != null limit 1];
      return csUser;
   } // getTestCSUser


    static testMethod void testAcctCtctCSFlag() {
      User csUser = getTestCSUser();
      User nonCsUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and CSUserId__c = null limit 1];
      
      Account acct1 = new Account(Name='Account1', OwnerId=nonCsUser.Id, SendToClientSpace__c=true);
      Account acct2 = new Account(Name='Account2', OwnerId=csUser.Id, SendToClientSpace__c=true);
      Account acct3 = new Account(Name='Account3', CSOrgID__c='123', SendToClientSpace__c=true);
      Account[] accts = new Account[]{acct1,acct2,acct3};
      insert accts;
      
      // nothing should be set on insert of the accounts
      Map<Id,Account> acctMap = getAcctMap();
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(false,acct1.UseClientSpace__c);
      // flag should still be set
      System.assertEquals(true,acct1.SendToClientSpace__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(false,acct2.UseClientSpace__c);
      System.assertEquals(true,acct2.SendToClientSpace__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(false,acct3.UseClientSpace__c);
      System.assertEquals(true,acct3.SendToClientSpace__c);
      System.assertEquals(0,[select count() from Work_Queue__c]);
       
      // update to actually fire the triggers.
      TriggerMethods.clearVariables();
      update acctMap.values();  
      acctMap = getAcctMap();
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(false,acct1.UseClientSpace__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.UseClientSpace__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(true,acct3.UseClientSpace__c);

      System.assertEquals(2,[select count() from Work_Queue__c]);
      
      acct1.CSOrgId__c = '234';
      acct2.OwnerId=nonCsUser.Id;
      acct2.CSOrgId__c = '345';
      acct3.CSOrgId__c = '456';
      
      accts = new Account[]{acct1,acct2,acct3};
      TriggerMethods.clearVariables();
      update accts;

      acctMap = getAcctMap();
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(true,acct1.UseClientSpace__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.UseClientSpace__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(true,acct3.UseClientSpace__c);      

      System.assertEquals(3,[select count() from Work_Queue__c]);

   } // testAcctCtctCSFlag
    
    static testMethod void checkImplementationAfterChecklistTest() {
        Schema.RecordTypeInfo rtAcct = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, 'Account');
        Account acct = new Account(Name = 'ParentTestAccountCommunities', RecordTypeId=rtAcct.getRecordTypeId());
        insert acct;
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='Test',Prospect_Client__c=acct.Id);
        insert checklist;
        PEO_Implementation_Checklist__c implChecklist = new PEO_Implementation_Checklist__c(Prospect_Client__c=acct.Id, Parent_Underwriting_Checklist__c=checklist.Id,
                                                                                             PEO_Underwriting_Checklist__c=checklist.Id);
        insert implChecklist;
        List<PEO_Implementation_Checklist__c> chkList = new List<PEO_Implementation_Checklist__c>();
        chkList.add(implChecklist);
        system.debug('+++'+chkList[0]);
        Test.startTest();
        clientSpaceHelper.checkImplementationAfterChecklist(chkList);
        Test.stopTest();
    }

    static testMethod void testPEOOnboardingChecklist() {
      User nonCsUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and CSUserId__c = null limit 1];
      
      Account acct1 = new Account(Name='Account1', OwnerId=nonCsUser.Id, SendToClientSpace__c=true);
      insert acct1;
       
      PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c = acct1.Id);
      insert checklist;
      
      checklist.annual_number_of_out_of_country_travel__c = 1;
      update checklist;
       
      System.assertEquals(1,[select count() from Work_Queue__c]);
 }
  static testMethod void testPEOOnboardingChecklist1() {	
      User nonCsUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and CSUserId__c = null limit 1];	
       User csUser = getTestCSUser();	
      Account acct1 = new Account(Name='Account1', OwnerId=nonCsUser.Id, SendToClientSpace__c=true);	
      insert acct1;	
	  Id oppRtId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(OPP_RT).getRecordTypeId();	
	  Opportunity opp1 = new Opportunity(AccountId=acct1.Id, RecordTypeId=oppRtId, Name='Opp1',CloseDate=Date.today().addDays(14), StageName='Pending');	
      insert opp1;	
      PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'PEO OASIS 1','PEO OASIS 2','ANOTHER PROD'}, UserHelper.SO_PEO, null); 	
      PricebookEntry peo1 = null;	
      PricebookEntry peo2 = null;	
      PricebookEntry otherProd = null;	
      for (PricebookEntry entry : entries) {	
         if (entry.Product2.Name == 'PEO OASIS 1') {	
            peo1 = entry;	
         } else if (entry.Product2.Name == 'PEO OASIS 2') {	
            peo2 = entry;	
         } else if (entry.Product2.Name == 'ANOTHER PROD') {	
            otherProd = entry;	
         }	
      }	
      Product2 updatePeo1 = new Product2(Id=peo1.Product2Id, ClientSpaceProduct__c=true);	
      Product2 updatePeo2 = new Product2(Id=peo2.Product2Id, ClientSpaceProduct__c=true);	
      Product2 updatePeo3 = new Product2(Id=otherProd.Product2Id, ClientSpaceProduct__c=true);	
      Product2[] updateProds = new Product2[]{updatePeo1,updatePeo2,updatePeo3};	
      update updateProds;	
      	
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=peo1.Id, Quantity=1,TotalPrice=5);	
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=peo2.Id, Quantity=1,TotalPrice=5);	
      OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=otherProd.Id, Quantity=1,TotalPrice=5);	
      OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=peo1.Id, Quantity=1,TotalPrice=5);	
      OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2,oli3,oli4};	
      insert olis;	
       	
      PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c();	
      checklist.Prospect_Client__c = acct1.Id;	
      checklist.Opportunity__C = opp1.id;	
 	  checklist.CS_CM_Med_UW_Submit_Date__c = system.today();	
      checklist.CS_CM_Contract_Status__c = 'Prospect';	
      checklist.CS_CM_Status_Date__c = system.today();	
      checklist.CS_CM_Status_Date__c = system.today();	
      checklist.CS_CM_Contract_Received_Date__c = system.today();	
      checklist.CS_CM_Implementation_Date__c = system.today();	
      checklist.CS_CM_Med_UW_Accept_Date__c = system.today();	
      checklist.CS_CM_Med_UW_Decision_Date__c = system.today();	
      checklist.CS_CM_WC_UW_Status__c = 'More Info Needed';	
      checklist.CS_CM_WC_UW_Accept_Date__c = system.today();	
      checklist.CS_CM_WC_UW_Decision_Date__c = system.today();	
      checklist.CS_CM_Medical_UW_Status__c = 'More Info Needed';	
      checklist.CS_CM_WC_UW_Submit_Date__c = system.today();	
      checklist.Oasis_Revenue__c = 1000;	
      insert checklist;	
      acct1.CSCMKillReason__c = 'TestRecord';
      acct1.CSCMContractStatus__c = 'Client';
      update acct1;	
	  	
      PEO_Onboarding_Checklist__c checklist1 = new PEO_Onboarding_Checklist__c();	
      checklist1.Id = checklist.Id;	
      checklist1.Prospect_Client__c = acct1.Id;	
      checklist1.Opportunity__C = opp1.id;	
      checklist1.annual_number_of_out_of_country_travel__c = 1;	
      checklist1.CS_CM_Med_UW_Submit_Date__c = system.today().addDays(2);	
      checklist1.CS_CM_Contract_Status__c = 'Client-DNU';	
      checklist1.CS_CM_Status_Date__c = system.today().addDays(8);	
      checklist1.CS_CM_Status_Date__c = system.today().addDays(9);	
      checklist1.CS_CM_Contract_Received_Date__c = system.today().addDays(3);	
      checklist1.CS_CM_Implementation_Date__c = system.today().addDays(1);	
      checklist1.CS_CM_Med_UW_Accept_Date__c = system.today().addDays(4);	
      checklist1.CS_CM_Med_UW_Decision_Date__c = system.today().addDays(-5);	
      checklist1.CS_CM_WC_UW_Status__c = 'In-Progress';	
      checklist1.CS_CM_WC_UW_Accept_Date__c = system.today().addDays(8);	
      checklist1.CS_CM_WC_UW_Decision_Date__c = system.today().addDays(7);	
      checklist1.CS_CM_Medical_UW_Status__c = 'In-Progress';	
      checklist1.CS_CM_WC_UW_Submit_Date__c = system.today().addDays(10);	
      checklist1.Oasis_Revenue__c = 1000;	
      checklist1.CS_CM_Kill_Reason__c = 'TestRecord';	
      update checklist1;	
	 	
	  	
     map<id, PEO_Onboarding_Checklist__c> peomap= new map<id,PEO_Onboarding_Checklist__c>();	
     peomap.put(checklist.Opportunity__c, checklist);	
	 checklist.CS_CM_Status_Date__c =system.today();	
	 list<PEO_Onboarding_Checklist__c> peoList=new list<PEO_Onboarding_Checklist__c>();	
     map<id, PEO_Onboarding_Checklist__c> peomap1= new map<id,PEO_Onboarding_Checklist__c>();	
     peomap1.put(checklist.id, checklist);	
	 peoList.add(checklist1);	
	  System.runAs(csUser) {	
    //  update checklist;	
	 clientSpaceHelper.checkChecklistAfterFromCS(peoList,peomap1);	
     string jsonstring=json.serialize(peomap);	 	
	 clientSpaceHelper.updateOpportunityFromChecklist (jsonstring);	
	}	
       	
 }  	
  
   /**static testMethod void testPEOMedQuestionnaire() {
      User nonCsUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and CSUserId__c = null limit 1];
      
      Account acct1 = new Account(Name='Account1', OwnerId=nonCsUser.Id, SendToClientSpace__c=true);
      insert acct1;
       
      PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c = acct1.Id);
      insert checklist;
      
      PEO_Onboarding_Medical_Questionnaire__c medQuestionnaire = new PEO_Onboarding_Medical_Questionnaire__c(PEO_Onboarding_Checklist__c = checklist.id);
      insert medQuestionnaire;
      
      medQuestionnaire.Past_medical_carrier_if_applicable__c = 'No';
      update medQuestionnaire;
       
      System.assertEquals(2,[select count() from Work_Queue__c]);
 }**/
   static testMethod void testActivityOpps() {
      User csUser = getTestCSUser();
      //updated NSC select to select PEO Sales org instead of NSC (NSC was recently removed)    
      User nsc = [Select Id, Name, HR_Person_Id__c from User where CSUserId__c != null and HR_Person_Id__c != null and IsActive=true and UserRoleId != null AND Sales_Division__c = 'PEO' limit 1];      User nonCsUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and CSUserId__c = null limit 1];
      
      Account acct1 = new Account(Name='Account1', OwnerId=nonCsUser.Id);
      Account acct2 = new Account(Name='Account2', OwnerId=csUser.Id);   // this will be a client space record
      Account acct3 = new Account(Name='Account3', CSOrgID__c='123', OwnerId=csUser.Id);  // this will be a client space record
      Account acct4 = new Account(Name='Account4', OwnerId=nonCsUser.Id);
      //Account acct5 = new Account(Name='Account5', OwnerId=csUser.Id); //will be worked by nsc
      //Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      
      Map<Id,Account> acctMap = getAcctMap();
      
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(false,acct1.UseClientSpace__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(false,acct2.UseClientSpace__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(false,acct3.UseClientSpace__c);
      acct4 = acctMap.get(acct4.Id);
      System.assertEquals(false,acct4.UseClientSpace__c);
      //acct5 = acctMap.get(acct5.Id);
      //System.assertEquals(false,acct5.UseClientSpace__c);
      
      Contact ctct1 = new Contact(AccountId=acct1.Id, OwnerId=acct1.OwnerId, LastName='Ctct1', CSContactId__c='234', Sales_Contact__c=true);
      Contact ctct2 = new Contact(AccountId=acct2.Id, OwnerId=acct2.OwnerId, LastName='Ctct2', CSContactId__c='235', Sales_Contact__c=true);
      Contact ctct3 = new Contact(AccountId=acct3.Id, OwnerId=acct3.OwnerId, LastName='Ctct3', CSContactId__c='236', Sales_Contact__c=true);
      Contact ctct4 = new Contact(AccountId=acct4.Id, OwnerId=acct4.OwnerId, LastName='Ctct4', Sales_Contact__c=true);
      //Contact ctct5 = new Contact(AccountId=acct5.Id, OwnerId=csUser.Id, LastName='Ctct3', CSContactId__c='237', Sales_Contact__c=true);
      //Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4,ctct5};
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;

      System.assertEquals(0,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_ACCOUNT and Completed__c=false]); 
      System.assertEquals(0,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_CONTACT and Completed__c=false]); 

      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo oppRtInfo = byNameMap.get(OPP_RT);
      System.assertNotEquals(null,oppRtInfo);
      Id oppRtId = oppRtInfo.getRecordTypeId();

      // the opportunities should trigger them coming into client space
      Opportunity opp1 = new Opportunity(Name='Opp1', OwnerId=csUser.Id, AccountId=acct1.Id, RecordTypeId=oppRtId, CloseDate=Date.today().addDays(7), StageName='Pending'); 
      Opportunity opp2 = new Opportunity(Name='Opp2', OwnerId=csUser.Id, AccountId=acct2.Id, RecordTypeId=oppRtId, CloseDate=Date.today().addDays(7), StageName='Pending'); 
      Opportunity opp3 = new Opportunity(Name='Opp3', OwnerId=csUser.Id, AccountId=acct3.Id, RecordTypeId=oppRtId, CloseDate=Date.today().addDays(7), StageName='Pending'); 
      Opportunity opp4 = new Opportunity(Name='Opp4', OwnerId=csUser.Id, AccountId=acct4.Id, RecordTypeId=oppRtId, CloseDate=Date.today().addDays(7), StageName='Pending');
      //Opportunity opp5 = new Opportunity(Name='Opp5', OwnerId=nsc.Id, AccountId=acct5.Id, RecordTypeId=oppRtId, CloseDate=Date.today().addDays(7), StageName='Pending');
      //Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5};
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4};
      System.debug('testActivityOpps before inserting opps');
      insert opps;
      
      System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_ACCOUNT and Completed__c=false]); 
      System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_CONTACT and Completed__c=false]); 
     // System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_OPPTY and Completed__c=false]); 

      acctMap = getAcctMap();
      
      acct1 = acctMap.get(acct1.Id);
      System.assertEquals(false,acct1.UseClientSpace__c);
      acct2 = acctMap.get(acct2.Id);
      System.assertEquals(true,acct2.UseClientSpace__c);
      acct3 = acctMap.get(acct3.Id);
      System.assertEquals(true,acct3.UseClientSpace__c);
      acct4 = acctMap.get(acct4.Id);
      System.assertEquals(false,acct4.UseClientSpace__c);
      //acct5 = acctMap.get(acct5.Id);
      //System.assertEquals(true,acct5.UseClientSpace__c);
      
      // no longer using the flag on the contact
      //Map<Id,Contact> ctctMap = getCtctMap();
      //ctct1 = ctctMap.get(ctct1.Id); 
      //System.assertEquals(false,ctct1.UseClientSpace__c);
      //ctct2 = ctctMap.get(ctct2.Id);      
      //System.assertEquals(true,ctct2.UseClientSpace__c);
      //ctct3 = ctctMap.get(ctct3.Id);      
      //System.assertEquals(true,ctct3.UseClientSpace__c);
      //ctct4 = ctctMap.get(ctct4.Id);      
      //System.assertEquals(false,ctct4.UseClientSpace__c);
      
      acct2.SignificantContact__c = ctct2.Id;
      update acct2;
      
      byNameMap = Task.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo tskRtInfo = byNameMap.get(TASK_RT);
      System.assertNotEquals(null,tskRtInfo);
      Id tskRtId = tskRtInfo.getRecordTypeId();
      
      Task tsk1 = new Task(RecordTypeId=tskRtId, OwnerId=csUser.Id, Subject='tsk1', WhoId=ctct1.Id, WhatId=acct1.Id, ActivityDate=Date.today(), Status='Pending');
      Task tsk2 = new Task(RecordTypeId=tskRtId, OwnerId=csUser.Id, Subject='tsk2', WhatId=acct2.Id, ActivityDate=Date.today(), Status='Pending');
      Task tsk3 = new Task(RecordTypeId=tskRtId, OwnerId=csUser.Id, Subject='tsk3', WhoId=ctct3.Id, WhatId=acct3.Id, ActivityDate=Date.today(), Status='Pending');
      Task tsk4 = new Task(RecordTypeId=tskRtId, OwnerId=csUser.Id, Subject='tsk4', WhoId=ctct4.Id, WhatId=acct4.Id, ActivityDate=Date.today(), Status='Pending');
      Task[] tsks = new Task[]{tsk1,tsk2,tsk3,tsk4};
      Test.startTest();
      insert tsks;
      Test.stopTest();

      System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_TASK and Completed__c=false]); 

      byNameMap = Event.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo evtRtInfo = byNameMap.get(EVENT_RT);
      System.assertNotEquals(null,evtRtInfo);
      Id evtRtId = evtRtInfo.getRecordTypeId();

      Event evt1 = new Event(RecordTypeId=evtRtId, OwnerId=csUser.Id, Subject='evt1', WhoId=ctct1.Id, WhatId=acct1.Id, ActivityDate=Date.today(), ActivityDateTime=Datetime.now(), DurationInMinutes=30);
      Event evt2 = new Event(RecordTypeId=evtRtId, OwnerId=csUser.Id, Subject='evt2', WhatId=acct2.Id, ActivityDate=Date.today(), ActivityDateTime=Datetime.now(), DurationInMinutes=30);
      Event evt3 = new Event(RecordTypeId=evtRtId, OwnerId=csUser.Id, Subject='evt3', WhoId=ctct3.Id, WhatId=acct3.Id, ActivityDate=Date.today(), ActivityDateTime=Datetime.now(), DurationInMinutes=30);
      Event evt4 = new Event(RecordTypeId=evtRtId, OwnerId=csUser.Id, Subject='evt4', WhoId=ctct4.Id, WhatId=acct4.Id, ActivityDate=Date.today(), ActivityDateTime=Datetime.now(), DurationInMinutes=30);
      Event[] evts = new Event[]{evt1,evt2,evt3,evt4};
      ClientSpaceHelper.SKIP_FUTURE=true;
      insert evts;
      
      System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_EVENT and Completed__c=false]); 
      
      TriggerMethods.clearVariables();
      // if the records are deleted, delete the work queue records? 
      System.debug('testActivityOpps start of delete testing');
      delete evts;
      System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_EVENT and Completed__c=true and RecordIsDeleted__c=true]); 
      delete tsks;
      System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_TASK and Completed__c=true and RecordIsDeleted__c=true]); 
        
      delete ctcts;
      System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_CONTACT ]); 
      System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_CONTACT and Completed__c=true and RecordIsDeleted__c=true]); 
       
      delete accts;
      System.assertEquals(2,[Select count() from Work_Queue__c where Object__c=:ObjectHelper.OBJECT_ACCOUNT and Completed__c=true and RecordIsDeleted__c=true]); 

   } // testActivityOpps

   
   public static Map<Id,Account> getAcctMap() {
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, OwnerId, CSOrgId__c, UseClientSpace__c, SendToClientSpace__c
                                                           ,SignificantContact__c 
                                                       from Account]);
      return acctMap;
   } // getAcctMap
   
   public static Map<Id,Contact> getCtctMap() {
      Map<Id,Contact> ctctMap = new Map<Id,Contact>([Select Id, Name, AccountId, OwnerId, CSContactId__c, UseClientSpace__c from Contact]);
      return ctctMap;
   } // getCtctMap
   
   public static Map<Id,Task> getTskMap() {
      Map<Id,Task> tskMap = new Map<Id,Task>([Select Id, Subject, WhoId, WhatId, CSContactID__c from Task]);
      return tskMap;
   } // getTskMap

 
   static testMethod void testSurveyResponse() {
      User csUser = getTestCSUser();
      User nonCsUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and CSUserId__c = null limit 1];
      
      Account acct1 = new Account(Name='Account1', OwnerId=csUser.Id, SendToClientSpace__c=true,UseClientSpace__c=true);
      Account acct2 = new Account(Name='Account2', OwnerId=nonCsUser.Id, SendToClientSpace__c=true);
      Account acct3 = new Account(Name='Account3', OwnerId=csUser.Id, CSOrgID__c='123', SendToClientSpace__c=true,UseClientSpace__c=true);
      Account acct4 = new Account(Name='Account4', OwnerId=csUser.Id, SendToClientSpace__c=true,UseClientSpace__c=true);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      System.assertEquals(3,[Select count() from Account where UseClientSpace__c=true]);
      
      Map<Id,Account> acctMap = getAcctMap();
      Contact ctct1 = new Contact(AccountId=acct1.Id, OwnerId=acct1.OwnerId, LastName='Ctct1', CSContactId__c='234', Sales_Contact__c=true);
      Contact ctct2 = new Contact(AccountId=acct2.Id, OwnerId=acct2.OwnerId, LastName='Ctct2', CSContactId__c='235', Sales_Contact__c=true);
      Contact ctct3 = new Contact(AccountId=acct3.Id, OwnerId=acct3.OwnerId, LastName='Ctct3', CSContactId__c='236', Sales_Contact__c=true);
      Contact ctct4 = new Contact(AccountId=acct4.Id, OwnerId=acct4.OwnerId, LastName='Ctct4', CSContactId__c='237', Sales_Contact__c=true);
      Contact[] ctcts = new Contact[]{ctct1,ctct2,ctct3,ctct4};
      insert ctcts;

      

   } // testSurveyResponse
    
   static testMethod void testReferenceRecs() {
      User csUser = getTestCSUser();
      User nonCsUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and CSUserId__c = null limit 1];
      
      Account acct1 = new Account(Name='Account1', OwnerId=csUser.Id, SendToClientSpace__c=true,UseClientSpace__c=true);
      Account acct2 = new Account(Name='Account2', OwnerId=nonCsUser.Id, SendToClientSpace__c=true);
      Account acct3 = new Account(Name='Account3', OwnerId=csUser.Id, CSOrgID__c='123', SendToClientSpace__c=true,UseClientSpace__c=true);
      Account acct4 = new Account(Name='Account4', OwnerId=csUser.Id, SendToClientSpace__c=true,UseClientSpace__c=true);
      Account acct5 = new Account(Name='Account5', OwnerId=csUser.Id, SendToClientSpace__c=true,UseClientSpace__c=true);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
      insert accts;
      //System.assertEquals(3,[Select count() from Account where UseClientSpace__c=true]);
      
      Opportunity opp5 = new Opportunity(Name='Opp5', AccountId=acct5.Id, CloseDate=Date.today().addDays(10), StageName='Pending');
      insert opp5;
       
      Reference_PEO_Medical_UW__c refPeoMed1 = new Reference_PEO_Medical_UW__c(Prospect_Client_Name__c=acct1.Id, OwnerId=csUser.Id);
      Reference_PEO_Medical_UW__c refPeoMed2 = new Reference_PEO_Medical_UW__c(Prospect_Client_Name__c=acct2.Id, OwnerId=csUser.Id);
      Reference_PEO_Medical_UW__c refPeoMed3 = new Reference_PEO_Medical_UW__c(Prospect_Client_Name__c=acct3.Id, OwnerId=csUser.Id);
      Reference_PEO_Medical_UW__c refPeoMed4 = new Reference_PEO_Medical_UW__c(Prospect_Client_Name__c=acct4.Id, OwnerId=csUser.Id);
      Reference_PEO_Medical_UW__c refPeoMed5 = new Reference_PEO_Medical_UW__c(Opportunity__c=opp5.Id, OwnerId=csUser.Id);
      Reference_PEO_Medical_UW__c[] refPeoMeds = new Reference_PEO_Medical_UW__c[]{refPeoMed1,refPeoMed2,refPeoMed3,refPeoMed4,refPeoMed5};
      insert refPeoMeds;
       
      System.assertEquals(5,[Select count() from Work_Queue__c where Object__c='Reference_PEO_Medical_UW__c']);
      System.assertEquals(4,[Select count() from Account where UseClientSpace__c=true]);
 
      Reference_PEO__c refPeo1 = new Reference_PEO__c(Account_Lookup__c=acct1.Id, OwnerId=csUser.Id);
      Reference_PEO__c refPeo2 = new Reference_PEO__c(Account_Lookup__c=acct2.Id, OwnerId=csUser.Id);
      Reference_PEO__c refPeo3 = new Reference_PEO__c(Account_Lookup__c=acct3.Id, OwnerId=csUser.Id);
      Reference_PEO__c refPeo4 = new Reference_PEO__c(Account_Lookup__c=acct4.Id, OwnerId=csUser.Id);
      Reference_PEO__c[] refPeos = new Reference_PEO__c[]{refPeo1,refPeo2,refPeo3,refPeo4};
      insert refPeos;
       
      System.assertEquals(3,[Select count() from Work_Queue__c where Object__c='Reference_PEO__c']);
      
   } // testReferenceRecs
    
   static testMethod void testCsOwnerIdChange() {
       User[] csUsers = [Select Id, Name, HR_Person_Id__c,CSUserId__c from User where CSUserId__c != null and HR_Person_Id__c != null and IsActive=true and UserRoleId != null and Sales_Division__c !='NSC' limit 10];
       Account acct1 = new Account(Name='Account1', OwnerId=csUsers[0].Id, CSOwnerId__c=csUsers[0].CSUserId__c);
       Account acct2 = new Account(Name='Account2', OwnerId=csUsers[1].Id, Premier_PBS_Account_Owner__c=csUsers[2].Id, CSOwnerId__c=csUsers[2].Id);
       ZipCheckOwner.SKIP_TRIGGERS=true;
       Account[] accts = new Account[]{acct1,acct2};
       insert accts;
       
       Map<Id,Account> oldMap = new Map<Id,Account>();
       oldMap.put(acct1.Id,acct1);
       oldMap.put(acct2.Id,acct2);
       
       System.debug('csUsers[0]='+csUsers[0].Id+', '+csUsers[0].Name+', '+csUsers[0].CSUserId__c);
       System.debug('csUsers[1]='+csUsers[1].Id+', '+csUsers[1].Name+', '+csUsers[1].CSUserId__c);
       System.debug('csUsers[2]='+csUsers[2].Id+', '+csUsers[2].Name+', '+csUsers[2].CSUserId__c);
       System.debug('csUsers[3]='+csUsers[3].Id+', '+csUsers[3].Name+', '+csUsers[3].CSUserId__c);
       System.debug('csUsers[4]='+csUsers[4].Id+', '+csUsers[4].Name+', '+csUsers[4].CSUserId__c);
       
       Account newAcct1 = new Account(Id=acct1.Id, Name=acct1.Name, OwnerId=acct1.OwnerId, CSOwnerId__c=csUsers[3].CSUserId__c);
       Account newAcct2 = new Account(Id=acct2.Id, Name=acct2.Name, OwnerId=acct2.OwnerId, Premier_PBS_Account_Owner__c=acct2.Premier_PBS_Account_Owner__c, CSOwnerId__c=csUsers[4].CSUserId__c);
       accts = new Account[]{newAcct1,newAcct2};
       
       Set<String> csIds = new Set<String>();
       csIds.add(csUsers[0].CSUserId__c);
       csIds.add(csUsers[1].CSUserId__c);
       csIds.add(csUsers[2].CSUserId__c);
       csIds.add(csUsers[3].CSUserId__c);
       csIds.add(csUsers[4].CSUserId__c);
       Set<Id> ownerIds = new Set<Id>();
       ownerIds.add(csUsers[0].Id);
       ownerIds.add(csUsers[1].Id);
       ownerIds.add(csUsers[2].Id);
       ownerIds.add(csUsers[3].Id);
       ownerIds.add(csUsers[4].Id);
       
       ClientSpaceHelper.checkCSOwnerChanged(accts, oldMap,csIds,ownerIds);
       System.assertEquals(csUsers[3].Id, newAcct1.OwnerId);
       System.assertEquals(csUsers[1].Id, newAcct2.OwnerId);
       System.assertEquals(csUsers[4].Id, newAcct2.Premier_PBS_Account_Owner__c);
   } // testCsOwnerIdChange
    
   static testMethod void testUpdatesFromCS() {
      User runningUser = UserHelper.getRunningUser();
      UserHelperTest.setupProcessName(ClientSpaceHelper.PREFIX_CS, runningUser.Name); 
      User[] users = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP limit 3];
      
      Account acct1 = new Account(Name='Test Account1');
      Account acct2 = new Account(Name='Test Account2');
      Account acct3 = new Account(Name='Test Account3');
      Account acct4 = new Account(Name='Test Account4');
      Account acct5 = new Account(Name='Test Account5', OasisPEOAccountOwner__c=users[0].Id);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
       
      PricebookEntry[] entries = ProductMethodsTest.getEntries(new String[]{'PEO OASIS 1','PEO OASIS 2','ANOTHER PROD'}, UserHelper.SO_PEO, null); 
      PricebookEntry peo1 = null;
      PricebookEntry peo2 = null;
      PricebookEntry otherProd = null;
      for (PricebookEntry entry : entries) {
         if (entry.Product2.Name == 'PEO OASIS 1') {
            peo1 = entry;
         } else if (entry.Product2.Name == 'PEO OASIS 2') {
            peo2 = entry;
         } else if (entry.Product2.Name == 'ANOTHER PROD') {
            otherProd = entry;
         }
      }
      System.AssertNotEquals(null,peo1);
      System.AssertNotEquals(null,peo2);
      System.AssertNotEquals(null,otherProd);
      
      Product2 updatePeo1 = new Product2(Id=peo1.Product2Id, ClientSpaceProduct__c=true);
      Product2 updatePeo2 = new Product2(Id=peo2.Product2Id, ClientSpaceProduct__c=true);
      Product2[] updateProds = new Product2[]{updatePeo1,updatePeo2};
      update updateProds;
       
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo oppRtInfo = byNameMap.get(OPP_RT);
      System.assertNotEquals(null,oppRtInfo);
      Id oppRtId = oppRtInfo.getRecordTypeId();

      Opportunity opp1 = new Opportunity(AccountId=acct1.Id, RecordTypeId=oppRtId, Name='Opp1',CloseDate=Date.today().addDays(14), StageName='Pending');
      Opportunity opp2 = new Opportunity(AccountId=acct2.Id, RecordTypeId=oppRtId, Name='Opp2',CloseDate=Date.today().addDays(14), StageName='Pending');
      Opportunity opp3 = new Opportunity(AccountId=acct3.Id, RecordTypeId=oppRtId, Name='Opp3',CloseDate=Date.today().addDays(14), StageName='Pending');
      Opportunity opp4 = new Opportunity(AccountId=acct4.Id, RecordTypeId=oppRtId, Name='Opp4',CloseDate=Date.today().addDays(14), StageName='Pending');
      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4};
      insert opps;
          
      OpportunityLineItem oli1 = new OpportunityLineItem(OpportunityId=opp1.Id, PricebookEntryId=peo1.Id, Quantity=1,TotalPrice=5);
      OpportunityLineItem oli2 = new OpportunityLineItem(OpportunityId=opp2.Id, PricebookEntryId=peo2.Id, Quantity=1,TotalPrice=5);
      OpportunityLineItem oli3 = new OpportunityLineItem(OpportunityId=opp3.Id, PricebookEntryId=otherProd.Id, Quantity=1,TotalPrice=5);
      OpportunityLineItem oli4 = new OpportunityLineItem(OpportunityId=opp4.Id, PricebookEntryId=peo1.Id, Quantity=1,TotalPrice=5);
      OpportunityLineItem[] olis = new OpportunityLineItem[]{oli1,oli2,oli3,oli4};
      insert olis;
       
      Asset asst5 = new Asset(Name='Test Asset5', AccountId=acct5.Id, Product2Id=peo1.Product2Id);
      insert asst5;
       
      // look for statuses
      ClientSpaceMapping__mdt statusPros = null;
      ClientSpaceMapping__mdt statusClient = null;
      ClientSpaceMapping__mdt statusNotSold = null;
      ClientSpaceMapping__mdt statusLostClient = null;
      for (ClientSpaceMapping__mdt csm : [Select Label, MasterLabel, AcctType__c, OpptyStatus__c, OpptyLost__c from ClientSpaceMapping__mdt]) {
          if (csm.OpptyLost__c) {
          //if (csm.OpptyStatus__c == 'Not Sold') {
              statusNotSold = csm;
          } else if (statusPros == null && csm.AcctType__c == 'Oasis Prospect') {
              statusPros = csm;
          } else if (statusClient == null && csm.AcctType__c == 'Oasis Client') {
              statusClient = csm;
          } else if (statusLostClient == null && csm.AcctType__c == Label.AccountTypeLost) {
              statusLostClient = csm;
          }
      } // for (ClientSpaceMapping__mdt csm
      // we should find all of these 
      System.assertNotEquals(null,statusNotSold);
      System.assertNotEquals(null,statusPros);
      System.assertNotEquals(null,statusClient);
      System.assertNotEquals(null,statusLostClient);

      acct1.CSCMContractStatus__c = statusPros.Label;
      acct1.Employees__c = 10;
      acct1.First_Run_Date__c = Date.today().addDays(2);
      //acct1.OasisRevenue__c = 10;
       
      acct2.CSCMContractStatus__c = statusClient.Label;
      acct2.Employees__c = 12;
      acct2.First_Run_Date__c = Date.today().addDays(3);
      //acct2.OasisRevenue__c = 12;

      // the opportunity has an unidentified product so will not update the revenue
      acct3.CSCMContractStatus__c = statusPros.Label;
      acct3.Employees__c = 14;
      acct3.First_Run_Date__c = Date.today().addDays(4);
      //acct3.OasisRevenue__c = 14;
      // a not sold status
      acct4.CSCMContractStatus__c = statusNotSold.Label;
      acct4.Employees__c = 16;
      acct4.First_Run_Date__c = Date.today().addDays(5);
      //acct4.OasisRevenue__c = 16;
      acct4.CSCMKillReason__c = 'ItDidNotSurvive';
                                                     
      acct5.CSCMContractStatus__c = statusLostClient.Label;
      acct5.CSCMStatusDate__c = Date.today().addDays(-1);
      acct5.Employees__c = 18;
      acct5.First_Run_Date__c = Date.today().addDays(4);
      //acct5.OasisRevenue__c = 18;

      Test.startTest();
      ZipCheckOwner.SKIP_TRIGGERS=false;
      update accts;
      Test.stopTest();
       
      Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, AccountId, RecordType.Name, CloseDate, StageName, Employees_Paid_Per_Payroll__c, Reason_Not_Sold__c, Amount
                                                           ,(Select Id, Name, Product2Id, TotalPrice
                                                                   ,Product2.Name, Product2.ProductCode, Product2.CreateAssetWhenSold__c, Product2.Sales_Org__c
                                                               From OpportunityLineItems)
                                                            From Opportunity]);
      System.debug('oppMap:'+oppMap);
       Opportunity checkOpp1 = oppMap.get(opp1.Id);
      //System.assertEquals(acct1.First_Run_Date__c, checkOpp1.CloseDate);
      System.assertEquals(statusPros.OpptyStatus__c, checkOpp1.StageName);
      System.assertEquals(acct1.Employees__c, checkOpp1.Employees_Paid_Per_Payroll__c);
      //System.assertEquals(acct1.OasisRevenue__c, checkOpp1.Amount);

      Opportunity checkOpp2 = oppMap.get(opp2.Id);
      //System.assertEquals(acct2.First_Run_Date__c, checkOpp2.CloseDate);
      System.assertEquals(statusClient.OpptyStatus__c, checkOpp2.StageName);
      System.assertEquals(acct2.Employees__c, checkOpp2.Employees_Paid_Per_Payroll__c);
      //System.assertEquals(acct2.OasisRevenue__c, checkOpp2.Amount);

      Opportunity checkOpp3 = oppMap.get(opp3.Id);
      //System.assertEquals(acct3.First_Run_Date__c, checkOpp3.CloseDate);
      System.assertEquals(statusPros.OpptyStatus__c, checkOpp3.StageName);
      System.assertEquals(acct3.Employees__c, checkOpp3.Employees_Paid_Per_Payroll__c);
      System.assertEquals(5, checkOpp3.Amount);

      Opportunity checkOpp4 = oppMap.get(opp4.Id);
      //System.assertEquals(acct4.First_Run_Date__c, checkOpp4.CloseDate);
      System.assertEquals(statusNotSold.OpptyStatus__c, checkOpp4.StageName);
      System.assertEquals(acct4.Employees__c, checkOpp4.Employees_Paid_Per_Payroll__c);
      //System.assertEquals('ItDidNotSurvive', opp4.Reason_Not_Sold__c);
       
      Asset checkAsset5 = [Select id, Name, AccountId, Plan_Cancel_Date__c, Product_End_Date__c, ProductCode, Plan_Lost_Reason__c from Asset where Id=:asst5.Id];
      System.assertEquals(acct5.CSCMStatusDate__c, checkAsset5.Plan_Cancel_Date__c);
      System.assertEquals(acct5.CSCMStatusDate__c, checkAsset5.Product_End_Date__c);
       
      Account checkAcct5 = [Select Id, Name, OasisPEOHoldOut__c, OasisPEOHoldOutExpiration__c, OasisPEOHoldOutReason__c
                                  ,Type, Lost_Date__c, Reason_Lost__c
                              From Account where Id=:acct5.Id];
   //   System.assertEquals(true, checkAcct5.OasisPEOHoldOut__c);
   //   System.assertEquals(null, checkAcct5.OasisPEOHoldOutExpiration__c);
    //  System.assertEquals(ClientSpaceHelper.HoldOut_LostClient, checkAcct5.OasisPEOHoldOutReason__c);
    //  System.assertEquals(Label.AccountTypeProspect, checkAcct5.Type);
    //  System.assertEquals(acct5.CSCMStatusDate__c, checkAcct5.Lost_Date__c);
   //   System.assertEquals(statusLostClient.Label, checkAcct5.Reason_Lost__c);

   } // testUpdatesFromCS

    static testMethod void testClearSalesParent() {
      User nonCsUser = [Select Id, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and CSUserId__c = null limit 1];
      Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        
      Account acct = new Account(Name='Account1', OwnerId=nonCsUser.Id, recordtypeId = acctCorert.getRecordTypeId());
      insert acct;
      Account childAcct = new Account(Name='Account2', OwnerId=nonCsUser.Id, SalesParent__c = acct.Id, recordtypeId = acctCorert.getRecordTypeId());
      insert childAcct;
       
      PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c = acct.Id);
      insert checklist;
      PEO_Onboarding_Checklist__c childChecklist = new PEO_Onboarding_Checklist__c(Prospect_Client__c = childAcct.Id, Parent_PEO_Checklist__c = checklist.Id);
      insert childChecklist;
      
      childAcct = [SELECT Id, Name, SalesParent__c FROM Account WHERE Id = :childAcct.id];
      childAcct.SalesParent__c = null;
      TriggerMethods.clearVariables();
      update childAcct;
        
      childChecklist = [SELECT Id, Name, Prospect_Client__c, Parent_PEO_Checklist__c FROM PEO_Onboarding_Checklist__c WHERE Id = :childChecklist.id];
      System.assertEquals(null, childChecklist.Parent_PEO_Checklist__c);
        
      childAcct.SalesParent__c = acct.Id;
      TriggerMethods.clearVariables();
      update childAcct;  
        
      childChecklist = [SELECT Id, Name, Prospect_Client__c, Parent_PEO_Checklist__c FROM PEO_Onboarding_Checklist__c WHERE Id = :childChecklist.id];
      System.assertEquals(checklist.Id, childChecklist.Parent_PEO_Checklist__c);
    } //testClearSalesParent
    
    //  test method for (method :createWorkQueuesForBrokenCommissions)
        static testMethod void testInsertUpdateBrokerCommissions(){
        Account acct1 = new Account(Name='Test 2', Bis_Id__c=122, AssignedToOutboundNSR__c=true,CSCMContractStatus__c = 'Approved');
        insert acct1;
        Contact con = new Contact(AccountId=acct1.Id,LastName='Test1',Hold_Out_Reason__c=LeadCompanyMethods.HOLD_OUT_DEFAULT, NSSStatus__c=LeadCompanyMethods.STATUS_DEFAULT);
        insert con;
        Referral_Account__c refAcc = new Referral_Account__c(Name='TestRA', Account__c = acct1.id);
        insert refAcc;
        Referral_Contact__c refCon = new Referral_Contact__c(Name='TestRC', Contact__c = con.id);
        insert refCon;
        List<Broker_Commission__c> lstBC = new List<Broker_Commission__c>(); 
        Broker_Commission__c bc1 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id, Referral_Contact__c = refCon.Id);
        Broker_Commission__c bc2 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id, Referral_Contact__c = refCon.Id);
        Broker_Commission__c bc3 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id, Referral_Contact__c = refCon.Id);
        Broker_Commission__c bc4 = new Broker_Commission__c( Status__c='Active', Referral_Account__c = refAcc.id, Referral_Contact__c = refCon.Id);
        lstBC.add(bc1);
        lstBC.add(bc2);
        lstBC.add(bc3);
        lstBC.add(bc4);
        insert lstBC;
    
     }
     static testMethod void testDocSend(){
        Account acct = new Account(Name='test',CSCMContractStatus__c='Prospect');
        insert acct;
        PEO_Onboarding_Checklist__c checklist = new PEO_Onboarding_Checklist__c(Name='test',Prospect_Client__c = acct.Id);
        insert checklist;
        PEO_Onboarding_Document__c doc = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=checklist.Id,Routing_Name__c='Census');
        insert doc;
        ContentVersion cdv = new ContentVersion(versionData = Blob.valueof('Test String!'), title='Test1', PathOnClient='c:\Test', description='Test');
        insert cdv;
        ContentVersion cv = [Select ContentDocumentID from ContentVersion where id = :cdv.id];
        contentDocumentLink cdl = new contentDocumentLink(ContentDocumentID = cv.ContentDocumentID, LinkedEntityID=doc.id, ShareType='V', Visibility='AllUsers' );
        insert cdl;
        
        Account acct2 = new Account(Name='testAccount2',CSCMContractStatus__c='Prospect');
        insert acct2;
        PEO_Onboarding_Checklist__c checklist2 = new PEO_Onboarding_Checklist__c(Name='testAccount2',Prospect_Client__c = acct2.Id,Sales_Rep__c = UserInfo.getUserId() ,Medical_Underwriting_Path_Type__c = 'Quick Quote - Medical',Workers_Comp_Underwriting_Path_Type__c = 'Quick Quote - Workers Comp');
        insert checklist2;
        PEO_Onboarding_Document__c doc2 = new PEO_Onboarding_Document__c(PEO_Onboarding_Checklist__c=checklist2.Id,Routing_Name__c='Census');
        insert doc2;
        ContentVersion cdv2 = new ContentVersion(versionData = Blob.valueof('Test String!'), title='Test2', PathOnClient='c:\Test2', description='Test2');
        insert cdv2;
        ContentVersion cv2 = [Select ContentDocumentID from ContentVersion where id = :cdv2.id];
        contentDocumentLink cdl2 = new contentDocumentLink(ContentDocumentID = cv2.ContentDocumentID, LinkedEntityID=doc2.id, ShareType='V', Visibility='AllUsers' );
        insert cdl2;
        PEO_Onboarding_Document_Map__c HSFDM = new PEO_Onboarding_Document_Map__c(name='HSF Census', Document_Category__c='Medical', Clientspace_Table__c = 'gen_BenefitsBatch', Clientspace_Field__c='fuGAIHealthCensus');
        Insert HSFDM;
        
        test.startTest();
        TriggerMethods.clearVariables();
        doc.Status__c = 'Approved';
        update doc;
        doc2.Status__c = 'Approved';
        update doc2;
        checklist.Submit_Docs_to_Clientspace__c = 'All';
        checklist2.Submit_Docs_to_Clientspace__c = 'All';
        update checklist;
        update checklist2;
        ContentVersion cdv3 = new ContentVersion(versionData = Blob.valueof('Test String!'), title='Test3', PathOnClient='c:\Test3', description='Test3');
        insert cdv3;
        ContentVersion cv3 = [Select ContentDocumentID from ContentVersion where id = :cdv3.id];
        contentDocumentLink cdl3 = new contentDocumentLink(ContentDocumentID = cv3.ContentDocumentID, LinkedEntityID=doc2.id, ShareType='V', Visibility='AllUsers' );
        insert cdl3;
        doc2.Docs_Sent_to_Clientspace__c = cdl2.Id+',';
        doc2.Status__c = 'Approved';
        update doc2;
        checklist2.Submit_Docs_to_Clientspace__c = 'All';
        update checklist2;
        test.stopTest();
         PEO_Onboarding_Checklist__c uChecklist = [SELECT Id,Submit_Docs_to_Clientspace__c,Med_pre_qual_submission__c FROM PEO_Onboarding_Checklist__c WHERE Id=:checkList.Id LIMIT 1];
         PEO_Onboarding_Checklist__c uChecklist2 = [SELECT Id,Submit_Docs_to_Clientspace__c,Med_pre_qual_submission__c,Sync_Locations_to_CS__c FROM PEO_Onboarding_Checklist__c WHERE Id=:checklist2.Id LIMIT 1];
         Contact ctct1 = new Contact(AccountId=acct2.Id, OwnerId=acct2.OwnerId, LastName='Ctct1', CSContactId__c='234', Sales_Contact__c=true);
             
        //system.assertEquals(null,uChecklist.Submit_Docs_to_Clientspace__c);
        PEO_Onboarding_Document__c uDoc = [SELECT Id,Status__c FROM PEO_Onboarding_Document__c WHERE Id=:doc.Id LIMIT 1];
        PEO_Onboarding_Document__c uDoc2 = [SELECT Id,Status__c FROM PEO_Onboarding_Document__c WHERE Id=:doc2.Id LIMIT 1];
        //system.assertEquals('Submitted to Clientspace',uDoc.Status__c);
         Id oppRtId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(OPP_RT).getRecordTypeId();	
         Opportunity opp1 = new Opportunity(AccountId=acct2.Id, RecordTypeId=oppRtId, Name='Opp1',CloseDate=Date.today().addDays(14), StageName='Pending');	
         insert opp1;
         try{
         ClientSpaceHelper.addOppWorkQueue(acct2, ctct1,opp1.Id, null);
         }catch(exception ex){
             
         }
            


    }
    
} // class ClientSpaceHelperTest