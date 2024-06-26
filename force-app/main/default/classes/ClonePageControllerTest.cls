/* 
 * Test methods for the ClonePageController.
 *
 * History
 * -------
 * 11/02/2015 Jacob Hinds    Created
 *
 */
@isTest
private class ClonePageControllerTest {

    static testMethod void testClone() {
        account acc = new account(Name = 'Acct1', Phone = '(555) 555-5555');
        insert acc;
        PageReference pageRef = new PageReference('/apex/ClonePage?id='+acc.Id+'&fieldSetName=CloneTest&ObjectName=Account');
        Test.setCurrentPage(pageRef);
        clonePageController cp = new clonePageController();
        cp.SaveClone();
        account acc2 = [SELECT Id,Name, Phone FROM Account WHERE id != :acc.id];
        system.assertEquals(acc2.Phone,acc.Phone); 
        system.assertEquals(acc2.Name,acc.Name);
    }
    
    static testMethod void testFailure() {
        account acc = new account(Name = 'Acct1', Phone = '(555) 555-5555');
        insert acc;
        PageReference pageRef = new PageReference('/apex/ClonePage?id='+acc.Id+'&fieldSetName=CloneTestFail&ObjectName=Account');
        Test.setCurrentPage(pageRef);
        clonePageController cp = new clonePageController();
        cp.SaveClone();
        List<account> acc2 = [SELECT Id,Name, Phone FROM Account WHERE id != :acc.id];
        system.assert(acc2.isEmpty()); 
    }

} // class ClonePageControllerTest