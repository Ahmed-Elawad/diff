/* 
 * Test Class for ReferenceESPreviewtoFlexNeeds.cls.
   Shows all Functionality Needed records in a table
   Table has pagination
 *
 * History
 * -------
 * 01/06/2016 Jacob Hinds        Created.
 *
 */
@isTest
private class ReferenceESPreviewToFlexNeedsTest {

    static testMethod void myUnitTest() {
        List<Reference_ES_Functionality_Needed__c> needs = new List<Reference_ES_Functionality_Needed__c>();
        Reference_ES_Functionality_Needed__c need1 = new Reference_ES_Functionality_Needed__c(Name='test1',Availability__c='testAvailability1',Description__c='testDesc1');
        Reference_ES_Functionality_Needed__c need2 = new Reference_ES_Functionality_Needed__c(Name='test2',Availability__c='testAvailability2',Description__c='testDesc2');
        Reference_ES_Functionality_Needed__c need3 = new Reference_ES_Functionality_Needed__c(Name='test3',Availability__c='testAvailability3',Description__c='testDesc3');
        Reference_ES_Functionality_Needed__c need4 = new Reference_ES_Functionality_Needed__c(Name='test4',Availability__c='testAvailability4',Description__c='testDesc4');
        Reference_ES_Functionality_Needed__c need5 = new Reference_ES_Functionality_Needed__c(Name='test5',Availability__c='testAvailability5',Description__c='testDesc5');
        Reference_ES_Functionality_Needed__c need6 = new Reference_ES_Functionality_Needed__c(Name='test6',Availability__c='testAvailability6',Description__c='testDesc6');
        needs.add(need1);
        needs.add(need2);
        needs.add(need3);
        needs.add(need4);
        needs.add(need5);
        needs.add(need6);
        insert needs;
        
        Test.startTest();
        
        ReferenceESPreviewToFlexNeeds ptfn = new ReferenceESPreviewToFlexNeeds(new ApexPages.StandardController(new Reference_ES_Preview_to_Flex_Needs__c()));
        ptfn.listSize = 2;
        System.assertEquals(6,ptfn.getTotalSize());
        
        //returns the size of the current page of the table, not the total amount of records, because of pagination
        System.assertEquals(2,ptfn.getNeeds.size());
        
        System.assertEquals(1,ptfn.getCurrentCount());
        System.assertEquals(2,ptfn.getPageSize());
        System.assertEquals(true,ptfn.getDisablePrevious());
        System.assertEquals(false,ptfn.getDisableNext());
        
        ptfn.Next();
        System.assertEquals(3,ptfn.getCurrentCount());
        System.assertEquals(4,ptfn.getPageSize());
        System.assertEquals(false,ptfn.getDisablePrevious());
        System.assertEquals(false,ptfn.getDisableNext());
        
        ptfn.End();
        System.assertEquals(5,ptfn.getCurrentCount());
        System.assertEquals(6,ptfn.getPageSize());
        System.assertEquals(false,ptfn.getDisablePrevious());
        System.assertEquals(true,ptfn.getDisableNext());
        
        ptfn.Previous();
        System.assertEquals(3,ptfn.getCurrentCount());
        System.assertEquals(4,ptfn.getPageSize());
        System.assertEquals(false,ptfn.getDisablePrevious());
        System.assertEquals(false,ptfn.getDisableNext());
        
        ptfn.Beginning();
        System.assertEquals(1,ptfn.getCurrentCount());
        System.assertEquals(2,ptfn.getPageSize());
        System.assertEquals(true,ptfn.getDisablePrevious());
        System.assertEquals(false,ptfn.getDisableNext());      
          
        Test.stopTest();
    }
}