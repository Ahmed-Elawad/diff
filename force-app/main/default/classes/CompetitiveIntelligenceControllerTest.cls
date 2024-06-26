/* 
* Test methods for CompetitiveIntelligenceController.
*
* History
* -------
* 12/13/2021 Eric Porter     Created
  11/16/2022 Dan Carmen      Add null check in getCompetitors
*/
@isTest
public class CompetitiveIntelligenceControllerTest {
   
    @testSetup
    Static void setupData() {
        //create opp
        Opportunity Opp = new Opportunity(Name = 'tempOpp',StageName='Open',CloseDate=Date.today());
        insert Opp;

        
    }
    
    static testMethod void saveToOpp2Test() {
        // create 3 Competitors in a list 
        List<Competitor__c> compList = new List<Competitor__c>();
        PickListValue__c tempPL = new PickListValue__c(name='testName',PicklistType__c='Competitor');
        insert tempPL;
        Opportunity Opp = new Opportunity(Name = 'tempOpp',StageName='Open',CloseDate=Date.today());
        insert Opp;
        for(Integer i = 0;i<4;i++){
            Competitor__c tempComp = new Competitor__c(Name='test'+i, Opportunity__c = Opp.Id , PickListValue__c = tempPL.Id);
            compList.add(tempComp);
        }
        
        // send the list into the method
        // test to see if those 3 competitors were saved
        
        Test.startTest();
        Boolean succeeded = CompetitiveIntelligenceController.saveToOpp2(compList);
        Test.stopTest();
        
        System.assert(succeeded);
        List<Competitor__c>  comps = [SELECT ID, Name,PickListValue__c,Opportunity__c,Opportunity__r.Primary_Competitor__c  FROM Competitor__c WHERE Name='test1' Order By Name ASC];
        System.assertEquals(tempPL.Id ,comps[0].PickListValue__c);
        Opportunity testOpp = [Select Id, Name,Primary_Competitor__c from Opportunity where Id =: comps[0].Opportunity__c limit 1];
        System.assertNotEquals(testOpp.Primary_Competitor__c,null,'Primary Competitor should not be null');
    }
    static testMethod void removeTest2() {
        // create 3 Competitors in a list 
        List<Competitor__c> compList = new List<Competitor__c>();
        PickListValue__c tempPL = new PickListValue__c(name='testName',PicklistType__c='Competitor');
        insert tempPL;
        Opportunity Opp = new Opportunity(Name = 'tempOpp',StageName='Open',CloseDate=Date.today());
        insert Opp;
        Competitor__c tempComp = new Competitor__c(Name='test1', Opportunity__c = Opp.Id , PickListValue__c = tempPL.Id);
        compList.add(tempComp);
        CompetitiveIntelligenceController.saveToOpp2(compList);
        
        // send the list into the method
        // test to see if those 3 competitors were saved
        
        Test.startTest();
        Boolean succeeded = CompetitiveIntelligenceController.removeCompetitor(0,compList);
        Test.stopTest();
        
        System.assert(succeeded);
        System.assertEquals(Opp.Primary_Competitor__c,null);
    }
    static testMethod void changePrimaryTest() {
        // create 2 competitors in a list 1st with primary__c = true and the 2nd with primary__c = false 
        // pass in 0 as oldIndex and 1 as newIndex 
        // check to see the returned list has index 2 as Primary__c = true 
        Opportunity Opp = new Opportunity(Name = 'tempOpp',StageName='Open',CloseDate=Date.today());
        insert Opp;
        List<Competitor__c> compList = new List<Competitor__c>();
        PickListValue__c tempPL = new PickListValue__c(name='testName',PicklistType__c='Competitor');
        insert tempPL;
        for(Integer i = 0;i<4;i++){
            Competitor__c tempComp = new Competitor__c(Name='test'+i, Opportunity__c =  Opp.Id , PickListValue__c = tempPL.Id);
            compList.add(tempComp);
        }
        insert compList;
        Test.startTest();
        List<Competitor__c> changedComps = CompetitiveIntelligenceController.changePrimary(0,1,compList);
        Test.stopTest();
        
        System.assertEquals(compList[0].Primary__c, false);
        System.assertEquals(compList[1].Primary__c, true);
    }
    static testMethod void getCompetitorsTest() {
        // create opp
        Opportunity Opp = new Opportunity(Name = 'tempOpp',StageName='Open',CloseDate=Date.today());
        insert Opp;
        PickListValue__c tempPL = new PickListValue__c(name='testName',PicklistType__c='Competitor');
        insert tempPL;
        List<Competitor__c> compList = new List<Competitor__c>();
        for(Integer i = 0;i<4;i++){
            Competitor__c tempComp = new Competitor__c(Name='test'+i, Opportunity__c = Opp.Id , PickListValue__c = tempPl.Id);
            compList.add(tempComp);
        }
        insert compList;

        Test.startTest();
        List<Competitor__c> compsInRest = CompetitiveIntelligenceController.getCompetitors(Opp.Id);
        Test.stopTest();
        // add competitors to opp
        // test to see if competitors work with Opp Id
        System.assertEquals(compsInRest.Size(),4);
    }
    static testMethod void removeCompetitorTest(){
        Opportunity Opp = new Opportunity(Name = 'tempOpp',StageName='Open',CloseDate=Date.today());
        insert Opp;

        //create list of competitors 
        // insert the competitors
        // run the remove command 
        // test that original size is 1 less than previous number
        PickListValue__c tempPL = new PickListValue__c(name='testName',PicklistType__c='Competitor');
        insert tempPL;
        List<Competitor__c> compList = new List<Competitor__c>();
        for(Integer i = 0;i<4;i++){
            Competitor__c tempComp = new Competitor__c(Name='test'+i, Opportunity__c = Opp.Id , PickListValue__c = tempPl.Id);
            compList.add(tempComp);
        }
        CompetitiveIntelligenceController.saveToOpp2(compList);
        Integer nameSizeStart = 4;
        Test.startTest();


       Boolean comps =  CompetitiveIntelligenceController.removeCompetitor(0, compList);
        Test.stopTest();
        System.assertEquals(comps,true);
        List<Competitor__c> remainingComps = [Select Id, Name, Opportunity__c from Competitor__c where Opportunity__c = : Opp.Id];
        System.assertEquals(3,remainingComps.size());
        String compNamesString = Opp.Competition__c;
        // List<String> compNames = compNamesString.split(';');
        // System.assertEquals(3,compNames.size());
    }
    
    static testMethod void getRecordsTest() {
        Opportunity Opp = new Opportunity(Name = 'tempOpp',StageName='Open',CloseDate=Date.today());
        insert Opp;

        // setup some records for retrieval
        List<PickListValue__c> tempPLs = new List<PickListValue__c>();
        tempPLs.add(new PickListValue__c(Name='Stark Industries', PicklistType__c = 'Competitor'));
        tempPLs.add(new PickListValue__c(Name='QENG Enterprises', PicklistType__c = 'Competitor',ManualEntry__c = true));
        tempPLs.add(new PickListValue__c(Name='Nelson & Murdock', PicklistType__c = 'Competitor'));
        tempPLs.add(new PickListValue__c(Name='The Daily Bugle', PicklistType__c = 'Competitor'));
        tempPLs.add( new PickListValue__c(Name='S.H.E.I.L.D', PicklistType__c = 'Competitor'));
        tempPLs.add( new PickListValue__c(Name='Stark Enterprises', PicklistType__c = 'Competitor'));


        
        
        Test.startTest();
        //!TODO this method 
        insert tempPLs;
        Test.stopTest();

        List<SObject> StarkLists= CompetitiveIntelligenceController.getRecords('Stark Enterprises','PickListValue__c','Id','Name','',5);

       
        System.assertEquals(StarkLists.size(),0);
    }
}