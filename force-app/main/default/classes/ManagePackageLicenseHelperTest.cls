/* Queuable job for ManagePackageLicenseHelper to process async
   
  History
  -------
    11/30/2018 Jake Hinds   Created 
    08/25/2020 Carrie Marciano Oracle CPQ license functionality tests
	02/14/2022 Carrie Marciano Reactivate CPQ functionality test
    04/01/2022 Carrie Marciano Fixed list that was returning multiple rows in testReactivateOracleCPQ
    07/31/2023 Dan Carmen      add OracleQuoteTriggerPayxHelperTest.setupOracleUserTrigger() so that Oracle doesn't try to perform a callout in a test method

*/
@isTest
private class ManagePackageLicenseHelperTest {
    @testSetup
    public static void setupData() {
      OracleQuoteTriggerPayxHelperTest.setupOracleUserTrigger();
    }
    
    static testMethod void testApprovedOracleCPQ() {
        Installed_Package__mdt ipmdt = [Select id, DeveloperName, Name_Prefix__c, User_Permission_Set__c,User_Permission_Set_Group__c,Pilot_User_Value__c,Oracle_CPQ__c,Salesforce_License__c
        											From Installed_Package__mdt  WHERE User_Permission_Set_Group__c!=null AND Pilot_User_Value__c != null AND Oracle_CPQ__c != null LIMIT 1];
        PackageLicense pl = [SELECT Id, NamespacePrefix, AllowedLicenses, UsedLicenses,ExpirationDate,Status 
        											FROM PackageLicense WHERE NamespacePrefix = :ipmdt.Name_Prefix__c];
        User salesRep = [SELECT Id FROM User WHERE IsActive = true and Profile.Name = 'Core Sales - SB' LIMIT 1];
        system.debug('ManagePackageLicenseHelperTest ipmdt: '+ipmdt.DeveloperName+' salesrep: '+salesRep);        
        Manage_Package_License__c mpl = new Manage_Package_License__c();
        mpl.User_Name__c = salesRep.Id;
        mpl.Requested_Date__c = date.today();
        mpl.Package_Name__c = ipmdt.DeveloperName; 
        mpl.Request_Status__c = 'Submitted for Approval';
        insert mpl;
        
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
                
        test.startTest();
        
        mpl.Request_Status__c = 'Approved';
        update mpl;
        test.stopTest();
        
        UserPackageLicense upl = [SELECT Id,UserId FROM UserPackageLicense WHERE UserId = :salesRep.Id AND PackageLicenseId = :pl.Id];
        system.assert(upl!=null);
        
        User uSalesRep = [SELECT Id,PilotUser__c FROM User WHERE Id=:salesRep.Id];
        system.assertEquals(ipmdt.Pilot_User_Value__c,uSalesRep.PilotUser__c);
        
        PermissionSetAssignment psa = [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetGroupId = :ipmdt.User_Permission_Set_Group__c AND AssigneeId=:salesRep.Id LIMIT 1];
        system.assert(psa!=null);
        
        cafsl__Oracle_User__c oUser = [SELECT Id FROM cafsl__Oracle_User__c WHERE cafsl__User__c = :salesRep.Id ];
        system.assert(oUser!=null);
        
        Manage_Package_License__c uMpl = [SELECT Id,Approved_By__c,Process_Notes__c FROM Manage_Package_License__c WHERE Id = :mpl.Id];
        system.assertEquals(UserInfo.getUserId(),uMpl.Approved_By__c);
        system.assertEquals(null,uMpl.Process_Notes__c);
    } //testApprovedOracleCPQ
    
    static testMethod void testReactivateOracleCPQ() {
        Installed_Package__mdt ipmdt = [Select id, DeveloperName, Name_Prefix__c, User_Permission_Set__c,User_Permission_Set_Group__c,Pilot_User_Value__c,Oracle_CPQ__c,Salesforce_License__c
        											From Installed_Package__mdt  WHERE User_Permission_Set_Group__c!=null AND Pilot_User_Value__c != null AND Oracle_CPQ__c != null LIMIT 1];
        PackageLicense pl = [SELECT Id, NamespacePrefix, AllowedLicenses, UsedLicenses,ExpirationDate,Status 
        											FROM PackageLicense WHERE NamespacePrefix = :ipmdt.Name_Prefix__c];
        // find an existing user with Oracle_CPQ__c = True
        User salesRep = [Select Id, FirstName, LastName, Name, Email, Cost_Center__c, HR_Person_Id__c, PostalCode from User where IsActive=true and Profile.Name != 'System Administrator' and HR_Person_Id__c != null and Id != :UserInfo.getUserId() and PostalCode != null and Oracle_CPQ__c=True limit 1 ];
        
        //insert Oracle Embedded CPQ Site Settings needed for Oracle User
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
        
        //insert Oracle User for sales rep
        cafsl__Oracle_User__c oUser = new cafsl__Oracle_User__c(cafsl__User__c=salesRep.Id, cafsl__allow_quote_creation__c=True,cafsl__Currency_Preference__c='USD',cafsl__Date_Time_Format__c='0',cafsl__Embedded_CPQ_Settings__c=embeddedCPQSetting.Id,
                                                              cafsl__Groups__c='salesUser',cafsl__Language_Preference__c='English',cafsl__Link_to_CPQ_User__c=True,cafsl__Number_Format__c='0',cafsl__Units__c='1',cafsl__User_Type__c='SALES_AGENT');
        insert oUser; 
        
        system.debug('ManagePackageLicenseHelperTest oUser: '+oUser+' salesrep: '+salesRep);        
        Manage_Package_License__c mpl = new Manage_Package_License__c();
        mpl.User_Name__c = salesRep.Id;
        mpl.Requested_Date__c = date.today();
        mpl.Package_Name__c = ipmdt.DeveloperName; 
        mpl.Request_Status__c = 'Submitted for Approval';
        mpl.Oracle_User__c = oUser.Id;
        mpl.Reactivation__c = True;
        insert mpl; 
        
        test.startTest();
        
        /*mplGood.Request_Status__c = 'Approved';
        mplBad.Request_Status__c = 'Approved';
        update mpls;*/
        
        mpl.Request_Status__c = 'Approved';
        update mpl;
        test.stopTest();
        
        cafsl__Oracle_User__c updatedOUser = [SELECT Id, cafsl__Link_to_CPQ_User__c FROM cafsl__Oracle_User__c WHERE Id = :oUser.Id ];
        system.assert(updatedOUser.cafsl__Link_to_CPQ_User__c,True);
        
        Manage_Package_License__c uMpl = [SELECT Id,Approved_By__c,Process_Notes__c FROM Manage_Package_License__c WHERE Id = :mpl.Id];
        system.assertEquals(UserInfo.getUserId(),uMpl.Approved_By__c);
        system.assertEquals(null,uMpl.Process_Notes__c);
    } //testReactivateOracleCPQ
}