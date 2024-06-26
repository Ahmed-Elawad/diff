/**
 * This class contains unit tests for validating the CaseBefore trigger
 * and triggers.
 *
 * History
 * --------
 * 12/11/2012	Cindy Freeman	created
 * 11/27/2016 	Cindy Freeman	changed query for mktoU (marketo user)
 * 12/04/2023	Carrie Marciano	added tests for round robin code that was moved to CaseBefore
 *
 */
@isTest
private class CaseBeforeTest {
 
    
    static testMethod void testCaseMkto() {

    	User mktoU = [Select Id, Name, ProfileId from User where Name = :UserHelper.MARKETO and IsActive = true limit 1];
    	
    	RecordType caseDNCType = [Select Id, Name, sobjectType from RecordType 
    								where sObjectType = 'Case' and Name = 'Sales Support Cases Record Type' and IsActive = true]; 

		List<Case> caseList = new List<Case>();

		String descrip = 'Below is the result..\r';
    	descrip = descrip + 'contacttype: Do Not Call\r'; 
 		descrip = descrip + 'contactsource: Prospect\r';
 		descrip = descrip + 'contact_fname: Joe\r';
 		descrip = descrip + 'contact_lname: Prospect1\r';
    	descrip = descrip + 'company: Test Prospect1\r';
    	descrip = descrip + 'zip: 10000\r';
    	descrip = descrip + 'contact_phone: 585-555-1212\r';
    	descrip = descrip + 'name: Cheryl Paychex\r';
    	
    	Case case1 = new Case (recordtypeId = caseDNCType.Id
    						,status = 'New'
    						,origin = 'Web'
    						,subject = 'Do Not Contact Request Form'
    						,description = descrip
    						,ownerId = mktoU.Id);		    		
		    		
		caseList.add(case1);
		
		insert caseList; 
				
		List<Case> updatedCases = [Select Id, recordtypeId, subject, description, status, isClosed from Case where id in :caseList];
		
		for (Case upkase: updatedCases)
		{	System.assertEquals(true, upkase.IsClosed);	}		 
		  	
    } // testCaseMkto		
		
		
	static testMethod void testCaseDNC() {
    	RecordType caseDNCType = [Select Id, Name, sobjectType from RecordType 
    								where sObjectType = 'Case' and Name = 'Sales Support Cases Record Type' and IsActive = true]; 

		List<Case> caseList = new List<Case>();
							
		String descrip = 'Below is the result..<br>';        
        descrip = 'Below is the result..<br>';
        descrip = descrip + 'company: Test Client<br>';
        descrip = descrip + 'branchnum: 0083<br>';
        descrip = descrip + 'clientnum: 1234567<br>';
        descrip = descrip + 'phone: 585-555-1212<br>';
        descrip = descrip + 'donotcall: Do Not Call<br>';
        descrip = descrip + 'emailoptout: no<br>';
        descrip = descrip + 'entirecompany: True<br>';
        descrip = descrip + 'contactemail: sftest1abcd@test.com<br>';
        descrip = descrip + 'comments: Test Comment<br>';
        descrip = descrip + 'submitter: Cheryl Paychex<br>';
    	
    	Case case2 = new Case (recordtypeId = caseDNCType.Id
    						,status = 'New'
    						,origin = 'Web'
    						,subject = 'Do Not Call Request - Contact'
    						,description = descrip);	
		caseList.add(case2);
				
		insert caseList; 
				
		List<Case> updatedCases = [Select Id, recordtypeId, subject, description, status, isClosed from Case where id in :caseList];
		
		for (Case upkase: updatedCases)
		{	System.assertEquals(true, upkase.IsClosed);	}		 
		  
    } // testCaseDNC
   
    static testMethod void testCaseOther() {
   		createTestData();
    	
    	RecordType caseGLType = [Select Id, Name, sobjectType from RecordType 
    								where sObjectType = 'Case' and Name = 'Service Onboarding GL Case' and IsActive = true]; 
    	
    	Contact ctct = [Select Id, Name from Contact where Name = 'First Last4'];
    	Case caseGL = new Case (recordtypeId = caseGLType.Id
    							,contactId = ctct.Id
    							,status = 'New'
    							,origin = 'Email'
    							,Product__c = 'GL'
    							,Reassign_Category_1__c = 'GL Onboarding'
    							,subject = 'GL Onboarding');
    	insert caseGL;
    	
    	Case updatedGL = [Select Id, subject, status, isClosed from Case where id = :caseGL.Id];
    	System.assertEquals(false, updatedGL.IsClosed);
   
    } // testCaseOther
 
    static testMethod void testCaseRR() {
   		createTestData();
    	
    	RecordType caseCRTType = [Select Id, Name, sobjectType from RecordType 
    								where sObjectType = 'Case' and Name = 'Service Support Client Retention' and IsActive = true]; 
    	
        Account acct1 = [Select Id, Name from Account where Name = 'Test Account1'];
        Group grp = [SELECT Id, Name FROM Group WHERE Type= 'Queue' and Name = 'Client Retention'];
        
        //insert case with owner as a queue
    	Case caseCRT = new Case (RecordTypeId=caseCRTType.Id, OwnerId=grp.Id, Status='New', Origin='Risk Model File', Current_Step__c='New', AccountId=acct1.Id);
    	insert caseCRT;
    	
    	Case updatedCRT = [Select Id, subject, status, OwnerId from Case where id = :caseCRT.Id];
        Assert.areNotEqual(grp.Id, updatedCRT.OwnerId);
   		//update case with owner as a user
        User user1 = [SELECT Id FROM User WHERE IsActive=True AND Id !=:updatedCRT.OwnerId LIMIT 1];
        updatedCRT.OwnerId = user1.Id;
        update updatedCRT;
        
        Case updatedCRT2 = [Select Id, subject, status, OwnerId from Case where id = :updatedCRT.Id];
        String strOwnerId = string.valueOf(updatedCRT2.OwnerId);
        Assert.isTrue(strOwnerId.startsWith('005'), 'owner is a not queue');
        
        //update case with owner as a queue
        updatedCRT2.OwnerId = grp.Id;
        update updatedCRT2;
        
        Case updatedCRT3 = [Select Id, subject, status, OwnerId from Case where id = :updatedCRT2.Id];
        Assert.areNotEqual(grp.Id, updatedCRT3.OwnerId);
        
    } // testCaseRR
    
    private static void createTestData () {
        Account acct1 = new Account (name = 'Test Account1'
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '83-1234567'
                                ,Do_Not_Call__c = true
                                ,Email_Opt_Out__c = true
                                ,AnnualRevenue = 25);
        insert acct1;
        Contact con1 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last1'
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast1@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct1.Id);
        insert con1;
 
        Account acct2 = new Account (name = 'Test Account2'
                                ,type = 'MMS Client'
                                ,BillingPostalCode = '10000'
                                ,AccountNumber = '99-7654321'
                                ,Do_Not_Call__c = false
                                ,Email_Opt_Out__c = false
                                ,AnnualRevenue = 25);
        insert acct2;
        Contact con2 = new Contact(Firstname = 'First'
                                ,Lastname = 'Last4'
                                ,Phone = '585-555-1212'
                                ,Email = 'fLast4@abc.com'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct2.Id);
        insert con2;     
        
        Account acct3 = new Account (name = 'Test Prospect1'
                                ,type = 'Prospect'
                                ,BillingPostalCode = '10000');
        insert acct3;
        Contact con3 = new Contact(Firstname = 'First'
                                ,Lastname = 'Prospect1'
                                ,Phone = '585-555-1212'
                                ,DoNotCall = false
                                ,HasOptedOutOfEmail = false
                                ,AccountId=acct3.Id);
        insert con3;
                     
        User crtUser = [SELECT Id FROM User WHERE IsActive=True AND Assignment_Group_Active__c = True LIMIT 1];
        
        Group grp = [SELECT Id, Name FROM Group WHERE Type= 'Queue' and Name = 'Client Retention'];
        ReferenceClientRetentionMethods.RR_QUEUE_ID=grp.Id;
        
        Assignment_Group_Name__c agn = new Assignment_Group_Name__c(Name=grp.Name,Type__c='Reference Client Retention');
        insert agn;
                    
        Assignment_Group_Queues__c agq = new Assignment_Group_Queues__c(Name=grp.Name, Assignment_Group_Name__c=agn.Id, QueueId__c=grp.Id); 
        insert agq;
        Assert.areEqual(1, [select count() from Assignment_Group_Queues__c]);
        
        Assignment_Groups__c grpMember = new Assignment_Groups__c(Active__c='True',Group_Name__c=agn.Id,User__c=crtUser.Id);
        insert grpMember;
        
        } // createTestData
   
     
}