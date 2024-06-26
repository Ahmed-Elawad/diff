/** Methods for communicating with RJDB

* History
* -------
02/15/2021 Jake Hinds       Created
05/18/2021 Carrie Marciano  Changed to use OppStage Labels
11/12/2021 Dan Carmen       Cleaned up code
02/24/2022 Dan Carmen       Removed logging to ProcessNotes
07/17/2023 Dan Carmen       Remove extra debug statements

*/
@isTest
public class RJMethodsTest {
    
   @testSetup
   public static void setupTestData() {
      TriggerMethodsTest.createTriggerSetting('OpptyBefore', true, false, false, false, new String[]{'RJMethods'});
      TriggerMethodsTest.saveSetupClasses();
   } // setupTestData
   
    public static String QUALIFIED=Label.OppStage_Qualified;
    
    static testMethod void testOACDate(){
        Account acct = new Account(Name='test Acct');
        insert acct;
        
        Test.startTest();
        Opportunity oppty = new Opportunity(Name='test opp',CloseDate=system.today(),accountId = acct.Id,StageName = QUALIFIED);
        insert oppty;
        //TO DO add verification that field is in the fieldset, fail if missing
        Schema.FieldSet oacFieldSet = Schema.SObjectType.Opportunity.fieldSets.getMap().get('OAC_Fields');
        system.assert(oacFieldSet!=null);
        Boolean amountIsInFieldSet = false;
        for(Schema.FieldSetMember field : oacFieldSet.getFields()) {
            system.debug(field.getFieldPath());
            if(field.getFieldPath() == 'Amount'){
                amountIsInFieldSet=true;
            }   
        }
        system.assertEquals(true,amountIsInFieldSet);
        
        Opportunity uOppty = [SELECT Id,OAC_Change_Date__c FROM Opportunity WHERE Id =:oppty.Id LIMIT 1];
        System.assertNotEquals(null,uOppty.OAC_Change_Date__c);
        RJMethods.RAN_SET.clear();
        uOppty.Amount = 100;
        uOppty.OAC_Change_Date__c = null;
        update uOppty;
        
        Opportunity uOppty2 = [SELECT Id,OAC_Change_Date__c FROM Opportunity WHERE Id =:oppty.Id LIMIT 1];
        system.assert(uOppty2.OAC_Change_Date__c != null);
        Test.stopTest();
        
    } // testOACDate
    
} // class RJMethodsTest