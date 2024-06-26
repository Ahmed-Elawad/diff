/* 
   Test methods for AmplifnityReferralBatch class
   
  History
  -------
  09/05/2019 Josh Cartwright Created
  10/15/2019 Dan Carmen      Change name of test batch
   
 */
@isTest
public class AmplifnityReferralBatchTest {
   

   static testMethod void testData() {
   //jc need to insert leads check status 
      date aRDate = system.today().adddays(-125); 
	  date opptyclosedate = system.today().adddays(-10); 	   
      string notSold =''; 
   	  
      Account a1 = new Account(Name='Test Account 1');
      Account a2 = new Account(Name = 'Test Advocate'); 
      Account[] accts = new Account[]{a1, a2};
      insert accts;
      
      amp_dev__Amp_Advocate__c amp1 = new amp_dev__Amp_Advocate__c (Name = 'Test Advocate',Account__c = a2.id); 
      insert amp1; 
       
      Contact c1_a1 = new Contact(FirstName='Test Account1',LastName='Contact 1', AccountId=a1.Id, Sales_Contact__c=true);
      Contact[] ctcts = new Contact[]{c1_a1};
      insert ctcts;
      
      Opportunity o1 = new Opportunity(Name='Test Oppty', AccountId = a1.id, StageName ='Sold', CloseDate = opptyclosedate); 
      insert o1; 
       
      amp_dev__Amp_Referral__c aR1 = new amp_dev__Amp_Referral__c (amp_dev__Last_Name__c='Test1', Name ='1234', createdDate = aRDate, Open_Close_Status__c = 'Open', amp_dev__Status__c ='Accepted' ); 
   	  amp_dev__Amp_Referral__c aR2 = new amp_dev__Amp_Referral__c (amp_dev__Last_Name__c='Test2', Name ='1234', createdDate = aRDate, amp_dev__Opportunity__c =  o1.id, Open_Close_Status__c = 'Open'); 
      amp_dev__Amp_Referral__c[] ARs = new amp_dev__Amp_Referral__c[]{aR1, ar2}; 
      insert ARs; 
       
   	  Lead l1 = new Lead(LastName='Test1',Company='Test1 Co',Product_Division__c='MMS',NumberOfEmployees=60, PostalCode='12345', amp_dev__Referral__c =aR1.Id);
      Lead l2 = new Lead(LastName='Test1',Company='Test1 Co',Product_Division__c='MMS',NumberOfEmployees=60, PostalCode='12345');
      lead[] lds = new lead[]{l1,l2}; 
      insert lds;    
        
      Test.startTest();
      Database.executeBatch(new AmplifinityReferralBatch());
      Test.stopTest();
      
      Amplifinity_AR_Status_Mapping__mdt[] statusMapping = [select MasterLabel, AR_Status__c, AMP_Status__c, Allow_Updates__c from Amplifinity_AR_Status_Mapping__mdt where label ='Not sold']; 
      notSold =statusMapping[0].AMP_Status__c; 
       
      aR1 = [Select Id, amp_dev__Status__c ,Open_Close_Status__c from amp_dev__Amp_Referral__c where Id=:aR1.Id];
      system.assertEquals('Closed', aR1.Open_Close_Status__c);  
      System.assertEquals(notSold, aR1.amp_dev__Status__c);
//      aR2 = [Select Id,amp_dev__Status__c, Open_Close_Status__c from amp_dev__Amp_Referral__c where Id=:aR2.Id ];
  //    System.assertEquals('Successful',aR2.amp_dev__Status__c);

            
   } // testData
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('AmplifinityReferralBatchTest', new AmplifinityReferralBatch());
   } // testScheduler

} // class AmplifnityReferralBatchTest