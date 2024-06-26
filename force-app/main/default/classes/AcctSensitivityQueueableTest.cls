/* 
 * Test methods for AcctSensitivityQueueable
 *
 * History
 * -------
11/02/2018 Dan Carmen       Created
08/11/2021 Dan Carmen       Fix logging
12/22/2023 Dan Carmen       Add additional check for launching the queueable

*/
@isTest
private class AcctSensitivityQueueableTest {
   
   @testSetup
   public static void setupData() {
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = 'AcctSensitivityQueueable', Active__c = true, BatchSize__c=6, SendCompletionEmail__c=true);
      insert abc;
      
      ReferralAccountMethodsTest.setupSensitivityCustomSetting();
      ZipCheckOwner.SKIP_TRIGGERS=true;
      
      Schema.RecordTypeInfo rtInfo = RecordTypeHelper.getRecordType(RecordTypeHelper.CHANNEL_REFERRAL_ACCOUNT, ObjectHelper.OBJECT_REF_ACCOUNT);
      
      Referral_Account__c refAcct1 = new Referral_Account__c(Name='Test RefAcct1', Sensitivity_401_k__c=false, Sensitivity_FSA__c=false, Sensitivity_Wrks_Comp__c=false );
      Referral_Account__c refAcct2 = new Referral_Account__c(Name='Test RefAcct2', Sensitivity_401_k__c=false, Sensitivity_FSA__c=false, Sensitivity_Wrks_Comp__c=false );
      Referral_Account__c refAcct3 = new Referral_Account__c(Name='Test RefAcct3', Sensitivity_401_k__c=false, Sensitivity_FSA__c=false, Sensitivity_Wrks_Comp__c=false );
      Referral_Account__c refAcct4 = new Referral_Account__c(Name='Test RefAcct4', Sensitivity_401_k__c=false, Sensitivity_FSA__c=false, Sensitivity_Wrks_Comp__c=false );
      Referral_Account__c refAcct5 = new Referral_Account__c(Name='Test RefAcct5', Sensitivity_401_k__c=true, Sensitivity_FSA__c=false, Sensitivity_Wrks_Comp__c=false, RecordTypeId=rtInfo.getRecordTypeId() );
      Referral_Account__c[] refAccts = new Referral_Account__c[]{refAcct1,refAcct2,refAcct3,refAcct4,refAcct5};
      insert refAccts;

      Referral_Contact__c refCtct1 = new Referral_Contact__c(Name='Test RefCtct1', Referral_Account__c=refAcct1.Id
                                                            ,Sensitivity_401_k__c=true, Sensitivity_FSA__c=false, Sensitivity_Wrks_Comp__c=false);
      Referral_Contact__c refCtct2 = new Referral_Contact__c(Name='Test RefCtct2', Referral_Account__c=refAcct2.Id
                                                            ,Sensitivity_401_k__c=false, Sensitivity_FSA__c=true, Sensitivity_Wrks_Comp__c=false);
      Referral_Contact__c refCtct3 = new Referral_Contact__c(Name='Test RefCtct3', Referral_Account__c=refAcct3.Id
                                                            ,Sensitivity_401_k__c=false, Sensitivity_FSA__c=false, Sensitivity_Wrks_Comp__c=true);
      Referral_Contact__c refCtct4 = new Referral_Contact__c(Name='Test RefCtct4', Referral_Account__c=refAcct4.Id
                                                            ,Sensitivity_401_k__c=true, Sensitivity_FSA__c=true, Sensitivity_Wrks_Comp__c=false);
      Referral_Contact__c refCtct5 = new Referral_Contact__c(Name='Test RefCtct5', Referral_Account__c=refAcct5.Id
                                                            ,Sensitivity_401_k__c=false, Sensitivity_FSA__c=false, Sensitivity_Wrks_Comp__c=false);
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2,refCtct3,refCtct4,refCtct5};
      insert refCtcts;
      
   } // setupData
   
   public static Referral_Contact__c[] getRefCtcts() {
      Referral_Contact__c[] refCtcts = [Select Id, Name
                                              ,Sensitivity_401_k__c
                                              ,Sensitivity_FSA__c
                                              ,Sensitivity_Wrks_Comp__c
                                              ,Referral_Account__c
                                              ,Referral_Account__r.Id
                                              ,Referral_Account__r.Name
                                              ,Referral_Account__r.Sensitivity_401_k__c
                                              ,Referral_Account__r.Sensitivity_FSA__c
                                              ,Referral_Account__r.Sensitivity_Wrks_Comp__c
                                          From Referral_Contact__c
                                         Where Name like 'Test RefCtct%'
                                         order by Name];
      return refCtcts;
   } // getRefCtcts;

   static testMethod void testQueueable() {
      Referral_Contact__c[] refCtcts = getRefCtcts();
      Account acct1 = new Account(Name='Acct1', Banker_Name_Ref__c=refCtcts[0].Id, Broker_Name_Ref__c=refCtcts[1].Id, CPA_Name_Ref__c=refCtcts[2].Id, Referral_National_Account__c=refCtcts[4].Referral_Account__c);
      Account acct2 = new Account(Name='Acct2', Broker_Name_Ref__c=refCtcts[1].Id);
      Account acct3 = new Account(Name='Acct3', CPA_Name_Ref__c=refCtcts[2].Id);
      Account acct4 = new Account(Name='Acct4', Referral_National_Account__c=refCtcts[4].Referral_Account__c);
      Account acct5 = new Account(Name='Acct5', SensitivityList__c='Prod1,Prod2');
      Account acct6 = new Account(Name='Acct6', SensitivityList__c='401k');
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5,acct6};
      ZipCheckOwner.SKIP_TRIGGERS=true;
      insert accts;
      
      Id[] acctIds = new Id[]{acct1.Id,acct2.Id,acct3.Id,acct4.Id,acct5.Id,acct6.Id};
      
      Account_Product_Sensitivities__c aps = new Account_Product_Sensitivities__c(Name='APS1', Oasis_401k_Sensitivity__c=true, Prospect_Client__c=acct6.Id);
      insert aps;
      
      AcctSensitivityQueueable.RUNNING_TEST=false;
      Test.StartTest();
      AcctSensitivityQueueable.launchQueueable(acctIds);
      Test.StopTest();
      
      ProductSensitivityFields__c psf401 = ProductSensitivityFields__c.getInstance('Sensitivity_401_k__c');
      ProductSensitivityFields__c psfFSA = ProductSensitivityFields__c.getInstance('Sensitivity_FSA__c');
      ProductSensitivityFields__c psfWrk = ProductSensitivityFields__c.getInstance('Sensitivity_Wrks_Comp__c');
      ProductSensitivityFields__c psfOasis401k = ProductSensitivityFields__c.getInstance('Oasis_401k_Sensitivity__c');
      System.debug('testQueueable psf401='+psf401);
      System.debug('testQueueable psfFSA='+psfFSA);
      System.debug('testQueueable psfWrk='+psfWrk);
      System.debug('testQueueable psfOasis401k='+psfOasis401k);
                  
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, SensitivityList__c from Account where Id in :accts]);
      System.debug('testQueueable acctMap='+acctMap.size());
      Account acct1Chk = acctMap.get(acct1.Id);
      System.debug('testQueueable acct1Chk='+acct1Chk);
      System.assertEquals(true, String.isNotBlank(acct1Chk.SensitivityList__c));
      System.assertEquals(true, acct1Chk.SensitivityList__c.contains(psf401.Label__c));
      System.assertEquals(true, acct1Chk.SensitivityList__c.contains(psfFSA.Label__c));
      System.assertEquals(true, acct1Chk.SensitivityList__c.contains(psfWrk.Label__c));
      
      Account acct2Chk = acctMap.get(acct2.Id);
      System.debug('testQueueable acct2Chk='+acct2Chk);
      System.assertEquals(true, String.isNotBlank(acct2Chk.SensitivityList__c));
      System.assertEquals(false, acct2Chk.SensitivityList__c.contains(psf401.Label__c));
      System.assertEquals(true, acct2Chk.SensitivityList__c.contains(psfFSA.Label__c));
      System.assertEquals(false, acct2Chk.SensitivityList__c.contains(psfWrk.Label__c));
      
      Account acct3Chk = acctMap.get(acct3.Id);
      System.debug('testQueueable acct3Chk='+acct3Chk);
      System.assertEquals(true, String.isNotBlank(acct3Chk.SensitivityList__c));
      System.assertEquals(false, acct3Chk.SensitivityList__c.contains(psf401.Label__c));
      System.assertEquals(false, acct3Chk.SensitivityList__c.contains(psfFSA.Label__c));
      System.assertEquals(true, acct3Chk.SensitivityList__c.contains(psfWrk.Label__c));
      
      Account acct4Chk = acctMap.get(acct4.Id);
      System.debug('testQueueable acct4Chk='+acct4Chk);
      System.assertEquals(true, String.isNotBlank(acct4Chk.SensitivityList__c));
      System.assertEquals(true, acct4Chk.SensitivityList__c.contains(psf401.Label__c));
      System.assertEquals(false, acct4Chk.SensitivityList__c.contains(psfFSA.Label__c));
      System.assertEquals(false, acct4Chk.SensitivityList__c.contains(psfWrk.Label__c));
      
      Account acct5Chk = acctMap.get(acct5.Id);
      System.debug('testQueueable acct5Chk='+acct5Chk);
      System.assertEquals(true, String.isBlank(acct5Chk.SensitivityList__c));
       
      Account acct6Chk = acctMap.get(acct6.Id);
      System.debug('testQueueable acct6Chk='+acct6Chk);
      System.assertEquals(true, acct6Chk.SensitivityList__c.contains(psfOasis401k.Label__c));
      
   } // testQueueable
   
   
} // class AcctSensitivityQueueableTest