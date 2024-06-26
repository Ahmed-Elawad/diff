/* Methods for working with cadence

 * History
 * -------
  07/01/2021 Eric Porter          Created
  08/03/2021 Dan Carmen           Change activity selection
  07/28/2022 Susmitha Somavarapu  Wholesaler and PEO - MutualClient Tab (US14 Clearslide)
  09/09/2022 Dan Carmen           Fixed queries for Strategic Accountant Firm, Accounting Firm, and Banks

*/
@isTest 
public class CadenceTouchpointExtensionTest {
   
   @testSetup
   public static void setupData() {
      ReferralObjectsSync.SKIP_SYNC=false;
      Referral_Account__c refAcct  = new Referral_Account__c(Name ='Hogwarts School of Witchcraft and Wizardry');
      insert refAcct;
      //set up referral contact
      Referral_Contact__c refCtct1 = new Referral_Contact__c(Name = 'Severus Snape', Referral_Account__c = refAcct.Id);
      Referral_Contact__c refCtct2 = new Referral_Contact__c(Name = 'Albus Dumbledore', Email__c = 'Adizzle@nowhere.net', Referral_Account__c = refAcct.Id);
      Referral_Contact__c refCtct3 = new Referral_Contact__c(Name = 'Harry Potter', Email__c = 'theboywholived@nowhere.net', Referral_Account__c = refAcct.Id);
      Referral_Contact__c[] refCtcts = new Referral_Contact__c[]{refCtct1,refCtct2,refCtct3};
      insert refCtcts;
   } // setupData
    
   public static Referral_Contact__c getRefCtct1() {
      Referral_Contact__c refCtct = [Select Id, Name, Referral_Account__c, Referral_Account__r.Id, Referral_Account__r.name from Referral_Contact__c where Name='Severus Snape'];
      return refCtct;
   } // getRefCtct1
    
   public static Referral_Account__c getRefAcct() {
      Referral_Account__c refAcct = [Select Id, Name
                                           ,(Select Id, Name, Email__c, Referral_Account__c from Referral_Contacts__r)
                                       From Referral_Account__c
                                      Where Name='Hogwarts School of Witchcraft and Wizardry'];
      return refAcct;
   } // getRefAcct
    
   Static testMethod void testgetMutualClients(){
      Referral_Contact__c refCtct = getRefCtct1();
      //create 3 accounts with related mutual clients 
      Account acc1 = new Account(Name='Tom Riddle', CPA_Name_Ref__c=refCtct.Id);
      Account acc2 = new Account(Name='Lucius Malfoy', Broker_Name_Ref__c=refCtct.Id);
      Account acc3 = new Account(Name='Draco Malfoy', Insurance_Broker_Name_Ref__c=refCtct.Id);
      ZipCheckOwner.SKIP_TRIGGERS=true;
      Account[] accts = new Account[]{acc1,acc2,acc3};
      insert accts;

        ReferralContactWrapper wrapper = ObjectBannerAuraService.getReferralContactWrapperById(refCtct.Id);
        List<Account> mutualClients = wrapper.MutualClients;
        Test.startTest();
        List<Account> mcs =  CadenceTouchpointExtension.getMutualClientsForTouchPointwithAcctId(refCtct.Referral_Account__c);
        System.debug('test Wrapper size: '+mcs.size());
        System.debug('Wrapper size: '+wrapper.MutualClients.size());
        System.assert(mcs.size()> 0,'Return List Size Null');
        //System.assertEquals(testWrapper.MutualClients.size(),wrapper.MutualClients.size(),'Not the Same Size List');
        Test.stopTest();
   } // testgetMutualClients
    
   Static testMethod void testGetReferralContactByAccountId(){
      Referral_Contact__c refCtct = getRefCtct1();
      test.startTest();
      Referral_Contact__c trialContact =  CadenceTouchpointExtension.getReferralContactwithAcctId(refCtct.Referral_Account__c);
      System.assertEquals(refCtct.Id,trialContact.Id,'Not the same Object');
      test.stopTest();
   } // testGetReferralContactByAccountId
    
   Static testMethod void testGetActivitiesForRefAcct(){
      Referral_Account__c refAcct = getRefAcct();
      Referral_Contact__c testRefCtct1 = refAcct.Referral_Contacts__r[0];
      Referral_Contact__c testRefCtct2 = refAcct.Referral_Contacts__r[1];

   Task t1 = new Task();
   t1.WhatId = testRefCtct2.Id;
   t1.ActivityDate = Date.today();
   t1.OwnerId = UserInfo.getUserId();
   insert t1;

   Event e1 = new Event();
   e1.WhatId = testRefCtct1.Id;
   e1.ActivityDate = Date.today().addMonths(2);
   e1.ownerId = UserInfo.getUserId();
   e1.DurationInMinutes = 15;
   e1.ActivityDateTime =  DateTime.newInstance(e1.Activitydate.year(),e1.ActivityDate.month(),e1.ActivityDate.day());
   insert e1;

   test.startTest();
   List<CadenceTouchpointExtension.EventTaskActivity> activityList = new List<CadenceTouchpointExtension.EventTaskActivity>();
   activityList = CadenceTouchpointExtension.getActivitiesForReferralContact(refAcct.Id);
   Datetime latestDate = CadenceTouchpointExtension.getLastMeetingDate(refAcct.Id);

   test.stopTest();
   System.assert(activityList.size() == 2,'Not the same size');
   System.assert(activityList[0] !=null,'No data is returning');
   System.assert(latestDate != null,'The date does not exist');

}
Static testMethod void testReferralOpsandMutualClientsCount(){
      Referral_Account__c refAcct = getRefAcct();
      List<Referral_Contact__c> refctcts = CadenceTouchpointExtension.getReferralContactswithAcctId(refAcct.Id);

    //create referrals in last 12 months
   Opportunity ref1 = new Opportunity();

   Date CloseDate = Date.today().addmonths(-2);
   ref1.CloseDate = CloseDate;
   Datetime createdDate = Datetime.newInstance(CloseDate.year(),CloseDate.month(),CloseDate.day());
   ref1.StageName='Sold - Revenue Recognition';
   ref1.Name='Test Ref 1';
   ref1.Referral_Account__c = refAcct.Id;
   ref1.Referral_Contact__c = refctcts[0].Id;
   insert ref1;
   Test.setCreatedDate(ref1.Id, createdDate);


   Opportunity ref2 = new Opportunity();
   Date CloseDate1 = Date.today().addmonths(-1);
   ref2.CloseDate = CloseDate1;
   Datetime createdDate1 = Datetime.newInstance(CloseDate1.year(),CloseDate1.month(),CloseDate1.day());
   ref2.StageName='Sold - Revenue Recognition';
   ref2.Name='Test Ref 2';
   ref2.Referral_Account__c = refAcct.Id;
   ref2.Referral_Contact__c = refctcts[1].Id;

   insert ref2;
   Test.setCreatedDate(ref2.Id, createdDate1);


   Opportunity ref3 = new Opportunity();
   Date CloseDate2 = Date.today().addmonths(-5);
   ref3.CloseDate = CloseDate2;
   Datetime createdDate2 = Datetime.newInstance(CloseDate2.year(),CloseDate2.month(),CloseDate2.day());
   ref3.StageName='Sold - Revenue Recognition';
   ref3.Name='Test Ref 3';
   ref3.Referral_Account__c = refAcct.Id;
   ref3.Referral_Contact__c = refctcts[2].Id;

   insert ref3;
   Test.setCreatedDate(ref3.Id, createdDate2);


   Opportunity ref4 = new Opportunity();
   Date CloseDate3 = Date.today().addmonths(-15);
   ref4.CloseDate = CloseDate3;
   Datetime createdDate3 = Datetime.newInstance(CloseDate3.year(),CloseDate3.month(),CloseDate3.day());
   ref4.StageName='Sold - Revenue Recognition';
   ref4.Name='Test Ref 4';
   ref4.Referral_Account__c = refAcct.Id;
   insert ref4;
   Test.setCreatedDate(ref4.Id, createdDate3);

   
   Opportunity opp = new Opportunity();
   opp.Referral_Account__c = refAcct.Id;
   opp.Name = 'test opp 1';
   opp.CloseDate = Date.today().adddays(23);
   opp.StageName = 'Needs Analysis';
   insert opp;

   Opportunity opp2 = new Opportunity();
   opp2.Referral_Account__c = refAcct.Id;
   opp2.Name = 'test opp 2';
   opp2.CloseDate = Date.today().adddays(23);
   opp2.StageName = 'Demo';

   insert opp2;
   // test for mutual clients 

   test.startTest();
   Integer refNum = CadenceTouchpointExtension.getReferralsInPastMonths(refAcct.Id,12);
   Integer oppNum = CadenceTouchpointExtension.getnumOfOpenOpps(refAcct.Id);
   Integer mutualsAndProspectNum = CadenceTouchpointExtension.getCurrentMutualAndProspectClientCount(refAcct.Id);

   test.stopTest();
   System.assertEquals(3,refNum);
   //System.assertEquals(refNum,refNum2);
   //System.assert(Integer.valueOf(refNum) == 3,'The number of referrals is Incorrect');
   System.assert(oppNum == 2,'The number of Opportunities is incorrect');

}
Static testMethod void testGetReferralContactsWithRefActId(){
      Referral_Account__c refAcct = getRefAcct();
      Referral_Contact__c testRefCtct1 = refAcct.Referral_Contacts__r[0];
      Referral_Contact__c testRefCtct2 = refAcct.Referral_Contacts__r[1];
      Referral_Contact__c testRefCtct3 = refAcct.Referral_Contacts__r[2];


   test.startTest();
   List<Referral_Contact__c> refctcts = CadenceTouchpointExtension.getReferralContactswithAcctId(refAcct.Id);
   test.stopTest();
   System.assert(refctcts!=null,'List of Referral Contacts is null');
   System.assert(refctcts.size()==3,'Number of Referral Contacts is not correct');

}
    
Static testMethod void testGetEmailCapableRefCtcts(){
      Referral_Account__c refAcct = getRefAcct();
      Referral_Contact__c testRefCtct1 = refAcct.Referral_Contacts__r[0];
      Referral_Contact__c testRefCtct2 = refAcct.Referral_Contacts__r[1];
      Referral_Contact__c testRefCtct3 = refAcct.Referral_Contacts__r[2];

 test.startTest();
   List<Referral_Contact__c> refctcts = CadenceTouchpointExtension.getEmailCapableRefCtcts(refAcct.Id);
   test.stopTest();
   System.assert(refctcts!=null,'List of Email Contacts is null');
   System.debug('TEST ref Contacts: '+refctcts);
   //System.assert(refctcts.size()==3,'Number of Email Contacts is not correct');
}

Static testMethod void testGetEmailContactIds(){
      Referral_Account__c refAcct = getRefAcct();
      Referral_Contact__c testRefCtct1 = refAcct.Referral_Contacts__r[0];
      Referral_Contact__c testRefCtct2 = refAcct.Referral_Contacts__r[1];
      Referral_Contact__c testRefCtct3 = refAcct.Referral_Contacts__r[2];
 List<Referral_Contact__c> refctcts = CadenceTouchpointExtension.getEmailCapableRefCtcts(refAcct.Id);

 test.startTest();
   List<Id> mirrorContactIds = CadenceTouchpointExtension.getEmailContactIds(refctcts);
   test.stopTest();
   System.assert(mirrorContactIds!=null,'List of Email Contact Ids is null');
   //System.assert(mirrorContactIds.size()>1,'Number of Email Contacts is not correct');
}
   Static testMethod void testGetReferralContactsEmailList(){
      Referral_Account__c refAcct = getRefAcct();
      Referral_Contact__c testRefCtct1 = refAcct.Referral_Contacts__r[0];
      Referral_Contact__c testRefCtct2 = refAcct.Referral_Contacts__r[1];
      Referral_Contact__c testRefCtct3 = refAcct.Referral_Contacts__r[2];

      test.startTest();
      List<Referral_Contact__c> refctcts = CadenceTouchpointExtension.getReferralContactsEmailList(refAcct.Id);
      test.stopTest();
      System.assert(refctcts!=null,'List of Email Contact Ids is null');
   } // testGetReferralContactsEmailList
   
   static testMethod void testGetCAOptionList() {
      Referral_Account__c refAcct = getRefAcct();
      Integer nbrCtcts = refAcct.Referral_Contacts__r.size();
       
      List<CadenceTouchpointExtension.CAOption> optionList = CadenceTouchpointExtension.getCAOptionList(refAcct.Id);
      System.assertEquals(nbrCtcts,optionList.size());
   } // testGetCAOptionList
   static testMethod void testGetTPRefContacts(){
      Referral_Account__c refAcct = getRefAcct();
      Referral_Contact__c refctct = getRefctct1();
      ReferralScoreHistory__c sH =new ReferralScoreHistory__c();
      sH.Name = 'Severus Snape';
      sh.Referral_Contact__c = refctct.Id;
      Date aMonthAgo = Date.today().addMonths(-1);
      sH.StartDate__c = aMonthAgo;
      sH.Count_Total_Referrals__c = 5;
      insert sH;
      Integer nbrCtcts2 = refAcct.Referral_Contacts__r.size();
      List<CadenceTouchpointExtension.TouchPointRefContactWrapper> enhancedContacts =CadenceTouchpointExtension.getTPRefctcts(refAcct.Id);
      List<Account> ac = CadenceTouchpointExtension.getMutualClientsForTouchPointwithAcctIdandRefBusiType(refAcct.id, 'Bank');
      List<Account> ac2 = CadenceTouchpointExtension.getMutualClientsForTouchPointwithAcctIdandRefBusiType(refAcct.id, 'Strategic Accountant Firm');
      List<Account> ac3 = CadenceTouchpointExtension.getMutualClientsForTouchPointwithAcctIdandRefBusiType(refAcct.id, 'Health Insurance Broker');
      List<Account> ac4 = CadenceTouchpointExtension.getMutualClientsForTouchPointwithAcctIdandRefBusiType(refAcct.id, 'Broker Dealer');
        List<Account> ac5 = CadenceTouchpointExtension.getMutualClientsForTouchPointwithAcctIdandRefBusiType(refAcct.id, 'Strategic Account');
      System.assertEquals(nbrCtcts2,enhancedContacts.size());
      System.assertEquals(5,enhancedContacts[0].Referrals_In_Last_Year);
   }
   static testMethod void testGetCurrentMutualCount(){
      Referral_Account__c refacct = getRefAcct();
      Integer currMC = CadenceTouchpointExtension.getCurrentMutualCount(refacct.Id);
      System.assert(currMC != null);
   }
   static testMethod void testGetRefctctName(){
   Referral_Contact__c refctct = getRefctct1();
   String CAName = CadenceTouchpointExtension.getCAContactName(refctct);
   System.assert(CAName==refctct.Name);
   }
   static testMethod void testGetOpportunities(){
      Referral_Account__c refacct = getRefAcct();
      Opportunity opp = new Opportunity();
      opp.Referral_Account__c = refAcct.Id;
      opp.Name = 'test opp 1';
      opp.CloseDate = Date.today().adddays(23);
      opp.StageName = 'Needs Analysis';
      insert opp;
      List<Opportunity> oppNum = CadenceTouchpointExtension.getOpportunityWithAcctId(refacct.Id);
      System.assertEquals(1,oppNum.size());
   }



} // class CadenceTouchpointExtensionTest