/*
 * Integration with FlexForward System
 *
 * History
 * -------
 * 05/29/2018 Jake Hinds   Created
 * 01/31/2018 Jake Hinds   Adding scrubbing for CSR Name, alias search.
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
 * 05/01/2022  Reetesh Pandey      Added code to update reference Core Payroll
 * 09/12/2022  Reetesh Pandey      update reference Core Payroll to set Original Proposed Date
 * 11/04/2022  Reetesh Pandey      update code to fix duplicate error in reference Core Payroll
 * 1/25/2023   Susmitha Somavarapu Added and updating specific RCP fields based on the Insite data in order to ensure it is accurate
 * 03/09/2023  Eric Porter         new Test method for update Ref Core Payroll and enhancement for Sharepoint Obsoletion
 * 06/14/2023  Eric Porter         Added code to remove duplicates for updates, 
 * 06/28/2023  Eric Porter         Removed error coding for RCPs found via OpptyIds
 * 07/19/2023  Eric Porter         Ensured OpptyId String matched our collection to be found(15 character string vs 18 Character string)
 * 04/04/2024  Susmitha Somavarapu APR0158678: Change an existing fields in SF/allow feed from Insite System into SF
 * 06/07/2024  Susmitha Somavarapu Commented out the createCase method since it's not actively called from Insite and SF(APR0171211).


 */

global without sharing class FFSService {
  //Commented out the createCase logic as per this APR0171211 - Sush
   /* global class CaseRecord {
    webService String CaseId;
    webService String BisID; //Bis_ID__c
    webService String ClientName;
    webService String ClientNumber;
    webService Date FlexFirstRunDate;
    webService String MigrationContactName;
    webService String Subject;
    webService String GoingLostDescription;
    webService String CSRUsername;
    webService String FlagName;
    webService String FlagComments;
    webService String Error;
  } */

 /* webService static list < CaseRecord > createCase(List < CaseRecord > cRecord) {
    Set < String > userSet = new Set < String > ();
    List < Case > upsertCases = new List < Case > ();
    Set < Decimal > BisIdSet = new Set < Decimal > ();
    Set < String > cltNbrSet = new Set < String > ();
    //store account by bis id, if bis is blank, store clt #
    Map < String, Account > accountByBisCltNbrMap = new Map < String, Account > ();
    //put csrUsername,bis,Clt # in sets to query against
    for (CaseRecord c: cRecord) {
      if (String.isNotBlank(c.CSRUserName)) {
        c.CSRUserName = c.CSRUserName.toLowerCase();
        c.CSRUserName = c.CSRUserName.replaceAll('\\s+', '');
        userSet.add(c.CSRUsername + '%');
      }
      if (String.isNotBlank(c.BisId)) {
        BisIdSet.add(Decimal.valueOf(c.BisId));
      } else if (String.isNotBlank(c.ClientNumber)) {
        cltNbrSet.add(c.ClientNumber);
      }
    }
    system.debug('FFSService createCase userSet' + userSet);
    Account[] accountList = new List < Account > {};

    //try to find account passed in based on BIS Id or Client Number, BIS ID is more likely to return a match.
    if (!BisIdSet.isEmpty() || !cltNbrSet.isEmpty()) {
      accountList = [
        SELECT
        id,
        Bis_ID__c,
        AccountNumber,  MMS_MAM_NAM__c, MMS_MAM_NAM__r.Name,
        (SELECT id FROM contacts WHERE Decision_Maker__c = TRUE LIMIT 1)
        FROM account
        WHERE Bis_ID__c IN: BisIdSet OR AccountNumber IN: cltNbrSet
      ];
    }
    for (Account acc: accountList) {
      if (BisIdSet.contains(acc.Bis_ID__c)) {
        accountByBisCltNbrMap.put(String.valueOf(acc.Bis_Id__c), acc);
      }
      if (cltNbrSet.contains(acc.AccountNumber)) {
        accountByBisCltNbrMap.put(acc.AccountNumber, acc);
      }
    }
    Id caseRTId = Schema.SObjectType.Case.getRecordTypeInfosByName()
      .get('Service Support MPSC Case')
      .getRecordTypeId();
    Group[] queues = [
      SELECT Id, Name
      FROM Group
      WHERE
      Type = 'Queue'
      AND(NAME = 'Data Integrity Queue'
        OR Name = 'Preview CSR Supervisor')
      LIMIT 2
    ];
    Id diq;
    Id pcsq;
    for (Group q: queues) {
      if (q.Name == 'Data Integrity Queue') {
        diq = q.Id;
      } else if (q.Name == 'Preview CSR Supervisor') {
        pcsq = q.Id;
      }
    }
    list < user > ExistUserList = new List < User > ();
    //the key to this map is going to be the bis id+subject, if the bis id is blank then the key will be clt nbr+subject.
    //this will allow the service to consume 1 case per type per client
    Map < String, CaseRecord > caseByKeyMap = new Map < String, CaseRecord > ();

    //query users that might match csrUsernames
    ExistUserList = [
      SELECT id, username, name, email, alias
      FROM user
      WHERE(username LIKE: userSet OR Email LIKE: userSet OR Alias LIKE: userSet)
      AND isActive = TRUE
    ];
    Map < String, User > userByCSRName = new Map < String, User > ();
    //strip away the % symbol needed for LIKE search.  need an exact match to match correctly to the map.
    for (String userName: userSet) {
      userSet.remove(userName);
      userName = userName.substringBefore('%');
      userSet.add(userName);
    }
    for (User u: ExistUserList) {
      //csrUsername sent in will be max 8 characters.  trim down user record values to try and match what was originally sent in. Take the first match if multiple
      String truncatedName = u.Username.substringBefore('@').left(8);
      String truncatedEmail = u.Email.substringBefore('@').left(8);
      String truncatedAlias = u.Alias.substringBefore('@').left(8);
      system.debug(
        'FFSService createCase username:' +
        truncatedName +
        ' email:' +
        truncatedEmail +
        '->' +
        userSet
      );
      if (
        userSet.contains(truncatedName) &&
        !userByCSRName.containsKey(truncatedName)
      ) {
        userByCSRName.put(truncatedName, u);
      }
      if (
        userSet.contains(truncatedEmail) &&
        !userByCSRName.containsKey(truncatedEmail)
      ) {
        userByCSRName.put(truncatedEmail, u);
      }
      if (
        userSet.contains(truncatedAlias) &&
        !userByCSRName.containsKey(truncatedAlias)
      ) {
        userByCSRName.put(truncatedAlias, u);
      }
    }
    system.debug('FFSService createCase userMap:' + userByCSRName);
    system.debug('FFSService createCase accountMap: ' + accountByBisCltNbrMap);
    for (CaseRecord cr: cRecord) {
      Case c = new Case();
      //look for account to add to case from BIS ID or Clt #, cannot create case without it
      if (
        String.isNotBlank(cr.BisId) &&
        accountByBisCltNbrMap.containskey(cr.BisId)
      ) {
        Account acc = accountByBisCltNbrMap.get(cr.BisId);
        c.accountId = acc.Id;
        //look for contact to add to case, can proceed without it.
        if (!acc.contacts.isEmpty()) {
          c.contactId = acc.contacts[0].Id;
        }
      } else if (accountByBisCltNbrMap.containskey(cr.ClientNumber)) {
        Account acc = accountByBisCltNbrMap.get(cr.ClientNumber);
        c.accountId = acc.Id;
        //look for contact to add to case, can proceed without it.
        if (!acc.contacts.isEmpty()) {
          c.contactId = acc.contacts[0].Id;
        }
      } else {
        cr.Error = 'Could not find matching account';
      }
      c.Bis_ID__c = (String.isNotBlank(cr.BisId) ?
        Decimal.valueOf(cr.BisID) :
        null);
      c.Client_Number__c = (String.isNotBlank(cr.ClientNumber) ?
        cr.ClientNumber :
        null);
      c.recordtypeid = caseRTId;
      c.status = 'New';
      c.Product__c = 'Other';
      c.origin = 'FFS';
      if (String.isNotBlank(cr.CaseId)) {
        c.Id = (Id) cr.CaseId;
      }
      c.reason = cr.subject;
      c.subject = cr.subject;
      c.Description =
        date.today().month() +
        '/' +
        date.today().day() +
        '/' +
        date.today().year() +
        ':\n';
      if (cr.subject == 'Client Going Lost') {
        //look for owner from query.  set to queue if we can't find the owner. Only set owner on insert
        if (String.isBlank(cr.CaseId)) {
          if (
            String.isNotBlank(cr.CSRUsername) &&
            userByCSRName.containskey(cr.CSRUsername)
          ) {
            c.ownerId = userByCSRName.get(cr.CSRUsername).id;
          } else {
            c.ownerId = pcsq;
          }
        }

        if (String.isNotBlank(cr.MigrationContactName)) {
          c.Description += 'Contact Name: ' + cr.MigrationContactName + '\n';
        }
        if (String.isNotBlank(cr.GoingLostDescription)) {
          c.Description +=
            'Lost Description: ' +
            cr.GoingLostDescription +
            '\n';
        }
        if (String.isNotBlank(String.valueOf(cr.FlexFirstRunDate))) {
          c.Description +=
            'First Run Date on Flex: ' +
            cr.FlexFirstRunDate.month() +
            '/' +
            cr.FlexFirstRunDate.day() +
            '/' +
            cr.FlexFirstRunDate.year();
        }
      } //Client Going Lost Case
      else if (cr.subject == 'Threshold Clean-up') {
        //only set owner on insert
        if (String.isBlank(cr.CaseId)) {
          c.ownerId = diq;
        }
        if (String.isNotBlank(cr.FlagName)) {
          c.Description += 'Flag Name: ' + cr.FlagName + '\n';
        }
        if (String.isNotBlank(cr.FlagComments)) {
          c.Description += 'Flag Comment: ' + cr.FlagComments + '\n';
        }
        if (String.isNotBlank(String.valueOf(cr.FlexFirstRunDate))) {
          c.Description +=
            'First Run Date on Flex: ' +
            cr.FlexFirstRunDate.month() +
            '/' +
            cr.FlexFirstRunDate.day() +
            '/' +
            cr.FlexFirstRunDate.year();
        }
      } else if (cr.subject == 'Pre-Scrub Clean-up') {
        //look for owner from query.  set to queue if we can't find the owner. Only set owner on insert
        if (String.isBlank(cr.CaseId)) {
          if (
            String.isNotBlank(cr.CSRUsername) &&
            userByCSRName.containskey(cr.CSRUsername)
          ) {
            c.ownerId = userByCSRName.get(cr.CSRUsername).id;
          } else {
            c.ownerId = pcsq;
          }
        }
        if (String.isNotBlank(cr.FlagName)) {
          c.Description += 'Flag Name: ' + cr.FlagName + '\n';
        }
        if (String.isNotBlank(cr.FlagComments)) {
          c.Description += 'Flag Comment: ' + cr.FlagComments + '\n';
        }
        if (String.isNotBlank(String.valueOf(cr.FlexFirstRunDate))) {
          c.Description +=
            'First Run Date on Flex: ' +
            cr.FlexFirstRunDate.month() +
            '/' +
            cr.FlexFirstRunDate.day() +
            '/' +
            cr.FlexFirstRunDate.year();
        }
      } else {
        cr.Error += '\nInvalid Subject';
      }
      String key;
      //if the bisid/clientnbr is filled in build key to upsert record
      if (String.isNotBlank(cr.BISId)) {
        key = cr.BISID + cr.Subject;
      } else if (String.isNotBlank(cr.ClientNumber)) {
        key = cr.ClientNumber + cr.Subject;
      }
      //if no errors and key is good, add to map of cases being returned and cases to insert
      if (key != null && String.isBlank(cr.Error)) {
        caseByKeyMap.put(key, cr);
        upsertCases.add(c);
      }
      //if there was missing data to prevent us from inserting case, return that, don't try to upsert
      else {
        caseByKeyMap.put(cr.ClientName + cr.ClientNumber + cr.Error, cr);
      }

      system.debug('FFSService createCase upsertCases' + upsertCases);
    } //for(CaseRecord cr:
    /* this was causing issues with list sizes if more than one error occured
        if (!upsertCases.isEmpty()) {
            try {
                upsert upsertCases;
            } catch (DMLException e) {
                system.debug('FFSService createCase there was an error: '+e);
                system.debug('error rows: '+e.getNumDml());
                system.debug('upsert cases size before loop: '+upsertCases.size());
                Integer[] errorIndexes = new Integer[]{};
                //loop through and capture any errors, add to caseByKeyMap
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    system.debug('dmlERR: '+e.getDMLIndex(i)+' i: '+i+' upsertCases size: '+upsertCases.size());
                    Case c = upsertCases.remove(e.getDMLIndex(i));  
                    errorIndexes.add(e.getDMLIndex(i));
                    String key;
                    if(c.BIS_Id__c!=null){
                        key = String.valueOf(c.Bis_Id__c)+c.Subject;
                    }
                    else if(c.Client_Number__c!=null){
                        key = c.Client_Number__c+c.Subject;
                    }
                    if(key!=null){
                        caseByKeyMap.get(key).Error = e.getDMLMessage(i);
                        system.debug('setting error'+e.getDMLMessage(i));
                    }
                }
            }
        }
        //any remaining cases in this list should all be successes because we removed errors above, get id of case if it was inserted
        for(Case c:upsertCases){
            system.debug('c:'+c.Id);
            String key;
            if(c.Bis_Id__c!=null){
                key = String.valueOf(c.Bis_Id__c)+c.Subject;
            }
            else if(c.Client_Number__c!=null){
                key = c.Client_Number__c+c.Subject;
            }
            if(key!=null && caseByKeyMap.get(key) !=null && String.isBlank(caseByKeyMap.get(key).CaseId)){
                caseByKeyMap.get(key).CaseId = c.Id;
            }
        }*/
  /*  list < Database.UpsertResult > results;
    if (!upsertCases.isEmpty()) {
      Database.DMLOptions dlo = new Database.DMLOptions();
      dlo.EmailHeader.triggerUserEmail = true;
      results = Database.upsert(upsertCases, false);
    }
    if (results != null) {
      for (Integer i = 0; i < results.size(); i++) {
        Case c = upsertCases.get(i);
        Database.UpsertResult result = results.get(i);
        String key;
        if (c.BIS_Id__c != null) {
          key = String.valueOf(c.Bis_Id__c) + c.Subject;
        } else if (c.Client_Number__c != null) {
          key = c.Client_Number__c + c.Subject;
        }
        if (key != null && c != null && result != null) {
          if (result.isSuccess()) {
            caseByKeyMap.get(key).CaseId = c.Id;
          } else {
            for (Database.Error err: result.getErrors()) {
              caseByKeyMap.get(key).Error += err.getMessage() + ';';
              system.debug('setting error' + err.getMessage());
            }
          }
        }
      }
    }
    system.debug('FFSService createCase caseByKeyMap: ' + caseByKeyMap);
    return caseByKeyMap.values();
  } //createCase */ //APR0171211 - Sush

  global class CaseRecordStatus {
    webService String CaseId;
    webService String Status;
    webService list < String > Comments;
  }

  webService static List < CaseRecordStatus > getCaseDetail(
    List < CaseRecordStatus > cRecord
  ) {
    Map < Id, CaseRecordStatus > caseRecordById = new Map < Id, CaseRecordStatus > ();
    set < String > caseIdset = new Set < String > ();
    for (CaseRecordStatus c: cRecord) {
      caseRecordById.put(c.CaseId, c);
    }

    List < Case > caseList = [
      SELECT id, status, (SELECT id, CommentBody FROM casecomments)
      FROM Case
      WHERE id IN: caseRecordById.keySet()
    ];

    for (Case c: caseList) {
      List < String > comments = new List < String > ();
      for (CaseComment comment: c.casecomments) {
        comments.add(comment.CommentBody);
      }
      if (
        caseRecordById.containsKey(c.Id) && caseRecordById.get(c.Id) != null
      ) {
        caseRecordById.get(c.Id).Status = c.Status;
        caseRecordById.get(c.Id).Comments = comments;
      }
    }

    return caseRecordById.values();
  }

  global class AccountRecord {
    webService String BisID; //Bis_ID__c
    webService String ClientName;
    webService String ClientNumber;
    webService String MigrationAnalyst;
    webService Date FlexFirstScheduledRunDate;
    webService Date OriginalClientRequestedStartDate;
    webService String MigrationChannel;
    webService String LastActivityDescription;
    webService Date ActivityDate;
    webService String MPSCAccountHealth;
    webService String Error;
    webservice String projectManager;
    webservice String projectManagerEmail;
    webservice String TAAICName;
    webservice String TAAICEmail;
    //webService String payRollImpSpecialist; 
  }

  global class AccountInformation {
    webService String BisID; //Bis_ID__c
    webService String ClientNumber;
    webService String OwnerUsername;
  }
  webService static List < AccountRecord > updateAccount(
    List < AccountRecord > aRecord
  ) {
    Web_Service_Log__c wsl = new Web_Service_Log__c(
      ServiceName__c = 'FFSService',
      CalledBy__c = UserInfo.getUserId(),
      CalledDt__c = system.now(),
      ServiceStart__c = system.now(),
      SobjName__c = 'Reference_Core_Payroll__c',
      NamedFunction__c = 'updateAccount',
      Action__c = 'Update',
      Notes__c = ''
    );

    Set < Decimal > bisIdSet = new Set < Decimal > ();
    Set < String > cltNbrSet = new Set < String > ();
    Set<String> projectManagerNameSet = new Set<String>(); 
    Set<String> projectManagerEmailsSet = new Set<String>(); 
    Set<String> TAAICNameSet = new Set<String>(); 
    Set<String> TAAICEmailSet = new Set<String>(); 
    //store account by bis id, if bis is blank, store clt #
    Map < String, Account > accountByBisCltNbrMap = new Map < String, Account > ();
    Map < String, AccountRecord > accountByKeyMap = new Map < String, AccountRecord > ();
    List < Account > accountUpdateList = new List < Account > ();
    set < String > speclistSet = new set < String > ();
    map < String, Id > nameVSSpcContactId = new map < String, Id > ();
    List < String > fixedNames = new List < String > ();
    List < String > fixedNamesTAA = new List < String > ();

    for (AccountRecord ar: ARecord) {
      if (String.isNotBlank(ar.BisId)) {
        bisIdSet.add(Decimal.valueOf(ar.BisID));
      } else if (String.isNotBlank(ar.ClientNumber)) {
        cltNbrSet.add(ar.ClientNumber);
      }
      if (String.isNotBlank(ar.projectManagerEmail)) {
        projectManagerEmailsSet.add(ar.projectManagerEmail);
      }
      if (String.isNotBlank(ar.projectManager)) {
        String trimmedCallerName = ar.projectManager.trim();
        projectManagerNameSet.add(trimmedCallerName);
      }

      if (String.isNotBlank(ar.TAAICEmail)) {
        TAAICEmailSet.add(ar.TAAICEmail);
      }
      if (String.isNotBlank(ar.TAAICName)) {
        String trimmedCallerName = ar.TAAICName.trim();
        TAAICNameSet.add(trimmedCallerName);
      }

      // if (String.isNotBlank(ar.payRollImpSpecialist)) {
      //   speclistSet.add(ar.payRollImpSpecialist);
      // }
    }
    // for (Contact contactRec : [select id, name from contact where name in: speclistSet order by lastmodifieddate]) {
    //   nameVSSpcContactId.put(contactRec.name, contactRec.Id); 
    // }

    List < Contact > contactList = getContactsByNames(wsl, projectManagerNameSet, fixedNames);
    List < User > taaUserList = getUsersByNames(wsl, TAAICNameSet, fixedNamesTAA);

    map < String, Contact > nameVSCont = new Map < String, Contact > ();
    map < String, Contact > emailVSCont = new Map < String, Contact > ();
    map < String, User > nameVSTAAUser = new Map < String, User > ();
    map < String, User > emailVSTaaUser = new Map < String, User > ();
    for (contact contacRec: contactList) {
      nameVSCont.put(contacRec.Name, contacRec);
    }
    for (Contact contacRec : [Select id, Name, email from contact where email in: projectManagerEmailsSet and HR_Person_Id__c != null ]) {
      emailVSCont.put(contacRec.email, contacRec);      
    }

    for (User userrec: taaUserList) {
      nameVSTAAUser.put(userrec.Name, userrec);
    }
    for (User userrec : [Select id, email, name  from User where email in: TAAICEmailSet]) {
      emailVSTaaUser.put(userrec.email, userrec);      
    }

    
    list < Account > accountList = [
      SELECT
      id,
      name,
      Activity_Date__c,
      Flex_First_Scheduled_Run_Date__c,
      Original_Client_Requested_Start_Date__c,
      Migration_Channel__c,
      Last_Activity__c,
      Migration_Analyst__c,
      BIS_Id__c,
      AccountNumber, MMS_MAM_NAM__c, MMS_MAM_NAM__r.Name,
      TLO_Implementation_Coordinator__c,
      TLO_Implementation_Coordinator__r.Name
      FROM account
      WHERE Bis_ID__c IN: BisIdSet OR AccountNumber IN: cltNbrSet
    ];
    System.debug('accountList rt' + accountList);
    wsl.Notes__c += 'Account Query Ran \n';
    wsl.Notes__c += 'Account Records Sent: ' + ARecord.size() + ' Account Records Found: ' + accountList.size();
    for (Account acc: accountList) {
      if (BisIdSet.contains(acc.Bis_ID__c)) {
        accountByBisCltNbrMap.put(String.valueOf(acc.Bis_Id__c), acc);
      } else {
        accountByBisCltNbrMap.put(acc.AccountNumber, acc);
      }
    }
    Contact unknownctct = [select Name, Id, User_Lookup__c from Contact where Name = 'CallerName NotFound' limit 1];
    for (AccountRecord ar: ARecord) {
      String key;
      if (String.isNotBlank(ar.BisId)) {
        key = ar.BisID;
      } else if (String.isNotBlank(ar.ClientNumber)) {
        key = ar.ClientNumber;
      }
      if (key != null && accountByBisCltNbrMap.containskey(key)) {
        Account acct = accountByBisCltNbrMap.get(key);
        //have to do a conversion for dates because for whatever reason blank date tags send in empty strings which can't be evaluated against a date
        if (
          ar.ActivityDate != null &&
          String.isNotBlank(String.valueOf(ar.ActivityDate))
        ) {
          acct.Activity_Date__c = ar.ActivityDate;
        }
        if (
          ar.MPSCAccountHealth != null &&
          String.isNotBlank(String.valueOf(ar.MPSCAccountHealth))
        ) {
          acct.MPSC_Account_Health__c = ar.MPSCAccountHealth;
        }
        if (
          ar.FlexFirstScheduledRunDate != null &&
          String.isNotBlank(String.valueOf(ar.FlexFirstScheduledRunDate))
        ) {
          acct.Flex_First_Scheduled_Run_Date__c = ar.FlexFirstScheduledRunDate;
        }
        if (
          ar.OriginalClientRequestedStartDate != null &&
          String.isNotBlank(String.valueOf(ar.OriginalClientRequestedStartDate))
        ) {
          acct.Original_Client_Requested_Start_Date__c = ar.OriginalClientRequestedStartDate;
        }
        if (String.isNotBlank(ar.MigrationChannel)) {
          acct.Migration_Channel__c = ar.MigrationChannel;
        }
        if (String.isNotBlank(ar.LastActivityDescription)) {
          acct.Last_Activity__c = ar.LastActivityDescription;
        }
        if (String.isNotBlank(ar.MigrationAnalyst)) {
          acct.Migration_Analyst__c = ar.MigrationAnalyst;
        }        

        // processing Project manager mapping 
        Boolean foundCotactTroguEmail = false;   
        System.debug('emailVSCont'+ emailVSCont)      ; 
        if (ar.projectManagerEmail != '' && String.isNotBlank(String.valueOf(ar.projectManagerEmail))) {    
        System.debug('0012'+ ar.projectManagerEmail)      ; 
          if (emailVSCont.containsKey(ar.projectManagerEmail)) {    
        System.debug('0012'+ ar.projectManagerEmail)      ; 
            if ( acct.MMS_MAM_NAM__r.Name == emailVSCont.get(ar.projectManagerEmail).name && acct.MMS_MAM_NAM__r.Name  != null ) {
            System.debug('0012'+ ar.projectManagerEmail)      ; 
              acct.MMS_MAM_NAM__c = emailVSCont.get(ar.projectManagerEmail).Id;   
              foundCotactTroguEmail = true;      
            }    
            else  if ( acct.MMS_MAM_NAM__r.Name  == null){              
              acct.MMS_MAM_NAM__c = emailVSCont.get(ar.projectManagerEmail).Id;  
              foundCotactTroguEmail = true;      

            }                                                      
          }             
        }
        if (nameVSCont.containsKey(ar.projectManager) && foundCotactTroguEmail == false ) {
          if ( acct.MMS_MAM_NAM__r.Name == nameVSCont.get(ar.projectManager).name && acct.MMS_MAM_NAM__r.Name  != null ) {
            System.debug('Name sent from Insite found in SF');
            acct.MMS_MAM_NAM__c = nameVSCont.get(ar.projectManager).Id;  
          }        
          else  if ( acct.MMS_MAM_NAM__r.Name  == null){
            System.debug('Name sent from Insite found in SF');
            acct.MMS_MAM_NAM__c = nameVSCont.get(ar.projectManager).Id;  
          }    
        } else if(foundCotactTroguEmail == false ) {
          StringHelper.parseFullName(ar.projectManager);
          String insiteFirstName = StringHelper.firstName;
          System.debug('*** insiteFirstName = ' + insiteFirstName + ' ***');
          String insiteLastName = StringHelper.lastName;
          System.debug('*** insiteLastName = ' + insiteLastName + ' ***');
          System.debug('Fixed Names: ' + fixedNames.toString());
          for (String fixedName: fixedNames) {
            StringHelper.parseFullName(fixedName);
            System.debug('StringHelper.firstName: ' + StringHelper.firstName);
            System.debug('StringHelper.lastName: ' + StringHelper.lastName);
            if (StringHelper.firstName == insiteFirstName && insiteLastName.contains(StringHelper.lastName)) {
              String tempName = StringHelper.firstName + ' ' + StringHelper.lastName;
              System.debug('tempName being used for finding CallerName: ' + tempName);
              if (nameVSCont.containsKey(tempName)) {
                System.debug('Found name: ' + tempName + ' in the Contact List');
                acct.MMS_MAM_NAM__c = nameVSCont.get(tempName).id;
                System.debug('acct.Project Manager after being set from new name: ' + acct.MMS_MAM_NAM__c);
                System.debug('Contact Id found: ' + nameVSCont.get(tempName).Id);
              }else{                  
                acct.MMS_MAM_NAM__c = unknownctct.Id;
              }
            }
          }
        }

         // processing TAA User
         Boolean foundTAAUserTroguEmail = false;         
         if (ar.TAAICEmail != '' && String.isNotBlank(String.valueOf(ar.TAAICEmail))) {                     
           if (emailVSTaaUser.containsKey(ar.TAAICEmail)) {    
             if ( acct.TLO_Implementation_Coordinator__r.Name == emailVSTaaUser.get(ar.TAAICEmail).name && acct.TLO_Implementation_Coordinator__r.Name != null ) {
               acct.TLO_Implementation_Coordinator__c = emailVSTaaUser.get(ar.TAAICEmail).Id;   
               foundCotactTroguEmail = true;      
             }    
             else if (acct.TLO_Implementation_Coordinator__r.Name == null){
              acct.TLO_Implementation_Coordinator__c = emailVSTaaUser.get(ar.TAAICEmail).Id;   
              foundCotactTroguEmail = true;   
             }                                                     
           }             
         }
         System.debug('nameVSTAAUser00' +nameVSTAAUser); 
         if (nameVSTAAUser.containsKey(ar.TAAICName) && foundCotactTroguEmail == false ) {
           if ( acct.TLO_Implementation_Coordinator__r.Name == nameVSTAAUser.get(ar.TAAICName).name && acct.TLO_Implementation_Coordinator__r.Name  != null ) {
             System.debug('Name sent from Insite found in SF');
             acct.TLO_Implementation_Coordinator__c = nameVSTAAUser.get(ar.TAAICName).Id;  
           }   
           else if (acct.TLO_Implementation_Coordinator__r.Name == null){
            acct.TLO_Implementation_Coordinator__c = nameVSTAAUser.get(ar.TAAICName).Id;   
           }           
         } else if(foundCotactTroguEmail == false ) {
           StringHelper.parseFullName(ar.TAAICName);
           String insiteFirstName = StringHelper.firstName;
           System.debug('*** insiteFirstName = ' + insiteFirstName + ' ***');
           String insiteLastName = StringHelper.lastName;
           System.debug('*** insiteLastName = ' + insiteLastName + ' ***');
           System.debug('Fixed Names: ' + fixedNames.toString());
           for (String fixedName: fixedNames) {
             StringHelper.parseFullName(fixedName);
             System.debug('StringHelper.firstName: ' + StringHelper.firstName);
             System.debug('StringHelper.lastName: ' + StringHelper.lastName);
             if (StringHelper.firstName == insiteFirstName && insiteLastName.contains(StringHelper.lastName)) {
               String tempName = StringHelper.firstName + ' ' + StringHelper.lastName;
               System.debug('tempName being used for finding CallerName: ' + tempName);
               if (nameVSTAAUser.containsKey(tempName)) {
                 System.debug('Found name: ' + tempName + ' in the User List');
                 acct.TLO_Implementation_Coordinator__c = nameVSTAAUser.get(tempName).Name;
                 System.debug('acct.TAAICName after being set from new name: ' + acct.TLO_Implementation_Coordinator__c);
                 System.debug('User Id found: ' + nameVSTAAUser.get(tempName).Id);
               }else{                             
                 acct.TLO_Implementation_Coordinator__c = unknownctct.User_Lookup__c;
               }
             }
           }
         }
        // if (String.isNotBlank(ar.payRollImpSpecialist) && nameVSSpcContactId.get(ar.payRollImpSpecialist) != null ) {
        //   acct.MMS_AS__c = nameVSSpcContactId.get(ar.payRollImpSpecialist);
        // }
        accountByKeyMap.put(key, ar);
        accountUpdateList.add(acct);
      } else {
        ar.Error = 'Could not find matching account';
        accountByKeyMap.put(ar.ClientName + ar.ClientNumber + ar.Error, ar);
      }
    }
    /*
        if (!accountUpdateList.isEmpty()) {
            try {
                update accountUpdateList;
            } catch (DMLException e) {
                system.debug('there was an error'+e);
                //loop through and capture any errors, add to caseByKeyMap
                for (Integer i = 0; i < e.getNumDml(); i++) {
                    Account acct = accountUpdateList.remove(e.getDMLIndex(i));
                    String key;
                    if(acct.BIS_Id__c!=null){
                        key = String.valueOf(acct.BIS_Id__c);
                    }
                    else if(acct.AccountNumber!=null){
                        key = acct.AccountNumber;
                    }
                    if(key!=null){
                        accountByKeyMap.get(key).Error = e.getDMLMessage(i);
                    }
                }
            }
        }*/
    list < Database.SaveResult > results;
    if (!accountUpdateList.isEmpty()) {
      results = Database.update(accountUpdateList, false);
    }
    if (results != null) {
      for (Integer i = 0; i < results.size(); i++) {
        Account acct = accountUpdateList.get(i);
        Database.SaveResult result = results.get(i);
        String key;
        if (acct.AccountNumber != null) {
          key = acct.AccountNumber;
        }
        if (String.isNotBlank(key) && acct != null && result != null) {
          if (!result.isSuccess()) {
            for (Database.Error err: result.getErrors()) {
              if (accountByKeyMap.get(key) != null) {
                accountByKeyMap.get(key).Error += err.getMessage() + ';';

              } else {
                wsl.Notes__c += 'No Account  with Account Number: ' + key + ' Found in List of Found Accounts';
              }
              system.debug('setting error' + err.getMessage());
            }
          }
        }
      }
    }
    DmlHelper.performDML2(
      new List < Web_Service_Log__c > {
        wsl
      },
      DmlHelper.DML_INSERT,
      'FFSService',
      'updateAccount',
      'Inserting Web Service Log',
      true
    );
    return accountByKeyMap.values();
  } //updateAccount

  //Method for FFS to call that returns Advantage and Preview clients with the "Main Owner Changed Date" field populated with a date between the two dates
  webService static List < AccountInformation > getUpdatedAccounts(
    String datetimeStart,
    String datetimeEnd
  ) {
    datetime startTime;
    datetime endTime;

    //If datetimes are entered, use the given datetimes. Otherwise use a default range of 3 days ago to today. Confirm range is no more than 3 days.
    //Catch formatting issues.
    if (!String.isBlank(datetimeStart)) {
      try {
        startTime = datetime.parse(datetimeStart);
      } catch (System.typeException e) {
        String errorMessage =
          'An error has occurred due to the start date having incorrect formatting. Full error: ' +
          e.getMessage();
        System.debug('FFSService, getUpdatedAccounts, error: ' + errorMessage);
        return null;
      }
    } else
      startTime = datetime.now() - 3;

    if (!String.isBlank(datetimeEnd)) {
      try {
        if (
          datetime.parse(datetimeEnd) > datetime.now() ||
          datetime.parse(datetimeEnd) > startTime + 3
        ) {
          endTime = startTime + 3;
        } else
          endTime = datetime.parse(datetimeEnd);
      } catch (System.typeException e) {
        String errorMessage =
          'An error has occurred due to the end date having incorrect formatting. Full error: ' +
          e.getMessage();
        System.debug('FFSService, getUpdatedAccounts, error: ' + errorMessage);
        return null;
      }
    } else
      endTime = startTime + 3;

    //Query accounts by type whose main owner changed date is within the dates provided to the method
    List < Account > accts = [
      SELECT Id, BIS_ID__c, AccountNumber, Owner.AD_Username__c,  MMS_MAM_NAM__c, MMS_MAM_NAM__r.Name
      FROM Account
      WHERE(Type LIKE '%Advantage%'
        OR Type LIKE '%Preview%')
      AND Main_Owner_Changed_Date__c >=: startTime
      AND Main_Owner_Changed_Date__c <=: endTime
      AND SystemModstamp >=: startTime
    ];
    List < AccountInformation > acctRecs = new List < AccountInformation > ();

    //Set up the returned accounts as AccountInformation objects to return
    if (!accts.isEmpty()) {
      for (Account acct: accts) {
        if (acct.BIS_ID__c != null || acct.AccountNumber != null) {
          AccountInformation ai = new AccountInformation();
          if (acct.BIS_ID__c != null) {
            ai.BisID = String.valueOf(acct.BIS_ID__c);
          }
          if (acct.AccountNumber != null) {
            ai.ClientNumber = acct.AccountNumber;
          }
          ai.OwnerUsername = acct.Owner.AD_Username__c;
          acctRecs.add(ai);
        }
      } //for
    } //if(!accts.isEmpty)

    return acctRecs;
  } //getUpdatedAccounts

  // Added as part of APR APR0127848 Reetesh
  global class RefCorePayrollRecord {
    webService String BisID; //Bis_ID__c
    webService String ClientName;
    webService String ClientNumber;
    webService Date initialContactDate; //Initial_Client_Contact_Date__c
    webService Date dateClientLoadComplete; //Date_Client_Load_Complete__c
    webService boolean clientLoadComplete; //Client_Load_Complete__c
    webService String iSCompletedClientAuditItems; //IS_Completed_open_Client_Audit_Items__c picklist
    webService Date newLoadAuditDate; //New_Load_Audit_Date__c
    webService Date payrollRunDate; //Payroll_Run_Date__c
    webService Date postFrstPyrlVerifDate; //Post_First_Payroll_Verification_Date__c
    webService String rescheduledRunReason; //Rescheduled_Run_Reason__c picklist
    webService Date orgnlProposedRunDate; //Original_Proposed_Run_Date__c
    webService Date proposedRunDate; //Proposed_Run_Date__c
    webService String clientNeverRanReason; //Client_Never_Ran_Reason__c picklist
    webService boolean clientNeverRan; //Client_Never_Ran__c
    webService Date clientReadyforTransition; //
    webService String callerName; //
    //webService Date dateIsAssigned; //
    webService Date dateClientLoadReceived; //
    webService String loaderName; //
    webService Date commissionDate; //
    webService String mpscAccountHealthNotes; //
    webService String callTime; // new 4/3/2023
    webService String intakeStatus; // new 4/3/2023
    webService String pivot; // new 4/3/2023
    webService Boolean commissionException; // new 4/3/2023
    webService String opptyId; // new 4/3/2023
    webService Date submissionComplete; // new 4/3/2023
    webService Date wcActual; // new 4/3/2023
    webService Integer activeEECount; // new 4/3/2023
    webService String rejectionReasonCode; // new 4/3/2023
    webService String comments; // new 4/3/2023
    webService String Error;
    webService String docCollector; //4/1/24
    webService String docCollectionStatus; //4/1/24
    webService Date docCollectionStatusDate; //4/1/24
    webService String callerEmail; //3/6/24
    //webService String ceid;
    //webService String caid;
    
  }
  global class RefCorePayrollRecord2 {
    webService String BisID; //Bis_ID__c
    webService String ClientName;
    webService String ClientNumber;
    webService Date initialContactDate; //Initial_Client_Contact_Date__c
    webService Date dateClientLoadComplete; //Date_Client_Load_Complete__c
    webService boolean clientLoadComplete; //Client_Load_Complete__c
    webService String iSCompletedClientAuditItems; //IS_Completed_open_Client_Audit_Items__c picklist
    webService Date newLoadAuditDate; //New_Load_Audit_Date__c
    webService Date payrollRunDate; //Payroll_Run_Date__c
    webService Date postFrstPyrlVerifDate; //Post_First_Payroll_Verification_Date__c
    webService String rescheduledRunReason; //Rescheduled_Run_Reason__c picklist
    webService Date orgnlProposedRunDate; //Original_Proposed_Run_Date__c
    webService Date proposedRunDate; //Proposed_Run_Date__c
    webService String clientNeverRanReason; //Client_Never_Ran_Reason__c picklist
    webService boolean clientNeverRan; //Client_Never_Ran__c
    webService Date clientReadyforTransition; //
    webService String callerName; //
    //webService Date dateIsAssigned; //

    webService Date dateClientLoadReceived; //
    webService String loaderName; //
    webService Date commissionDate; //
    webService String mpscAccountHealthNotes; //
    webService String callTime; // new 4/3/2023
    webService String intakeStatus; // new 4/3/2023
    webService String pivot; // new 4/3/2023
    webService Boolean commissionException; // new 4/3/2023
    webService String opptyId; // new 4/3/2023
    webService Date submissionComplete; // new 4/3/2023
    webService Date wcActual; // new 4/3/2023
    webService Integer activeEECount; // new 4/3/2023
    webService String rejectionReasonCode; // new 4/3/2023
    webService String comments; // new 4/3/2023
    webService String docCollector; //4/1/24
    webService String docCollectionStatus; //4/1/24
    webService Date docCollectionStatusDate; //4/1/24
    webService String callerEmail; //4/1/24
    webService String Error;
   //webService String comments;
  }
  webService static List < RefCorePayrollRecord > updaterefCorePayRoll(
    List < RefCorePayrollRecord > rcpRecord
  ) {

    /* pull in custom label determining which process to run
        if(label =='MPSC'){ run MPSC code aka current updaterefCorePayRoll code}else{run updateRefCorePayRollNew code }
    */
    List<String> rtfilter = System.Label.RcpRecordTypeFilter.split(',');

    System.debug('Start CPU Time===>' + Limits.getCpuTime());

    Web_Service_Log__c wsl = new Web_Service_Log__c(
      ServiceName__c = 'FFSService',
      CalledBy__c = UserInfo.getUserId(),
      CalledDt__c = system.now(),
      ServiceStart__c = system.now(),
      SobjName__c = 'Reference_Core_Payroll__c',
      NamedFunction__c = 'updaterefCorePayRoll',
      Action__c = 'Update',
      Notes__c = ''
    );

    Set < String > cltNbrSet = new Set < String > ();
    //store account by bis id, if bis is blank, store clt #
    Map < String, Account > accountByBisCltNbrMap = new Map < String, Account > ();
    Map < String, RefCorePayrollRecord > accountByKeyMap = new Map < String, RefCorePayrollRecord > ();
    List < Reference_Core_Payroll__c > rcpUpdateList = new List < Reference_Core_Payroll__c > ();
    Map < Id, Reference_Core_Payroll__c > idRcpMap = new Map < Id, Reference_Core_Payroll__c > ();
    List < Reference_Core_Payroll__c > foundRCPsFromOpptyIds = new List < Reference_Core_Payroll__c > ();
    List < RefCorePayrollRecord > RCPsNoOpptyId = new List < RefCorePayrollRecord > ();
    List < RefCorePayrollRecord > RCPsWithOpptyId = new List < RefCorePayrollRecord > ();

    set < String > opptyIds = new set < String > ();
    set < String > callerEmailSet = new set < String > ();
    List < String > fixedNames = new List < String > ();

    set < String > contactNames = new Set < String > ();
    for (RefCorePayrollRecord ar: rcpRecord) {
      if (String.isNotBlank(ar.ClientNumber)) {
        if (ar.ClientNumber.startsWith('0')) {
          /* ECP 05/10/2023 issue with inserting data prepended with zeros it chopped off the prepending zero when inserted 
          so we must too chop off that prepended zero ECP */
          String TempNum = ar.ClientNumber.removeStart('0');
          cltNbrSet.add(TempNum);
        } else {
          cltNbrSet.add(ar.ClientNumber);
        }
      }
      if (String.isNotBlank(ar.opptyId)) {
        String tempOpptyId = ar.opptyId;
        System.debug('Oppty Sent in: \"'+ ar.opptyId+'\"');
        tempOpptyId = tempOpptyId.trim(); 
        opptyIds.add(tempOpptyId);
        RCPsWithOpptyId.add(ar);
      } else {
        RCPsNoOpptyId.add(ar);
      }
      if (String.isNotBlank(ar.callerName)) {
        // StringHelper sh = new StringHelper();
        // sh.parseFullName(ar.callerName);

        // List<String> callerNameList = ar.callerName.split(' ');
        // if(callerNameList.size()>2){
        //   String newName = callerNameList[0] + callerNameList[callerNameList.size()-1];
        //   contactNames.add(newName);
        // }else{
          String trimmedCallerName = ar.callerName.trim();
          System.debug('Original Caller Name: '+ar.callerName+'  Trimmed Caller Name: '+trimmedCallerName);
        contactNames.add(trimmedCallerName);
        //}

      }
      if (String.isNotBlank(ar.callerEmail)) {                 
          System.debug('Email Caller Email: '+ar.callerEmail);
          callerEmailSet.add(ar.callerEmail);
        //}

      }
    }
    if (wsl.UC_Notes__c != null) {
      wsl.UC_Notes__c += 'List of Client Numbers: ' + cltNbrSet.toString() + '\n';
    }

    wsl.UC_Notes__c = 'List of Client Numbers: ' + cltNbrSet.toString() + '\n';
    if (wsl.UC_Notes__c != null) {
      wsl.UC_Notes__c += 'List of Oppty Ids: ' + opptyIds.toString() + '\n';
    } else {
      wsl.UC_Notes__c = 'List of Oppty Ids: ' + opptyIds.toString() + '\n';
    }

    List < Contact > contactList = getContactsByNames(wsl, contactNames, fixedNames);
    //if(contactList == null){
    // add to error notes on WSL 
    // insert wsl
    // return list of original records 
    //}
    // List<Contact> contactList = [
    //   SELECT id, name
    //   FROM contact
    //   WHERE name IN :contactNames
    //   ORDER BY lastmodifieddate
    // ];
    map < String, id > nameVSContid = new Map < String, Id > ();
    map < String, id > emailVSContid = new Map < String, id > ();
    for (contact contacRec: contactList) {
      nameVSContid.put(contacRec.Name, contacRec.id);
    }
    for (Contact contacRec : [Select id, email from contact where email in: callerEmailSet and HR_Person_Id__c != null ]) {
      emailVSContid.put(contacRec.email, contacRec.id);      
    }
    //System.debug('nameVSContId values ' + nameVSContId.values().toString());
    //System.debug('nameVSContId keys ' + nameVSContId.keySet().toString());
    List < String > statusLimits = System.label.RcpStatusLimit.split(',');
    List < String > currentStepLimits = System.label.RcpCurStepLimit.split(',');
    System.debug('RCP Queries');
    List < Reference_Core_Payroll__c > RefCorePayrollList = new List < Reference_Core_Payroll__c > ();
    if (opptyIds.size() > 0) {
      wsl.Notes__c += 'Running Oppty RCP Query \n';
      RefCorePayrollList = (cltNbrSet.size() > 0) ?
        [
          SELECT
          Id,
          recordtype.name,
          Initial_Client_Contact_Date__c,
          Date_Client_Load_Complete__c,
          Client_Load_Complete__c,
          IS_Completed_open_Client_Audit_Items__c,
          New_Load_Audit_Date__c,
          Payroll_Run_Date__c,
          Post_First_Payroll_Verification_Date__c,
          Rescheduled_Run_Reason__c,
          Original_Proposed_Run_Date__c,
          Proposed_Run_Date__c,
          Client_Never_Ran_Reason__c,
          Client_Never_Ran__c,
          Prospect_Client_Name__c,
          Prospect_Client_Number__c,
          Case_Lookup__c,
          Status__c,
          Payroll_Status__c,
          CallerName__c,
          CallerName__r.Name,
          Date_IS_Assigned__c,
          Case_Lookup__r.AccountId,
          Case_Lookup__r.Account.MMS_AS__c,
          Case_Lookup__r.Account.MMS_AS__r.Name,
          Case_Lookup__r.Subject,
          New_Prospect_Client_Number__c,
          Opportunity_Lookup__c,
          Name,
          Opportunity_Lookup__r.OpportunityType__c,
          Month_End_Exception_Approved__c
          FROM Reference_Core_Payroll__c
          WHERE
          Opportunity_Lookup__c IN: opptyIds
          AND recordtype.name in :rtfilter


        ] :
        null;
      //
      System.debug('opptyIds.size(): '+opptyIds.size() +' RefCorePayrollList.size() : '+RefCorePayrollList.size());
      System.debug(RefCorePayrollList);
      System.debug(opptyIds);

        if(opptyIds.size() != RefCorePayrollList.size()){
          // System.debug('We made it to the Oppty Code checker');
          // System.debug('RCPsNoOpptyId before: '+RCPsNoOpptyId);
          List<String> foundOppIds = new List<String>();
          List<RefCorePayrollRecord> lostOpps = new List<RefCorePayrollRecord>();
          for(Reference_Core_Payroll__c rcp: RefCorePayrollList){
            String opptyId15 = rcp.Opportunity_Lookup__c;
            opptyId15 = opptyId15.Substring(0,15);
            foundOppIds.add(opptyId15);
          }
          for(RefCorePayrollRecord ar : RCPsWithOpptyId){
            String tempOppty = ar.opptyId;
            tempOppty = tempOppty.trim();
            tempOppty = tempOppty.Substring(0,15);
            if(!foundOppIds.contains(tempOppty)){
              System.debug(foundOppIds);
              System.debug(tempOppty);
              System.debug('we did not find this RCP ('+ar.ClientName+') sent in, will be adding to the bigger list of RCPsNoOpptyId vvv');
              // System.debug(ar);
            //add in the list of AR's NotFound from the original Opportunity list 
              RCPsNoOpptyId.add(ar);
            }else{
              System.debug('we found RCP: ('+ ar.ClientName+')');

              // return error of lost client 
              // 06/28/2023 ***ECP*** if we have the RCP in our list we don't need to report an error, as we will eventually search for the same record's client number later 
              // ar.Error = 'Could not find Client by Opportunity ID nor Client Number';
              // accountByKeyMap.put(ar.ClientName + ar.ClientNumber.removeStart('0') + ar.Error, ar);
    
            }
          }
          // System.debug('RCPsNoOpptyId after: '+RCPsNoOpptyId.toString());
          // System.debug('RefCorePayrollList: '+ RefCorePayrollList.toString());
        }
      if (rcpRecord.size() != RefCorePayrollList.size()) {
        wsl.Notes__c += 'Not All RCP\'s sent had an OpptyId. \n';

        //Grab all incoming non Oppty rcp's and their client numbers for the query
        Set < String > cltNbrSet2 = new Set < String > ();
        for (RefCorePayrollRecord rcp: RCPsNoOpptyId) {
          if (rcp.ClientNumber.startsWith('0')) {
            String clientNum2 = rcp.ClientNumber.removeStart('0');
            System.debug('parsed client Num: '+clientNum2);

            cltNbrSet2.add(clientNum2);
            //cltNbrSet2.add(rcp.ClientNumber);
          }else{
            cltNbrSet2.add(rcp.ClientNumber);
          }

        }
        // System.debug('ClientNumberSet'+cltNbrSet2.toString());
        wsl.UC_Notes__c += 'Secondary Client Number List' + cltNbrSet2.toString() + '\n';

        List < Reference_Core_Payroll__c > MiniRefCorePayrollList = (cltNbrSet2.size() > 0) ?
          [
            SELECT
            Id,
            recordtype.name,
            Initial_Client_Contact_Date__c,
            Date_Client_Load_Complete__c,
            Client_Load_Complete__c,
            IS_Completed_open_Client_Audit_Items__c,
            New_Load_Audit_Date__c,
            Payroll_Run_Date__c,
            Post_First_Payroll_Verification_Date__c,
            Rescheduled_Run_Reason__c,
            Original_Proposed_Run_Date__c,
            Proposed_Run_Date__c,
            Client_Never_Ran_Reason__c,
            Client_Never_Ran__c,
            Prospect_Client_Name__c,
            Prospect_Client_Number__c,
            Case_Lookup__c,
            Status__c,
            Payroll_Status__c,
            CallerName__c,
            CallerName__r.Name,
            Date_IS_Assigned__c,
            Case_Lookup__r.AccountId,
            Case_Lookup__r.Account.MMS_AS__c,
            Case_Lookup__r.Account.MMS_AS__r.Name,
            Case_Lookup__r.Subject,
            New_Prospect_Client_Number__c,
            Opportunity_Lookup__c,
            Name,
            Opportunity_Lookup__r.OpportunityType__c,
            Month_End_Exception_Approved__c
            FROM Reference_Core_Payroll__c
            WHERE(Prospect_Client_Number__c IN: cltNbrSet2 OR New_Prospect_Client_Number__c IN: cltNbrSet2)
            AND Payroll_Status__c NOT IN: statusLimits 
            AND recordtype.name in :rtfilter
            ] :
          null;

          if(MiniRefCorePayrollList != null){
            List<RefCorePayrollRecord> notFoundRCPs = new List<RefCorePayrollRecord>();
            List<String> foundIds2 = new List<String>();
            if(MiniRefCorePayrollList.size() != cltNbrSet2.size()){

              for(Reference_Core_Payroll__c rcp : MiniRefCorePayrollList){
                foundIds2.add(rcp.Prospect_Client_Number__c);
              }
              for(String id : cltNbrSet2){
                if(!foundIds2.contains(id)){
                  for(RefCorePayrollRecord ar: RCPsNoOpptyId){
                    String tempId = '';
                    if(ar.ClientNumber.startsWith('0')){
                      tempId = ar.ClientNumber.removeStart('0');
                    }else{
                      tempId = ar.ClientNumber;
                    }
                    if(tempId == id){
                      System.debug('tempID: '+tempId);
                      System.debug('id: '+id);
                      System.debug('We lost this client '+ar.ClientName+' and couldn\'t find them in our system');
                      ar.Error = 'Could not find Client by Opportunity ID or Client Number';
                      accountByKeyMap.put(ar.ClientName + ar.ClientNumber.removeStart('0') + ar.Error, ar);

                    }
                  }
                  

                }

              }
            }
            // System.debug('Mini RCP List: '+MiniRefCorePayrollList.toString());
            // System.debug('Old RefCorePayrollList '+RefCorePayrollList);
            RefCorePayrollList.addAll(MiniRefCorePayrollList);
            // System.debug('New RefCorePayrollList '+RefCorePayrollList);

            wsl.Notes__c += 'RCP\'s Sent in: ' + rcpRecord.size() + ' RCP\'s Found from OpptyIds: ' + RefCorePayrollList.size() + ' RCP\'s Found w/o OpptyIds: ' + MiniRefCorePayrollList.size() + ' \n';

          }
        //Use Sparingly causes issues with CPU Time when running
        //System.debug('ALL RCPS FOUND: '+RefCorePayrollList.toString());

      }
    } else {
      wsl.Notes__c += 'Running Standard RCP Query \n';
      //Old Code with filters on status current step 
      // RefCorePayrollList = (cltNbrSet.size() > 0) ?
      //   [
      //     SELECT
      //     Id,
      //     recordtype.name,
      //     Initial_Client_Contact_Date__c,
      //     Date_Client_Load_Complete__c,
      //     Client_Load_Complete__c,
      //     IS_Completed_open_Client_Audit_Items__c,
      //     New_Load_Audit_Date__c,
      //     Payroll_Run_Date__c,
      //     Post_First_Payroll_Verification_Date__c,
      //     Rescheduled_Run_Reason__c,
      //     Original_Proposed_Run_Date__c,
      //     Proposed_Run_Date__c,
      //     Client_Never_Ran_Reason__c,
      //     Client_Never_Ran__c,
      //     Prospect_Client_Name__c,
      //     Prospect_Client_Number__c,
      //     Case_Lookup__c,
      //     Status__c,
      //     Payroll_Status__c,
      //     CallerName__c,
      //     Date_IS_Assigned__c,
      //     Case_Lookup__r.AccountId,
      //     Case_Lookup__r.Account.MMS_AS__c,
      //     Case_Lookup__r.Account.MMS_AS__r.Name,
      //     Case_Lookup__r.Subject,
      //     New_Prospect_Client_Number__c,
      //     Opportunity_Lookup__c,
      //     Opportunity_Lookup__r.OpportunityType__c,
      //     Month_End_Exception_Approved__c
      //     FROM Reference_Core_Payroll__c
      //     WHERE(Prospect_Client_Number__c IN: cltNbrSet OR New_Prospect_Client_Number__c IN: cltNbrSet)
      //     AND Current_Step__c NOT IN: currentStepLimits
      //     AND Payroll_Status__c NOT IN: statusLimits, 
      //     AND(NOT Current_Step__c LIKE '% of 4%')
      //   ] :
      //   null;
        RefCorePayrollList = (cltNbrSet.size() > 0) ?
        [
          SELECT
          Id,
          recordtype.name,
          Initial_Client_Contact_Date__c,
          Date_Client_Load_Complete__c,
          Client_Load_Complete__c,
          IS_Completed_open_Client_Audit_Items__c,
          New_Load_Audit_Date__c,
          Payroll_Run_Date__c,
          Post_First_Payroll_Verification_Date__c,
          Rescheduled_Run_Reason__c,
          Original_Proposed_Run_Date__c,
          Proposed_Run_Date__c,
          Client_Never_Ran_Reason__c,
          Client_Never_Ran__c,
          Prospect_Client_Name__c,
          Prospect_Client_Number__c,
          Case_Lookup__c,
          Status__c,
          Payroll_Status__c,
          CallerName__c,
          CallerName__r.Name,
          Date_IS_Assigned__c,
          Case_Lookup__r.AccountId,
          Case_Lookup__r.Account.MMS_AS__c,
          Case_Lookup__r.Account.MMS_AS__r.Name,
          Case_Lookup__r.Subject,
          New_Prospect_Client_Number__c,
          Opportunity_Lookup__c,
          Name,
          Opportunity_Lookup__r.OpportunityType__c,
          Month_End_Exception_Approved__c
          FROM Reference_Core_Payroll__c
          WHERE(Prospect_Client_Number__c IN: cltNbrSet OR New_Prospect_Client_Number__c IN: cltNbrSet)
          AND Payroll_Status__c NOT IN: statusLimits 
          AND recordtype.name in :rtfilter
        ] :
        null;
    }

    //wsl.Notes__c +='Sent In'+rcpRecord.size()+' RCP records: Found '+RefCorePayrollList.size()+'\n';
    Map < String, Reference_Core_Payroll__c > clntNoRcpMap = new Map < String, Reference_Core_Payroll__c > ();
    Map < String, Reference_Core_Payroll__c > opptyIdRcpMap = new Map < String, Reference_Core_Payroll__c > ();
    List<String> foundRCPNames = new List<String>();
    if (RefCorePayrollList != null && RefCorePayrollList.size() > 0) {
      for (Reference_Core_Payroll__c rcp: RefCorePayrollList) {
        foundRCPNames.add(rcp.Name);
        if(rcp.Opportunity_Lookup__c != null){
          String optString15 = String.valueOf(rcp.Opportunity_Lookup__c).substring(0, 15);
          opptyIdRcpMap.put(optString15, rcp);
        }
        if(rcp.Prospect_Client_Number__c !=null){
          clntNoRcpMap.put(rcp.Prospect_Client_Number__c, rcp);

        }

        if (String.isNotBlank(rcp.New_Prospect_Client_Number__c)) {
          clntNoRcpMap.put(rcp.New_Prospect_Client_Number__c, rcp);
        }

      }
      System.debug('clntNoRcpMap:(Keys) '+clntNoRcpMap.keySet());
      System.debug('opptyIdRcpMap:(Keys) '+opptyIdRcpMap.keySet());

      wsl.UC_Notes__c += ' \n Names of RCP\'s Found from queries: '+foundRCPNames.toString()+'\n';
      Contact unknownctct = [select Name, Id from Contact where Name = 'CallerName NotFound' limit 1];
      for (RefCorePayrollRecord ar: rcpRecord) {
        System.debug('*** CLIENT NUMBER USED *** '+ar.ClientNumber.removeStart('0'));
        System.debug('***Boolean condition pass?: '+Boolean.valueOf(String.isNotBlank(ar.ClientNumber) &&
        clntNoRcpMap.containsKey(ar.ClientNumber.removeStart('0'))));
        if (
          (String.isNotBlank(ar.ClientNumber) &&
          clntNoRcpMap.containsKey(ar.ClientNumber.removeStart('0')))  || 
          (String.IsNotBlank(ar.OpptyId) && opptyIdRcpMap.containsKey(ar.OpptyId.substring(0,15)))
          )
         {
          string fclientnumber = ar.ClientNumber.startsWith('0')? ar.ClientNumber.removeStart('0') : ar.ClientNumber; 
          System.debug('ar.opptyId: '+ar.opptyId);
          System.debug('is it blank?'+String.isNotBlank(ar.OpptyId));
          System.debug('is it Empty?'+String.isEmpty(ar.OpptyId));
          if(ar.opptyId != null){
            System.debug('Longer than 15 characters? '+ Boolean.valueOf(ar.opptyId.length() >= 15));
          }

          String fOpptyId = ((!String.isEmpty(ar.opptyId) || ar.opptyId != null) && ar.opptyId.length()>= 15)? ar.opptyId.substring(0,15): null ;
          System.debug('fOpptyId: '+ fOpptyId);
          System.debug('fclientNumber: '+fclientnumber);
          System.debug(clntNoRcpMap);
          System.debug(clntNoRcpMap.get(fclientnumber));
          Reference_Core_Payroll__c rc = (fOpptyId != null && opptyIdRcpMap.keySet().contains(fOpptyId))   ? opptyIdRcpMap.get(fOpptyId) :  (fclientnumber != null ? clntNoRcpMap.get(fclientnumber) : null);
          // if(rc == null){
          //   rc = fclientnumber != null ? clntNoRcpMap.get(fclientnumber) : null;
          // }
          System.debug('RCP OpptyId: ' + ar.opptyId);
          System.debug('RCPfclientnumber : ' + fclientnumber);
          System.debug('Client Number RCP Map: ' + ar.ClientNumber);
          System.debug('RCP opty map : ' + opptyIdRcpMap);
          System.debug('Client Number RCP Map: ' + clntNoRcpMap.get(fclientnumber));
          System.debug('RC Map: ' + rc);
          if (rc != null) {
            if(rc.Prospect_Client_Name__c !=null){
              System.debug('RCP Prospect Client Name: ' +rc.Prospect_Client_Name__c);
            }
            System.debug('RCP Found with Client Number: ' + rc.Prospect_Client_Number__c + 'and new client number: ' + rc.New_Prospect_Client_Number__c);
            System.debug('RCP id = ' + rc.Id);
           
            if(ar.pivot != null && String.isNotBlank(String.valueOf(ar.pivot))){
              System.debug(
                'The pivot from the Feed: ' + ar.pivot + 'Type of ar.pivot:  ' +String.valueOf(ar.pivot)
              );
              rc.New_Load_Reviewed_by__c = String.valueOf(ar.pivot);
              System.debug('Pivot Set as : '+rc.New_Load_Reviewed_by__c );
            }
            if(ar.wcActual != null){
              System.debug(
                'The wcActual from the Feed: ' + ar.wcActual
              );
              rc.Welcome_Call_Complete_Date__c= ar.wcActual;
            }
            
            if(ar.activeEECount != null){
              System.debug(
                'The activeEECount from the Feed: ' + ar.activeEECount
              );
              rc.Number_of_Employees__c  = ar.activeEECount;
            }
            if(ar.commissionException != null){
              System.debug(
                'The commissionException from the Feed: ' + ar.commissionException
              );
              rc.Month_End_Exception_Approved__c = ar.commissionException;
            }
            // if (ar.callerName != null && rc.Date_IS_Assigned__c == null &&
            //   String.isBlank(String.valueOf(rc.Date_IS_Assigned__c))) {
            //   rc.Date_IS_Assigned__c = System.today();
            // }
            if (
              ar.initialContactDate != null &&
              String.isNotBlank(String.valueOf(ar.initialContactDate))
            ) {
              System.debug(
                'The initialContactDate from the Feed: ' + ar.initialContactDate
              );
              String tempDate = String.valueOf(ar.initialContactDate);

              String tempDateTrimmed = tempDate.substringBefore('00:');
              tempDateTrimmed.trim();
              List < String > tempDateSplit = tempDateTrimmed.split('-');
              List < String > newDateOrder = new List < String > ();

              if (tempDateSplit.size() > 0) {
                newDateOrder.add(tempDateSplit.get(1));
                newDateOrder.add(tempDateSplit.get(2));
                newDateOrder.add(tempDateSplit.get(0));
              }
              String newDateString = String.join(newDateOrder, '/');
              Date newDate = date.parse(newDateString);
              System.debug('newDate parsed by hand: ' + newDate);
              System.debug(
                'does newDate == DateFromFeed:' +
                Boolean.valueOf(
                  String.valueOf(ar.initialContactDate) ==
                  String.valueOf(newDate)
                )
              );
              //System.debug(tempDateSplit);
              rc.Initial_Client_Contact_Date__c = ar.initialContactDate;
            } else {
              rc.Initial_Client_Contact_Date__c = null;
            }
            if (
              ar.dateClientLoadComplete != null &&
              String.isNotBlank(String.valueOf(ar.dateClientLoadComplete))
            ) {
              System.debug(
                'The dateClientLoadComplete from the Feed: ' +
                ar.dateClientLoadComplete
              );
              rc.Date_Client_Load_Complete__c = ar.dateClientLoadComplete;
            } else {
              rc.Date_Client_Load_Complete__c = null;
            } //
            if (
              ar.clientReadyforTransition != null &&
              String.isNotBlank(String.valueOf(ar.clientReadyforTransition))
            ) {
              System.debug(
                'The clientReadyforTransition from the Feed: ' +
                ar.clientReadyforTransition
              );
              rc.Client_ready_for_transition__c = true;
            } else {
              rc.Client_ready_for_transition__c = false;
            }
            if (rc.Case_Lookup__r.Account.MMS_AS__c != null) {
              System.debug('Implementation Specialist Found');
              System.debug('Setting Caller_Name on RCP to the Implementation Specialist');
              rc.Caller_Name__c = rc.Case_Lookup__r.Account.MMS_AS__r.Name;

              System.debug('rc.Caller_Name__c' + rc.Caller_Name__c);
              System.debug('Implementation Specialist: ' + rc.Case_Lookup__r.Account.MMS_AS__r.Name);
              rc.CallerName__c = rc.Case_Lookup__r.Account.MMS_AS__c;
              System.debug('rc.CallerName__c:' + rc.CallerName__c);
              System.debug('Implementation Specialist Contact: ' + rc.Case_Lookup__r.Account.MMS_AS__c);
            }
            if (ar.comments != null && String.isNotBlank(String.valueOf(ar.comments))) {
              System.debug('The comments from the Feed: ' + ar.comments);
              rc.Comments__c = ar.comments;
            } else {
              rc.Comments__c = ''; //smb fields from 609 to 651
            }
            

            // if ((Boolean) (ar.monthEndExceptionApproved)) {
            //   rc.Month_End_Exception_Approved__c = ar.monthEndExceptionApproved;
            // } else {
            //   rc.Month_End_Exception_Approved__c = false;
            // }
            if (
              ar.commissionDate != null &&
              String.isNotBlank(String.valueOf(ar.commissionDate))
            ) {
              System.debug(
                'The commissionDate from the Feed: ' + ar.commissionDate
              );
              rc.Date_CSS_Responded__c = ar.commissionDate;
            } else {
              rc.Date_CSS_Responded__c = null;
            }

            //             if (
            //   ar.welcomeCallCompleteDate != null &&
            //   String.isNotBlank(String.valueOf(ar.welcomeCallCompleteDate))
            // ) {
            //   System.debug(
            //     'The welcomeCallCompleteDate from the Feed: ' + ar.welcomeCallCompleteDate
            //   );
            //   rc.Welcome_Call_Complete_Date__c = ar.welcomeCallCompleteDate;
            // } else {
            //   rc.Welcome_Call_Complete_Date__c = null;
            // } //smb fields from 609 to 651

            if (
              ar.callerName != '' &&
              String.isNotBlank(String.valueOf(ar.callerName))
            ) {
              // System.debug(
              //   'The callerName from the Feed: ' +
              //   ar.dateIsAssigned
              // );
              System.debug('Caller_Name__c is set with: ' + ar.callerName);
              rc.Caller_Name__c = ar.callerName;
              System.debug('rc.Caller_Name__c after being set. rc.Caller_Name__c: ' + rc.Caller_Name__c);
              System.debug('rc.Date_Is_Assigned__c :'+rc.Date_IS_Assigned__c);
              System.debug('String.isBlank(String.valueOf(rc.Date_IS_Assigned__c)): '+ rc.Date_IS_Assigned__c);
              if (rc.Date_IS_Assigned__c == null &&
              String.isBlank(String.valueOf(rc.Date_IS_Assigned__c))) {
              rc.Date_IS_Assigned__c = System.today();
            }
            Boolean foundCotactTroguEmail = false; 
            System.debug('emailVSContid00'+emailVSContid);


            if (
              ar.callerEmail != '' &&
              String.isNotBlank(String.valueOf(ar.callerEmail))
            ) {          
              System.debug('*** Made it to email Check ***');
              rc.Caller_Email__c = ar.callerEmail;
              if (emailVSContid.containsKey(ar.callerEmail)) {               
                rc.CallerName__c = emailVSContid.get(ar.callerEmail);   
                foundCotactTroguEmail = true;     
                System.debug('*** Found contact via email ***');                                   
              }             
            } else {
              System.debug('*** Made it to Name check *** ');
              if (nameVSContId.containsKey(ar.callerName) && foundCotactTroguEmail == false ) {
                System.debug('Name sent from Insite found in SF');
                rc.CallerName__c = nameVSContId.get(ar.callerName);

              } else if(foundCotactTroguEmail == false ) {
                StringHelper.parseFullName(ar.callerName);
                String insiteFirstName = StringHelper.firstName;
                System.debug('*** insiteFirstName = ' + insiteFirstName + ' ***');
                String insiteLastName = StringHelper.lastName;
                System.debug('*** insiteLastName = ' + insiteLastName + ' ***');
                System.debug('Fixed Names: ' + fixedNames.toString());
                for (String fixedName: fixedNames) {
                  StringHelper.parseFullName(fixedName);
                  System.debug('StringHelper.firstName: ' + StringHelper.firstName);
                  System.debug('StringHelper.lastName: ' + StringHelper.lastName);
                  if (StringHelper.firstName == insiteFirstName && insiteLastName.contains(StringHelper.lastName)) {
                    String tempName = StringHelper.firstName + ' ' + StringHelper.lastName;
                    System.debug('tempName being used for finding CallerName: ' + tempName);
                    if (nameVSContId.containsKey(tempName)) {
                      System.debug('Found name: ' + tempName + ' in the Contact List');
                      rc.CallerName__c = nameVSContId.get(tempName);
                      System.debug('rc.Caller_Name__c after being set from new name: ' + rc.CallerName__c);
                      System.debug('Contact Id found: ' + nameVSContId.get(tempName));
                    }else{
                      // pull the unknown contact, populate it here 
                      // ECP 11/28/2023
                      rc.CallerName__c = unknownctct.Id;
                    }
                  }
                }

              }
            }
             } else {
              rc.Caller_Name__c = '';
              rc.CallerName__c = null;
            }

            // if (
            //   ar.dateIsAssigned != null &&
            //   String.isNotBlank(String.valueOf(ar.dateIsAssigned)) &&
            //   rc.Date_IS_Assigned__c == null
            // ) {
            //   System.debug(
            //     'The calldateIsAssignederName from the Feed: ' +
            //     ar.dateIsAssigned
            //   );
            //   rc.Date_IS_Assigned__c = ar.dateIsAssigned;
            // } else {
            //   rc.Date_IS_Assigned__c = null;
            // }
            if (
              ar.dateClientLoadReceived != null &&
              String.isNotBlank(String.valueOf(ar.dateClientLoadReceived))
            ) {
              System.debug(
                'The dateClientLoadReceived from the Feed: ' +
                ar.dateClientLoadReceived
              );
              rc.Date_Client_Load_Received__c = ar.dateClientLoadReceived;
              rc.Client_Load_Received__c = true;
            } else {
              rc.Date_Client_Load_Received__c = null;
              rc.Client_Load_Received__c = false;
            }
            if (
              ar.loaderName != null &&
              String.isNotBlank(String.valueOf(ar.loaderName))
            ) {
              System.debug('The loaderName from the Feed: ' + ar.loaderName);
              rc.Loader_Name__c = ar.loaderName;
            } else {
              rc.Loader_Name__c = '';
            }
            if (
              ar.commissionDate != null &&
              String.isNotBlank(String.valueOf(ar.commissionDate))
            ) {
              System.debug(
                'The commissionDate from the Feed: ' + ar.commissionDate
              );
              rc.Date_CSS_Responded__c = ar.commissionDate;
            } else {
              rc.Date_CSS_Responded__c = null;
            }
            if (
              ar.docCollector != null &&
              String.isNotBlank(String.valueOf(ar.docCollector))
            ) {
              System.debug(
                'The docCollector from the Feed: ' + ar.docCollector
              );
              rc.Doc_Collector__c = ar.docCollector;
            } else {
              rc.Doc_Collector__c = null;
            }
            if (
              ar.docCollectionStatus != null &&
              String.isNotBlank(String.valueOf(ar.docCollectionStatus))
            ) {
              System.debug(
                'The docCollectionStatus from the Feed: ' + ar.docCollectionStatus
              );
              rc.Doc_Collection_Status__c = ar.docCollectionStatus;
            } else {
              rc.Doc_Collection_Status__c = null;
            }
            if (
              ar.docCollectionStatusDate != null &&
              String.isNotBlank(String.valueOf(ar.docCollectionStatusDate))
            ) {
              System.debug(
                'The docCollectionStatusDate from the Feed: ' + ar.docCollectionStatusDate
              );
              rc.Doc_Collection_Status_Date__c = ar.docCollectionStatusDate;
            } else {
              rc.Doc_Collection_Status_Date__c = null;
            }
            if (
              ar.mpscAccountHealthNotes != null &&
              String.isNotBlank(String.valueOf(ar.mpscAccountHealthNotes))
            ) {
              System.debug(
                'The mpscAccountHealthNotes from the Feed: ' +
                ar.mpscAccountHealthNotes
              );
              rc.MPSC_Account_Health_Notes__c = ar.mpscAccountHealthNotes;
            } else {
              rc.MPSC_Account_Health_Notes__c = '';
            }
            if (
              rc.recordtype.name == 'Reference Onboarding Core Payroll' ||
              rc.recordtype.name == 'Reference MPSC Onboarding Core Payroll'
            ) {
              if (
                ar.callTime != null &&
                String.isNotBlank(String.valueOf(ar.callTime))
              ) {
                System.debug('The callTime from the Feed: ' + ar.callTime);
                List<String> callNums = ar.CallTime.split(':');
                Time callTimeConvert = Time.newInstance(Integer.valueOf(callNums[0]),Integer.valueOf(callNums[1]),0,0);

                System.debug('Call Time Parsed: ' + callTimeConvert );

                //rc.Call_Time__c = ar.callTime;
                rc.Call_Time__c = callTimeConvert;
              } else {
                rc.Call_Time__c = null;
              }
              if (
                ar.intakeStatus != null &&
                String.isNotBlank(String.valueOf(ar.intakeStatus))
              ) {
                if (
                ar.intakeStatus == 'Submission accepted-assignments complete'||
                ar.intakeStatus == 'Complete not ready for assignment'||
                ar.intakeStatus == 'Under Review' || 
                ar.intakeStatus == 'Missing Items/Information' || 
                ar.intakeStatus == 'Submission accepted-ready for assignment' || 
                  ar.intakeStatus == 'Rejected') {
                  System.debug(
                    'The intakeStatus from the Feed: ' + ar.intakeStatus
                  );
                  if (ar.intakeStatus == 'Submission accepted-ready for assignment') {
                    rc.New_Load_Reviewed__c = true;
                    rc.New_Load_Review_Date__c = System.today();
                    System.debug('Ran submission accepted-ready for assignment');
                  }
                  if(ar.intakeStatus=='Rejected'){
                    if (ar.rejectionReasonCode != null && String.isNotBlank(String.valueOf(ar.rejectionReasonCode))) {
                      System.debug('The rejectionReasonCode from the Feed: ' + ar.rejectionReasonCode);
                      rc.Rejection_Reason_Code__c = ar.rejectionReasonCode;
                    } else {
                      rc.Rejection_Reason_Code__c = '';
                    }
                  }else{
                    System.debug('Anti Logic for Intake Status');
                    System.debug('RC Reject Reason Code: '+rc.Rejection_Reason_Code__c);
                    if(rc.Rejection_Reason_Code__c != ''){
                    System.debug('REMOVES REJECTION REASON');
                    rc.Rejection_Reason_Code__c = '';
                  }
                }
                  rc.Intake_Status__c = ar.intakeStatus;

                } else {
                  rc.Intake_Status__c = '';
                }
              }

              if ((Boolean)(ar.clientLoadComplete)) {
                rc.Client_Load_Complete__c = ar.clientLoadComplete;
              } else {
                rc.Client_Load_Complete__c = false;
              }
              //TODO review with Insite 05/31/2023
              if (String.isNotBlank(ar.iSCompletedClientAuditItems)) {
                System.debug('iSCompletedClientAuditItems from Insite: ' + ar.iSCompletedClientAuditItems);
                // if (ar.iSCompletedClientAuditItems == 'Yes') {
                  //System.debug('ar.iSCompletedClientAuditItems = Complete');
                  rc.IS_Completed_open_Client_Audit_Items__c = ar.iSCompletedClientAuditItems.trim();
                  rc.New_Load_Audit_Date__c = System.today();
                //}
                //rc.IS_Completed_open_Client_Audit_Items__c = ar.iSCompletedClientAuditItems;

              } else {
                rc.IS_Completed_open_Client_Audit_Items__c = '';
              }
              //todo review with Insite 05/31/2023
              if (
                ar.newLoadAuditDate != null &&
                String.isNotBlank(String.valueOf(ar.newLoadAuditDate))
              ) {
                System.debug(
                  'The newLoadAuditDate from the Feed: ' + ar.newLoadAuditDate
                );
                rc.New_Load_Audit_Date__c = ar.newLoadAuditDate;
              } else {
                rc.New_Load_Audit_Date__c = null;
              }
              if (
                ar.payrollRunDate != null &&
                String.isNotBlank(String.valueOf(ar.payrollRunDate))
              ) {
                System.debug(
                  'The payrollRunDate from the Feed: ' + ar.payrollRunDate
                );
                rc.Payroll_Run_Date__c = ar.payrollRunDate;
              } else {
                rc.Payroll_Run_Date__c = null;
              }
              //Todo Review with Insite 05/31/2023 
              // if (
              //   ar.postFrstPyrlVerifDate != null &&
              //   String.isNotBlank(String.valueOf(ar.postFrstPyrlVerifDate))
              // ) {
              //   System.debug(
              //     'The postFrstPyrlVerifDate from the Feed: ' +
              //     ar.postFrstPyrlVerifDate
              //   );
              //   rc.Post_First_Payroll_Verification_Date__c = ar.postFrstPyrlVerifDate;
              // } else {
              //   rc.Post_First_Payroll_Verification_Date__c = null;
              // }
              if (String.isNotBlank(ar.rescheduledRunReason)) {
                rc.Rescheduled_Run_Reason__c = ar.rescheduledRunReason;
              } else {
                rc.Rescheduled_Run_Reason__c = '';
              }
              //if(ar.orgnlProposedRunDate!=null && String.isNotBlank(String.valueOf(ar.orgnlProposedRunDate))){rc.Original_Proposed_Run_Date__c = ar.orgnlProposedRunDate ;} else {rc.Original_Proposed_Run_Date__c = null;}
              //if(ar.proposedRunDate!=null && String.isNotBlank(String.valueOf(ar.proposedRunDate))){rc.Proposed_Run_Date__c = ar.proposedRunDate ;}
              if (
                ar.proposedRunDate != null &&
                String.isNotBlank(String.valueOf(ar.proposedRunDate))
              ) {
                if (
                  rc.Proposed_Run_Date__c != null &&
                  rc.Proposed_Run_Date__c != ar.proposedRunDate
                ) {
                  rc.Original_Proposed_Run_Date__c = rc.Proposed_Run_Date__c;
                  System.debug(
                    'The proposedRunDate from the Feed: ' + ar.proposedRunDate
                  );
                  rc.Proposed_Run_Date__c = ar.proposedRunDate;
                } else {
                  rc.Proposed_Run_Date__c = ar.proposedRunDate;
                }
              }
              if (String.isNotBlank(ar.clientNeverRanReason)) {
                rc.Client_Never_Ran_Reason__c = ar.clientNeverRanReason;
              } else {
                rc.Client_Never_Ran_Reason__c = '';
              }
              if ((Boolean)(ar.clientNeverRan)) {
                rc.Client_Never_Ran__c = ar.clientNeverRan;
              } else {
                rc.Client_Never_Ran__c = false;
              }
              System.debug('final rc ' + rc ); 
              rcpUpdateList.add(rc);
            }
            accountByKeyMap.put(ar.ClientName + ar.ClientNumber.removeStart('0') + ar.Error, ar);
          } else {
            ar.Error = 'Could not find Reference Core Payroll Record';
            accountByKeyMap.put(ar.ClientName + ar.ClientNumber.removeStart('0') + ar.Error, ar);
          }
        } // End If
      } //END For
    } else {
      //for loop through all records if all records aren't found
      for (RefCorePayrollRecord rcp: rcpRecord) {
        rcp.Error = 'Could not find Any Reference Core Payroll Records with  Prospect Client Numbers provided';
        accountByKeyMap.put(rcp.ClientName + rcp.ClientNumber + rcp.Error, rcp);
      }
      // RefCorePayrollRecord ar = rcpRecord[0];
      // ar.Error = 'Could not find Any Reference Core Payroll Records with these Prospect Client Number';
      //           accountByKeyMap.put(ar.ClientName + ar.ClientNumber + ar.Error, ar);
    }
    //list < Database.SaveResult > results;
    List < Reference_Core_Payroll__c > rcpUpdateFinalList = new List < Reference_Core_Payroll__c > ();
    if (!rcpUpdateList.isEmpty()) {
      //System.debug('***List of records to be updated. If record not found here was lost in process.*** RcpUpdateList: '+rcpUpdateList.toString());
      idRcpMap.putAll(rcpUpdateList);
      rcpUpdateFinalList.addAll(rcpUpdateList);
      Set<Reference_Core_Payroll__c> uniqueRCPs = new Set<Reference_Core_Payroll__c>(rcpUpdateFinalList);
      List<Reference_Core_Payroll__c> rcpUpdateFinalList2 = new List<Reference_Core_Payroll__c>(uniqueRCPs);
      //results = Database.update(rcpUpdateFinalList, false);
      DmlHelper.performDML2(rcpUpdateFinalList2, DmlHelper.DML_UPDATE, 'FFSService', 'updateRefCorePayroll', 'updating Ref Core Payroll', true);

      System.debug('final list' + rcpUpdateFinalList2); 
     // System.debug('final list restult' + results); 
    }
    // if (results != null) {
    //   if (!rcpUpdateFinalList.isEmpty()) {
    //     for (Integer i = 0; i < results.size(); i++) {
    //       Database.SaveResult result = results.get(i);
    //       if (!result.isSuccess()) {
    //         for (Database.Error err: result.getErrors()) {
    //           if (accountByKeyMap.get(rcpUpdateFinalList.get(i).Prospect_Client_Name__c + rcpUpdateFinalList.get(i).Prospect_Client_Number__c + 'Could not find Reference Core Payroll Record') != null) {
    //             accountByKeyMap.get(
    //                 rcpUpdateFinalList.get(i).Prospect_Client_Name__c + rcpUpdateFinalList.get(i).Prospect_Client_Number__c + 'Could not find Reference Core Payroll Record')
    //               .Error = err.getMessage() + ';';
    //             system.debug('setting error' + err.getMessage());

    //             //insert error log here
    //             wsl = new Web_Service_Log__c(
    //               ServiceName__c = 'FFSService',
    //               CalledBy__c = UserInfo.getUserId(),
    //               CalledDt__c = system.now(),
    //               ServiceStart__c = system.now(),
    //               SobjName__c = 'Reference_Core_Payroll__c',
    //               NamedFunction__c = 'updaterefCorePayRoll',
    //               Action__c = 'Update',
    //               ErrorMsg__c = err.getMessage()
    //             );
    //             DmlHelper.performDML2(
    //               new List < Web_Service_Log__c > {
    //                 wsl
    //               },
    //               DmlHelper.DML_INSERT,
    //               'FFSService',
    //               'updaterefCorePayRoll',
    //               'Inserting Web Service Log',
    //               true
    //             );
    //           }

    //         }
    //       }
    //     }
    //   }
    // }
    DmlHelper.performDML2(
      new List < Web_Service_Log__c > {
        wsl
      },
      DmlHelper.DML_INSERT,
      'FFSService',
      'updaterefCorePayRoll',
      'Inserting Web Service Log',
      true
    );
    System.debug('End CPU Time===>' + Limits.getCpuTime());
    //System.debug('*** Final List of Returned RCP\'s'+ accountByKeyMap.values().toString());
    Set<RefCorePayrollRecord> uniqueRCPs = new Set<RefCorePayrollRecord>(accountByKeyMap.values());
    List<RefCorePayrollRecord> finalUniqueRCPs = new List<RefCorePayrollRecord>(uniqueRCPs);
    System.debug('*** unique rcps*** '+finalUniqueRCPs.toString());
    return finalUniqueRCPs;
  }

  public static List < Contact > getContactsByNames(Web_Service_Log__c wsl, Set < String > names, List < String > parsedNames) {
    Integer startNum = names.size();
    List < Contact > finalContacts = new List < Contact > ();
    // insert sush's query
    System.debug('Running First Contact Query');
    //wsl.Notes__c += 'Running First Contact Query \n';
    List < Contact > contactList = [
      SELECT id, name, Email
      FROM contact
      WHERE name IN: names and Email like '%@paychex.com'
      ORDER BY lastmodifieddate
    ];
    List < String > contactNamesFound = new List < String > ();
    for (Contact ctct: contactList) {
      contactNamesFound.add(ctct.Name);
    }

    Integer endNum = contactList.size();
    if (endNum == startNum && endNum != 0) {
      finalContacts = contactList;
    } else {
      List < String > problemNames = new List < String > ();
      for (String name: names) {
        if (!contactNamesFound.contains(name)) {
          problemNames.add(name);
        }
      }

      Integer endNum2;
      List < String > names2 = new List < String > ();
      for (String name: problemNames) {
        System.debug('Problem Name: ' + name);
        names.remove(name);
        StringHelper.parseFullName(name);
        // add newly parsed string for lastName in hello.apex
        List < String > lName = StringHelper.lastName.split(' ');
        String finalLastName = '';
        List < String > suffixes = new String[] {
          'Junior',
          'Jr',
          'jr',
          'junior',
          'Sr',
          'Senior',
          'sr',
          'senior',
          'I',
          'II',
          'III',
          'IV',
          'V'
        };
        //remove suffixes from last names
        if (suffixes.contains(lName[lName.size() - 1])) {
          lName.remove(lName.size() - 1);
        }

        if (lName.size() >= 2) {
          System.debug(lName.size());

          if (lName.size() == 2) {
            finalLastName = lName[1];
          }
          if(lName.size()>2){
            System.debug('last name has more than 2 strings');
            // 'J R R Tolken'
            // firstname = 'J'
            //LN = 'R R Tolken'
            //current process = if LastName size == 2 check the second element, if greater than 2 no handling
            //future process = if LastName size >2 grab the last element of the list of strings
            //INC3576802 accounting for multiple Stringed Last Names
            finalLastName = lName[lName.size()-1];
            System.debug(finalLastName);

          }
        } else {
          finalLastName = lname[0];
        }

        String parsedName = +StringHelper.firstName + '%' + finalLastName;
        parsedNames.add(StringHelper.firstName + ' ' + finalLastName);
        names2.add(parsedName);
      }

      //names.addAll(names2);
      //names2 = names;

      //names2.addAll(names);
      System.debug('Running Second Contact Query, Couldn\'t find ' + problemNames.toString());
      System.debug('parsedNames ~ the sanitized names ~ : ' + parsedNames.toString());
      System.debug('names2 ~the new name filter ~ ' + names2.toString());
      wsl.UC_Notes__c += 'Running Second Contact Query, Couldn\'t find ' + problemNames.toString() + '\n';
      List < Contact > contactList2 = [
        SELECT id, name, Email
        FROM contact
        WHERE name Like: names2
        AND Email like '%@paychex.com'
        ORDER BY lastmodifieddate
      ];
      System.debug('completed second Contact Query ');
      //wsl.Notes__c += 'Ran Second Contact Query, found : ' contactList2.toString()+'\n';

      endNum2 = contactList2.size();
      if (endNum2 != 0) {
        System.debug('contactList2: ' + contactList2.toString());
        contactList.addAll(contactList2);
        System.debug('Post adding contactList2 the new ContactList = ' + contactList.toString());
        finalContacts = contactList;
        System.debug('Final Contacts which will be returned: ' + finalContacts.toString());
      } else {
        finalContacts = contactList;
        wsl.UC_Notes__c += 'Final Contacts = : ' + finalContacts.toString();
        if (problemNames.size() > 0) {
          wsl.ErrorMsg__c += 'Could not find corresponding Contacts for: ' + String.Join(problemNames, ',' + '\n');
        }
      }
    }
    return finalContacts;
  }

  public static List < User > getUsersByNames(Web_Service_Log__c wsl, Set < String > names, List < String > parsedNames) {
    Integer startNum = names.size();
    List < User > finalUsers = new List < User > ();
    // insert sush's query
    System.debug('Running First User Query');
    //wsl.Notes__c += 'Running First User Query \n';
    List < User > UserList = [
      SELECT id, name, Email
      FROM User
      WHERE name IN: names and Email like '%@paychex.com%' and isactive = true
      ORDER BY lastmodifieddate
    ];
    List < String > UserNamesFound = new List < String > ();
    for (User ctct: UserList) {
      UserNamesFound.add(ctct.Name);
    }

    Integer endNum = UserList.size();
    if (endNum == startNum && endNum != 0) {
      finalUsers = UserList;
    } else {
      List < String > problemNames = new List < String > ();
      for (String name: names) {
        if (!UserNamesFound.contains(name)) {
          problemNames.add(name);
        }
      }

      Integer endNum2;
      List < String > names2 = new List < String > ();
      for (String name: problemNames) {
        System.debug('Problem Name: ' + name);
        names.remove(name);
        StringHelper.parseFullName(name);
        // add newly parsed string for lastName in hello.apex
        List < String > lName = StringHelper.lastName.split(' ');
        String finalLastName = '';
        List < String > suffixes = new String[] {
          'Junior',
          'Jr',
          'jr',
          'junior',
          'Sr',
          'Senior',
          'sr',
          'senior',
          'I',
          'II',
          'III',
          'IV',
          'V'
        };
        //remove suffixes from last names
        if (suffixes.contains(lName[lName.size() - 1])) {
          lName.remove(lName.size() - 1);
        }

        if (lName.size() >= 2) {
          System.debug(lName.size());

          if (lName.size() == 2) {
            finalLastName = lName[1];
          }
          if(lName.size()>2){
            System.debug('last name has more than 2 strings');
            
            finalLastName = lName[lName.size()-1];
            System.debug(finalLastName);

          }
        } else {
          finalLastName = lname[0];
        }

        String parsedName = +StringHelper.firstName + '%' + finalLastName;
        parsedNames.add(StringHelper.firstName + ' ' + finalLastName);
        names2.add(parsedName);
      }

      System.debug('Running Second User Query, Couldn\'t find ' + problemNames.toString());
      System.debug('parsedNames ~ the sanitized names ~ : ' + parsedNames.toString());
      System.debug('names2 ~the new name filter ~ ' + names2.toString());
      wsl.UC_Notes__c += 'Running Second User Query, Couldn\'t find ' + problemNames.toString() + '\n';
      List < User > UserList2 = [
        SELECT id, name, Email
        FROM User
        WHERE name Like: names2
        AND Email like '%@paychex.com%' and isactive =true 
        ORDER BY lastmodifieddate
      ];
      System.debug('completed second User Query ');
      //wsl.Notes__c += 'Ran Second User Query, found : ' UserList2.toString()+'\n';

      endNum2 = UserList2.size();
      if (endNum2 != 0) {
        System.debug('UserList2: ' + UserList2.toString());
        UserList.addAll(UserList2);
        System.debug('Post adding UserList2 the new UserList = ' + UserList.toString());
        finalUsers = UserList;
        System.debug('Final Users which will be returned: ' + finalUsers.toString());
      } else {
        finalUsers = UserList;
        wsl.UC_Notes__c += 'Final Users = : ' + finalUsers.toString();
        if (problemNames.size() > 0) {
          wsl.ErrorMsg__c += 'Could not find corresponding Users for: ' + String.Join(problemNames, ',' + '\n');
        }
      }
    }
    return finalUsers;
  }

}