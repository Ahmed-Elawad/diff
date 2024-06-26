/* Test Methods for the UserEmailChangeSchedulable class

   
  History
  -------
  10/14/2020 Carrie Marciano      Created
  07/31/2023 Dan Carmen           add OracleQuoteTriggerPayxHelperTest.setupOracleUserTrigger() so that Oracle doesn't try to perform a callout in a test method

 */

@isTest
private class UserEmailChangeSchedulableTest {
    @testSetup
    public static void setupData() {
      OracleQuoteTriggerPayxHelperTest.setupOracleUserTrigger();
    }

    public static List<cafsl__Oracle_User__c> createOracleUser(Integer numSFUser){       
        
        //CPQ setup
        cafsl__CPQ_Site_Settings__c cpqSiteSettings = new cafsl__CPQ_Site_Settings__c();
        cpqSiteSettings.Name = 'CPQ Test Class';
        cpqSiteSettings.cafsl__Callout_URL__c = 'https://paychexinctest1.bigmachines.com/';
        cpqSiteSettings.cafsl__Certificate_Name__c ='OracleCPQ';
        cpqSiteSettings.cafsl__Connected_App_Name__c = 'OracleCPQ';
        cpqSiteSettings.cafsl__Text_2__c = '56789123';
        cpqSiteSettings.cafsl__Version__c ='18B';
        cpqSiteSettings.cafsl__Data_Set__c = 'paychexinctestclass';
        cpqSiteSettings.cafsl__Disable_Local_Save__c = True;      
        cpqSiteSettings.cafsl__Document_Id__c = '23456789';
        cpqSiteSettings.cafsl__Document_Name__c = 'transaction';  
        cpqSiteSettings.cafsl__Open_Action_Id__c = '34567891';
        cpqSiteSettings.cafsl__Primary__c = True;
        cpqSiteSettings.cafsl__Process_Id__c = '12345678';
        cpqSiteSettings.cafsl__Process_Name__c = 'paychexCommerceProcess';
        cpqSiteSettings.cafsl__Subdocument_Name__c = 'transactionLine';
        cpqSiteSettings.cafsl__Checkbox_1__c = True;   
        cpqSiteSettings.cafsl__Use_Opportunity_Currency__c = True;
        cpqSiteSettings.cafsl__Use_Opportunity_Pricebook__c = True; 
        cpqSiteSettings.cafsl__Text_3__c = '45678912';     
        insert cpqSiteSettings;
        
        cafsl__Embedded_CPQ_Settings__c embeddedCPQSetting = new cafsl__Embedded_CPQ_Settings__c();
        embeddedCPQSetting.Name = 'CPQ Test Class';
        embeddedCPQSetting.cafsl__Callout_URL__c = 'https://paychexinctest1.bigmachines.com/';
        embeddedCPQSetting.cafsl__Connected_App_Name__c = 'OracleCPQ';
        embeddedCPQSetting.cafsl__Copy_Action_Id__c = '56789123';
        embeddedCPQSetting.cafsl__Data_Set__c = 'paychexinctestclass';
        embeddedCPQSetting.cafsl__Document_Id__c = '23456789';
        embeddedCPQSetting.cafsl__Open_Action_Id__c = '34567891';
        embeddedCPQSetting.cafsl__Primary__c = True;
        embeddedCPQSetting.cafsl__Process_Id__c = '12345678';
        embeddedCPQSetting.cafsl__Process_Name__c  = 'paychexCommerceProcess';
        embeddedCPQSetting.cafsl__Embed_In_Lightning__c = True;    
        embeddedCPQSetting.cafsl__Use_Opportunity_Currency__c = True;
        embeddedCPQSetting.cafsl__Use_Opportunity_Pricebook__c = True;   
        embeddedCPQSetting.cafsl__Version_Id__c = '67891234';
        embeddedCPQSetting.cafsl__Version_Number__c = 2018.200;
        insert embeddedCPQSetting; 
        
        //salesforce user records
        User[] users = [Select Id, Name, Email from User where IsActive=true and Sales_Org__c in :UserHelper.DIVISION_LIST limit :numSFUser];
        
        List<cafsl__Oracle_User__c> oUsers = new List<cafsl__Oracle_User__c>();
        for(Integer i=0;i<numSFUser;i++){
            User sfUser = users[i];
            //for each sfUser create an Oracle User
            oUsers.add(new cafsl__Oracle_User__c(
                cafsl__allow_quote_creation__c=True,
        		cafsl__Currency_Preference__c='USD',
        		cafsl__Date_Time_Format__c='0',
        		cafsl__Embedded_CPQ_Settings__c=embeddedCPQSetting.Id,
        		cafsl__Groups__c='salesUser',
        		cafsl__Language_Preference__c='English',
        		cafsl__Link_to_CPQ_User__c=True,
        		cafsl__Number_Format__c='0',
        		cafsl__Units__c='1',
        		cafsl__User__c=sfUser.Id,
        		cafsl__User_Type__c='SALES_AGENT',
            	LatestEmail__c = 'testouser@paychex.com'));
        }
    
      	insert oUsers;
        return oUsers;
    }
    
    static testMethod void underBatchLimit() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='UserEmailChangeSchedulable', Active__c=true, BatchSize__c=5 );
      insert abc;  
      cafsl__Oracle_User__c[] oUsersUnder = UserEmailChangeSchedulableTest.createOracleUser(3);  
      cafsl__Oracle_User__c[] oUsersUnderCreated = [Select LatestEmail__c, cafsl__User__r.Email from cafsl__Oracle_User__c where Id in:oUsersUnder];  
      system.assertNotEquals(oUsersUnderCreated[0].LatestEmail__c,oUsersUnderCreated[0].cafsl__User__r.Email,'emails match'); 
      system.assertNotEquals(oUsersUnderCreated[1].LatestEmail__c,oUsersUnderCreated[1].cafsl__User__r.Email,'emails match');
      system.assertNotEquals(oUsersUnderCreated[2].LatestEmail__c,oUsersUnderCreated[2].cafsl__User__r.Email,'emails match');
        
      Test.startTest();
      UserEmailChangeSchedulable uec = new UserEmailChangeSchedulable();
      uec.execute(null);
      Test.stopTest();
      
      cafsl__Oracle_User__c[] oUsersUnderUpdated = [Select LatestEmail__c, cafsl__User__r.Email from cafsl__Oracle_User__c where Id in:oUsersUnder];
      system.assertEquals(oUsersUnderUpdated[0].LatestEmail__c,oUsersUnderUpdated[0].cafsl__User__r.Email); 
      system.assertEquals(oUsersUnderUpdated[1].LatestEmail__c,oUsersUnderUpdated[1].cafsl__User__r.Email);
      system.assertEquals(oUsersUnderUpdated[2].LatestEmail__c,oUsersUnderUpdated[2].cafsl__User__r.Email);  
        
    } // underBatchLimit

    
   static testMethod void overBatchLimit() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(Name='UserEmailChangeSchedulable', Active__c=true, BatchSize__c=2 );
      insert abc; 
      cafsl__Oracle_User__c[] oUsersOver = UserEmailChangeSchedulableTest.createOracleUser(3);
      cafsl__Oracle_User__c[] oUsersOverCreated = [Select LatestEmail__c, cafsl__User__r.Email from cafsl__Oracle_User__c where Id in:oUsersOver];
      system.assertNotEquals(oUsersOverCreated[0].LatestEmail__c,oUsersOverCreated[0].cafsl__User__r.Email,'emails match'); 
      system.assertNotEquals(oUsersOverCreated[1].LatestEmail__c,oUsersOverCreated[1].cafsl__User__r.Email,'emails match');
      system.assertNotEquals(oUsersOverCreated[2].LatestEmail__c,oUsersOverCreated[2].cafsl__User__r.Email,'emails match');
        
      Test.startTest();
      UserEmailChangeSchedulable uec = new UserEmailChangeSchedulable();
      uec.execute(null);
      Test.stopTest();
      
      cafsl__Oracle_User__c[] oUsersOverUpdated = [Select LatestEmail__c, cafsl__User__r.Email from cafsl__Oracle_User__c where Id in:oUsersOver];
      system.assertEquals(oUsersOverUpdated[0].LatestEmail__c,oUsersOverUpdated[0].cafsl__User__r.Email); 
      system.assertEquals(oUsersOverUpdated[1].LatestEmail__c,oUsersOverUpdated[1].cafsl__User__r.Email);
      system.assertEquals(oUsersOverUpdated[2].LatestEmail__c,oUsersOverUpdated[2].cafsl__User__r.Email);  
      
    } // overBatchLimit
    
    
}