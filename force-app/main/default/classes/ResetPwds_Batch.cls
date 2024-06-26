/**
 * Test class for this is UserPwdExtensionTest
 *
 * History
 * --------
   10/29/2018 Dan Carmen        Increment API to version 44
   08/10/2020 Jake Hinds    Changing debug statement per PMD

 */
global class ResetPwds_Batch implements Database.Batchable<sObject>, Database.Stateful {
    global String query;
    global String email;
    global String msg, firstuser, lastuser, newpwd;
    Integer cntr;
    
    global Database.querylocator start(Database.BatchableContext BC)
    {       
        return Database.getQueryLocator(query);
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        Datetime D8 = System.now();
        String mon = D8.format('MMM');
        String daa = D8.format('dd');
        String yr = D8.format('yyyy');
        String pwd = mon + daa + yr;
        newpwd= pwd;
        
        msg = '';
        firstuser = '';
        cntr = 0;
        
        List<User> usr = new List<user>();      
        try
        {   
            for(sObject s : scope) 
            {   User u = (User)s;
                if (firstuser.length() == 0)
                    {firstuser = u.username;}
                cntr ++;
                /////////  System.setPassword(u.ID, pwd ); 
                lastuser = u.username;                
            }
        }
        catch (Exception e1)
        {   msg = e1.getMessage();
            System.debug('temp ' + mon + daa + yr + ' got exception-' + e1 + ', cntr=' + cntr);
        }
    }
    
    global void finish(Database.BatchableContext BC) 
    {
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        mail.setSubject('Password reset');
        mail.setToAddresses(new String[] {email});
        mail.setReplyTo('cmfreeman@paychex.com');
        mail.setSenderDisplayName('Batch Process Completed');
        if (msg.length() == 0)
            {  mail.setHtmlBody(cntr + ' users have updated passwords = '+newpwd+'. Firstuser = ' + firstuser + '. Last user = ' + lastuser);  }
        else
            {  mail.setHtmlBody('ERROR, passwords not reset: ' + msg);  }
        Messaging.sendEmail(new Messaging.Singleemailmessage[] {mail });    
    }


} // class ResetPwds_Batch