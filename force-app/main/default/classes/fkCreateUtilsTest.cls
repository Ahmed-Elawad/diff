/* 
 * 
 *
 * History
 * -------
   10/26/2018 Dan Carmen         Increase the API version of the code, move the tests to another class

 */
@isTest
private class fkCreateUtilsTest {

    static testMethod void testInsertMassCreate()
    {
           // create a Mass Create dude
           //  create one and try to insert, trigger should catch it
           try
           {
               MassCreateConfig__c massCreate = new MassCreateConfig__c();
               massCreate.Mass_Create_Type__c = 'child';
               insert massCreate;
           }
           catch(Exception ex)
           {
           }
          
    }
    static testMethod void testCopy()
    {
        try
        {
            Account acc = [select Id, Name from Account limit 1]; // get any account
    
            // create a case
            Case c1 = new Case();   
            c1.Subject = 'Test case';
            c1.Description = 'test case';
            c1.AccountId = acc.Id;
          
            insert c1;
            fkCreateUtils.MassCreateCaseFromField(c1.Id, acc.Id);
            fkCreateUtils.MassCreateCaseForChildren(c1.Id, acc.Id);
            fkCreateUtils.GetMassCreateType();
            fkCreateUtils fkObj = new fkCreateUtils();
            fkObj.CopyCase(acc.Id, c1.Id);
            fkObj.CopyCaseFromField(acc.Id, c1.Id);
            fkCreateUtils.CopyCaseEx(acc.Id, c1.Id);
             fkObj.OnChildFound(acc);
             fkObj.EnumerateChildren(acc.Id, c1.Id);
             fkObj.EnumerateChildren2(acc.Id, c1.Id);
             fkCreateUtils.FindChildren(acc.Id);
             fkCreateUtils.FindAccountsByHRO(acc.Id);
             
            
            
        }
        catch(Exception ex)
        {
            System.debug('testMethod:EXCEPTION ' + ex.getMessage());
        }
    }
    

} // class fkCreateUtilsTest