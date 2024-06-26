/* 
    History
    --------
    
    9/25/201 Josh Cartwright    created
    06/03/2020 Matthew Fritschi Added test for the new Error Message
    10/09/2020 Brandon Vidro    Added to testMessages() for APR0109682 - PRN for MMS - Preview Client error message
    05/18/2021 Carrie Marciano  updated StageNames with OppStage labels
*/  
@isTest
public class PaychexAccountAdvocateInfoControllerTest {
   
        
   static testMethod void testSigContact() {
        Account acct1 = new account (name = 'test acct1', AccountNumber='11-1111');
        insert acct1; 
 
        Contact cntct1 = new contact (firstName = 'ct1', lastName='ct1LN', accountId =acct1.id);
        Contact cntct2 = new contact (firstName = 'ct2', lastName='ct2LN', accountId =acct1.id);
        Contact[] cntcts = new Contact []{cntct1, cntct2};
        insert cntcts;     

        acct1.SignificantContact__c = cntct1.id;
        update acct1;
       
        Opportunity opp1 = new Opportunity(Name = 'Test Opp', AccountId=acct1.Id, StageName=label.OppStage_Won, CloseDate=System.Date.today()+1);
        insert opp1;
       
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(acct1);
        PaychexAccountAdvocateInfoController PAAIC = new PaychexAccountAdvocateInfoController(sc); 
        
        system.assertEquals(null, PAAIC.displayMessage);
        system.assertequals(cntct1.id, PAAIC.sigContact.id);     
        system.assertequals(PAAIC.allCtList.size(),2);  
        
        PAAIC.changeContact(); 
        system.assert(PAAIC.swapContact); 
        PAAIC.selectedCtctID = cntct2.id;  
        PAAIC.saveContact();  
        acct1 = [select id,SignificantContact__c from account where name = 'test acct1']; 
        system.assertequals(acct1.SignificantContact__c, cntct2.id); 
        
        PAAIC.changeContact(); 
        PAAIC.cancel();
        system.assertequals(PAAIC.swapContact, false); 
       
       
    }//testSigContact
       
     static testMethod void testMessages() {
        Account acct1 = new account (name = 'test acct1', AccountNumber=null);
        insert acct1;  
        update acct1;     
        
        ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(acct1);
        PaychexAccountAdvocateInfoController PAAIC1 = new PaychexAccountAdvocateInfoController(sc1); 
        system.assertEquals(PAAIC1.displayMessage, 'This Prospect is not ready for Paychex Referral Network. Eligibility will be available during the "Verbal Commit" status.' );
         
        Opportunity opp1 = new Opportunity(Name = 'Test Opp', AccountId=acct1.Id, StageName=label.OppStage_Won, CloseDate=System.Date.today()+1);
        insert opp1;
         
        ApexPages.Standardcontroller sc2 = New ApexPages.StandardController(acct1);
        PaychexAccountAdvocateInfoController PAAIC2 = new PaychexAccountAdvocateInfoController(sc2); 
        system.assertEquals(PAAIC2.displayMessage, 'No Significant Contact! You must create a contact record before proceeding.' );
         
        Contact con = new Contact(
             FirstName='FirstNameTest',
             LastName='LastNameTest',
             Email = 'Email@test.com',
             Decision_Maker__c = true,
             AccountId=acct1.ID);
        insert con; 
         
        acct1.SignificantContact__c = con.Id;
        acct1.Type = 'Preview Client';
        update acct1;   
         
        ApexPages.Standardcontroller sc3 = New ApexPages.StandardController(acct1);
        PaychexAccountAdvocateInfoController PAAIC3 = new PaychexAccountAdvocateInfoController(sc3); 
        system.debug(PAAIC3.displayMessage); 
        system.assertEquals(PAAIC3.displayMessage, 'Preview clients are not eligible for Paychex Referral Network'); 
         
        acct1.Type = 'Prospect';
        update acct1;
         
        ApexPages.Standardcontroller sc4 = New ApexPages.StandardController(acct1);
        PaychexAccountAdvocateInfoController PAAIC4 = new PaychexAccountAdvocateInfoController(sc4); 
        system.assertEquals(PAAIC4.displayMessage, null);
     }
    
}//PaychexAccountAdvocateInfoControllerTest