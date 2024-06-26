/* 
 * A class used for CPA web service calls
 *
 * History
 * -------
 * 06/25/2017 	Jermaine Stukes   Created
   03/04/2019  Dan Carmen        Add more logging to the Web Service Log
 
 */
global with sharing class cpaServices {
 
    global class RepInfo {
        webservice String repFirstName;
        webservice String repLastName;
        webservice String repEmail;
        webservice String repPhone;
        webservice String repPhoneExt;
        webservice String acctName;
        webservice String partnerId;
    } // RepInfo
      
    //Return Rep info, Account name, and PartnerId
	static webservice RepInfo getRepInfo(string contactId)
    {
        RepInfo ri = new RepInfo();
        Boolean successful;
        String errorLog;
        String notes = 'contactId='+contactId;
        try
        {
            Referral_Contact__c RC = [Select Id, Name, Contact_ID__c, Referral_Account__r.Id, Referral_Account__r.Name, Referral_Account__r.PartnerId__c,OwnerId, Owner.Id, Owner.FirstName, Owner.LastName, Owner.Email, Owner.Phone from Referral_Contact__c where Contact_ID__c=:contactId limit 1];
            notes += ' rc='+rc;
            if(RC != Null)
            {
                if(RC.Owner.Phone!=Null)
                {
                    string parsedPhone = Utilities.removeExtraChars(RC.Owner.Phone, '1234567890');
                    if(parsedPhone.length() > 10)
                    {
                        ri.repPhone = parsedPhone.substring(0,10);
                        ri.repPhoneExt = parsedPhone.substring(10);
                    }
                    else
                    {ri.repPhone = RC.Owner.Phone;}
                }
                else
                {
                    ri.repPhone = null;
                }
                ri.repFirstName = RC.Owner.FirstName;
                ri.repLastName = RC.Owner.LastName;
                ri.repEmail = RC.Owner.Email;
                ri.acctName = RC.Referral_Account__r.Name;
                ri.partnerId = RC.Referral_Account__r.PartnerId__c;
                successful = true;
            }
        }
        catch(Exception e)
        {
            ri = null;
            successful = false;
            errorlog+= 'Cpa Services issue: '+e.getMessage();
        }
        WebServicesHelper.logServiceCall('cpaServices', successful, (String.isNotBlank(errorlog) ? errorlog: null), notes);
        return ri;
    }
} // cpaServices