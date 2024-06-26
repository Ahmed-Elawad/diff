/**
 * Test methods for the SendToNSRController
 *
 * History   
 * -------
 * 08/17/2016 Cindy Freeman		Created
 * 07/02/2018 Cindy Freeman		added Label for NSS Beta profile name
 *
 */
@isTest
private class SendToNSRControllerTest {

	// test Lead already being worked
    static testMethod void myTest1() {
   		User testWorkingNsr = [Select Id, Name, FirstName, LastName, isActive, Profile.Name, UserRole.Name from User
							where isActive = true and Job_Name__c = :UserHelper.JOB_NSR 
                            and (Profile.Name = :Label.RoleNSSOutboundRep OR Profile.Name = :Label.RoleNSSOutboundRepBeta) limit 1];
		Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);	
						
   		Lead leed = new Lead(Firstname = 'First'
								,Lastname = 'Last Lead1'
								,Company = 'Test Lead Company1'
								,recordtypeId = leadCorert.getRecordTypeId()
								,OwnerId = testWorkingNsr.ID
								,DataFlux_Id__c = null
                                ,LeadGroupId__c = null);
		insert leed;
		
		User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
         	Test.SetCurrentPageReference(Page.SendToNSR);
         	System.CurrentPageReference().getParameters().put('sfdcId',leed.Id);
         	SendToNSRController nsrC = new SendToNSRController();
         	
         	System.assertEquals(false, nsrC.hasError);
         	System.assertEquals(false, nsrC.showReturn);
         	System.assertEquals(true, nsrC.showCancel);
         	System.assertEquals(true, nsrC.isLead);
         	System.assertEquals('Lead: ', nsrC.objLabel);
         	System.assertEquals(true, nsrC.beingWorked);
         	System.assertEquals('This lead', nsrC.workedMsg);
         	//System.assertEquals(testWorkingNsr.Name, nsrC.workingNSR);
         	System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
 	        //System.assertEquals('This lead is already being worked by '+ workingNSR.Name,msg.getDetail() );
 	        System.assertNotEquals(null, nsrC.objToSend);
 	        Lead ld = (Lead)nsrC.objToSend;
 	        ///////System.assertEquals(testWorkingNsr.Name,String.valueOf(ld.Owner.Name)); why is Owner = null?
        } // runAs   
         	        
    } // my Test1

	// test Account and Contact already being worked
    static testMethod void myTest2() {
   		User testWorkingNsr = [Select Id, Name, FirstName, LastName, isActive, Profile.Name, UserRole.Name from User
							where isActive = true and Job_Name__c = :UserHelper.JOB_NSR 
                            and (Profile.Name = :Label.RoleNSSOutboundRep OR Profile.Name = :Label.RoleNSSOutboundRepBeta) limit 1];
							
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Prospect'
                                ,BillingPostalCode = '10000'
                                ,NumberOfEmployees = 25
                                ,AnnualRevenue = 25
                                ,AssignedToOutboundNSR__c = true
                                );
        insert acct1;
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()                                
                                ,AccountId=acct1.Id);
		insert ctct1;  
        ctct1 = [Select Id, Name, Owner.Name from Contact where Id = :ctct1.Id];
        Contact ctct2 = new Contact(Firstname = 'Second'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Sales_Contact__c = true
                                ,AccountId=acct1.Id);
        insert ctct2;	
		acct1.SignificantContact__c = ctct1.Id;
		update acct1;
		
		Prospect_Ownership__c po = new Prospect_Ownership__c(Ownership_Status__c = 'Prospecting'
								,NSR_Name__c = testWorkingNsr.Id
								,Decision_Maker__c = ctct1.Id
								,Prospect_Client__c = acct1.Id
                                ,NSS_Source__c = 'Outbound'
                                ,StartDate__c = System.today());
		insert po;
		 
		User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
         	Test.SetCurrentPageReference(Page.SendToNSR);
         	System.CurrentPageReference().getParameters().put('sfdcId',acct1.Id);
         	SendToNSRController nsrC = new SendToNSRController();
         	
         	System.assertEquals('Prospect-Client:  ', nsrC.objLabel);
         	System.assertEquals(true, nsrC.beingWorked);
         	System.assertEquals('The significant contact, '+ctct1.Name, nsrC.workedMsg);
         	//System.assertEquals(testWorkingNsr.Name, nsrC.workingNSR);
         	System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
 	        System.assertEquals('The significant contact, '+ctct1.Name+' is already being worked by '+ testWorkingNsr.Name,msg.getDetail() );
 	        System.assertEquals(null, nsrC.objToSend);
        } // runAs
            
     } // myTest2

	// test Account with Contact owned by NSR
    static testMethod void myTest3() {
   		User testWorkingNsr = [Select Id, Name, FirstName, LastName, isActive, Profile.Name, UserRole.Name from User
							where isActive = true and Job_Name__c = :UserHelper.JOB_NSR 
                            and (Profile.Name = :Label.RoleNSSOutboundRep OR Profile.Name = :Label.RoleNSSOutboundRepBeta) limit 1];
							
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Prospect'
                                ,BillingPostalCode = '10000'
                                ,NumberOfEmployees = 25
                                ,AnnualRevenue = 25
                                );
        insert acct1;
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId() 
                                ,Sales_Contact__c = true
                                ,AccountId=acct1.Id
                                ,Hold_Out__c=true
                                 ,OwnerId = testWorkingNsr.Id);
		insert ctct1;  
        acct1.SignificantContact__c = ctct1.Id;
		update acct1;        	
		ctct1 = [Select Id, Name, Owner.Name, SignificantContact__c from Contact where Id = :ctct1.Id];
        
		User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
         	Test.SetCurrentPageReference(Page.SendToNSR);
         	System.CurrentPageReference().getParameters().put('sfdcId',acct1.Id);
         	SendToNSRController nsrC = new SendToNSRController();
         	
         	System.assertEquals('Significant Contact: ', nsrC.objLabel);
            System.assertEquals('Test Account1 - First Last1',nsrC.ObjToSendName);
            System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals('The significant contact, '+ctct1.Name+' is already being worked by '+ testWorkingNsr.Name,msg.getDetail() );
            System.assertEquals(null, nsrC.nsrOptions);            

        } // runAs
            
     } // myTest3

    // test Account with no Contact
    static testMethod void myTest4() {
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Prospect'
                                ,BillingPostalCode = '10000'
                                ,NumberOfEmployees = 25
                                ,AnnualRevenue = 25
                                );
        insert acct1;
        
		User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
         	Test.SetCurrentPageReference(Page.SendToNSR);
         	System.CurrentPageReference().getParameters().put('sfdcId',acct1.Id);
         	SendToNSRController nsrC = new SendToNSRController();
         	
         	System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals('You must create a contact on this prospect-client before you can send it to an NSR.',msg.getDetail() );            
        } // runAs
            
     } // myTest4

    // test Contact owned by NSR
    static testMethod void myTest5() {
   		User testWorkingNsr = [Select Id, Name, FirstName, LastName, isActive, Profile.Name, UserRole.Name from User
							where isActive = true and Job_Name__c = :UserHelper.JOB_NSR 
                            and (Profile.Name = :Label.RoleNSSOutboundRep OR Profile.Name = :Label.RoleNSSOutboundRepBeta) limit 1];
							
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Prospect'
                                ,BillingPostalCode = '10000'
                                ,NumberOfEmployees = 25
                                ,AnnualRevenue = 25
                                );
        insert acct1;
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId() 
                                ,Sales_Contact__c = true
                                ,AccountId=acct1.Id
                                ,Hold_Out__c=true
                                ,OwnerId = testWorkingNsr.Id);
		insert ctct1;  
        acct1.SignificantContact__c = ctct1.Id;
		update acct1;        	
		ctct1 = [Select Id, Name, Owner.Name, SignificantContact__c from Contact where Id = :ctct1.Id];
        
		User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
         	Test.SetCurrentPageReference(Page.SendToNSR);
         	System.CurrentPageReference().getParameters().put('sfdcId',ctct1.Id);
         	SendToNSRController nsrC = new SendToNSRController();
         	
         	System.assertEquals('Contact:  ', nsrC.objLabel);
            System.assertEquals('First Last1',nsrC.ObjToSendName);
            System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
            System.assertEquals('This contact is already being worked by '+ testWorkingNsr.Name,msg.getDetail() );
        } // runAs
            
     } // myTest5

    // test Account and Contact already being worked
    static testMethod void myTest6() {
   		User testWorkingNsr = [Select Id, Name, FirstName, LastName, isActive, Profile.Name, UserRole.Name from User
							where isActive = true and Job_Name__c = :UserHelper.JOB_NSR 
                            and (Profile.Name = :Label.RoleNSSOutboundRep OR Profile.Name = :Label.RoleNSSOutboundRepBeta) limit 1];
							
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Prospect'
                                ,BillingPostalCode = '10000'
                                ,NumberOfEmployees = 25
                                ,AnnualRevenue = 25
                                ,AssignedToOutboundNSR__c = true
                                );
        insert acct1;
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Sales_Contact__c = true
                                ,AccountId=acct1.Id);
		insert ctct1;  
        ctct1 = [Select Id, Name, Owner.Name from Contact where Id = :ctct1.Id];
		acct1.SignificantContact__c = ctct1.Id;
		update acct1;
		
		Prospect_Ownership__c po = new Prospect_Ownership__c(Ownership_Status__c = 'Prospecting'
								,NSR_Name__c = testWorkingNsr.Id
								,Decision_Maker__c = ctct1.Id
								,Prospect_Client__c = acct1.Id
                                ,NSS_Source__c = 'Outbound'
                                ,StartDate__c = System.today());
		insert po;
		 
		User u = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
         	Test.SetCurrentPageReference(Page.SendToNSR);
         	System.CurrentPageReference().getParameters().put('sfdcId',ctct1.Id);
         	SendToNSRController nsrC = new SendToNSRController();
         	
         	System.assertEquals('Contact:  ', nsrC.objLabel);
         	System.assertEquals(true, nsrC.beingWorked);
         	//System.assertEquals(testWorkingNsr.Name, nsrC.workingNSR);
         	System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
 	        System.assertEquals('This contact is already being worked by '+ testWorkingNsr.Name,msg.getDetail() );
 	        System.assertNotEquals(null, nsrC.objToSend);
        } // runAs
            
     } // myTest6

	// test Lead being reassigned
    static testMethod void myTest8() {
        UserHelperTest.setupSalesOrgSetting();
		Schema.RecordTypeInfo leadCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_LEAD, ObjectHelper.OBJECT_LEAD);	
						
   		Lead leed = new Lead(Firstname = 'First'
								,Lastname = 'Last Lead1'
								,Company = 'Test Lead Company1'
								,recordtypeId = leadCorert.getRecordTypeId()
								,PostalCode = '14414'
                                ,LeadGroupId__c = null);
		insert leed;
		
		User u = [Select Id, Name, Sales_Org__c from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
        System.runAs(u) {
         	Test.SetCurrentPageReference(Page.SendToNSR);
         	System.CurrentPageReference().getParameters().put('sfdcId',leed.Id);
         	SendToNSRController nsrC = new SendToNSRController();
         	
	        Lead ld = (Lead)nsrC.objToSend;
			System.assertNotEquals(null, nsrC.nsrOptions);
            System.assertEquals(null, nsrC.selectedNSRId);
            
            User userNsr = [Select Id, Name, FirstName, LastName, isActive, Profile.Name, UserRole.Name, Sales_Org__c from User
							where isActive = true and Job_Name__c = :UserHelper.JOB_NSR 
                            and (Profile.Name = :Label.RoleNSSOutboundRep OR Profile.Name = :Label.RoleNSSOutboundRepBeta) 
							order by LastName, FirstName limit 1];
            nsrC.selectedNSRId = userNsr.Id;
            nsrC.reassignToNsr();
            
            Lead newLeed = [Select Id, OwnerId, Date_Sent_to_NSS__c from Lead where Id = :leed.Id];            
            System.assertEquals(userNsr.Id, newLeed.OwnerId);
            System.assertEquals(newLeed.Date_Sent_to_NSS__c, System.today());
            
            ObjectTracker__c ot = [Select Id, Lead__c, Action__c from ObjectTracker__c where Lead__c = :newLeed.Id];            
            System.assertEquals('Lead Sent to NSS', ot.Action__c);
            
			Task tsk = [select Id, WhoId, OwnerId, RecordTypeId, RecordType.Name from Task where WhoId = :newLeed.Id];
            System.assertEquals(newLeed.OwnerId, tsk.OwnerId);
            String rcdTypeName = tsk.RecordType.Name;
            System.assertEquals(true, rcdTypeName.contains('MMS'));
            
        } // runAs   
         	        
    } // my Test8

	// test Contact being reassigned
    static testMethod void myTest9() {
        UserHelperTest.setupSalesOrgSetting();
        User salesUser = [Select Id, Name from User where IsActive=true and Profile.Name = :Utilities.PROF_MMS_SALES_SB and Sales_Org__c in :UserHelper.DIVISION_LIST limit 1];
            
        Schema.RecordTypeInfo acctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_ACCOUNT, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctCorert = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);
        
        Account acct1 = new Account (name = 'Test Account1'
                                ,recordtypeId = acctCorert.getRecordTypeId()
                                ,type = 'Prospect'
                                ,BillingPostalCode = '10000'
                                ,NumberOfEmployees = 25
                                ,AnnualRevenue = 25
                                ,OwnerId = salesUser.Id
                                );
        insert acct1;
        Contact ctct1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,recordtypeId = ctctCorert.getRecordTypeId()
                                ,Sales_Contact__c = true
                                ,AccountId=acct1.Id);
		insert ctct1;  
		
        //System.runAs(salesUser) {
         	Test.SetCurrentPageReference(Page.SendToNSR);
         	System.CurrentPageReference().getParameters().put('sfdcId',ctct1.Id);
         	SendToNSRController nsrC = new SendToNSRController();
         	
	        Contact ct = (Contact)nsrC.objToSend;
			System.assertNotEquals(null, nsrC.nsrOptions);
            System.assertEquals(null, nsrC.selectedNSRId);
            
            nsrC.reassignToNsr();
            System.assertEquals(true,ApexPages.hasMessages());
         	ApexPages.Message msg = ApexPages.getMessages().get(0);
 	        System.assertEquals('You must select an NSR or hit Cancel',msg.getDetail() );
        
            User userNsr = [Select Id, Name, FirstName, LastName, isActive, Profile.Name, UserRole.Name from User
							where isActive = true and Job_Name__c = :UserHelper.JOB_NSR 
                            and (Profile.Name = :Label.RoleNSSOutboundRep OR Profile.Name = :Label.RoleNSSOutboundRepBeta) 
							order by LastName, FirstName limit 1];
            nsrC.selectedNSRId = userNsr.Id;
            nsrC.reassignToNsr();
            
            Contact newCtct = [Select Id, OwnerId, Date_Sent_to_NSS__c from Contact where Id = :ctct1.Id];            
            System.assertEquals(userNsr.Id, newCtct.OwnerId);
            System.assertEquals(newCtct.Date_Sent_to_NSS__c, System.today());
            
            ObjectTracker__c ot = [Select Id, Lead__c, Action__c from ObjectTracker__c where Contact__c = :newCtct.Id];            
            System.assertEquals('Contact Sent to NSS', ot.Action__c);
            
			Task tsk = [select Id, WhoId, OwnerId from Task where WhoId = :newCtct.Id];
            System.assertEquals(newCtct.OwnerId, tsk.OwnerId);
            
            System.assertEquals(true,ApexPages.hasMessages());
         	msg = ApexPages.getMessages().get(1);
 	        System.assertEquals('This record been transferred to '+ userNsr.LastName+', '+userNsr.FirstName,msg.getDetail() );
            
        //} // runAs   
         	        
    } // my Test9

} // class SendToNSRControllerTest