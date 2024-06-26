/* 
 * Before LeadStrategyView record is saved, make sure the query will run.
 *
 * History
 * -------
 * 04/02/2012 Cindy Freeman   Created
 * 01/20/2014 Cindy Freeman	  Modified to check Show My Zipcodes, only works on Leads and Accounts
 							  prevent Show_Account_Teams and Show_My_Zipcodes both being set
 *
 */
trigger LeadStrategyViewCheckSOQL on Lead_Strategy_Views__c (before insert, before update) {
     
        List<String> sqls = new List<String>();
        List <SObject> sobj;
        ID UserID = Userinfo.getUserID();
        String errmsg = '';
                       
        for(Integer i = 0; i < trigger.size; i++)
        {   String tempsoql = trigger.new[i].SOQL__c.toLowerCase();
            
            Set<ID> acctTeams = new Set<ID>();
            if (trigger.new[i].Show_Account_Teams__c && trigger.new[i].Show_My_ZipCodes__c)
            {	errmsg += 'You can not show Account Teams and My Zipcodes at the same time.  Please pick one option. ';	}

            if (trigger.new[i].Show_Account_Teams__c)
            {   if (tempsoql.contains('account'))
	               {   for (AccountTeamMember atm : [Select accountid from accountteammember where userid = :UserID])
                   	   {   acctTeams.add(atm.accountId);   }                           
                   if (tempsoql.contains('ownerid = :userid') || tempsoql.contains('ownerid=:userid'))                     
                   {   integer y = tempsoql.indexof('ownerid',tempsoql.indexof('where'));
	                   String x = tempsoql.substring(0,y) + '(ownerid = :userid or id in :acctteams)';                 
                       tempsoql = x;
                   }
                   else if (tempsoql.contains('where'))
                   {   tempsoql = tempsoql + ' and Id in :acctteams ';   }
                   else
                   {   tempsoql = tempsoql + ' where id in :acctteams';    } 
               	}
               	else
               	{   errmsg += 'Your query must select records from the Account object if you want to Show Account Teams. '; }
            } // if Show_Account_Teams__c
             
            Set<String> zipcodeSet = new Set<String>();
            if (trigger.new[i].Show_My_ZipCodes__c)
            {	for (Zip_Assignment__c zip : [Select Name from Zip_Assignment__c where User__r.Id = :UserID])	// get list of rep's zip assignments
            	{	zipcodeSet.add(zip.Name);	}
            	String zipField = (trigger.new[i].Parent_Object__c == 'Account' ? 'Owner_ZipCode__c' : 'postalcode');            		
            		if (tempsoql.contains('ownerid = :userid') || tempsoql.contains('ownerid=:userid'))                     
                	{   integer y = tempsoql.indexof('ownerid',tempsoql.indexof('where'));
	                    String x = tempsoql.substring(0,y) + '(ownerid = :userid or ' + zipField + ' in :zipcodeSet)';                 
                    	tempsoql = x;
                	}
                	else if (tempsoql.contains('where'))
                	{   tempsoql = tempsoql + ' or ' + zipField + ' in :zipcodeSet ';   }
                	else
                	{   tempsoql = tempsoql + ' where ' + zipField + ' in :zipcodeSet';    }
            	
            	
            }   
            String sqlstmt = tempsoql;  
            
            if (trigger.new[i].order_by__c != null)
            {   sqlstmt = sqlstmt + ' order by ' + Trigger.new[i].order_by__c;  }
            
            sqlstmt += ' limit 10';		// we are just checking syntax not validating data
                    
            String pfields = Trigger.new[i].Parent_Fields__c.toLowerCase().replace(' ','');
            for (String p: pfields.split(','))
            {   if (!sqlstmt.contains(p))
                { errmsg += 'Parent field "' + p + '" missing from soql statement. ';   }
            }
            if (Trigger.new[i].Child_fields__c != null)
            {   String cfields = Trigger.new[i].Child_Fields__c.toLowerCase().replace(' ','');
                for (String c: cfields.split(','))
                {   if (sqlstmt.indexOf(c,sqlstmt.indexOf('(')) == -1)
                    { errmsg += 'Child field "' + c + '" missing from soql statement. ';    }
                }
            }
            
            if (errmsg.length() == 0)
            {   try 
                {   sobj = new List<SObject> (Database.Query(sqlstmt));     }
                catch (Exception e)
                {   trigger.new[i].addError('*** BAD SOQL statement ***  ' + e.getMessage());   }
            }
            else
            {   trigger.new[i].addError('*** Please review your query statement. ***  ' + errmsg);  }
        }
            
}