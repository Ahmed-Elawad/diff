/* Test methods for the class OpptyTerritoryAssign class

  History
  -------
  11/28/2023 Dan Carmen        Created
  
 */
@isTest
public class OpptyTerritoryAssignTest {
   @testSetup
   public static void setupData() {
      TerritoryManagerTest.setupTestModel();
   } // setupData

   static testMethod void testTerritory() {
      // the model is created in a planning state
      OpptyTerritoryAssign.TERR_STATE='Planning';
      Territory2Model terrModel = TerritoryManagerTest.getTestModel();
       
      // doesn't really matter which types
      Territory2Type[] terriTypes = [SELECT id, DeveloperName from Territory2Type LIMIT 1];
      System.debug('terriTypes='+terriTypes);
      
      User[] reps = [Select Id, Name, ManagerId
                       from User 
                      where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and ManagerId != null and Manager.IsActive=true limit 3];
      Id[] managerIds = new Id[]{};
      for (User rep : reps) {
         managerIds.add(rep.ManagerId);
      }
      // make sure this manager isn't the same as the first few
      User rep4 = [Select Id, Name, ManagerId
                       from User 
                      where IsActive=true and Job_Name__c=:UserHelper.JOB_REP and ManagerId != null and Manager.IsActive=true 
                        and ManagerId not in :managerIds
                      limit 1];
      
      Territory2 terr1 = new Territory2(DeveloperName = 'TestTerritory1', Territory2ModelId=terrModel.Id, Name='TestTerritory1', Territory2TypeId=terriTypes[0].Id);
      Territory2 terr2 = new Territory2(DeveloperName = 'TestTerritory2', Territory2ModelId=terrModel.Id, Name='TestTerritory2', Territory2TypeId=terriTypes[0].Id);
      Territory2 terr3 = new Territory2(DeveloperName = 'TestTerritory3', Territory2ModelId=terrModel.Id, Name='TestTerritory3', Territory2TypeId=terriTypes[0].Id);
      insert new Territory2[]{terr1,terr2,terr3};
          
      UserTerritory2Association userTerr1 = new UserTerritory2Association(Territory2Id=terr1.Id, UserId=reps[0].Id, RoleInTerritory2='Sales Rep');
      UserTerritory2Association userTerr2 = new UserTerritory2Association(Territory2Id=terr2.Id, UserId=reps[1].Id, RoleInTerritory2='Sales Rep');
      UserTerritory2Association userTerr3 = new UserTerritory2Association(Territory2Id=terr3.Id, UserId=reps[2].ManagerId, RoleInTerritory2='Sales Rep');
      insert new UserTerritory2Association[]{userTerr1,userTerr2,userTerr3};
      User runningUser = UserHelper.getRunningUser();
      System.runAs(runningUser) {
         Account acct1 = new Account(Name='Test Acct1');
         Account acct2 = new Account(Name='Test Acct2');
         Account acct3 = new Account(Name='Test Acct3');
         Account acct4 = new Account(Name='Test Acct4');
         ZipCheckOwner.SKIP_TRIGGERS=true;
         insert new Account[]{acct1,acct2,acct3,acct4};
          
         Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, OwnerId=reps[0].Id, StageName='Pending', CloseDate=Date.today().addDays(7));
         Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, OwnerId=reps[1].Id, StageName='Pending', CloseDate=Date.today().addDays(7));
         Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct3.Id, OwnerId=reps[2].Id, StageName='Pending', CloseDate=Date.today().addDays(7));
         Opportunity opp4 = new Opportunity(Name='Opp4', AccountId=acct4.Id, OwnerId=rep4.Id, StageName='Pending', CloseDate=Date.today().addDays(7));
         insert new Opportunity[]{opp1,opp2,opp3,opp4};
          
         Id[] oppIds = new Id[]{opp1.Id,opp2.Id,opp3.Id,opp4.Id};
         OpptyTerritoryAssign ota = new OpptyTerritoryAssign();
         Map<Id,Id> oppTerrMap = ota.getOpportunityTerritory2Assignments(oppIds);
       
         Assert.areEqual(4,oppTerrMap.size());
         Assert.areEqual(terr1.Id, oppTerrMap.get(opp1.Id));
         Assert.areEqual(terr2.Id, oppTerrMap.get(opp2.Id));
         Assert.areEqual(terr3.Id, oppTerrMap.get(opp3.Id));
         Assert.isNull(oppTerrMap.get(opp4.Id));
      } // System.runAs
   } // testTerritory
    
   static testMethod void testTerritoryTrigger() {
      OpptyTerritoryAssign.onlyEvalCheckbox=false;
         TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'OpptyTerritoryAssign'});
         TriggerMethodsTest.saveSetupClasses();
         // make sure the triggers see the new value
         CacheManager.removeOrg(TriggerMethods.CACHE_KEY);
       
      // get the active model - should be one
      Territory2Model terrModel = [Select Id, Name, State from Territory2Model where State='Active' limit 1];
      OpptyTerritoryAssign.TERR_STATE=terrModel.State;
       
      UserTerritory2Association[] utas = [Select Id, RoleInTerritory2, Territory2Id, UserId
                                                 ,Territory2.Id, Territory2.Territory2Type.Priority
                                             From UserTerritory2Association
                                            Where Territory2.EndDate__c = null
                                              and Territory2.Territory2ModelId = :terrModel.Id
                                            limit 4];
      UserTerritory2Association terrUsr1 = utas[0];
      UserTerritory2Association terrUsr2 = utas[1];
      UserTerritory2Association terrUsr3 = utas[2];
      UserTerritory2Association terrUsr4 = utas[3];

       // select all of the territories that have those users.
       Id[] queryUserIds = new Id[]{terrUsr1.UserId,terrUsr2.UserId,terrUsr3.UserId,terrUsr4.UserId};
       UserTerritory2Association[] utas2 = [Select Id, RoleInTerritory2, Territory2Id, UserId
                                                 ,Territory2.Id, Territory2.Territory2Type.Priority
                                             From UserTerritory2Association
                                            Where Territory2.EndDate__c = null
                                              and Territory2.Territory2ModelId = :terrModel.Id
                                              and UserId in :queryUserIds];
       System.debug('testTerritoryTrigger utas2='+utas2.size());
       Map<Id,Id[]> terrsByUserId = new Map<Id,Id[]>();
       for (UserTerritory2Association uta : utas2) {
          Id[] terrIds = (terrsByUserId.containsKey(uta.UserId) ? terrsByUserId.get(uta.UserId) : new Id[]{});
          terrIds.add(uta.Territory2Id);
          terrsByUserId.put(uta.UserId,terrIds);
          System.debug('testTerritoryTrigger userId='+uta.UserId+' terrIds='+terrIds.size());
       }
          
         Account acct1 = new Account(Name='Test Acct1');
         Account acct2 = new Account(Name='Test Acct2');
         Account acct3 = new Account(Name='Test Acct3');
         Account acct4 = new Account(Name='Test Acct4');
         ZipCheckOwner.SKIP_TRIGGERS=true;
         insert new Account[]{acct1,acct2,acct3,acct4};
          
         Opportunity opp1 = new Opportunity(Name='Opp1', AccountId=acct1.Id, OwnerId=terrUsr1.UserId, StageName='Pending', CloseDate=Date.today().addDays(7));
         Opportunity opp2 = new Opportunity(Name='Opp2', AccountId=acct2.Id, OwnerId=terrUsr2.UserId, StageName='Pending', CloseDate=Date.today().addDays(7));
         Opportunity opp3 = new Opportunity(Name='Opp3', AccountId=acct3.Id, OwnerId=terrUsr3.UserId, StageName='Pending', CloseDate=Date.today().addDays(7));
         Opportunity opp4 = new Opportunity(Name='Opp4', AccountId=acct4.Id, OwnerId=terrUsr4.UserId, StageName='Pending', CloseDate=Date.today().addDays(7));
         insert new Opportunity[]{opp1,opp2,opp3,opp4};
          
         Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, OwnerId, Territory2Id
                                                                 From Opportunity]);
         Assert.areEqual(4,oppMap.size());
         // because it uses metadata that we don't always have control of in this test, we just want to make sure the code is setting the field.
         // TODO - see if there's a better way to test the values. Maybe select the territories found and make sure there's a correct user in that territory?
         Assert.IsNotNull(oppMap.get(opp1.Id).Territory2Id);
         Assert.IsNotNull(oppMap.get(opp2.Id).Territory2Id);
         Assert.IsNotNull(oppMap.get(opp3.Id).Territory2Id);
         Assert.IsNotNull(oppMap.get(opp4.Id).Territory2Id);
       
         Assert.isTrue(terrsByUserId.get(terrUsr1.UserId).contains(oppMap.get(opp1.Id).Territory2Id));
         Assert.isTrue(terrsByUserId.get(terrUsr2.UserId).contains(oppMap.get(opp2.Id).Territory2Id));
         Assert.isTrue(terrsByUserId.get(terrUsr3.UserId).contains(oppMap.get(opp3.Id).Territory2Id));
         Assert.isTrue(terrsByUserId.get(terrUsr4.UserId).contains(oppMap.get(opp4.Id).Territory2Id));
         //Assert.areEqual(terrUsr1.Territory2Id, oppMap.get(opp1.Id).Territory2Id);
         //Assert.areEqual(terrUsr2.Territory2Id, oppMap.get(opp2.Id).Territory2Id);
         //Assert.areEqual(terrUsr3.Territory2Id, oppMap.get(opp3.Id).Territory2Id);
         //Assert.areEqual(terrUsr4.Territory2Id, oppMap.get(opp4.Id).Territory2Id);

   } // testTerritoryTrigger
    
} // class OpptyTerritoryAssignTest