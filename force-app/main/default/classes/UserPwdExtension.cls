/**
 * Controller for UserPwdExtension controller class
 *
 * History
 * --------
 * 07/06/2014 Cindy Freeman     modified to give choice of test users or NSS test users
 * 08/22/2014 Cindy Freeman     fixed bug in NSS batch 2
   10/29/2018 Dan Carmen        Increment API to version 44

 */

public with sharing class UserPwdExtension {
    private final User userObj;
    public boolean orgBad {get; set;}   // public so test class can see it
    public String emale {get; set;}     // public so test class can see it
    public String uzers {get; set;}
    private Integer cntr = 0;
    
    public UserPwdExtension(ApexPages.StandardController controller) 
    {   this.userObj = (User)controller.getRecord();
        User usr = [SELECT email from User where id = :userObj.Id];
        emale = usr.email;
    }
    
    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>(); 
        options.add(new SelectOption('testUsers','Test Users')); 
        options.add(new SelectOption('testNsrs','Test NSRs')); 
        return options; 
    }
    
    
    
    public String getWhoandWhere () 
    {
        String ans;
        ans = Utilities.checkForProduction();
        if (ans == null)
        {   ans = 'This is the production org.  You can not run this here!';
            orgBad = true;
        }
        else
        {   ans = 'Welcome ' + UserInfo.getName();
            orgBad = false;
        }
                
        return ans;
    }
   
    public void resetPwd1 ()
    {   cntr = 0;       
        if (orgBad)
        {   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Not a sandbox, Reset1 DENIED!');
            ApexPages.addMessage(myMsg);
        }
        else if (uzers == null)
        {   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Please pick a type of user to reset!');
            ApexPages.addMessage(myMsg);
        }
        else
        {   ResetPwds_Batch pwdBatch = new ResetPwds_Batch();            
            pwdBatch.email = emale;    
            if (uzers == 'testUsers')        
            {   pwdBatch.query = 'SELECT ID, username, firstname from User WHERE firstname like \'Test%\' and firstname < \'Test183\' and lastname = \'User\' and IsActive = true order by firstname';  
                cntr = [Select count() from User WHERE firstname like 'Test%' and firstname < 'Test183' and lastname = 'User' and IsActive = true];
            }
            else
            {   pwdBatch.query = 'SELECT ID, username, firstname from User WHERE Job_Name__c = \''+UserHelper.JOB_NSR+'\' and firstname like \'Test%\' and firstname < \'Test183\' and lastname = \'User NSS\' and IsActive = true order by firstname';     
                cntr = [SELECT count() from User WHERE Job_Name__c = :UserHelper.JOB_NSR and firstname like 'Test%' and firstname < 'Test183' and lastname = 'User NSS' and IsActive = true];
            }
            
            if (cntr > 0)
            {   ID batchprocessid = Database.executeBatch(pwdBatch);
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'Password 1-An email will be sent to you when ' + cntr + ' users have been updated. ');
                ApexPages.addMessage(myMsg);
            }
            else
            {   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'No users to be updated.');
                ApexPages.addMessage(myMsg);
            }            
        } // else (orgBad and uzers != null)
            
    } // resetPwd1
    
    public void resetPwd2 ()
    {   cntr = 0;
        if (orgBad)
        {   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Not a sandbox, Reset2 DENIED!');
            ApexPages.addMessage(myMsg);
        }
        else if (uzers == null)
        {   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Please pick a type of user to reset!');
            ApexPages.addMessage(myMsg);
        }        
        else
        {
            ResetPwds_Batch pwdBatch = new ResetPwds_Batch();            
            pwdBatch.email = emale;
            if (uzers == 'testUsers')            
            {   pwdBatch.query = 'SELECT ID, username, firstname from User WHERE firstname like \'Test%\' and firstname > \'Test182\' and firstname < \'Test275\' and lastname = \'User\' and IsActive = true order by firstname';
                cntr = [Select count() from User WHERE firstname like 'Test%' and firstname > 'Test182' and firstname < 'Test275' and lastname = 'User' and IsActive = true];
            }
            else
            {   pwdBatch.query = 'SELECT ID, username, firstname from User WHERE Job_Name__c = \'NSS Rep\' and firstname > \'Test182\' and firstname < \'Test275\' and lastname = \'User NSS\' and IsActive = true order by firstname'; 
                cntr = [SELECT count() from User WHERE Job_Name__c = :UserHelper.JOB_NSR and firstname > 'Test182' and firstname < 'Test275' and lastname = 'User NSS' and IsActive = true];
            }
            
            if (cntr > 0)
            {   ID batchprocessid = Database.executeBatch(pwdBatch);
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'Password 2-An email will be sent to you when ' + cntr + ' users have been updated. ');
                ApexPages.addMessage(myMsg);
            }
            else
            {   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'No more users to be updated.');
                ApexPages.addMessage(myMsg);
            }
        }  // else (orgBad and uzers != null)
            
    } // resetPwd2
    
    public void resetPwd3 ()
    {   cntr = 0;
        if (orgBad)
        {   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Not a sandbox, Reset3 DENIED!');
            ApexPages.addMessage(myMsg);
        }
        else if (uzers == null)
        {   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Please pick a type of user to reset!');
            ApexPages.addMessage(myMsg);
        }        
        else
        {
            ResetPwds_Batch pwdBatch = new ResetPwds_Batch();            
            pwdBatch.email = emale; 
            if (uzers == 'testUsers')           
            {   pwdBatch.query = 'SELECT ID, username, firstname from User WHERE firstname like \'Test%\' and firstname > \'Test274\' and lastname = \'User\' and IsActive = true order by firstname';
                cntr = [Select count() from User WHERE firstname like 'Test%' and firstname > 'Test274' and lastname = 'User' and IsActive = true];
            }
            else
            {   pwdBatch.query = 'SELECT ID, username, firstname from User WHERE Job_Name__c = \'NSS Rep\' and firstname like \'Test%\' and firstname > \'Test274\' and lastname = \'User NSS\' and IsActive = true order by firstname';    
                cntr = [SELECT count() from User WHERE Job_Name__c = :UserHelper.JOB_NSR and firstname like 'Test%' and firstname > 'Test274' and lastname = 'User NSS' and IsActive = true];
            }
             
            if (cntr > 0)            
            {   ID batchprocessid = Database.executeBatch(pwdBatch);
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'Password 3-An email will be sent to you when ' + cntr + ' users have been updated. ');
                ApexPages.addMessage(myMsg);
            }
            else
            {   ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.INFO, 'No more users to be updated.');
                ApexPages.addMessage(myMsg);
            }
        } // else (orgBad and uzers != null)   
            
    } // resetPwd3    
 
 
                 
}