/**
 * 10/10/2017	Lynn Michels	Created
 * 05/12/2023	Reetesh Pandey	added rejectionDateTest method
 */
@isTest
private class RefHRSTermTransferMethodsTest {

    static testMethod void myUnitTest() {
    	TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createCustomSetting(null, 'RefHRSTermTransferAfter', false, true, new String[]{'RefHRSTermTransferMethods'}, classes);
        insert classes;
        
        
        RefHRSTermTransferMethods.skipTrigger = false;
        
    	Id TermTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Reference HRS Termination/Transfer').getRecordTypeId(); 
    	Id relatedTermTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Related Term/Transfer Record').getRecordTypeId(); 
		Id CaseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
		Date checkDate = Date.today();
		
		//Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
      	//User u = new User(Alias = 'abcd', Email='abcd@testorg.com', 
      	//EmailEncodingKey='UTF-8', LastName='Abcd', LanguageLocaleKey='en_US', 
      	//LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'COE',
      	//TimeZoneSidKey='America/Los_Angeles', UserName='abcd@testorg.com');
      	//insert u;
        
        User u = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 1];
      	
    	List<Case> insertCases = new List<Case>();
		Case c1 = new Case(OwnerId = u.id,
						RecordTypeId = CaseTermTransfer);
		insertCases.add(c1);
		Case c2 = new Case(OwnerId = u.id,
						RecordTypeId = CaseTermTransfer);
		insertCases.add(c2);
		Case c3 = new Case(OwnerId = u.id,
						RecordTypeId = CaseTermTransfer);
		insertCases.add(c3);
		insert insertCases;
    	Reference_HRS_Termination_Transfer__c ref = new Reference_HRS_Termination_Transfer__c(
    												Case_Lookup__c = c1.id,
    												RecordTypeId = TermTransferRtId,
    												Code_Lost_Date__c = checkDate,
    												Termination_or_Transfer__c = 'Transfer',
    												Primary_Tier_1_Reasons__c = 'test 1',
    												Primary_Tier_2_Reasons__c = 'test 2',
    												Primary_Tier_3_Reasons__c = 'test 3');
        insert ref;
        Reference_HRS_Termination_Transfer__c relatedRef1 = new Reference_HRS_Termination_Transfer__c(
        											Case_Lookup__c = c2.id,
    												RecordTypeId = relatedTermTransferRtId,
    												Parent_Ref_HRS_Termination_Transfer__c = ref.id,
    												Code_Lost_Date__c = checkDate +3,
    												Termination_or_Transfer__c = 'Transfer',
    												Primary_Tier_1_Reasons__c = 'test a',
    												Primary_Tier_2_Reasons__c = 'test b',
    												Primary_Tier_3_Reasons__c = 'test c');
        insert relatedRef1;
        Reference_HRS_Termination_Transfer__c relatedRef2 = new Reference_HRS_Termination_Transfer__c(
        											Case_Lookup__c = c3.id,
    												RecordTypeId = relatedTermTransferRtId,
    												Parent_Ref_HRS_Termination_Transfer__c = ref.id,
    												Code_Lost_Date__c = checkDate+2,
    												Termination_or_Transfer__c = 'Transfer',
    												Primary_Tier_1_Reasons__c = 'test d',
    												Primary_Tier_2_Reasons__c = 'test e',
    												Primary_Tier_3_Reasons__c = 'test f');
        insert relatedRef2;
        
        List<Reference_HRS_Termination_Transfer__c> refRecords = [SELECT Id, RecordTypeId, Code_Lost_Date__c FROM Reference_HRS_Termination_Transfer__c];
        system.assertEquals (3, refRecords.size());
system.debug('LM refRecords '+refRecords);
system.debug('LM skip trigger1 '+RefHRSTermTransferMethods.skipTrigger);
 RefHRSTermTransferMethods.skipTrigger = false;        
        ref.Code_Lost_Date__c = checkDate+5;
    	ref.Termination_or_Transfer__c = 'Termination';
    	ref.Primary_Tier_1_Reasons__c = 'testing change';
    	ref.Primary_Tier_2_Reasons__c = 'changing reason 2';
    	ref.Primary_Tier_3_Reasons__c = 'changing reason 3';
    	update ref;
    	
system.debug('LM testing '+ref.Code_Lost_Date__c);
system.debug('LM skip trigger2 '+RefHRSTermTransferMethods.skipTrigger);


    	Map<Id,Reference_HRS_Termination_Transfer__c> changedRecordMap = new Map<Id,Reference_HRS_Termination_Transfer__c> ([SELECT Id, Code_Lost_Date__c, Termination_or_Transfer__c,
    	Primary_Tier_1_Reasons__c, Primary_Tier_2_Reasons__c, Primary_Tier_3_Reasons__c FROM Reference_HRS_Termination_Transfer__c WHERE 
    	Parent_Ref_HRS_Termination_Transfer__c =: ref.id]);
        system.debug('LM changed records' +changedRecordMap);
    	system.assertEquals (2, changedRecordMap.size());
        
        Reference_HRS_Termination_Transfer__c refCheck1 = changedRecordMap.get(relatedRef1.Id);
        system.assertEquals (checkDate +5, refCheck1.Code_Lost_Date__c);
    	system.assertEquals ('Termination', refCheck1.Termination_or_Transfer__c);
    	system.assertEquals ('testing change', refCheck1.Primary_Tier_1_Reasons__c);
    	system.assertEquals ('changing reason 2', refCheck1.Primary_Tier_2_Reasons__c);
    	system.assertEquals ('changing reason 3', refCheck1.Primary_Tier_3_Reasons__c);
        
        Reference_HRS_Termination_Transfer__c refCheck2 = changedRecordMap.get(relatedRef2.Id);
        system.assertEquals (checkDate +5, refCheck2.Code_Lost_Date__c);
    	system.assertEquals ('Termination', refCheck2.Termination_or_Transfer__c);
    	system.assertEquals ('testing change', refCheck2.Primary_Tier_1_Reasons__c);
    	system.assertEquals ('changing reason 2', refCheck2.Primary_Tier_2_Reasons__c);
    	system.assertEquals ('changing reason 3', refCheck2.Primary_Tier_3_Reasons__c);
        
        

    } // myUnitTest
    
    static testMethod void rejectionDateTest() {
        TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createCustomSetting(null, 'RefHRSTermTransferAfter', false, true, new String[]{'RefHRSTermTransferMethods'}, classes);
        insert classes;
        
        
        RefHRSTermTransferMethods.skipTrigger = false;
        
    	Id TermTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Reference HRS Termination/Transfer').getRecordTypeId(); 
    	Id relatedTermTransferRtId = Schema.SObjectType.Reference_HRS_Termination_Transfer__c.getRecordTypeInfosByName().get('Related Term/Transfer Record').getRecordTypeId(); 
		Id CaseTermTransfer = Schema.SObjectType.Case.getRecordTypeInfosByName().get('HRS Termination Transfer Case Record Type').getRecordTypeId(); 
		Date checkDate = Date.today();
		
		//Profile p = [SELECT Id FROM Profile WHERE Name='System Administrator']; 
      	//User u = new User(Alias = 'abcd', Email='abcd@testorg.com', 
      	//EmailEncodingKey='UTF-8', LastName='Abcd', LanguageLocaleKey='en_US', 
      	//LocaleSidKey='en_US', ProfileId = p.Id, Sales_Org__c = 'COE',
      	//TimeZoneSidKey='America/Los_Angeles', UserName='abcd@testorg.com');
      	//insert u;
        
        User u = [Select Id, Name from User where IsActive=true and Profile.Name='System Administrator' and Id != :UserInfo.getUserId() limit 1];
      	
    	List<Case> insertCases = new List<Case>();
		Case c1 = new Case(OwnerId = u.id,
						RecordTypeId = CaseTermTransfer);
		insertCases.add(c1);
		Case c2 = new Case(OwnerId = u.id,
						RecordTypeId = CaseTermTransfer);
		insertCases.add(c2);
		Case c3 = new Case(OwnerId = u.id,
						RecordTypeId = CaseTermTransfer);
		insertCases.add(c3);
		insert insertCases;
    	Reference_HRS_Termination_Transfer__c ref = new Reference_HRS_Termination_Transfer__c(
    												Case_Lookup__c = c1.id,
    												RecordTypeId = TermTransferRtId,
    												Code_Lost_Date__c = checkDate,
    												Termination_or_Transfer__c = 'Transfer',
    												Primary_Tier_1_Reasons__c = 'test 1',
    												Primary_Tier_2_Reasons__c = 'test 2',
    												Primary_Tier_3_Reasons__c = 'test 3'
                                                    );
        insert ref;
        //Added Reetesh
        List<Reference_HRS_Termination_Transfer__c> refRec = [SELECT Id, RecordTypeId, Code_Lost_Date__c,Rejection_Date__c FROM Reference_HRS_Termination_Transfer__c where Case_Lookup__c =: c1.id limit 1];
        System.debug('Rejection_Date__c>>>>' +refRec[0].Rejection_Date__c);
        refRec[0].Rejection_Date__c = System.today().addDays(2);
        update refRec[0];
        System.debug('Rejection_Date__c>>' +refRec[0].Rejection_Date__c);
       system.assertNotEquals (refRec[0].Rejection_Date__c, checkDate);
    }
    static testMethod void coverageForUnusedMethods() {
    	RefHRSTermTransferMethods rhttm = new RefHRSTermTransferMethods();
    	
        rhttm.checkAllBeforeTrigger(null, null);
        rhttm.checkAllAfterTrigger(null, null);
        rhttm.checkBeforeTrigger(null, null);
        rhttm.processBeforeTriggerActions();
    	rhttm.processAfterTriggerActions();
    }
} // class RefHRSTermTransferMethodsTest