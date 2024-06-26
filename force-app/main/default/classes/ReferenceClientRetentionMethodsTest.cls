/* 
   Test methods for ReferenceClientRetentionMethods 

   
  History
  -------
  04/06/2023 Carrie Marciano    Created
  05/02/2023 Carrie Marciano	Added test for create CAR and case update
  05/09/2023 Carrie Marciano	added test for update of Parent Prospect Client on reference client retention record
  05/31/2023 Carrie Marciano	added test for auto population of Primary Concern Type 1 when Current Step is set to Client Unresponsive
  06/13/2023 Carrie Marciano    added test for over writing process notes, creating cases on exception refs, not finding br-clt# due to lowercase
  08/02/2023 Carrie Marciano	added test for POD Model - multiple recordtypes, current step automation, send to resolution team automation
  10/11/2023 Carrie Marciano	added logic for Email Analytics records to take precedence over other record types when closing duplicate
  1/22/2024  Carrie Marciano	updated testNoAcct to create case on RCR that previously didnt have account populated, when account gets populated.
  05/22/2024 Jermaine Stukes	Update test scenarios for APR0162327 - CRT Email Analytics Automation
*/

@isTest
public class ReferenceClientRetentionMethodsTest {
	public static string closedChatter = Label.ClientRetentionClosedChatter;
    
    @testSetup
    public static void setupData() {
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
        
        String[] CRT_Cadence_Names = Label.ClientRetentionCadenceName.split(',');
    	Cadence__c cad1 = new Cadence__c(Name=CRT_Cadence_Names[0], Active__c=true, Cadence_Type__c='Client Retention', EmpsMin__c=null, EmpsMax__c=null, TargetType__c='Client');
        insert cad1;    
    } //setupData
    
  	static testMethod void testExistingAcctCtctNoCase() { 
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();    
        
        Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct1;
                
        Contact ctct1 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
        insert ctct1;
        
        Reference_Client_Retention__c refCR1 = new Reference_Client_Retention__c(BISID__c=4759974, Branch_Client_Number__c='903-19048033', Contact_Name__c='Louis Test1a', Contact_Phone_Number__c='(585)111-2222', 
                                                                                 Contact_Email__c='louis@test1.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT);
        insert refCR1;
        
        refCR1 = [Select Id, Name, 	Case__c, Case__r.Subject, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email from Reference_Client_Retention__c where Id=:refCR1.Id];
        Assert.areEqual(acct1.Id, refCR1.Prospect_Client_Name__c);
        Assert.areEqual(ctct1.Email, refCR1.Prospect_Client_Contact__r.Email);
        Assert.areEqual('Client Retention at Risk Model', refCR1.Case__r.Subject);
        
        /* Touchpoint is on hold for CRT
        Cadence_Assignment_Record__c[] cars = [SELECT Id,AccountId__c,AccountId__r.Name,Cadence__c,Cadence__r.Name,Cadence_Owner__c,ContactId__c,ContactId__r.Name FROM Cadence_Assignment_Record__c];
        Assert.areEqual(1, cars.size());
		*/
    } //testExistingAcctCtctNoCase
    
    static testMethod void testExistingAcctBISIDCtctNoCase() { 
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
    	String[] CRT_Cadence_Names = Label.ClientRetentionCadenceName.split(',');
    	Cadence__c cad1 = new Cadence__c(Name=CRT_Cadence_Names[0], Active__c=true, Cadence_Type__c='Client Retention', EmpsMin__c=null, EmpsMax__c=null, TargetType__c='Client');
        insert cad1;
        
        Account acct1a = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct1a;
                
        Contact ctct1a = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1a.id);
        insert ctct1a;
        
        Reference_Client_Retention__c refCR1a = new Reference_Client_Retention__c(BISID__c=4759974, Contact_Name__c='Louis Test1a', Contact_Phone_Number__c='(585)111-2222', 
                                                                                 Contact_Email__c='louis@test1.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT);
        insert refCR1a;
        
        refCR1a = [Select Id, Name,	Case__c, Case__r.Subject, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email from Reference_Client_Retention__c where Id=:refCR1a.Id];
        Assert.areEqual(acct1a.Id, refCR1a.Prospect_Client_Name__c);
        Assert.areEqual(ctct1a.Email, refCR1a.Prospect_Client_Contact__r.Email);
        Assert.areEqual('Client Retention at Risk Model', refCR1a.Case__r.Subject);
        
        /* Touchpoint is on hold for CRT
        Cadence_Assignment_Record__c[] cars = [SELECT Id,AccountId__c,AccountId__r.Name,Cadence__c,Cadence__r.Name,Cadence_Owner__c,ContactId__c,ContactId__r.Name FROM Cadence_Assignment_Record__c];
        Assert.areEqual(1, cars.size());
		*/
    } //testExistingAcctBISIDCtctNoCase
    
    static testMethod void testExistingAcctNoCtctNoCase() { 
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
    	String[] CRT_Cadence_Names = Label.ClientRetentionCadenceName.split(',');
    	Cadence__c cad1 = new Cadence__c(Name=CRT_Cadence_Names[0], Active__c=true, Cadence_Type__c='Client Retention', EmpsMin__c=null, EmpsMax__c=null, TargetType__c='Client');
        insert cad1;
        
        Account acct2 = new Account(Name='ACCT2', Federal_ID_Number__c='86-7530913', AccountNumber='906-19048033', Bis_ID__c=4759974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct2;
        
        Reference_Client_Retention__c refCR2 = new Reference_Client_Retention__c(BISID__c=4759974, Branch_Client_Number__c='906-19048033', Contact_Name__c='Louis Test2a', Contact_Phone_Number__c='(585)111-3434', 
                                                                                 Contact_Email__c='louis@test2.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT);
        insert refCR2;
        
        refCR2 = [Select Id, Name, 	Case__c, Case__r.Subject, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email from Reference_Client_Retention__c where Id=:refCR2.Id];
        Assert.areEqual(acct2.Id, refCR2.Prospect_Client_Name__c, acct2.Id);
        Assert.isNotNull(refCR2.Prospect_Client_Contact__c);
        Assert.isNotNull(refCR2.Case__c);
        
        /* Touchpoint is on hold for CRT
        Cadence_Assignment_Record__c[] cars = [SELECT Id,AccountId__c,AccountId__r.Name,Cadence__c,Cadence__r.Name,Cadence_Owner__c,ContactId__c,ContactId__r.Name FROM Cadence_Assignment_Record__c];
        Assert.areEqual(1, cars.size());
		*/
    } //testExistingAcctNoCtctNoCase
    
    static testMethod void testNoAcct() { 
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();

        Account acct1 = new Account(Name='ACCT1', Federal_ID_Number__c='86-7530913', AccountNumber='903-19048033', Bis_ID__c=4759974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct1;
                
        Contact ctct1 = new Contact(FirstName='Louis',LastName='Test1a',Email='louis@test1.com', MobilePhone='(585) 111-2222', AccountId=acct1.id);
        insert ctct1;
                
        Reference_Client_Retention__c refCR3 = new Reference_Client_Retention__c(BISID__c=4759884, Branch_Client_Number__c='903-15748033', Contact_Name__c='Louis Test3a', Contact_Phone_Number__c='(585)111-3434', 
                                                                                 Contact_Email__c='louis@test3.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT);
        insert refCR3;
        
        refCR3 = [Select Id, Name, 	Case__c, Case__r.Subject, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c from Reference_Client_Retention__c where Id=:refCR3.Id];
        Assert.isNotNull(refCR3.ProcessNotes__c);
        Assert.isNull(refCR3.Case__c, 'Case should be null');
        Assert.isNull(refCR3.Prospect_Client_Name__c, 'Prospect_Client_Name__c should be null');
        
        //update RCR with an account
        refCR3.Prospect_Client_Name__c = acct1.Id;
        refCR3.Prospect_Client_Contact__c = ctct1.Id;
        update refCR3;
        
        refCR3 = [Select Id, Name, 	Case__c, Case__r.Subject, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c from Reference_Client_Retention__c where Id=:refCR3.Id];
        Assert.areEqual(acct1.Id, refCR3.Prospect_Client_Name__c);
        Assert.isNotNull(refCR3.Prospect_Client_Contact__c);
        Assert.isNotNull(refCR3.Case__c);
        
    } //testNoAcct
    
    static testMethod void testExistingAcctCtctCase() { 
    	Id caseCRrt = RecordTypeHelper.getRecordType('Service Support Client Retention', 'Case').getRecordTypeId();
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
        
        closedChatter = 'True';
        Account acct4 = new Account(Name='ACCT4', Federal_ID_Number__c='86-7538754', AccountNumber='903-19049853', Bis_ID__c=3259974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct4;
                
        Contact ctct4= new Contact(FirstName='Louis',LastName='Test4a',Email='louis@test4.com', MobilePhone='(585) 111-1472', AccountId=acct4.id);
        insert ctct4;
        
        /*Case case4 = new Case(RecordTypeId=caseCRrt, Status='New', Origin='Risk Model File', Current_Step__c='New', AccountId=acct4.Id);
        insert case4;*/
        
        Reference_Client_Retention__c refCR4 = new Reference_Client_Retention__c(BISID__c=3259974, Branch_Client_Number__c='903-19049853', Contact_Name__c='Louis Test4a', Contact_Phone_Number__c='(585)111-1472', 
                                                                                 Contact_Email__c='louis@test4.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT,
                                                                                Retention_Notes__c='Test Retention_Notes__c',Resolution_Team_Comments__c='Test Resolution_Team_Comments__c');
        insert refCR4;
        
        refCR4 = [Select Id, Name, 	Case__c, Case__r.Status, Case__r.Current_Step__c, Case__r.Origin,Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c, Retention_Notes__c,Resolution_Team_Comments__c  
                  from Reference_Client_Retention__c where Id=:refCR4.Id];
       	Assert.areEqual(acct4.Id, refCR4.Prospect_Client_Name__c);
        Assert.areEqual(ctct4.Email, refCR4.Prospect_Client_Contact__r.Email);
        Assert.areEqual('New', refCR4.Case__r.Current_Step__c);
    } //testExistingAcctCtctCase
    
    static testMethod void testExistingCaseRiskModel() { 
    	Id caseCRrt = RecordTypeHelper.getRecordType('Service Support Client Retention', 'Case').getRecordTypeId();
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
        
        closedChatter = 'True';
        Account acct4 = new Account(Name='ACCT4', Federal_ID_Number__c='86-7538754', AccountNumber='903-19049853', Bis_ID__c=3259974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct4;
                
        Contact ctct4= new Contact(FirstName='Louis',LastName='Test4a',Email='louis@test4.com', MobilePhone='(585) 111-1472', AccountId=acct4.id);
        insert ctct4;
        
        /*Case case4 = new Case(RecordTypeId=caseCRrt, Status='New', Origin='Risk Model File', Current_Step__c='New', AccountId=acct4.Id);
        insert case4;*/
        
        Reference_Client_Retention__c refCR4 = new Reference_Client_Retention__c(BISID__c=3259974, Branch_Client_Number__c='903-19049853', Contact_Name__c='Louis Test4a', Contact_Phone_Number__c='(585)111-1472', 
                                                                                 Contact_Email__c='louis@test4.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT,
                                                                                Retention_Notes__c='Test Retention_Notes__c',Resolution_Team_Comments__c='Test Resolution_Team_Comments__c');
        insert refCR4;
        
        refCR4 = [Select Id, Name, 	Case__c, Case__r.Id, Case__r.Status, Case__r.Current_Step__c, Case__r.Origin,Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c, Retention_Notes__c,Resolution_Team_Comments__c  
                  from Reference_Client_Retention__c where Id=:refCR4.Id];
       	Assert.areEqual(acct4.Id, refCR4.Prospect_Client_Name__c);
        Assert.areEqual(ctct4.Email, refCR4.Prospect_Client_Contact__r.Email);
        Assert.areEqual('New', refCR4.Case__r.Current_Step__c);
        Id kaseId = refCR4.Case__r.Id;
                
        Reference_Client_Retention__c refCR5 = new Reference_Client_Retention__c(BISID__c=3259974, Branch_Client_Number__c='903-19049853', Contact_Name__c='Louis Test4a', Contact_Phone_Number__c='(585)111-1472', 
                                                                                 Contact_Email__c='louis@test4.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT,
                                                                                 Retention_Notes__c='Test Retention_Notes__c',Resolution_Team_Comments__c='Test Resolution_Team_Comments__c');
        insert refCR5;
        Case existKase = [Select Id, Current_Step__c from Case where Id=:kaseId];
        Assert.areEqual('Closed - Duplicate', existKase.Current_Step__c);

    } //testExistingAcctCtctCase
        static testMethod void testExistingCaseRiskModel2() { 
    	Id caseCRrt = RecordTypeHelper.getRecordType('Service Support Client Retention', 'Case').getRecordTypeId();
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
        
        closedChatter = 'True';
        Account acct4 = new Account(Name='ACCT4', Federal_ID_Number__c='86-7538754', AccountNumber='903-19049853', Bis_ID__c=3259974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct4;
                
        Contact ctct4= new Contact(FirstName='Louis',LastName='Test4a',Email='louis@test4.com', MobilePhone='(585) 111-1472', AccountId=acct4.id);
        insert ctct4;
        
        /*Case case4 = new Case(RecordTypeId=caseCRrt, Status='New', Origin='Risk Model File', Current_Step__c='New', AccountId=acct4.Id);
        insert case4;*/
        
        Reference_Client_Retention__c refCR4 = new Reference_Client_Retention__c(BISID__c=3259974, Branch_Client_Number__c='903-19049853', Contact_Name__c='Louis Test4a', Contact_Phone_Number__c='(585)111-1472', 
                                                                                 Contact_Email__c='louis@test4.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT,
                                                                                Retention_Notes__c='Test Retention_Notes__c',Resolution_Team_Comments__c='Test Resolution_Team_Comments__c');
        insert refCR4;
        
            refCR4 = [Select Id, Name, 	Case__c, Case__r.Id, Case__r.Status, Case__r.Current_Step__c, Case__r.Origin,Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                      , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c, Retention_Notes__c,Resolution_Team_Comments__c  
                      from Reference_Client_Retention__c where Id=:refCR4.Id];
            Assert.areEqual(acct4.Id, refCR4.Prospect_Client_Name__c);
            Assert.areEqual(ctct4.Email, refCR4.Prospect_Client_Contact__r.Email);
            Assert.areEqual('New', refCR4.Case__r.Current_Step__c);
            refCR4.Current_Step__c = 'First Attempt made';
            update refCR4;
            Id kaseId = refCR4.Case__r.Id;
                
        Reference_Client_Retention__c refCR5 = new Reference_Client_Retention__c(BISID__c=3259974, Branch_Client_Number__c='903-19049853', Contact_Name__c='Louis Test4a', Contact_Phone_Number__c='(585)111-1472', 
                                                                                 Contact_Email__c='louis@test4.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT,
                                                                                 Retention_Notes__c='Test Retention_Notes__c',Resolution_Team_Comments__c='Test Resolution_Team_Comments__c');
        insert refCR5;
            refCR5 = [Select Id, Name, 	Case__c, Case__r.Id, Case__r.Status, Case__r.Current_Step__c, Case__r.Origin,Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                      , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c, Retention_Notes__c,Resolution_Team_Comments__c  
                      from Reference_Client_Retention__c where Id=:refCR5.Id];
            Case existKase = [Select Id, Current_Step__c from Case where Id=:kaseId];
            Assert.areEqual('First Attempt made', existKase.Current_Step__c);
            Assert.areEqual('Closed - Duplicate', refCR5.Current_Step__c);

    } //testExistingAcctCtctCase
    static testMethod void testUpdateToCase() { 
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
    	
        Account acct4 = new Account(Name='ACCT4', Federal_ID_Number__c='86-7538754', AccountNumber='903-19049853', Bis_ID__c=3259974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        Account acct5 = new Account(Name='ACCT5', Federal_ID_Number__c='86-7538529', AccountNumber='20-Y0049853', Bis_ID__c=3259977
                                       ,ShippingStreet='80 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        Account[] accts = new Account[]{acct4,acct5};
      	insert accts;
        
        Account upAcct5 = [Select Id, Name, ParentId from Account where Id=:acct5.Id];
        upAcct5.ParentId=acct4.Id;
        update upAcct5;
                
        Contact ctct4= new Contact(FirstName='Louis',LastName='Test4a',Email='louis@test4.com', MobilePhone='(585) 111-1472', AccountId=acct4.id);
        Contact ctct5= new Contact(FirstName='Mary',LastName='Test5a',Email='mary@test5.com', MobilePhone='(585) 222-3258', AccountId=acct5.id);
        Contact[] ctcts = new Contact[]{ctct4,ctct5};
        insert ctcts;
        
        Reference_Client_Retention__c refCR4 = new Reference_Client_Retention__c(BISID__c=3259974, Branch_Client_Number__c='903-19049853', Contact_Name__c='Louis Test4a', Contact_Phone_Number__c='(585)111-1472', 
                                                                                 Contact_Email__c='louis@test4.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Current_Step__c = 'New', Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT);
        insert refCR4;
        refCR4 = [Select Id, Name, Prospect_Client_Contact__c, Prospect_Client_Name__c, Current_Step__c, OwnerId from Reference_Client_Retention__c where Id =:refCR4.Id];
        
        // test that changing values updates ref and case correctly
        refCR4.Prospect_Client_Contact__c = ctct5.id;
        refCR4.Prospect_Client_Name__c = acct5.id;
        refCR4.Current_Step__c = 'First Attempt made';       
        update refCR4;
        
        refCR4 = [Select Id, Name, Case__c, Case__r.Status, Case__r.Current_Step__c, Parent_Prospect_Client_Name__c, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c from Reference_Client_Retention__c where Id=:refCR4.Id];
       	Assert.areEqual(acct5.Id, refCR4.Prospect_Client_Name__c);
        Assert.areEqual(acct4.Id, refCR4.Parent_Prospect_Client_Name__c);
        Assert.areEqual(ctct5.Email, refCR4.Prospect_Client_Contact__r.Email);
        Assert.areEqual('First Attempt made', refCR4.Case__r.Current_Step__c);
        
        // test that particular current step value auto populates primary concern type 1
        refCR4.Current_Step__c = 'Client Unresponsive';     
        update refCR4;
        
        refCR4 = [Select Id, Name, Current_Step__c, Primary_Concern_Type_1__c from Reference_Client_Retention__c where Id=:refCR4.Id];
       	Assert.areEqual('No Contact', refCR4.Primary_Concern_Type_1__c);   
        
    } //testUpdateToCase
    
    static testMethod void testXferToResolutionTeam() { 
        String RR_ClientRetention_ID = Label.ClientRetentionResolutionQueue;
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
        Id resoRT = RecordTypeHelper.getRecordType('Client Retention - Resolution Team','Reference_Client_Retention__c').getRecordTypeId();
    	Id resoQueueId = RR_ClientRetention_ID;
        Account acct = new Account(Name='ACCT', Federal_ID_Number__c='86-7538754', AccountNumber='903-19049853', Bis_ID__c=3259974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
      	insert acct;
                        
        Contact ctct= new Contact(FirstName='Louis',LastName='Test4a',Email='louis@test4.com', MobilePhone='(585) 111-1472', AccountId=acct.id);
        insert ctct;
        
        Reference_Client_Retention__c refCR = new Reference_Client_Retention__c(BISID__c=3259974, Branch_Client_Number__c='903-19049853', Contact_Name__c='Louis Test4a', Contact_Phone_Number__c='(585)111-1472', 
                                                                                 Contact_Email__c='louis@test4.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Current_Step__c = 'New', Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT);
        insert refCR;
        refCR = [Select Id, Name, Prospect_Client_Contact__c, Prospect_Client_Name__c, Current_Step__c, OwnerId from Reference_Client_Retention__c where Id =:refCR.Id];
        
        // test that changing values updates ref and case correctly
        refCR.Current_Step__c = 'Transfer to Resolution Team';       
        update refCR;
        
        refCR = [Select Id, Name, Case__c, Case__r.Status, Case__r.Current_Step__c, Case__r.OwnerId, Parent_Prospect_Client_Name__c, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c, RecordTypeId from Reference_Client_Retention__c where Id=:refCR.Id];
       	
        Assert.areEqual(resoQueueId, refCR.OwnerId); 
        Assert.areEqual(resoRT, refCR.RecordTypeId);
        Assert.areEqual(refCR.OwnerId, refCR.Case__r.OwnerId);
        Assert.areEqual(refCR.Current_Step__c, refCR.Case__r.Current_Step__c);
        
    } //testXferToResolutionTeam
    
    static testMethod void testEmailAnalyticsOpenNonEmailRef(){
    	Id caseCRrt = RecordTypeHelper.getRecordType('Service Support Client Retention', 'Case').getRecordTypeId();
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
        Id emailRT = RecordTypeHelper.getRecordType('Client Retention - Email Analytics', 'Reference_Client_Retention__c').getRecordTypeId();
        
        closedChatter = 'True';
        Account acct = new Account(Name='ACCT', Federal_ID_Number__c='86-7538754', AccountNumber='903-19049853', Bis_ID__c=3259974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct;
                
        Contact ctct= new Contact(FirstName='Louis',LastName='Test4a',Email='louis@test4.com', MobilePhone='(585) 111-1472', AccountId=acct.id);
        insert ctct;
        
        // insert non Email recordtype RCR
        Reference_Client_Retention__c refCR = new Reference_Client_Retention__c(BISID__c=3259974, Branch_Client_Number__c='903-19049853', Contact_Name__c='Louis Test4a', Contact_Phone_Number__c='(585)111-1472', 
                                                                                 Contact_Email__c='louis@test4.com', No_Longer_Continue_Business_with_Us_1__c='Too Many Issues', Primary_Area_of_Dissatisfaction_1__c='errors with payroll',
                                                                                 Lost_Date__c=Date.today(), Retention_Priority__c='Medium', Case_Type__c='Retention Model', RecordtypeId = rcrRT);
        insert refCR;
        
        refCR = [Select Id, Name, 	Case__c, Case__r.Status, Case__r.Current_Step__c, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c from Reference_Client_Retention__c where Id=:refCR.Id];
       	Assert.areEqual(acct.Id, refCR.Prospect_Client_Name__c);
        Assert.areEqual(ctct.Email, refCR.Prospect_Client_Contact__r.Email);
        
        // insert Email recordtype RCR
        Reference_Client_Retention__c refCRemail = new Reference_Client_Retention__c(Prospect_Client_Name__c=acct.Id, Prospect_Client_Contact__c=ctct.Id, Case_Type__c='Email Analytics', RecordtypeId = emailRT);
        insert refCRemail;
        refCRemail = [Select Id, Name, 	Case__c, Case__r.Status, Case__r.Current_Step__c, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c from Reference_Client_Retention__c where Id=:refCRemail.Id];
        Assert.areEqual(acct.Id, refCRemail.Prospect_Client_Name__c);
        Assert.areEqual(ctct.Email, refCRemail.Prospect_Client_Contact__r.Email);
        Assert.areEqual('New', refCRemail.Case__r.Status);    
    } //testEmailAnalyticsOpenNonEmailRef 
    
    static testMethod void testEmailAnalyticsOpenEmailRef(){
    	Id caseCRrt = RecordTypeHelper.getRecordType('Service Support Client Retention', 'Case').getRecordTypeId();
        Id rcrRT = RecordTypeHelper.getRecordType('Reference Client Retention','Reference_Client_Retention__c').getRecordTypeId();
        Id emailRT = RecordTypeHelper.getRecordType('Client Retention - Email Analytics', 'Reference_Client_Retention__c').getRecordTypeId();
        
        closedChatter = 'True';
        Account acct4 = new Account(Name='ACCT4', Federal_ID_Number__c='86-7538754', AccountNumber='903-19049853', Bis_ID__c=3259974
                                       ,ShippingStreet='23 Some Street', ShippingCity='SomeCity', ShippingState='NY', ShippingPostalCode='14623', ShippingCountry='US');
        insert acct4;
                
        Contact ctct4= new Contact(FirstName='Louis',LastName='Test4a',Email='louis@test4.com', MobilePhone='(585) 111-1472', AccountId=acct4.id);
        insert ctct4;
        
        Case case4 = new Case(RecordTypeId=caseCRrt, Status='New', Origin='Email Analytics', Current_Step__c='New', AccountId=acct4.Id);
        insert case4;
        
        Reference_Client_Retention__c refCR4 = new Reference_Client_Retention__c(Prospect_Client_Name__c=acct4.Id, Prospect_Client_Contact__c=ctct4.Id, Case_Type__c='Email Analytics', RecordtypeId = emailRT);
        insert refCR4;
        
        refCR4 = [Select Id, Name, 	Case__c, Case__r.Status, Case__r.Current_Step__c, Prospect_Client_Name__c, Prospect_Client_Number__c, BIS_ID__c, Paychex_CAID__c, Prospect_Client_Lost_Date__c
                  , OwnerId, Current_Step__c, Case_Type__c, Prospect_Client_Contact__c, Prospect_Client_Contact__r.Email, ProcessNotes__c from Reference_Client_Retention__c where Id=:refCR4.Id];
       	Assert.areEqual(acct4.Id, refCR4.Prospect_Client_Name__c);
        Assert.areEqual(ctct4.Email, refCR4.Prospect_Client_Contact__r.Email);
        Assert.areEqual('Closed - Duplicate', refCR4.Case__r.Current_Step__c);    
    } //testEmailAnalyticsOpenEmailRef 
}