/** Test Methods for Attachments
 * 
 * History
 * -------
   09/12/2022 Dan Carmen         Created
   05/22/2023 Dan Carmen         Updated Quote test to set the Data Set name based on the cafsl__Embedded_CPQ_Settings__c
   08/01/2023 Dan Carmen         Removed call to OracleQuoteTriggerPayxHelperTest.setupOracleSetting(); in the setup since it's already called in EZOnboardingRegistrationTest.setupData()
 
 */
@isTest
public class AttachmentHandlerTest {

    @testSetup
    public static void setupData() {
        //Create Trigger Method 
        TriggerMethodsTest.createTriggerSetting('AttachmentTrigger', false, true, false, false, new String[]{'AttachmentHandler'});
        TriggerMethodsTest.saveSetupClasses();
        EZOnboardingRegistrationTest.setupData();
    } // setupData
    
    static testMethod void testSignedQuote() {
       User runningUser = UserHelper.getRunningUser();
       EZOnboardingRegistration.QUOTE_CREATED_BY = runningUser.Name;
        
       Opportunity testOpp = EZOnboardingRegistrationTest.getTestOpp(EZOnboardingRegistrationTest.OPP1);
       EZOnboardingRegistration.OppPathWrapper wrap = EZOnboardingRegistration.getOppPathInfo(testOpp.Id);
       System.assertEquals(false,wrap.docusignComplete);
       System.assertEquals(false,wrap.oppStageIsWon);
       System.assertEquals(false,wrap.ezComplete);
        
       cafsl__Embedded_CPQ_Settings__c setting = OracleQuoteTriggerPayxHelperTest.getOracleSetting();
       cafsl__Oracle_Quote__c newQuote = new cafsl__Oracle_Quote__c(Name=EZOnboardingRegistrationTest.OPP1, cafsl__Opportunity__c=testOpp.Id, cafsl__Account__c=testOpp.AccountId
                                                                   ,cafsl__Data_Set__c = setting.cafsl__Data_Set__c);
       insert newQuote;
       testOpp.Primary_Oracle_Quote__c = newQuote.Id;
       testOpp.StageName = label.OppStage_Won;
       testOpp.Probability=70;
       OpptyMethods.SKIP_OPPTY_TRIGGERS=true;
       update testOpp;
       wrap = EZOnboardingRegistration.getOppPathInfo(testOpp.Id);
       System.assertEquals(false,wrap.docusignComplete);
       System.assertEquals(true,wrap.oppStageIsWon);
       System.assertEquals(false,wrap.ezComplete);

       Blob b = Blob.valueOf('This is just some fun sample text');
       Attachment a = new Attachment(ParentId = testOpp.id
                                        ,Description = 'A very cool attachment'
                                        ,Name=testOpp.Name+' is now completed'
                                        ,Body=b);
       insert a;
       wrap = EZOnboardingRegistration.getOppPathInfo(testOpp.Id);
       System.assertEquals(true,wrap.docusignComplete);
       System.assertEquals(true,wrap.oppStageIsWon);
       System.assertEquals(true,wrap.ezComplete);
        
       CSO_Tracking__c tracker = [Select Id, QuoteSigned__c, QuoteSignedDate__c, ProcessNotes__c from CSO_Tracking__c where Opportunity__c=:testOpp.Id];
       System.assertEquals(true,tracker.QuoteSigned__c);
       System.assertNotEquals(null,tracker.QuoteSignedDate__c);
       System.assertEquals(true,tracker.ProcessNotes__c.contains('Marking Quote Signed through AttachmentHandler'));
    } // testSignedQuote
} // class AttachmentHandlerTest