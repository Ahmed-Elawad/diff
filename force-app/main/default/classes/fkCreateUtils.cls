/* 
 * 
 *
 * History
 * -------
   10/26/2018 Dan Carmen         Increase the API version of the code, move the tests to another class
   07/06/2020  Jacob Hinds         Added without sharing per PMD

 */
global without sharing class fkCreateUtils 
{
    public sObject rootObj;
    public Case m_caseIn;
    public Integer m_iCnt = 0;
    public boolean fIsDebug = false;
    public String m_sCreateType = 'HRO Field';
    
    WebService static String MassCreateCaseFromField(String sCaseId, String sAccountId)
    {
        try
        {
            Id idCase = sCaseId;
            
            fkCreateUtils fkObj = new fkCreateUtils();
            return fkObj.CopyCaseFromField(sAccountId, sCaseId);
            
            //if (fkObj.m_iCnt > 0)
            //    return 'Copied case to ' + fkObj.m_iCnt + ' child accounts';
            //else
            //    return 'error';
        }
        catch(Exception ex)
        {
            System.debug('EXCEPTION CopyRelated ' + ex.getMessage());
            return ex.getMessage();
        }
    }
    
    WebService static String GetMassCreateType()
    {
        String sCreateType = 'Account Hierarchy';
        try
        {
            // see what we are doing
            MassCreateConfig__c[] aMassCreate = [SELECT Id,Mass_Create_Type__c,Name FROM MassCreateConfig__c limit 1];
            MassCreateConfig__c massCreate;
            
            if (aMassCreate.size() < 1)
            {
                //  create one
                massCreate = new MassCreateConfig__c();
                massCreate.Mass_Create_Type__c = sCreateType;
                insert massCreate;
            }
            else
                massCreate = aMassCreate[0];
                
            if ('Account Hierarchy' != massCreate.Mass_Create_Type__c)
                return 'hro';

            return 'child';
        }
        catch(Exception ex)
        {
            System.debug('EXCEPTION CopyCaseEx() ' + ex.getMessage());
            // if all else fails, just assume account hierarhy
            return ex.getMessage();
        }   
        finally
        {
        }   
        
    }   
    WebService static String CopyCaseEx(String sCaseId, String sAccountId)
    {
        String sCreateType = 'Account Hierarchy';
        try
        {
            String sCurrType = GetMassCreateType();
            if ('Account Hierarchy' != sCurrType)
                return MassCreateCaseFromField(sCaseId, sAccountId);

            return MassCreateCaseForChildren(sCaseId, sAccountId);
        }
        catch(Exception ex)
        {
            System.debug('EXCEPTION CopyCaseEx() ' + ex.getMessage());
            // if all else fails, just assume account hierarhy
            return MassCreateCaseForChildren(sCaseId, sAccountId);
        }   
        finally
        {
        }   
    }
    WebService static String MassCreateCaseForChildren(String sCaseId, String sAccountId)
    {
        try
        {
            Id idCase = sCaseId;
            
            fkCreateUtils fkObj = new fkCreateUtils();
            return fkObj.CopyCase(sAccountId, sCaseId);
/*            
            if (fkObj.m_iCnt > 0)
                return 'Copied case to ' + fkObj.m_iCnt + ' child accounts';
            else
                return 'error';
*/                
        }
        catch(Exception ex)
        {
            System.debug('EXCEPTION CopyCaseToChildren ' + ex.getMessage());
            return ex.getMessage();
        }
    }
    
    public String CopyCaseFromField(Id accountId, Id caseId)
    {
        m_caseIn = [select Id, AccountId, Description, origin, Subject  from CASE WHERE Id = :caseId];
        System.debug('CopyCaseFromField(): ' + m_caseIn);
        EnumerateChildren2(accountId, caseId);
        
        // if any cases have been copied, put cloneid in
        if (m_iCnt > 0)
        {
            m_caseIn.CloneId__c = caseId;
            update m_caseIn;
        }
        return 'Copied Case to  ' + m_iCnt + ' Account records';
    }
    
    public String CopyCase(Id accountId, Id caseId)
    {
        
        m_caseIn = [select Id, AccountId, Description, Subject from CASE WHERE Id = :caseId];
        System.debug('CopyCase(): ' + m_caseIn);
        EnumerateChildren(accountId, caseId);
        
        // if any cases have been copied, put cloneid in
        if (m_iCnt > 0)
        {
            m_caseIn.CloneId__c = caseId;
            update m_caseIn;
        }
        return 'Copied Case to  ' + m_iCnt + ' Account records';
    }
    public String EnumerateChildren2(Id accountId, Id caseId)
    {
        try
        {
            System.debug('EnumerateChildren2() ' + accountId);
            Account[] accs;
            // find all child accounts of THIS account
            accs = FindAccountsByHRO(accountId);
            
            for (Account acc2:accs)
            {
                System.debug(' EnumerateChildren2() Account: ' + acc2.Name);
                
                if (fIsDebug == false)
                {
                    Case caseNew = new Case();
                    caseNew.Subject = m_caseIn.Subject;
                    caseNew.Description = m_caseIn.Description;
                    caseNew.Origin = m_caseIn.Origin;
                    caseNew.CloneId__c = caseId;
                    
//                    caseNew.Asset = m_caseIn.Asset;
//                    caseNew.ContactId = m_caseIn.ContactId;
//                    caseNew.Operating_System__c = m_caseIn.Operating_System__c;

                    caseNew.AccountID = acc2.Id;        // put account in
        
                    System.debug('INSERTING Case for Account ' + acc2.Id);          
                    insert caseNew;                     // insert new case
                    ++m_iCnt;
                    
                    System.debug('EnumerateChildren2(): new Case:' + caseNew.Id);
                }
                else
                    System.debug('EnumerateChildren2(): new Case for account ' + acc2.Id);
            }
            return 'success';
        }
        catch(Exception ex)
        {
            System.debug('EnumerateChildren2:EXCEPTION ' + ex.getMessage());
            return ex.getMessage();
        }
    }

    public String EnumerateChildren(Id accountId, Id caseId)
    {
        try
        {
            System.debug('EnumerateChildren() ' + accountId);
            Account[] accs;
            // find all child accounts of THIS account
            accs = FindChildren(accountId);
            
            for (Account acc2:accs)
            {
                System.debug(' Account: ' + acc2.Name);
                
                if (fIsDebug == false)
                {
                    Case caseNew = new Case();
                    caseNew.Subject = m_caseIn.Subject;
                    caseNew.Description = m_caseIn.Description;
                    caseNew.Origin = m_caseIn.Origin;
                    caseNew.CloneId__c = caseId;
                    
//                    caseNew.Asset = m_caseIn.Asset;
                    caseNew.ContactId = m_caseIn.ContactId;
 //                   caseNew.Operating_System__c = m_caseIn.Operating_System__c;
/*
                    caseNew.ParentId = m_caseIn.ParentId;
                    caseNew.Priority = m_caseIn.Priority;
                    caseNew.Reason = m_caseIn.Reason;
                    caseNew.RecordTypeId = m_caseIn.RecordTypeId;
                    caseNew.Status = m_caseIn.Status;
                    caseNew.Type = m_caseIn.Type;
*/                   
                    caseNew.AccountID = acc2.Id;        // put account in
        
                    System.debug('INSERTING Case for Account ' + acc2.Id);          
                    insert caseNew;                     // insert new case
                    ++m_iCnt;
                    
                    System.debug('EnumerateChildren(): new Case:' + caseNew.Id);
                }
                else
                    System.debug('EnumerateChildren(): new Case for account ' + acc2.Id);
                
                // for each child account, find IT'S child accounts and recurse
                EnumerateChildren(acc2.Id, m_caseIn.Id);
            }
            return 'success';
        }
        catch(Exception ex)
        {
            System.debug('EnumerateChildren:EXCEPTION ' + ex.getMessage());
            return ex.getMessage();
        }
    }
    
    // we have a child object, do some operation for each
    public void OnChildFound(Account accChild)
    {
        Case caseRoot = (Case)rootObj;
        Case caseNew2 = caseRoot.clone();
        
        caseNew2.AccountID = accChild.Id;       // put account in
        insert caseNew2;                        // insert new case
    }
        
    public static Account[] FindChildren(Id accountId)
    {
        try
        {
            system.debug('FindChildren() ' + accountId);
            // select all accounts that have this guy as parent and that don't already have this case
            
//          Account [] accs = [select id,Name from ACCOUNT where ParentId= :accountId and Id <> :accountId];
            Account [] accs = [select id,Name from ACCOUNT where ParentId= :accountId and Id <> :accountId];
            
            return accs;
        }
        catch(Exception ex)
        {
            System.debug('FindChildren:EXCEPTION ' + ex.getMessage());
            return null;
        }
    }
    public static Account[] FindAccountsByHRO(Id accountId)
    {
        try
        {
            system.debug('FindAccountsByHRO() ' + accountId);
            // select all accounts that have this guys HRO Id
            Account acc = [select id, HRO_Test__c, Type from ACCOUNT where Id = :accountId];
            Account [] accs = [select id, Name from ACCOUNT where HRO_Test__c <> null and HRO_Test__c = :acc.HRO_Test__c and Id <> :accountId];
            system.debug('FindAccountsByHRO() found ' + accs.size() + ' records');
            
            return accs;
        }
        catch(Exception ex)
        {
            System.debug('FindAccountsByHRO:EXCEPTION ' + ex.getMessage());
            return null;
        }
    }

}