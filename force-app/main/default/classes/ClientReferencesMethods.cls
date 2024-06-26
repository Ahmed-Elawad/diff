/* 
 * Methods to process new Client References to match them to accounts and contacts
 *
 * History
 * -------
 * 08/20/2017 Cindy Freeman     created
 * 03/08/2018 Cindy Freeman		fix bug if Primary Contact is blank 
   12/21/2022 Dan Carmen        Changed TriggerInterface, use SF Duplicate Management

 */ 

public with sharing class ClientReferencesMethods implements TriggerInterfaceC {
    

    /* counter needed for Test class to get better code coverage */
    public static Integer testcount = 0;

    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
       Client_Reference__c[] crs = (Client_Reference__c[])recs;
       if (isAfter && !crs.isEmpty()) {
           Id[] recIdsToProcess = new Id[]{};
           for (Client_Reference__c cr : crs) {
              Client_Reference__c oldCr = (oldMap != null ? (Client_Reference__c)oldMap.get(cr.Id) : null);
              if (oldCr == null && cr.Account__c == null) {
                 recIdsToProcess.add(cr.Id);
              }
           }
           if (!recIdsToProcess.isEmpty()) {
              processClientRef(recIdsToProcess);
           }
       }
    } // handleTrigger
    
   /* find account based on Bis ID, find Contact or create one 
    *********** Do we need to add logic to check for Bis IDS that did not find a matching Account?  Put in error log?
    */
    public static void processClientRef(Id[] recIds) {
        
        List<Client_Reference__c> crList = [Select Id, BIS_Id__c, Account__c, Contact__c, Primary_Contact__c, Primary_Contact_Email__c
                                            from Client_Reference__c where Id in :recIds];

        Set<Double> bisIdSet = new Set<Double>();
        for (Client_Reference__c cr :crList)
        {   if (cr.BIS_Id__c != null)
            {   bisIdSet.add(cr.BIS_Id__c);     }
        } // for
        System.debug('** ClientReferencesMethods processClientRef recIds='+recIds.size()+' bisIdSet='+bisIdSet);
        
        List<Account> acctList = [Select Id, Name, Bis_Id__c, RecordTypeId,
                                    (Select Id, Name, Phone, Email from Contacts where Sales_Contact__c = true)
                                    from Account where BIS_ID__c in :bisIdSet];
System.debug('** ClientReferencesMethods processClientRef, acctList='+acctLIst.size());       
        Map<Double, Account> bisidAcctMap = new Map<Double, Account>();
        Map<Double,List<Contact>> bisidCtctMap = new Map<Double, List<Contact>>();
        Set<Id> acctIdSet = new Set<Id>();
        for (Account acct: acctList)
        {   acctIdSet.add(acct.Id);
            List<Contact> ctctList = new List<Contact>();
            for (Contact ctct:acct.Contacts)
            {   ctctList.add(ctct); }
System.debug('** ClientReferencesMethods processClientRef, ctctList='+ctctList.size());           
            bisidCtctMap.put(acct.Bis_Id__c,ctctList);
            bisidAcctMap.put(acct.Bis_Id__c, acct);
        } // for (Account...

        // find ERAM account team members
        Map<Id, Id> acctIdUserIdMap = new Map<Id, Id>();
        List<AccountTeamMember> atmList = [Select UserId, TeamMemberRole, AccountId from AccountTeamMember                       
                          where AccountId in :acctIdSet and TeamMemberRole = 'Enterprise Client Support Representative'];
                          //where AccountId in :acctIdSet and TeamMemberRole = 'Enterprise Relationship Account Manager'];                          
        for (AccountTeamMember atm: atmList)
        {   if (!acctIdUserIdMap.containsKey(atm.AccountId))
            {   acctIdUserIdMap.put(atm.AccountId, atm.UserId); }
        }
System.debug('**ClientReferencesMethods processClientRef found ERAMs atmMap size='+acctIdUserIdMap.size());
        
        List<Client_Reference__c> updateCRList = new List<Client_Reference__c>();
        
        for (Client_Reference__c cr: crList)
        {   if (bisIdAcctMap.containsKey(cr.Bis_Id__c))
            {   Account acct = bisIdAcctMap.get(cr.Bis_Id__c);
                cr.Account__c = acct.Id;
                Boolean foundCtct = false;                  
                // match on name and email
                for (Contact ct:bisidCtctMap.get(cr.Bis_Id__c))
                {   if (ct.name == cr.Primary_Contact__c && cr.Primary_Contact_Email__c == ct.Email)
                    {   cr.Contact__c = ct.Id;
                        foundCtct = true;
                        break;
                    }  // if name and email match
                }  // for
                // match on name
                if (!foundCtct)
                {   for (Contact ct:bisidCtctMap.get(cr.Bis_Id__c))
                    {   if (ct.name == cr.Primary_Contact__c)
                        {   cr.Contact__c = ct.Id;
                            foundCtct = true;
                            break;
                        } // if name matches
                    } // for
                } // if (!foundCtct)
                // match on email
                if (!foundCtct)
                {   for (Contact ct:bisidCtctMap.get(cr.Bis_Id__c))
                    {   if (ct.Email == cr.Primary_Contact_Email__c)
                        {   cr.Contact__c = ct.Id;
                            foundCtct = true;
                            break;
                        } // if email matach
                    } // for
                } // if (!foundCtct)                
                if (!foundCtct && String.isNotBlank(cr.Primary_Contact__c) && String.isNotBlank(cr.Primary_Contact_Email__c))
                {   cr.Contact__c = createContact(cr, acct);    }
                
                // set to first ERAM found on account if there is one
                cr.ERAM__c = (acctIdUserIdMap.containsKey(acct.Id)? acctIdUserIdMap.get(acct.Id) : null);
                
                updateCRList.add(cr);       
            } // if (bisIdAcctMap.containsKey
            
        } // for (crList)
 
        //clientRefIdsToBeProcessed.clear();
        if (!updateCRList.isEmpty())
        {   update updateCRList;    }
 
    } // processClientRef
    
     // create contact
    private static Id createContact (Client_Reference__c cr, Account acct)
    {   Schema.RecordTypeInfo acctrt = RecordTypeHelper.getRecordTypebyId(acct.RecordTypeId, ObjectHelper.OBJECT_ACCOUNT);
        Schema.RecordTypeInfo ctctrt;
        if (acctrt.getName().contains('MMS'))
        {   ctctrt = RecordTypeHelper.getRecordType(RecordTypeHelper.MMS_CONTACT, ObjectHelper.OBJECT_CONTACT); }
        else
        {   ctctrt = RecordTypeHelper.getRecordType(RecordTypeHelper.CORE_CONTACT, ObjectHelper.OBJECT_CONTACT);    }

        Id existingCtctId = null;
        ZipCheckOwner.accountIdsProcessedSet.clear();       // do this so contact gets correct owner (same as account)
 
        String fName = null;
        String lName = null;     
        fName = cr.Primary_Contact__c.substringBefore(' ');
        lName = cr.Primary_Contact__c.substringAfter(' ');
        if (String.isBlank(fName) || String.isBlank(lName))
        {  fName = cr.Primary_Contact__c;
           lName = cr.Primary_Contact__c;
        }
     
        Contact newCtct = new Contact(recordtypeId = ctctrt.getRecordTypeId()
                                        ,FirstName = fname
                                        ,LastName = lname
                                        ,AccountId = cr.Account__c
                                        ,Email = cr.Primary_Contact_Email__c
                                        ,DoNotCall = false
                                        ,HasOptedOutOfEmail = false
                                        ,Use_Zip_Assignment_Rules__c = true);            
        DuplicateHelper.DupeResult[] results = DuplicateHelper.findDuplicates(new Contact[]{newCtct}); 
        if (results[0].hasResults && !results[0].ctctIds.isEmpty()) {
           existingCtctId = results[0].ctctIds[0];
        }
        /*
        CRMfusionDBR101.DB_Api.preventBlocking();
        List<CRMfusionDBR101.DB_Api.Matches> matchSets = CRMfusionDBR101.DB_Api.findMatches(newCtct);        
       
        if (!matchSets.isEmpty())
        {       Set<Id> matchedCtctSet = new Set<Id>(); 
                for ( CRMfusionDBR101.DB_Api.Matches matchSet : matchSets )
                {   for (Id matchId : matchSet.matchedIds)
                    {   matchedCtctSet.add(matchId);        }
                }
         
                if (matchedCtctSet.size() > 1)
                {   //throw new SOARException('multiple Contact matches found by DupeBlocker-'+matchSets);  
                
                }
                else
                {   for (Id cid : matchedCtctSet)
                    {   existingCtctId = cid;   }
                }         
        } // if !matchSets.isEmpty        
        //else
        */
        if (existingCtctId == null) {
           try {  
               insert newCtct;
               existingCtctId = newCtct.Id;
           } catch (exception e) {
               String errmsg = e.getMessage();
               ErrorLog.logError('ClientReferencesMethods', 'processClientRef', 'create new contact insert error', null, errmsg);
               ErrorLog.checkSave();   
           } // catch
        } // else
        //newCtct = [Select Id, Name, FirstName,LastName, Phone, Owner.Id, recordtypeId, AccountId, Email 
        //       from Contact where Id = :existingCtctId];  // requery just in case               

        return existingCtctId;
    } // createContact
    
} //  ClientReferencesMethods