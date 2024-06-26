/* Test methods for HoldOutAcctBatch class
   
  History
  -------
  04/24/2015 Dan Carmen      Created
  07/17/2019 Dan Carmen      Modify to tune up SQL
  10/28/2019 Josh Cartwright added lead test 
  

 */
@isTest
private class HoldOutAcctBatchTest {
   
   @testSetup()
   public static void setupData() {
      HoldOutExpirationMethodsTest.setupData();
      Apex_Batch_Control__c abc = new Apex_Batch_Control__c(name = HoldOutAcctBatch.CLASS_NAME, Active__c = true, BatchSize__c=100);
      insert abc; 
   }

   static testMethod void testBatch() {
      HoldOutExpirationMethodsTest.populateSetting();
      String testZip = '14624';
      Id[] excludeUserIds = new Id[]{};
      //Map<String,List<Zip_Assignment__c>> zaListMap = ZipCheckOwnerTest.getZaMapList(testZip, excludeUserIds);
      
      //Zip_Assignment__c zaPay = zaListMap.get(UserHelper.SO_CORE)[0];
      //Zip_Assignment__c zaHrs = zaListMap.get(UserHelper.SO_401)[0];
      //Zip_Assignment__c zaPas = zaListMap.get(UserHelper.SO_PEO_ASO)[0];
      //Zip_Assignment__c zaHnb = zaListMap.get(UserHelper.SO_HNB)[0];
      
      User[] reps = [Select Id, Name, UserRoleId, UserRole.ParentRoleId 
                    ,Sales_Org__c, District__c, District_Name__c
                from User 
               where IsActive=true 
                 and Sales_Org__c=:UserHelper.SO_CORE 
                 and Profile.Name in :Utilities.REP_PROFS 
                 and Id not in :excludeUserIds
               limit 6];
      User rep1=reps[0];
      User rep2=reps[1];
      User rep3=reps[2];
      User rep4=reps[3];
      User rep5=reps[4];
      User rep6=reps[5];
      
      Date holdOutDate = Date.today().addDays(-2);
      Date holdOutDate2 = Date.today().addDays(2);
      
      Account acct1 = new Account(Name='Test Acct1', ShippingPostalCode=testZip
              ,OwnerId=rep1.Id ,Hold_Out__c=true, Hold_Out_Expiration__c=holdOutDate, Permanent_Hold_Out_Description__c=null
              ,HNBF_Account_Owner__c=rep2.Id,HNBF_Hold_Out__c=true,HNBF_Hold_Out_Expiration__c=holdOutDate
              ,HRS_Account_Owner__c=rep3.Id, HRS_Hold_Out__c=true, HRS_Hold_Out_Expiration__c=holdOutDate
              ,Premier_PBS_Account_Owner__c=rep4.Id,Premier_PBS_Hold_Out__c=true,Premier_PBS_Hold_Out_Expiration__c=holdOutDate,MS_Hold_Out__c=true,MS_Hold_Out_Expiration__c=holdoutDate);

      Account acct2 = new Account(Name='Test Acct2', ShippingPostalCode=testZip
              ,OwnerId=rep1.Id ,Hold_Out__c=true, Hold_Out_Expiration__c=holdOutDate, Permanent_Hold_Out_Description__c=null
              ,HNBF_Account_Owner__c=rep6.Id,HNBF_Hold_Out__c=false,HNBF_Hold_Out_Expiration__c=null
              ,HRS_Account_Owner__c=rep6.Id, HRS_Hold_Out__c=false, HRS_Hold_Out_Expiration__c=null
              ,Premier_PBS_Account_Owner__c=rep4.Id,Premier_PBS_Hold_Out__c=true,Premier_PBS_Hold_Out_Expiration__c=holdOutDate,MS_Hold_Out__c=true,MS_Hold_Out_Expiration__c=holdoutDate);

      Account acct3 = new Account(Name='Test Acct3', ShippingPostalCode=testZip
              ,OwnerId=rep1.Id ,Hold_Out__c=true, Hold_Out_Expiration__c=holdOutDate, Permanent_Hold_Out_Description__c=null
              ,HNBF_Account_Owner__c=rep2.Id,HNBF_Hold_Out__c=true,HNBF_Hold_Out_Expiration__c=holdOutDate2
              ,HRS_Account_Owner__c=rep3.Id, HRS_Hold_Out__c=true, HRS_Hold_Out_Expiration__c=holdOutDate2
              ,Premier_PBS_Account_Owner__c=rep4.Id,Premier_PBS_Hold_Out__c=true,Premier_PBS_Hold_Out_Expiration__c=holdOutDate,MS_Hold_Out__c=true,MS_Hold_Out_Expiration__c=holdoutDate);

      Account acct4 = new Account(Name='Test Acct4', ShippingPostalCode=testZip
              ,OwnerId=rep6.Id ,Hold_Out__c=false, Hold_Out_Expiration__c=null, Permanent_Hold_Out_Description__c=null
              ,HNBF_Account_Owner__c=rep6.Id,HNBF_Hold_Out__c=false,HNBF_Hold_Out_Expiration__c=null
              ,HRS_Account_Owner__c=rep6.Id, HRS_Hold_Out__c=false, HRS_Hold_Out_Expiration__c=null
              ,Premier_PBS_Account_Owner__c=rep6.Id,Premier_PBS_Hold_Out__c=false,Premier_PBS_Hold_Out_Expiration__c=null,MS_Hold_Out__c=true,MS_Hold_Out_Expiration__c=holdoutDate);
      
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4};
      insert accts;
      
      Contact ctct1 = new Contact(AccountId=acct2.Id, LastName='Last1', Hold_Out__c=true, Hold_Out_Expiration__c=holdOutDate);
      Contact ctct2 = new Contact(AccountId=acct4.Id, LastName='Last2', Hold_Out__c=true, Hold_Out_Expiration__c=holdOutDate);
      Contact[] ctcts = new Contact[]{ctct1, ctct2};
      insert ctcts;
      
      HoldOutAcctBatch hoab = new HoldOutAcctBatch();
      Test.startTest();
      Database.executeBatch(hoab,12);
      Test.stopTest();
      
      Map<Id,Account> acctMap = new Map<Id,Account>([Select Id, Name, ShippingPostalCode
                            ,OwnerId,Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c
                            ,HNBF_Account_Owner__c,HNBF_Hold_Out__c,HNBF_Hold_Out_Expiration__c
                            ,HRS_Account_Owner__c, HRS_Hold_Out__c, HRS_Hold_Out_Expiration__c
                            ,Premier_PBS_Account_Owner__c,Premier_PBS_Hold_Out__c,Premier_PBS_Hold_Out_Expiration__c,MS_Hold_Out__c,MS_Hold_Out_Expiration__c
                        from Account]);
      
      acct1 = acctMap.get(acct1.Id);
      //System.assertEquals(zaPay.User__c,acct1.OwnerId);
      System.assertEquals(false,acct1.Hold_Out__c);
      System.assertEquals(null,acct1.Hold_Out_Expiration__c);
      //System.assertEquals(zaHrs.User__c,acct1.HRS_Account_Owner__c);
      System.assertEquals(false,acct1.HRS_Hold_Out__c);
      System.assertEquals(null,acct1.HRS_Hold_Out_Expiration__c);
      //System.assertEquals(zaHnb.User__c,acct1.HNBF_Account_Owner__c);
      System.assertEquals(false,acct1.HNBF_Hold_Out__c);
      System.assertEquals(null,acct1.HRS_Hold_Out_Expiration__c);
      //System.assertEquals(zaPas.User__c,acct1.Premier_PBS_Account_Owner__c);
      System.assertEquals(false,acct1.Premier_PBS_Hold_Out__c);
      System.assertEquals(null,acct1.Premier_PBS_Hold_Out_Expiration__c);
      
      System.assertEquals(false,acct1.MS_Hold_Out__c);
      System.assertEquals(null,acct1.MS_Hold_Out_Expiration__c);
      
      acct2 = acctMap.get(acct2.Id);
      //System.assertEquals(zaPay.User__c,acct2.OwnerId);
      System.assertEquals(false,acct2.Hold_Out__c);
      System.assertEquals(null,acct2.Hold_Out_Expiration__c);
      //System.assertEquals(zaHrs.User__c,acct2.HRS_Account_Owner__c);
      System.assertEquals(false,acct2.HRS_Hold_Out__c);
      System.assertEquals(null,acct2.HRS_Hold_Out_Expiration__c);
      //System.assertEquals(zaHnb.User__c,acct2.HNBF_Account_Owner__c);
      System.assertEquals(false,acct2.HNBF_Hold_Out__c);
      System.assertEquals(null,acct2.HRS_Hold_Out_Expiration__c);
      //System.assertEquals(zaPas.User__c,acct2.Premier_PBS_Account_Owner__c);
      System.assertEquals(false,acct2.Premier_PBS_Hold_Out__c);
      System.assertEquals(null,acct2.Premier_PBS_Hold_Out_Expiration__c);
      
      System.assertEquals(false,acct2.MS_Hold_Out__c);
      System.assertEquals(null,acct2.MS_Hold_Out_Expiration__c);
      
      acct3 = acctMap.get(acct3.Id);
      //System.assertEquals(zaPay.User__c,acct3.OwnerId);
      System.assertEquals(false,acct3.Hold_Out__c);
      System.assertEquals(null,acct3.Hold_Out_Expiration__c);
      //System.assertEquals(rep3.Id,acct3.HRS_Account_Owner__c);
      System.assertEquals(true,acct3.HRS_Hold_Out__c);
      System.assertEquals(holdOutDate2,acct3.HRS_Hold_Out_Expiration__c);
      //System.assertEquals(rep2.Id,acct3.HNBF_Account_Owner__c);
      System.assertEquals(true,acct3.HNBF_Hold_Out__c);
      System.assertEquals(holdOutDate2,acct3.HRS_Hold_Out_Expiration__c);
      //System.assertEquals(zaPas.User__c,acct3.Premier_PBS_Account_Owner__c);
      System.assertEquals(false,acct3.Premier_PBS_Hold_Out__c);
      System.assertEquals(null,acct3.Premier_PBS_Hold_Out_Expiration__c);
      
      System.assertEquals(false,acct3.MS_Hold_Out__c);
      System.assertEquals(null,acct3.MS_Hold_Out_Expiration__c);
      
      acct4 = acctMap.get(acct4.Id);
      //System.assertEquals(rep6.Id,acct4.OwnerId);
      System.assertEquals(false,acct4.Hold_Out__c);
      System.assertEquals(null,acct4.Hold_Out_Expiration__c);
      //System.assertEquals(rep6.Id,acct4.HRS_Account_Owner__c);
      System.assertEquals(false,acct4.HRS_Hold_Out__c);
      System.assertEquals(null,acct4.HRS_Hold_Out_Expiration__c);
      //System.assertEquals(rep6.Id,acct4.HNBF_Account_Owner__c);
      System.assertEquals(false,acct4.HNBF_Hold_Out__c);
      System.assertEquals(null,acct4.HRS_Hold_Out_Expiration__c);
      //System.assertEquals(rep6.Id,acct4.Premier_PBS_Account_Owner__c);
      System.assertEquals(false,acct4.Premier_PBS_Hold_Out__c);
      System.assertEquals(null,acct4.Premier_PBS_Hold_Out_Expiration__c);
      
      System.assertEquals(false,acct4.MS_Hold_Out__c);
      System.assertEquals(null,acct4.MS_Hold_Out_Expiration__c);
      
      ctct1 = [Select Id, AccountId, LastName, Hold_Out__c, Hold_Out_Expiration__c from Contact where Id=:ctct1.Id];
      System.assertEquals(false,ctct1.Hold_Out__c);
      System.assertEquals(null,ctct1.Hold_Out_Expiration__c);
      
      ctct2 = [Select Id, AccountId, LastName, Hold_Out__c, Hold_Out_Expiration__c from Contact where Id=:ctct2.Id];
      System.assertEquals(false,ctct2.Hold_Out__c);
      System.assertEquals(null,ctct2.Hold_Out_Expiration__c);
      
   } // testBatch
   
   public static Account getAccount(Id acctId) {
      Account acct = [Select Id, Name, ShippingPostalCode
                            ,OwnerId,Hold_Out__c, Hold_Out_Expiration__c, Permanent_Hold_Out_Description__c
                            ,HNBF_Account_Owner__c,HNBF_Hold_Out__c,HNBF_Hold_Out_Expiration__c
                            ,HRS_Account_Owner__c, HRS_Hold_Out__c, HRS_Hold_Out_Expiration__c
                            ,Premier_PBS_Account_Owner__c,Premier_PBS_Hold_Out__c,Premier_PBS_Hold_Out_Expiration__c,MS_Hold_Out__c,MS_Hold_Out_Expiration__c
                        from Account where Id=:acctId];
      return acct;
   } // getAccount
   
   static testMethod void testScheduler() {
      TestHelper.testScheduler('HoldOutAcctBatch', new HoldOutAcctBatch());
   } // testScheduler

   static testMethod void testContacts() {
      HoldOutExpirationMethodsTest.populateSetting();
      Account acct = new Account(Name='Test Account');
      insert acct;
      
      Contact[] ctcts = new Contact[]{};
      Date hoDate = Date.today().addDays(-1);
      for (Integer cnt=0; cnt<10; cnt++) {
         Contact ctct = new Contact(AccountId=acct.Id, LastName='TestCtct'+cnt, Hold_Out__c=true, Hold_Out_Expiration__c=hoDate, Hold_Out_Reason__c='Test');
         ctcts.add(ctct);
      }
      insert ctcts;
      
      System.assertEquals(10, [select count() from Contact where Hold_Out__c=true]);
      
      HoldOutAcctBatch hoab = new HoldOutAcctBatch(HoldOutAcctBatch.MODE_CTCTS);
      Test.startTest();
      Database.executeBatch(hoab,100);
      Test.stopTest();
      
      System.assertEquals(10, [select count() from Contact where Hold_Out__c=false and Hold_Out_Expiration__c=null]);
      
   } // testContacts
    
    static testMethod void testLeads(){
      Date hoDate = Date.today().addDays(-1);

      Lead Ld1 = new Lead(FirstName='FN1', LastName='LN1', Company = 'Company1', Hold_Out_Expiration__c =hoDate, Hold_Out__c = true, Hold_Out_Reason__c='Test');
      insert Ld1;     

    System.assertEquals(1, [select count() from Lead where Hold_Out__c=true]);
    HoldOutAcctBatch hoab = new HoldOutAcctBatch(HoldOutAcctBatch.MODE_LEADS);
    test.startTest();
    Database.executeBatch(hoab,100);
    test.stopTest();
        
    system.assertEquals (1, [select count() from Lead where Hold_Out__c=false]); 
        
        
    }//testLeads


} // class HoldOutAcctBatchTest