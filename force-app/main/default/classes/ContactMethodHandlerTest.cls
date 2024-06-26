/* 
* Test Methods for the OpptyMethods class
*
* History
* -------
12/11/2023 Lalan kumar      Created

*/
@isTest(seeAllData=false)
public class ContactMethodHandlerTest {
    
    @testSetup
    public static void setup(){
        
        TriggerMethodsTest.createTriggerSetting('ContactAfter', false, true, false, false,new String[]{'ContactMethodHandler'});
        TriggerMethodsTest.saveSetupClasses();
        
    } // setup
    static testMethod void updateOppPhoneandConsentToTextTest(){
        
        User u1 = [Select Id, Name from User where (District__c='012' or District__c='031' or District__c='033') and IsActive=true limit 1];
        
        Account acct = new Account(Name='Test Send to HB Acct');
        insert acct;
        Contact ctct = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id,Consent_to_Text__c = true,MobilePhone = '7894561230');
        insert ctct;
        Contact ctct1 = new Contact(FirstName='Test', LastName='Contact', AccountId=acct.Id);
        insert ctct1;
        Opportunity oppty = new  Opportunity(Name='Test Oppty1',AccountId=acct.Id,OwnerId=u1.id,StageName=Label.OppStage_Qualified,CloseDate=Date.today().addDays(30));
        insert oppty;
        System.debug('Close Date' + oppty.IsClosed );
        OpportunityContactRole ocr = new OpportunityContactRole(ContactId=ctct.Id,OpportunityId=oppty.Id, IsPrimary=true);
        insert ocr; 
        // Contact ct1 = [Select Id, LastName, OwnedBy__c, OwnedByPrev__c, NSSOwnership__c from Contact where Id=:ctct.Id];
        OpportunityContactRole ocr1 = new OpportunityContactRole(ContactId=ctct1.Id,OpportunityId=oppty.Id, IsPrimary=true);
        insert ocr1; 
        ctct1.Consent_to_Text__c = true;
        ctct1.MobilePhone = '9894561230'; 
        update ctct1;
        
    }
    
}