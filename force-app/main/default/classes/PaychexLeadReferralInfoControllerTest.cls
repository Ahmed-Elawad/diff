/* 
	History
	--------
	
	10/02/2019 Josh Cartwright 	created

*/	
@isTest
public class PaychexLeadReferralInfoControllerTest {

        
   static testMethod void prnContact() {
   		Account acct1 = new account (name = 'test acct1', AccountNumber='11-1111' );
   		insert acct1; 
 		
        amp_dev__Amp_Referral__c aDR = new amp_dev__Amp_Referral__c (name = 'aDR1'); 
        insert aDR; 
       
	    Contact cntct1 = new contact (firstName = 'ct1', lastName='ct1LN', email='contact@email.com', accountId =acct1.id, AMP_Referral__c = aDR.id);
   		insert cntct1; 
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(cntct1);
        PaychexLeadReferralInfoController PLRIC = new PaychexLeadReferralInfoController(sc); 
        
        system.assert(PLRIC.ct != null);      
	
	}//prnContact
    
    static testMethod void prnLead(){
        lead ld = new lead (lastName ='ld',firstName = 'test', email='lead@email.com', Company = 'test Acct');
        insert ld; 
		
   		amp_dev__Amp_Referral__c aDR = new amp_dev__Amp_Referral__c (name = 'aDR1'); 
        insert aDR;         
        
        ApexPages.Standardcontroller sc = New ApexPages.StandardController(ld);
        PaychexLeadReferralInfoController PLRIC = new PaychexLeadReferralInfoController(sc); 
       
        system.assert(PLRIC.ld !=null); 
        
        PLRIC.submitReferral(); 
        system.assert(PLRIC.showPage = true);
        
        ld.amp_dev__Referral__c = aDr.Id; 
        update ld; 
        
        ApexPages.Standardcontroller sc1 = New ApexPages.StandardController(ld);
        PaychexLeadReferralInfoController PLRIC1 = new PaychexLeadReferralInfoController(sc);         
        system.assert(PLRIC1.showPage =true); 
        
        PaychexLeadReferralInfoController.AccountLookupComponentModel alcm = new PaychexLeadReferralInfoController.AccountLookupComponentModel();
        alcm.GetLookupId();
        alcm.GetLookupSObjectType(); 
              
        
    }//prnLead

}