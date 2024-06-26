/* 
 * test method for the CheckReferralsBatch 
 *
 * History
 * -------
   04/11/2017 Josh Cartwright   Created

 *
 */
 
@isTest
private class CheckReferralsBatchTest {
    
    static testMethod void testBatch(){ 
       // create ref account
       Referral_Account__c refA1 = createTestRefAcct('refAcct1'); 
       insert refA1; 
       
       ReferralObjectsSync.SKIP_SYNC=True; 
       
       // create ref contact
       Referral_Contact__c refC1 = createTestRefCntct ('RefCtct1', RefA1.id); 
       Referral_Contact__c refC2 = createTestRefCntct ('RefCtct2', RefA1.id); 
       Referral_Contact__c refC3 = createTestRefCntct ('RefCtct3', RefA1.id);     
       Referral_Contact__c[] refCntctList = new Referral_Contact__c []{refC1, refC2,refC3}; 
       
       insert refCntctList; 
       
       system.assertequals(refC1.Contact__c, null); 
       // assert to confirm contact field is null
       
       ReferralObjectsSync.SKIP_SYNC=false; 
       
         CheckReferralsBatch crb = new CheckReferralsBatch();
         Test.startTest();
         Database.executeBatch(crb,10);
         Test.stopTest();
       
    
    //after test, requery records assert = contact is populated 
    
    }//testBatch
    
    
    //method that creates a generic test referral account   
	public static Referral_Account__c createTestRefAcct(string name){
		
      return new Referral_Account__c(name = name
                                        ,Referral_Source_Business_Type__c = 'Broker Dealer'
                                        ,Street_Address_1__c = '911 Panorama Trail South'
                                        ,City__c = 'Rochester'
                                        ,State_Province__c = 'NY'
                                        ,Zip_Postal_Code__c = '14586');
   } // createTestRefAcct
	
	//method that creates a generic test referral contact  
    public static Referral_Contact__c createTestRefCntct(string name,id refAcct1){
    	
        return new Referral_Contact__c(name = name 
                                        ,Referral_Account__c = refAcct1
                                        ,Mailing_Street__c = '123'
                                        ,Mailing_City__c = 'Rochester'
                                        ,Mailing_State__c = 'NY'
                                        ,Mailing_Postal_Code__c = '14514'
                                        ,Mailing_Country__c = 'US');
    }
    
     static testMethod void testScheduler() {
      TestHelper.testScheduler('CheckReferralsBatch', new CheckReferralsBatch());
   } // testScheduler
   
     static testMethod void testJob() { 
     
     Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = CheckReferralsBatch.CHECKREFERRALS_BATCH, Active__c = true, Minutes_till_Launch__c =5  );
		insert abc; 
     
   
      CheckReferralsBatch.kickOffRefBatchJob(); 
      
      list<Apex_Batch_Control__c> abcList = [select Latest_Scheduled_Time__c from Apex_Batch_Control__c where Latest_Scheduled_Time__c >= :system.now()];
      
      system.assert (abcList[0].Latest_Scheduled_Time__c != null); 
      
      //for asert query custom setting, verify last run is populated 
     }//testjob
}//CheckReferralsBatchTest