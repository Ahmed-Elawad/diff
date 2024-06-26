/* 
 * Test methods for the OpptyTeamMember class
 *
 * History
 * -------
   07/25/2018 Dan Carmen       Created
   12/05/2018 Dan Carmen       Add chatter message
   12/13/2018 Dan Carmen       Add in RecordTypeName as a criteria
   
 */
@isTest
private class OpptyTeamMemberTest {

   @testSetup 
   public static void setupTestData() {
      TriggerSetupClasses__c[] setupClasses = new TriggerSetupClasses__c[]{};
      TriggerSetup__c trigSetup1 = TriggerMethodsTest.createCustomSetting(null, 'OpptyAfter', false, true, new String[]{'OpptyTeamMember'},setupClasses, TriggerMethods.INTERFACE_B);
      insert setupClasses;

   } // setupTestData

   static testMethod void testSalesEngineerAssignment() {
      String ZIP1='12345';
      String ZIP2='12346';
      Zip_Segment__c seg1 = new Zip_Segment__c(Name='TestSegment1', Emps_Min__c=0, Emps_Max__c=49,OpportunityType__c='Payroll,SomethingElse'
                                              ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS, OpptyTeamMemberName__c='Team1', Sales_Org__c='Sales Eng');
      Zip_Segment__c seg2 = new Zip_Segment__c(Name='TestSegment2', Emps_Min__c=50, Emps_Max__c=100,OpportunityType__c='Payroll,SomethingElse'
                                              ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS, OpptyTeamMemberName__c='Team2', Sales_Org__c='Sales Eng');
      Zip_Segment__c seg3 = new Zip_Segment__c(Name='TestSegment3', Emps_Min__c=0, Emps_Max__c=49,OpportunityType__c='Payroll,SomethingElse'
                                              ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS, OpptyTeamMemberName__c='Team3', Sales_Org__c='Sales Eng');
      Zip_Segment__c seg4 = new Zip_Segment__c(Name='TestSegment4', Emps_Min__c=50, Emps_Max__c=100,OpportunityType__c='Payroll,SomethingElse'
                                              ,OpptyRecordTypeName__c=OpportunityCreateCase.RT_OPPTY_MMS, OpptyTeamMemberName__c='Team4', Sales_Org__c='Sales Eng');
      Zip_Segment__c[] segs = new Zip_Segment__c[]{seg1,seg2,seg3,seg4};
      insert segs;
      
      Set<String> roleNameSet = new Set<String>{seg1.OpptyTeamMemberName__c, seg2.OpptyTeamMemberName__c, seg3.OpptyTeamMemberName__c, seg4.OpptyTeamMemberName__c};
      System.debug('testSalesEngineerAssignment roleNameSet='+roleNameSet);

      Org_Unit__c distSalesEng = new Org_Unit__c(Name='1', Org_Type__c='District', Sales_Org__c='Sales Eng');
      insert distSalesEng;

      // select users to assign to the territories      
      User[] users = [Select Id, HR_Person_Id__c, Name from User where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and Sales_Org__c=:UserHelper.SO_CORE limit 4 ];
      
      ZipTerritory__c terr1 = new ZipTerritory__c(Name=users[0].Name, Zip_Segment__c=seg1.Id, TerritoryRep__c=users[0].Id, District__c=distSalesEng.Id);
      ZipTerritory__c terr2 = new ZipTerritory__c(Name=users[1].Name, Zip_Segment__c=seg2.Id, TerritoryRep__c=users[1].Id, District__c=distSalesEng.Id);
      ZipTerritory__c terr3 = new ZipTerritory__c(Name=users[2].Name, Zip_Segment__c=seg3.Id, TerritoryRep__c=users[2].Id, District__c=distSalesEng.Id);
      ZipTerritory__c terr4 = new ZipTerritory__c(Name=users[3].Name, Zip_Segment__c=seg4.Id, TerritoryRep__c=users[3].Id, District__c=distSalesEng.Id);
      ZipTerritory__c[] territories = new ZipTerritory__c[]{terr1,terr2,terr3,terr4};
      insert territories;
      
      Zip_Assignment__c za1 = new Zip_Assignment__c(Name=ZIP1, Rep_Name__c=users[0].Name, Sales_Org__c='Sales Eng', Segment_Name__c=seg1.Name
                                                  ,ZipTerritory__c=terr1.Id, District__c=distSalesEng.Id);
      Zip_Assignment__c za2 = new Zip_Assignment__c(Name=ZIP1, Rep_Name__c=users[1].Name, Sales_Org__c='Sales Eng', Segment_Name__c=seg2.Name
                                                  ,ZipTerritory__c=terr2.Id, District__c=distSalesEng.Id);
      Zip_Assignment__c za3 = new Zip_Assignment__c(Name=ZIP2, Rep_Name__c=users[2].Name, Sales_Org__c='Sales Eng', Segment_Name__c=seg3.Name
                                                  ,ZipTerritory__c=terr3.Id, District__c=distSalesEng.Id);
      Zip_Assignment__c za4 = new Zip_Assignment__c(Name=ZIP2, Rep_Name__c=users[3].Name, Sales_Org__c='Sales Eng', Segment_Name__c=seg4.Name
                                                  ,ZipTerritory__c=terr4.Id, District__c=distSalesEng.Id);
      Zip_Assignment__c[] zas = new Zip_Assignment__c[]{za1,za2,za3,za4};
      insert zas;
      
      Set<String> zipSet = new Set<String>{ZIP1,ZIP2};
      Map<String,Zip_Assignment__c[]> zaMap = OpptyTeamMember.getOppZipAssigns(zipSet);
      // all zip assignments should be returned
      System.assertEquals(2,zaMap.size());
      System.assertEquals(2,zaMap.get(ZIP1).size());
      System.assertEquals(2,zaMap.get(ZIP2).size());
      
      Account acct1 = new Account(Name='Test Account 1', ShippingPostalCode=ZIP1);
      Account acct2 = new Account(Name='Test Account 2', ShippingPostalCode=ZIP1);
      Account acct3 = new Account(Name='Test Account 3', ShippingPostalCode=ZIP2);
      Account acct4 = new Account(Name='Test Account 4', ShippingPostalCode=ZIP2);
      Account acct5 = new Account(Name='Test Account 5', ShippingPostalCode=ZIP2);
      Account[] accts = new Account[]{acct1,acct2,acct3,acct4,acct5};
      insert accts;
      
      Map<String,Schema.RecordTypeInfo> byNameMap = Opportunity.SObjectType.getDescribe().getRecordTypeInfosByName();
      Schema.RecordTypeInfo rtInfoMMS = byNameMap.get(OpportunityCreateCase.RT_OPPTY_MMS);
      Schema.RecordTypeInfo rtInfoPAY = byNameMap.get(OpportunityCreateCase.RT_OPPTY_CORE);
            
      Opportunity opp1 = new Opportunity(RecordTypeId=rtInfoMMS.getRecordTypeId(), Name='Opp 1', AccountId=acct1.Id, CloseDate=Date.today().addDays(7), StageName='Pending', OpportunityType__c='Payroll', Employees_Paid_Per_Payroll__c=25); 
      Opportunity opp2 = new Opportunity(RecordTypeId=rtInfoMMS.getRecordTypeId(), Name='Opp 2', AccountId=acct2.Id, CloseDate=Date.today().addDays(7), StageName='Pending', OpportunityType__c='Payroll', Employees_Paid_Per_Payroll__c=75); 
      Opportunity opp3 = new Opportunity(RecordTypeId=rtInfoMMS.getRecordTypeId(), Name='Opp 3', AccountId=acct3.Id, CloseDate=Date.today().addDays(7), StageName='Pending', OpportunityType__c='SomethingElse', Employees_Paid_Per_Payroll__c=null); 
      Opportunity opp4 = new Opportunity(RecordTypeId=rtInfoMMS.getRecordTypeId(), Name='Opp 4', AccountId=acct4.Id, CloseDate=Date.today().addDays(7), StageName='Pending', OpportunityType__c='SomethingElse', Employees_Paid_Per_Payroll__c=null); 
      Opportunity opp5 = new Opportunity(RecordTypeId=rtInfoPAY.getRecordTypeId(), Name='Opp 5', AccountId=acct5.Id, CloseDate=Date.today().addDays(7), StageName='Pending', OpportunityType__c='SomethingElse', Employees_Paid_Per_Payroll__c=25); 

      Opportunity[] opps = new Opportunity[]{opp1,opp2,opp3,opp4,opp5};
      OpptyTeamMember.TEST_PROCESS_NOW = true;
      System.debug('testSalesEngineerAssignment before insert');
      insert opps;
      System.debug('testSalesEngineerAssignment after insert');
      
      // 2 team members should be created
      OpportunityTeamMember[] otms = [select Id, OpportunityId, UserId, TeamMemberRole from OpportunityTeamMember where TeamMemberRole in :roleNameSet];
      System.assertEquals(2,otms.size());
      Boolean otm1Check = false;
      Boolean otm2Check = false;
      for (OpportunityTeamMember otm : otms) {
         if (otm.OpportunityId == opp1.Id) {
            otm1Check=true;
            System.assertEquals(terr1.TerritoryRep__c,otm.UserId);
            System.assertEquals(seg1.OpptyTeamMemberName__c, otm.TeamMemberRole);
         } else if (otm.OpportunityId == opp2.Id) {
            otm2Check=true;
            System.assertEquals(terr2.TerritoryRep__c,otm.UserId);
            System.assertEquals(seg2.OpptyTeamMemberName__c, otm.TeamMemberRole);
         }
      }
      System.assertEquals(true, otm1Check);
      System.assertEquals(true, otm2Check);
      
      // create an existing team member - make sure a new one isn't created
      OpportunityTeamMember otm3 = new OpportunityTeamMember(OpportunityId=opp3.Id, UserId=terr3.TerritoryRep__c, TeamMemberRole=seg3.OpptyTeamMemberName__c);
      insert otm3;
      
      // change the number of employees to make sure the team member doesn't change
      opp1.Employees_Paid_Per_Payroll__c = 80;
      opp2.Employees_Paid_Per_Payroll__c = 25;
      opp3.Employees_Paid_Per_Payroll__c = 80;
      opp4.Employees_Paid_Per_Payroll__c = 80;
      
      // let it process as a future method
      OpptyTeamMember.TEST_PROCESS_NOW = false;
      // make sure it's selecting from the cache
      OpptyTeamMember.OPPTY_TYPES = null;
      OpptyMethods.SKIP_OPPTY_TRIGGERS = false;
      Test.startTest();
      System.debug('testSalesEngineerAssignment before update in Test');
      update opps;
      Test.stopTest();
      System.debug('testSalesEngineerAssignment after update in Test');
      
      otms = [select Id, OpportunityId, UserId, TeamMemberRole from OpportunityTeamMember where TeamMemberRole in :roleNameSet];
      System.assertEquals(4,otms.size());
      otm1Check = false;
      otm2Check = false;
      Boolean otm3Check = false;
      Boolean otm4Check = false;
      for (OpportunityTeamMember otm : otms) {
         if (otm.OpportunityId == opp1.Id) {
            otm1Check=true;
            System.assertEquals(terr1.TerritoryRep__c,otm.UserId);
            System.assertEquals(seg1.OpptyTeamMemberName__c, otm.TeamMemberRole);
         } else if (otm.OpportunityId == opp2.Id) {
            otm2Check=true;
            System.assertEquals(terr2.TerritoryRep__c,otm.UserId);
            System.assertEquals(seg2.OpptyTeamMemberName__c, otm.TeamMemberRole);
         } else if (otm.OpportunityId == opp3.Id) {
            otm3Check=true;
            System.assertEquals(terr3.TerritoryRep__c,otm.UserId);
            System.assertEquals(seg3.OpptyTeamMemberName__c, otm.TeamMemberRole);
         } else if (otm.OpportunityId == opp4.Id) {
            otm4Check=true;
            System.assertEquals(terr4.TerritoryRep__c,otm.UserId);
            System.assertEquals(seg4.OpptyTeamMemberName__c, otm.TeamMemberRole);
         }
      }
      System.assertEquals(true, otm1Check);
      System.assertEquals(true, otm2Check);
      System.assertEquals(true, otm3Check);
      System.assertEquals(true, otm4Check);
      
   } // testSalesEngineerAssignment
   
} // class OpptyTeamMemberTest