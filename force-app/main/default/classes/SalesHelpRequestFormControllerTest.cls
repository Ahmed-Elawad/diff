/* 
* Test methods for the SalesHelpRequestFormController.
*
* History
* -------
* 04/12/2019 Michael Karcz Created
* 10/5/2020  Brandon Vidro change populateCase() to use Date.today() instead of hard coding date 
* 12/29/2020 Jermaine Stukes	Recreated for Sales Help lightning component
*/
@isTest
public class SalesHelpRequestFormControllerTest {
    public static String CaseSH_RT='Sales Help Request Case';
    public static String CaseMessage='Additional Documentation #Here# Required';
    public static String CaseTranslatedMessage='Additional Documentation in the link below  Required';
    public static String CaseURL='test@test.com';
    @testSetup
    static void setup() {
        //Creating Custom Settings
        TriggerSetupClasses__c[] classes = new TriggerSetupClasses__c[]{};
        TriggerMethodsTest.createTriggerSetting('CaseBefore', true, false, false, false, new String[]{'SalesHelpRequestFormController'}, classes, TriggerMethods.INTERFACE_C);
        TriggerMethodsTest.createTriggerSetting('CaseAfter', false, true, false, false, new String[]{'SalesHelpRequestFormController'}, classes, TriggerMethods.INTERFACE_C);
        insert classes;
        
        Sales_Help_Request_Case__c[] shCases = new Sales_Help_Request_Case__c[]{};
        shCases.add(new Sales_Help_Request_Case__c(Name='Contest Approval',Type__c='Contest Approval',Sub_Type__c='Contest Approval (Management Only)', Group_Name__c='Contest Approval Help Request Queue', Alert_Message__c=caseMessage, Alert_Message_URL__c=CaseURL));
        shCases.add(new Sales_Help_Request_Case__c(Name='General_Touchpoint',Type__c='General', Group_Name__c='Touchpoint Help Request Queue',Route_via_Sales_Org__c= true ));
        shCases.add(new Sales_Help_Request_Case__c(Name='Sales Enablement Request', Type__c='Sales Enablement Request', Group_Name__c='Sales Enablement Request Queue',Permission_Needed__c='Sales Enablement Request Type'));
        shCases.add(new Sales_Help_Request_Case__c(Name='Virtual_NSS', Group_Name__c='Virtual Sales Help Request Queue'));
        shCases.add(new Sales_Help_Request_Case__c(Name='Default',Group_Name__c='Sales Data Steward Queue'));
        insert shCases;

        RecordType__c shRT = new RecordType__c(Name=CaseSH_RT, ObjectName__c='Case', RecordTypeName__c=CaseSH_RT);
        insert shRT;
    } //setup()
    
    static testMethod void testRouting(){
        Case newCase = new Case();
        newCase.RecordTypeId = SalesHelpRequestFormController.retrieveSalesHelpRT();
        newCase.Type = 'Contest Approval';
        newCase.Sub_Type__c = 'Contest Approval (Management Only)';
        newCase.Description = 'Testingc';
        newCase.Due_Date__c = Date.today() + 1;
        test.startTest();
        insert newCase;
        test.stopTest();
        Sales_Help_Request_Case__c shrc = SalesHelpRequestFormController.retrieveSHCS(newCase.Type, newCase.Sub_Type__c);
        Group GroupId = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = :shrc.Group_Name__c LIMIT 1];
        Case kase = [Select Id, OwnerId from Case where Id=:newCase.Id];
        //Verify Case routed correctly
        System.assertEquals(GroupId.Id, kase.OwnerId);
    }
    static testMethod void testNonVirtualRouting(){
        String caseType = 'General';
        String CaseSubType = 'Touchpoint';
        //Test Non Virtual
        User testUserA = [Select Id, Name, Sales_Division__c, Sales_Org__c, Profile.Name, UserRole.Name
                         from User Where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE 
                         and (UserRole.Name like 'CORE SALES REP%' or UserRole.Name like 'SMB Sales Rep%')  limit 1];
        System.runAs(testUserA){
            Case kase = new Case();
                    kase.RecordTypeId = SalesHelpRequestFormController.retrieveSalesHelpRT();
        kase.Type = caseType;
        kase.Sub_Type__c = CaseSubType;
        kase.Description = 'TestingCase';
        kase.Due_Date__c = Date.today() + 1;
        test.startTest();
        insert kase;
        test.stopTest();
        //Validate Case
        SalesHelpRequestFormController.ShValidationWrapper validationWrap = SalesHelpRequestFormController.validateForm(kase.Type, kase.Sub_Type__c);
        System.assertEquals(true, validationWrap.formValid);
        System.assertEquals(null, validationWrap.errorMessage);
        //Verify Case routed correctly
        Sales_Help_Request_Case__c shrc = SalesHelpRequestFormController.retrieveSHCS(kase.Type, kase.Sub_Type__c);
        Group GroupId = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Virtual Sales Help Request Queue' LIMIT 1];
        Case cs1 = [Select Id, OwnerId from Case where Id=:kase.Id];
        System.assertNotEquals(GroupId.Id, cs1.OwnerId);
        }
    }
    static testMethod void testVirtualRouting(){
        String caseType = 'General';
        String CaseSubType = 'Touchpoint';
        //Test Virtual
        User testUser = [Select Id, Name, Sales_Division__c, Sales_Org__c, Profile.Name, UserRole.Name
                         from User Where IsActive=true
                         and (UserRole.Name like '%Virtual%' AND UserRole.Name NOT in ('PEO Virtual Sales') AND Profile.Name like '%Manager%')  limit 1];
            System.RunAs(testUser){
            Case newCase = new Case();
            newCase.RecordTypeId = SalesHelpRequestFormController.retrieveSalesHelpRT();
            newCase.Type = caseType;
            newCase.Sub_Type__c = CaseSubType;
            newCase.Description = 'TestingCase';
            newCase.Due_Date__c = Date.today() + 1;
            test.startTest();
            insert newCase;
            test.stopTest();
            //Validate Case
            SalesHelpRequestFormController.ShValidationWrapper validationWrap = SalesHelpRequestFormController.validateForm(newCase.Type, newCase.Sub_Type__c);
            System.assertEquals(true, validationWrap.formValid);
            System.assertEquals(null, validationWrap.errorMessage);
            //Verify Case routed correctly
            Sales_Help_Request_Case__c shrc = SalesHelpRequestFormController.retrieveSHCS(newCase.Type, newCase.Sub_Type__c);
            Group GroupId = [SELECT Id, Name FROM Group WHERE Type = 'Queue' AND Name = 'Virtual Sales Help Request Queue' LIMIT 1];
            Case cs2 = [Select Id, OwnerId from Case where Id=:newCase.Id];
            //System.assertEquals(GroupId.Id, cs2.OwnerId);
        }
    }
    static testMethod void testValidationMessage(){
        SalesHelpRequestFormController.ShValidationWrapper validationWrap = SalesHelpRequestFormController.validateForm('Contest Approval', 'Contest Approval (Management Only)');
        System.assertEquals(true, validationWrap.formValid);
        System.assertEquals(CaseTranslatedMessage, validationWrap.errorMessage);
        System.assertEquals(CaseURL, validationWrap.urlLink);
    }
    static testMethod void testPermissionsValidation(){
        User testUser = [Select Id, Name, Sales_Division__c, Sales_Org__c, Profile.Name, UserRole.Name
                         from User Where IsActive=true and Sales_Org__c=:UserHelper.SO_CORE 
                         and (UserRole.Name like 'CORE SALES REP%' or UserRole.Name like 'SMB Sales Rep%')  limit 1];
        System.RunAs(testUser){
            SalesHelpRequestFormController.ShValidationWrapper validationWrap = SalesHelpRequestFormController.validateForm('Sales Enablement Request', '');
            System.assertEquals(false, validationWrap.formValid);
        }
    }
        
}