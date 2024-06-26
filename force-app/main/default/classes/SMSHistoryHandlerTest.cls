/* Test Method for UpdateOppFieldsQueueable
*
*History
*----------------
* 
*   08/09/2023 Jaipal      Created
    01/17/2024 Lalan       APR0162915 SMS Conversation Box - Opportunity View
   

*/
@isTest
public class SMSHistoryHandlerTest 
{
    static testMethod void TestList1() {
        String squishedCntctPhone;
        Map<Id, tdc_tsw__Message__c> oldSMSMap;
        Map<Id, tdc_tsw__Message__c> newSMSMap;
        Boolean isInsert;
        Boolean isUpdate;
        Test.startTest();
        Contact cntct1 = new Contact(FirstName = 'Test Contact', LastName = 'Contact 1', DoNotCall = false, Email = 'c1a1@whoknows.com', HasOptedOutOfEmail = false, HR_Person_Id__c = 'TEST000', Phone = '123456789', MobilePhone = '467928238765');
        insert cntct1;
        
        Contact cntct2 = new Contact(FirstName = 'Test', LastName = 'Contact 2', DoNotCall = false,Phone = '9876543210',Consent_to_Text__c = true, tdc_tsw__SMS_Opt_out__c = true, MobilePhone = '4679288765');
        insert cntct2;
        
        Lead ld1 = new Lead(Company='Test1', FirstName='username1', LastName= 'LeadTest', PostalCode='12345', Status=LeadOnlineSetup.STATUS_OPEN, Mthd_Lead_Rcvd__c=LeadOnlineSetup.CHECK_METHOD);
        insert ld1;

        Lead ld2 = new Lead(Company='Test2', FirstName='username2', LastName= 'LeadTest1', PostalCode='12345', Status=LeadOnlineSetup.STATUS_OPEN, Mthd_Lead_Rcvd__c=LeadOnlineSetup.CHECK_METHOD, Consent_to_Text__c = True, tdc_tsw__SMS_Opt_out__c = true, Phone = '523145789', MobilePhone = '4679765');
        insert ld2;
        
        //APR0162915 -Inserted Account, Oppty and OpportunityContactRole
        Account acct = new Account(Name='test acct');
        insert acct;
        Opportunity opp = new Opportunity(Name='test Opp',AccountId=acct.Id,StageName=Label.OppStage_Qualified,Probability= 60,CloseDate = date.today().addDays(80),Auto_Close_Date__c=date.today(),ownerId=UserInfo.getUserId());
		insert opp;
        OpportunityContactRole ocr = new OpportunityContactRole(ContactId=cntct2.Id, OpportunityId=opp.Id, IsPrimary=true);
        insert ocr;
        
        tdc_tsw__Message__c smsHist1 = new tdc_tsw__Message__c(Name = 'Incoming', tdc_tsw__Contact__c = cntct1.id, tdc_tsw__Lead__c = ld1.id,tdc_tsw__Opportunity__c = opp.id, tdc_tsw__Sender_Number__c = '123456789');
        insert smsHist1;
        
        tdc_tsw__Message__c smsHist2 = new tdc_tsw__Message__c(Name = 'Outgoing', tdc_tsw__Contact__c = cntct2.Id, tdc_tsw__Lead__c = ld2.id, tdc_tsw__Sender_Number__c = '63214598');
        insert smsHist2;
        tdc_tsw__Message__c smsHist3 = new tdc_tsw__Message__c(Name = 'Outgoing', tdc_tsw__Opportunity__c = opp.Id, tdc_tsw__Lead__c = ld2.id, tdc_tsw__Sender_Number__c = '63214598');
        insert smsHist3;
        
        squishedCntctPhone = Utilities.removeExtraChars(smsHist1.tdc_tsw__Contact__r.Phone, '0123456789');
        
        cntct1.Phone = '1234567890';
        cntct1.MobilePhone = '1234567890';
      //  cntct1.Consent_to_Text__c = True;
        cntct1.Consent_to_Text_Date__c= DateTime.now();
        cntct1.Consent_to_Text_reason__c = 'Prospect Opt In Via Text';
        cntct1.tdc_tsw__SMS_Opt_out__c = False;
        update cntct1;
        
        ld1.Phone = '127890';
        ld1.MobilePhone = '1237890';
      //  cntct1.Consent_to_Text__c = True;
        ld1.Consent_to_Text_Date__c= DateTime.now();
        ld1.Consent_to_Text_reason__c = 'Prospect';
        ld1.tdc_tsw__SMS_Opt_out__c = False;
        update ld1;
        
        smsHist1.tdc_tsw__Sender_Number__c = cntct1.Phone;
        smsHist1.Name = 'Incoming';
        smsHist1.tdc_tsw__Contact__c = cntct1.Id;
        smsHist1.tdc_tsw__Lead__c = ld1.Id;
        update smsHist1;	
        
        smsHist2.tdc_tsw__Sender_Number__c = ld2.Phone;
        smsHist2.Name = 'Outgoing';
        smsHist2.tdc_tsw__Contact__c = cntct2.Id;
        smsHist2.tdc_tsw__Lead__c = ld2.Id;
        update smsHist2;	
        
         SMSHistoryHandler smsHandler = new SMSHistoryHandler();
      //  SMSHistoryHandler.clearVariables();
        
    //   smsHandler.updateContactLead(null, null, null, null);
        Test.stopTest();
        system.assertEquals(smsHist1.tdc_tsw__Sender_Number__c, cntct1.Phone);
      //  system.assertEquals(true, smsHist.tdc_tsw__Contact__r.Consent_to_Text__c);
     //   system.debug(smsHist.tdc_tsw__Contact__r.Consent_to_Text__c+smsHist.tdc_tsw__Sender_Number__c);
      //  system.assertEquals(true, smsHist.tdc_tsw__Contact__r.Consent_to_Text__c);
        
    }//TestList1
}//SMSHistoryHandlerTest