/*
 *  This class will process the parsed messages received from email services.  It will search for the referral account 
 *  and/or contact, creating 1 or both of needed.  Then create a task for a wholesaler to contact this FA.
 *
 * History
 * --------
 * 04/24/2013  Cindy Freeman    created
 * 08/01/2013  Cindy Freeman	modified to set activity_source on task so we know where it came from, used in Referral Engine code
 * 01/20/2014  Cindy Freeman	modified to blank out bad email address so insert doesn't fail, blank out state if length > 2
 * 11/08/2021  Jermaine Stukes	Removed references to external wholesaler owner fields
 */

public with sharing class WebFALeadHelper {
    public class FAlead {
        public String firstName;
        public String lastName;
        public String fullName;
        public String company;
        public String email;
        public String phone;
        public String squishedPhone;
        public String street;
        public String city;
        public String state;
        public String zip;
        public String comments;
        public String calltype;
        public ID refAcctId;
        public ID refCtctId;
        public ID userId;
        public Boolean createTask;
        public Boolean isError;
    }
    
    // gather any ref ctcts that need updates to phone or email
    private static List<Referral_Contact__c> updateRefCt = new List<Referral_Contact__c>();
    
    public static void processFAlead(List<FAlead> faList) {
        Schema.RecordTypeInfo taskHRSrt = RecordTypeHelper.getRecordType('HRS Task Record Type', 'Task');
        Date nextday = Date.today().addDays(1);     
        Referral_Contact__c foundRefCt;
        Referral_Account__c foundRefAcct;
                
        List<Task> newTaskList = new List<Task>();
        for (FAlead fa: faList)     
        {   foundRefAcct = findRefAcct(fa);
            if (foundRefAcct == null)
            {   foundRefAcct = createRefAcct(fa);   }
            foundRefCt = findRefCt(foundRefAcct, fa);
            if (foundRefCt == null)
            {   foundRefCt = createRefCt(foundRefAcct.Id, fa);  }
                        
            if (foundRefCt != null)
            {   Id taskOwner;
                /*if (foundRefCt.External_Wholesaler_Contact_Owner__c != null)
                {   taskOwner = foundRefCt.External_Wholesaler_Contact_Owner__c;    }
                else */if (foundRefCt.Internal_Wholesaler_Contact_Owner__c != null)
                {   taskOwner = foundRefCt.Internal_Wholesaler_Contact_Owner__c;    }
                else if (foundRefCt.Referral_Account__r.HRS_Account_Owner__c != null)
                {   taskOwner = foundRefCt.Referral_Account__r.HRS_Account_Owner__c;    }
                else
                {   taskOwner = foundRefCt.Referral_Account__r.Owner.Id;    }
                Task tsk = new Task(RecordTypeId = taskHRSrt.getRecordTypeId()
                                    , Description =  fa.comments
                                    , Lead_Source_WAR_Call_Type__c = fa.calltype
                                    , Type = 'Call'                                 
                                    , Priority = 'Normal'
                                    , Status = 'Not Started'
                                    , Subject = 'Financial Advisor requests a conversation'
                                    , Activity_Source__c = 'FAEmailSvc'
                                    , IsReminderSet = true
                                    , ReminderDateTime = System.now()+1                                     
                                    , ActivityDate = nextday
                                    , Product__c = 'Large Market 401K' 
                                    , WhatId =  foundRefCt.Id
                                    , OwnerId = taskOwner);
                newTaskList.add(tsk);           
            }
        } // for faList
                                        
        if (!newTaskList.isEmpty())
        {   Database.DMLOptions dml = new Database.DMLOptions();
            dml.EmailHeader.triggerUserEmail = true;
            database.insert(newTaskList, dml);
        }
                
        if (!updateRefCt.isEmpty())
        {   update updateRefCt; }
        
    } // processFAlead


    // try to find the referral account
    // matches by 70% of name AND street number AND zip5
    private static Referral_Account__c findRefAcct (FAlead fa)
    {   Referral_Account__c foundRefAcct;
        List<Referral_Account__c> foundList = new List<Referral_Account__c>();
        ReferralSearch rs = new ReferralSearch();
        Boolean okay = rs.searchRfrlAccts(fa.company, fa.street, fa.zip);
        if (okay)
        {   foundList = rs.searchRefAcctResults;    }
    
        if (foundList.size() >= 1)
        {   foundRefAcct = foundList.get(0);    }
        
        return foundRefAcct;
                   
    } // findRefAcct
    
        
    // try to find the referral contact from referral account we already found
    // matches by full name OR last name and email OR last name and phone
    private static Referral_Contact__c findRefCt (Referral_Account__c refAcct, FAlead fa)
    {   ReferralSearch rs = new ReferralSearch();       
        Referral_Contact__c foundRefCt = rs.searchRfrlCtct(refAcct.Id, fa.FullName, fa.LastName, fa.phone, fa.email) ;
        if (foundRefCt != null)
        {   String refctnewPhone;           
            if (foundRefCt.Phone__c != null)       
            {   refctnewPhone = Utilities.removeExtraChars(foundRefCt.Phone__c, '0123456789');    }  
            Boolean tempUpCtct = false;
            if (refctnewPhone != fa.squishedPhone && fa.squishedPhone != null)
            {   foundRefCt.Phone__c = fa.phone;
                tempUpCtct = true;
            }
            if (foundRefCt.Email__c != fa.email && fa.email != null)
            {   foundRefCt.Email__c = fa.email;
                tempUpCtct = true;
            }
            if (tempUpCtct)
            {   updateRefCt.add(foundRefCt);    }
        }
                
        return foundRefCt;
                   
    } // findRefCt
          
        
          
    // create referral account
    private static Referral_Account__c createRefAcct (FAlead fa)
    {   Schema.RecordTypeInfo refacctrt = RecordTypeHelper.getRecordType('HRS Referral Source Record Type', 'Referral_Account__c');
        Referral_Account__c tempRefAcct;
    
        Referral_Account__C newRefAcct = new Referral_Account__c(recordtypeId = refacctrt.getRecordTypeId()
                                        ,Name = fa.company
                                        ,Phone__c = fa.phone
                                        ,Street_Address_1__c = fa.street
                                        ,City__c = fa.city
                                        ,State_Province__c = fa.state
                                        ,Zip_Postal_Code__c = fa.zip
                                        ,Use_Zip_Assignment_Rules__c = true);
        try
        {   insert newRefAcct;
            tempRefAcct = [Select Id, Owner.Id from Referral_Account__c where Id = :newRefAcct.Id];
            
        }
        catch (exception e)
        {   System.debug('**CMF ** error inserting newRefAcct, msg='+e.getMessage()+' newRefAcct='+newRefAcct); 
            throw e;
        }
        
        return tempRefAcct;
    } // createRefAcct      
                
    // create referral contact
    private static Referral_Contact__c createRefCt  (Id refAcctId, FAlead fa)
    {   Schema.RecordTypeInfo refctrt = RecordTypeHelper.getRecordType('HRS Referral Record Type', 'Referral_Contact__c');
        Referral_Contact__c tempRefCt;
    
        Referral_Contact__C newRefCt = new Referral_Contact__c(recordtypeId = refctrt.getRecordTypeId()
                                        ,Name = fa.fullName
                                        ,Email__c = fa.email
                                        ,Phone__c = fa.phone
                                        ,Referral_Account__c = refAcctId
                                        ,Referral_Type__c = 'Unknown'
                                        ,Use_Account_Ownership__c = true);
        try
        {   insert newRefCt;
            tempRefCt = [Select Id, Owner.Id, Internal_Wholesaler_Contact_Owner__c,
                            Referral_Account__r.HRS_Account_Owner__c, Referral_Account__r.Owner.Id from Referral_Contact__c where Id = :newRefCt.Id];            
        }
        catch (exception e)		
        {	System.debug('**CMF ** error inserting newRefCt, msg='+e.getMessage()+' newRefCt='+newRefCt);   
           	throw e;
        }
        
        return tempRefCt;
    } // createRefCt      

    // this exception is used to throw missing data error messages
    public class FAException extends Exception {}
      
    public static FAlead parseXml(String toParse) 
    {   String tempStr;
    	// fix email address     	
    	Integer x1 = toParse.indexOf('<mailto:');
    	if (x1 > 0)
    	{	Integer x2 = toParse.indexOf('</email>',x1);
    		tempStr = toParse.substring(0,x1);
    		tempStr += toParse.substring(x2);    		
    	}    		
    	else
    	{	tempStr = toParse;	}
    	// fix & in company name
    	tempStr = tempStr.replaceAll('&', '&amp;');
    	Map<String, String> tempParse = new Map<String, String>();
        FALead fa = new FALead();
        DOM.Document doc = new DOM.Document();
        try {
            doc.load(tempStr);
            DOM.Xmlnode root = doc.getRootElement();
            tempParse = walkthrough(root, tempParse);     
System.debug('**CMF ** parseXml tempParse='+tempParse);                 
            fa.firstName = tempParse.get('firstname');
            fa.lastName = tempParse.get('lastname');
            fa.fullName = fa.firstName + ' ' + fa.lastName;
            fa.company =  tempParse.get('company');
            fa.email =  tempParse.get('email');
            Boolean ok = validateEmail(fa.email);					// is the email in a valid format?
System.debug('**CMF ** email is ok ='+ok);            
            fa.email = (ok ? fa.email : null);
            fa.phone =  tempParse.get('phone');
            fa.squishedPhone = Utilities.removeExtraChars(fa.phone, '0123456789');        
            fa.street =  tempParse.get('street');
            fa.city =  tempParse.get('city');
            fa.state =  tempParse.get('state');
            fa.state = (fa.state.length() > 2 ? null : fa.state);
            fa.zip =  tempParse.get('zip');
            fa.comments =  tempParse.get('comments');       
            fa.calltype = tempParse.get('calltype');        
        }
        catch (System.Xmlexception ex) {
            throw ex;
        }       
        if (fa.company == null || fa.company.length() == 0)
        {   Throw new FAException('missing company');   }
        else if (fa.fullName == null || fa.fullName.length() ==0)
        {   Throw new FAException('missing contact name');  }

        return fa;
            
    } // parseXML

    private static Map<String, String> walkthrough(DOM.XMLnode node, Map<String, String> tempParse)
    {   if (node.getNodeType() == DOM.XMLNodeType.ELEMENT) 
        {   //tempParse.put(node.getName(), node.getText().trim()); 
            String nam = node.getName();
            String txt = node.getText().trim();
            txt = txt.replaceAll('\n', '');
            txt = txt.replaceAll('\r', '');       
            tempParse.put(nam,txt);
        }
            
        for (Dom.XMLNode child: node.getChildElements()) 
        {   tempParse = walkThrough(child, tempParse);  }       
        return tempParse;
    } // walkthrough    
    
    /** use a regular expression to validate the email address so an insert or update doesnt bomb
    */    
    private static Boolean validateEmail(String emailString) {
    	Boolean okay = false;
    	String emailRegex = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
		Pattern MyPattern = Pattern.compile(emailRegex);
		Matcher MyMatcher = MyPattern.matcher(emailString);
		if (MyMatcher.matches()) 
    	{	okay = true;	}
    	return okay;
    } // validateEmail
      
 /** this code is incase the FA lead web form data comes in as plain text and not as an xml document
              
    public static FAlead parse(String toParse) 
    {    FALead fa = new FAlead();
         fa.firstName = findInput(toParse, 'FirstName: ');
         fa.lastName = findInput(toParse, 'LastName: ');
         fa.fullName = fa.firstName + ' ' + fa.lastName;
         fa.company =  findInput(toParse, 'Company: ');
         fa.email =  findInput(toParse, 'Email: ');
         fa.phone =  findInput(toParse, 'Phone: ');
         fa.squishedPhone = Utilities.removeExtraChars(fa.phone, '0123456789');        
         fa.street =  findInput(toParse, 'Street: ');
         fa.city =  findInput(toParse, 'City: ');
         fa.state =  findInput(toParse, 'State: ');
         fa.zip =  findInput(toParse, 'Zip: ');
         fa.comments =  findInput(toParse, 'Comments: ');       // will stop at first CR within comments unless change findInput
         fa.calltype = findInput(toParse, 'CallType: ');        
         return fa;
   } // parse
 
   // find value and trim it
   private static String findInput (String str, String parameter)
   {   String ans;             
        if (str.indexOfIgnoreCase(parameter) > -1)
        {   ans = str.substringBetween(parameter, '\n');                    // look for ending NL
            if (ans == null)
            {   ans = str.substringBetween(parameter, '\r');    }           // look for ending CR         
            if (ans != Null && ans.length() > 0 )
            {   ans = ans.trim();   }
        }       
        return ans;
   } // findInput   
 */
    
  
} // WebFALeadHelper