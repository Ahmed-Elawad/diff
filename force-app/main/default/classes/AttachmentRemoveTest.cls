/**
 * Tests that if there is a custom setting record in Record Type for the record type and case origin,
 * the attachments will be deleted on cases created by email-to-case
 * 02/09/2018 Lynn Michels Created
 * 03/25/2024 Carrie Marciano	commenting out code to remove old MPSC tech debt
 */
@isTest
private class AttachmentRemoveTest {
	
	@testSetup
	static void setupData() {
 		TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      	TriggerSetup__c trigSetup = TriggerMethodsTest.createCustomSetting(null, 'AttachmentTrigger', false, true, new String[]{'AttachmentRemove'}, setupClasses);
     	insert setupClasses;
      
     	List<RecordType__c> recordTypeSettings = new List<RecordType__c>{
     			/*new RecordType__c(Name = 'Service Support MPSC Case',
	      			Case_Origin__c = 'Email-to-Case',
	      			RecordTypeName__c ='Service Support MPSC Case',
	      			ObjectName__c = ObjectHelper.OBJECT_CASE),
				*/	
     			new RecordType__c(Name = 'Service Support MMS Case',
	      			Case_Origin__c = 'Inbound Email',
	      			RecordTypeName__c ='Service Support MMS Case',
	      			ObjectName__c = ObjectHelper.OBJECT_CASE)};
 		insert recordTypeSettings;

	} // setupData

	/*static testMethod void oneCaseAttachmentsDeleted() {
    	
		RecordType serviceSupportMPSCType = [Select Id, Name, sobjectType from RecordType 
                                        where sObjectType = 'Case' and Name = 'Service Support MPSC Case' and IsActive = true]; 
		Case supportMPSCcase = new Case (recordtypeId = serviceSupportMPSCType.Id
                                        ,status = 'New'
                                		,Origin = 'Email-to-Case');
		insert supportMPSCcase;
       
    	
        
        EmailMessage em = new EmailMessage(ParentId = supportMPSCcase.id
        									,Subject = 'testing attachment delete'
        									,TextBody = 'testing attachment delete with Service Support MPSC Cases');
        insert em;
        Blob b = Blob.valueOf('This is a test');
        Attachment a = new Attachment(ParentId = em.id
        								,Description = 'attachment 1'
        								,Name='Test.txt'
        								,Body=b);
        insert a;
        List<Attachment> aList = [SELECT id FROM Attachment where ParentID =: em.id];
        system.assertEquals(0,aList.size());
        
    }//oneCaseAttachmentsDeleted
	*/
    
    //create case with origin that doesn't match a custom setting. Attachments should be kept.
	/*
   	static testMethod void oneCaseAttachmentsNotDeleted() {
    	
		RecordType serviceSupportMPSCType = [Select Id, Name, sobjectType from RecordType 
                                        where sObjectType = 'Case' and Name = 'Service Support MPSC Case' and IsActive = true]; 
		Case supportMPSCcase = new Case (recordtypeId = serviceSupportMPSCType.Id
                                        ,status = 'New'
                                		,Origin = 'Email');
		insert supportMPSCcase;
       
    	
        EmailMessage em = new EmailMessage(ParentId = supportMPSCcase.id
        									,Subject = 'testing attachment delete'
        									,TextBody = 'testing attachment delete with Service Support MPSC Cases');
        insert em;
        Blob b = Blob.valueOf('This is a test');
        Attachment a = new Attachment(ParentId = em.id
        								,Description = 'attachment 1'
        								,Name='Test.txt'
        								,Body=b);
        insert a;
        List<Attachment> aList = [SELECT id FROM Attachment where ParentID =: em.id];
        system.assertEquals(1,aList.size());
        
    }//oneCaseAttachmentsNotDeleted
	*/
    
    //create two cases that match a custom setting. Attachments should be deleted.
	/*
   	static testMethod void twoCaseAttachmentsDeleted() {
    	//case 1
		RecordType serviceSupportMPSCType = [Select Id, Name, sobjectType from RecordType 
                                        where sObjectType = 'Case' and Name = 'Service Support MPSC Case' and IsActive = true]; 
		Case supportMPSCcase = new Case (recordtypeId = serviceSupportMPSCType.Id
                                        ,status = 'New'
                                		,Origin = 'Email-to-Case');
		insert supportMPSCcase;
       
    	
        EmailMessage emMPSC = new EmailMessage(ParentId = supportMPSCcase.id
        									,Subject = 'testing attachment delete for MPSC'
        									,TextBody = 'testing attachment delete with Service Support MPSC Cases');
        insert emMPSC;
        //case 2
        RecordType serviceSupportMMSType = [Select Id, Name, sobjectType from RecordType 
                                        where sObjectType = 'Case' and Name = 'Service Support MMS Case' and IsActive = true]; 
		Case supportMMScase = new Case (recordtypeId = serviceSupportMMSType.Id
                                        ,status = 'New'
                                		,Origin = 'Inbound Email');
		insert supportMMScase;
       
    	
        EmailMessage emMMS = new EmailMessage(ParentId = supportMMScase.id
        									,Subject = 'testing attachment delete for MMS'
        									,TextBody = 'testing attachment delete with Service Support MMS Cases');
        insert emMMS;
        Blob b = Blob.valueOf('This is a test');
        List<Attachment> attachmentList = new List<Attachment>{ 
        	new Attachment(ParentId = emMPSC.id
        								,Description = 'attachment 1'
        								,Name='Test.txt'
        								,Body=b),
        	new Attachment(ParentId = emMMS.id
        								,Description = 'attachment 2'
        								,Name='Test2.txt'
        								,Body=b)};
        insert attachmentList;
        List<Attachment> aList = [SELECT id FROM Attachment where ParentID =: emMPSC.id OR ParentID =: emMMS.id];
        system.assertEquals(0,aList.size());
        
    }//twoCaseAttachmentsDeleted
	*/
    
        //create two cases ,one matches a custom setting and it's atachments should be deleted.
        //the other does not match a custom setting. Attachments should be not deleted.
   	static testMethod void twoCaseAttachmentsDeletedonOne() {
    	//case 1 - does not match 
		RecordType serviceSupportSTMType = [Select Id, Name, sobjectType from RecordType 
                                        where sObjectType = 'Case' and Name = 'Service Support STM Case' and IsActive = true]; 
		Case supportSTMcase = new Case (recordtypeId = serviceSupportSTMType.Id
                                        ,status = 'New'
                                		,Origin = 'Email-to-Case');
		insert supportSTMcase;
       
    	
        EmailMessage emSTM = new EmailMessage(ParentId = supportSTMcase.id
        									,Subject = 'testing attachment delete for STM'
        									,TextBody = 'testing attachment delete with Service Support STM Cases');
        insert emSTM;
        //case 2 - matches
        RecordType serviceSupportMMSType = [Select Id, Name, sobjectType from RecordType 
                                        where sObjectType = 'Case' and Name = 'Service Support MMS Case' and IsActive = true]; 
		Case supportMMScase = new Case (recordtypeId = serviceSupportMMSType.Id
                                        ,status = 'New'
                                		,Origin = 'Inbound Email');
		insert supportMMScase;
       
    	
        EmailMessage emMMS = new EmailMessage(ParentId = supportMMScase.id
        									,Subject = 'testing attachment delete for MMS'
        									,TextBody = 'testing attachment delete with Service Support MMS Cases');
        insert emMMS;
        Blob b = Blob.valueOf('This is a test');
        List<Attachment> attachmentList = new List<Attachment>{ 
        	new Attachment(ParentId = emSTM.id
        								,Description = 'attachment 1'
        								,Name='Test.txt'
        								,Body=b),
        	new Attachment(ParentId = emMMS.id
        								,Description = 'attachment 2'
        								,Name='Test2.txt'
        								,Body=b)};
        insert attachmentList;
        List<Attachment> aList = [SELECT id FROM Attachment where ParentID =: emSTM.id];
        system.assertEquals(1,aList.size());
        
        List<Attachment> aList2 = [SELECT id FROM Attachment where ParentID =: emMMS.id];
        system.assertEquals(0,aList2.size());
        
    }//twoCaseAttachmentsDeletedonOne
    
    //for code coverage
    static testMethod void testMisc() {     
            AttachmentRemove ar = new AttachmentRemove();
            ar.checkAllBeforeTrigger(null, null);
            ar.checkBeforeTrigger(null, null); 
            ar.processBeforeTriggerActions();
            ar.checkAfterTrigger(null, null);
            ar.processAfterTriggerActions(); 
                       
    }//end testMisc
}