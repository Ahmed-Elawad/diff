/* 
 * Test methods for the RefPEOQuickResolveCloneController.
 *
 * History
 * -------
 * 06/22/2016 Jermaine Stukes Created
 *
 */
@isTest
public class RefPEOQuickResolveControllerTest 
{
    static testMethod void testQuickResolve() 
    {
        Reference_PEO__c testReference = new Reference_PEO__c();
        insert testReference;
        
        //Set test page reference to the Id of the inserted reference peo
        pageReference pageRef = new pageReference('/'+testReference.Id);
        pageRef.getParameters().put('retURL', testReference.Id);
        test.setCurrentPageReference(pageRef);
        
        
        Reference_PEO_Discrepancy__c  newDiscrepancy = new Reference_PEO_Discrepancy__c();
        newDiscrepancy.Reference_PEO__c = testReference.Id;
        newDiscrepancy.Status__c = 'Open';
        newDiscrepancy.Resolved_by__c = '';
        
        List<Reference_PEO_Discrepancy__c> disc = new List<Reference_PEO_Discrepancy__c>();
        disc.add(newDiscrepancy);
        insert(disc);
        
        //Create the controller and run the method
        ApexPages.StandardSetController sc = new ApexPages.StandardSetController(Database.getQueryLocator(
                    [SELECT id FROM Reference_PEO_Discrepancy__c where id =:newDiscrepancy.Id]));
        //ApexPages.StandardSetController sc;
        sc.setSelected(disc);
        
        RefPEOQuickResolveController newTest = new RefPEOQuickResolveController(sc);
        newTest.quickResolve();
        System.assertNotEquals(Null, testReference.Id);
    }
}