/* Utilities to help with the maintenance of accounts.
 
  History
  -------
  03/30/2009 Dan Carmen   Created
  11/04/2009 Dan Carmen   Added activity record types. 
  12/03/2009 Dan Carmen   Added getRecordType method.
  09/01/2010 Dan Carmen   Added HNB.
  02/17/2011 Dan Carmen   Added logic so record types are only retrieved once from the database.
  07/09/2015 Dan Carmen   Added isCurrentClient method
  02/04/2016 Dan Carmen   Added verifyAcctNbr method
  04/09/2020 Dan Carmen   Remove getActivityRecordTypes
  10/09/2020 Jake Hinds   Adding without sharing per PMD
  11/10/2020 Dan Carmen   Ecommerce changes - mark ecom opp as sold started, close any other matching (opp types match) opps
  01/13/2021 Dan Carmen   Additional ecom changes   
  02/24/2021 Dan Carmen   Comment out code to close other opps when 1 opp closes
  05/18/2021 Dan Carmen   Changed to use OppStage Labels
  01/25/2024 Shilpa G     APR0161315: Updated method 'getSalesAccountType' to update record type as MMS if Account is in 10-19 EE space
  04/08/2024 Reetesh Pandey APR0167924 : Clientspace should update only PEO opps
 */
public without sharing class AccountHelper implements TriggerInterfaceC {
    
   public static final String CLASSNAME='AccountHelper';

   /** The core sales force */
   public static final String CORE='Core';
   /** The MMS sales force */
   public static final String MMS='MMS';
   /** The HRS sales force */
   public static final String HRS='HRS';
   /** The Premier sales force */
   public static final String Premier='Premier';
   /** The HNB Sales Force */
   public static final String HNB='HNB';
   
   /* The name of the Account record type for Core. */ 
   public static final String CORE_ACCOUNT = 'Core Account Record Type';
   /* The name of the Account record type for MMS. */
   public static final String MMS_ACCOUNT = 'MMS Account Record Type';
   /** The name of the Contact record type for Core. */
   public static final String CORE_CONTACT = 'Core Contact Record Type';
   /** The name of the Contact record type for MMS. */
   public static final String MMS_CONTACT = 'MMS Contact Record Type';
   
   /** A map of all record types that have been retrieved. To only retrieve once. */
   private static Map<String,List<RecordType>> allRts = new Map<String,List<RecordType>>();
   
   /** The name of the Task record type for Core. */
   public static final String CORE_TASK = 'Core Task Record Type';
   /** The name of the Task record type for MMS. */
   public static final String MMS_TASK = 'MMS Task Record Type';
   /** The name of the Task record type for HRS. */
   public static final String HRS_TASK = 'HRS Task Record Type'; 
   /** The name of the Event record type for Core. */
   public static final String CORE_EVENT = 'Core Event Record Type';
   /** The name of the Event record type for MMS. */
   public static final String MMS_EVENT = 'MMS Event Record Type';
   /** The name of the Event record type for HRS. */
   public static final String HRS_EVENT = 'HRS Event Record Type'; 
   
   /** The name of the Lead record type for Core. */
   public static final String CORE_LEAD = 'Core Lead Record Type';
   /** The name of the Lead record type for HRS. */
   public static final String HRS_LEAD = 'HRS Lead Record Type';
   /** The name of the Lead record type for MMS. */
   public static final String MMS_LEAD = 'MMS Lead Record Type';

   public void handleTrigger(SObject[] p_recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      SObject[] recs = TriggerMethods.checkRecs('AccountHelper', p_recs, oldMap, isBefore, isAfter, isDelete, null, null);
      if (recs == null || recs.isEmpty()) {
         return;
      }
      SObjectType objType = TriggerMethods.objType;
      String objTypeName = TriggerMethods.objectTypeName;
      System.debug('AccountHelper objTypeName='+objTypeName+' recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete);
      if (isAfter) {
         if (objType == Account.sObjectType) {
            handleAcctsAfter((Account[])recs, (Map<Id,Account>)oldMap);
         }
      } // if (isAfter
   } // handleTrigger
    
   public static void handleAcctsAfter(Account[] accts, Map<Id,Account> oldMap) {
      Id[] checkForFirstRunOpps = new Id[]{};
      for (Account acct : accts) {
         Account oldAcct = (oldMap != null ? oldMap.get(acct.Id) : null);
         if (acct.First_Run_Date__c != null && oldAcct != null && acct.First_Run_Date__c != oldAcct.First_Run_Date__c) {
            checkForFirstRunOpps.add(acct.Id);
         }
      } // for (Account acct
       
      if (!checkForFirstRunOpps.isEmpty()) {
         if (Utilities.allowFuture()) {
            checkFirstRunOppsFuture(checkForFirstRunOpps);
         } else {
            checkFirstRunOppsNow(checkForFirstRunOpps);
         }
      }
   } // handleAcctsAfter

   @future
   public static void checkFirstRunOppsFuture(Id[] acctIds) {
      checkFirstRunOppsNow(acctIds);
   } // checkFirstRunOppsFuture
    
   public static String SOLD_STARTED=Label.OppStage_Sold_Started;
   public static String NOT_SOLD=Label.OppStage_Lost;
    
   public static void checkFirstRunOppsNow(Id[] acctIds) {
      Account[] accts = [Select Id, Name, First_Run_Date__c
                                ,(Select Id, CloseDate, StageName, OpportunityType__c, Reason_Not_Sold__c
                                        ,RecordTypeId, RecordType.Name
                                    From Opportunities
                                   Where IsClosed = false)
                            From Account
                           Where Id in :acctIds];
      Opportunity[] updateOpps = new Opportunity[]{};
      Boolean isClientSpaceUser = UserInfo.getUsername().contains('clientspace_user');
      for (Account acct : accts) {
         // there should (in theory) at most be one opportunity that meets this criteria
         Opportunity soldStartedOpp = null;
         RecordType__c soldStartedRt = null;
         for (Opportunity opp: acct.Opportunities) {
            RecordType__c rt = RecordType__c.getInstance(RecordTypeHelper.cleanRtName(opp.RecordType.Name));
            if (rt != null && rt.FirstRunDateUpdate__c && (!isClientSpaceUser || (isClientSpaceUser && rt.RecordTypeName__c.contains('PEO')))) {
               soldStartedOpp = opp;
               soldStartedRt = rt;
               opp.StageName = SOLD_STARTED;
               opp.CloseDate = acct.First_Run_Date__c;
               opp.Reason_Won__c = rt.FirstRunReasonWon__c;
               updateOpps.add(opp);
            }
         } // for (Opportunity opp : acct.Opportunities
         // mark other open opportunities of the same opportunity type as not sold
         /* Not sure if we need to keep this. Originally for an ecommerce change to close other opps of the same type if an ecommerce opp went sold
          * requirement was subsequently changed to close other open opps when the ecommerce opp was created instead.
         if (soldStartedOpp != null && soldStartedRt != null) {
            for (Opportunity opp : acct.Opportunities) {
               if (opp.Id != soldStartedOpp.Id && opp.OpportunityType__c == soldStartedOpp.OpportunityType__c) {
                  opp.StageName = NOT_SOLD;
                  opp.Reason_Not_Sold__c = soldStartedRt.FirstRunReasonLost__c;
                  updateOpps.add(opp);
               }
            }
         }
         */
         
      } // for (Account acct : accts
      DmlHelper.performDML2(updateOpps, DmlHelper.DML_UPDATE, CLASSNAME, 'checkFirstRunOppsNow', 'Update Accounts', true);
   } // checkFirstRunOppsNow
    
   public static RecordType__c getAcctRecordTypeMatch(Integer numEmps) {
      RecordType__c rtEmpMatch = null;
      if (numEmps != null) {
         RecordType__c rtCore = RecordType__c.getInstance(RecordTypeHelper.CORE_ACCOUNT);
         if (rtCore != null && rtCore.EmpsMin__c != null && rtCore.EmpsMax__c != null
             && (numEmps >= rtCore.EmpsMin__c && numEmps <= rtCore.EmpsMax__c)) {
            rtEmpMatch = rtCore;
         } // if (rtCore != null
         System.debug('getAcctRecordTypeMatch numEmps='+numEmps+' rtEmpMatch='+(rtEmpMatch != null)+' rtCore='+rtCore);
   
         if (rtEmpMatch == null) {
            RecordType__c rtMms = RecordType__c.getInstance(RecordTypeHelper.MMS_ACCOUNT);
            if (rtMms != null && rtMms.EmpsMin__c != null && rtMms.EmpsMax__c != null
                && (numEmps >= rtMms.EmpsMin__c && numEmps <= rtMms.EmpsMax__c)) {
               rtEmpMatch = rtMms;
            } // if (rtCore != null
            System.debug('evaluateSegmentation rtEmpMatch='+(rtEmpMatch != null)+' rtMms='+rtMms);
         } // if (rtEmpMatch == null
      } // if (numEmps != null
      return rtEmpMatch;
   } // getAcctRecordTypeMatch
     
   /** Get the type of account being represented based on the Sales Organization of the
       User and/or the number of employees.
       
       @param salesOrg - the sales organization of the user
       @param numerEmployees - the number of employees
       @param defAcctType - the default account type
    */
   public static String getSalesAccountType(String salesOrg, Integer numberEmployees, String defAcctType) {
    String acctType = null;
    //APR0161315: Update record type to MMS if Account is in 10-19 EE space
    //RecordType__c rtEmpMatch = getAcctRecordTypeMatch(numberEmployees);
    RecordType__c rtEmpMatch = null;
    if(numberEmployees != null && numberEmployees >= Integer.valueOf(Label.MMS_Prospect_Emp_Min) && numberEmployees <= Integer.valueOf(Label.MMS_Prospect_Emp_Max)){
      rtEmpMatch = RecordType__c.getInstance(RecordTypeHelper.MMS_ACCOUNT);
    }
    if (rtEmpMatch == null) {
      rtEmpMatch = getAcctRecordTypeMatch(numberEmployees);
    }
    if (rtEmpMatch != null) {
       acctType = rtEmpMatch.Name;
    }
    /*
    if (numberEmployees != null) {
       RecordType__c rtCore = RecordType__c.getInstance(RecordTypeHelper.CORE_ACCOUNT);
       if (rtCore != null && )
         if (numberEmployees >= 50) {
            acctType = MMS_ACCOUNT;
         } else if (numberEmployees > 0) {
            acctType = CORE_ACCOUNT;
         }
    }
    */ 
      if (String.isBlank(acctType) && String.isNotBlank(salesOrg)) {
         if (salesOrg == UserHelper.SO_CORE) {
            acctType = CORE_ACCOUNT;
         } else if (salesOrg == UserHelper.SO_MMS) {
            acctType = MMS_ACCOUNT;
         }
      } // if (salesOrg != null

      if (String.isBlank(acctType)) {
         acctType = defAcctType;
      }
      // default return value
      return acctType;
   } // getSalesAccountType
   
   /* Check the passed in value for the account number. The 
      account number should be in the format branch-client. The branch
      can be 2,3, or 4 characters. If it is less that 4 characters, left
      pad it with zeroes to make it 4 characters. An account number needs
      to be at least 7 characters to be valid.
      If the branch number is passed in at 4 characters, will strip off any
      leading zeroes.
    */
   public static String transformAcctNbr(String acctNbr) {
      // Check for length. It must be at least 6 characters (1 branch, 1 dash, 4 char client number)
      if ((acctNbr == null) || (acctNbr.length() < 6)) {
         return null;
      } 
      // check for dash. Do not continue is there is not a dash.
      Integer dashPos = acctNbr.indexOf('-',0);
      if ((dashPos > -1) && (dashPos < 4)) {
         String newAcctNbr = acctNbr;
         // how many zeroes are needed?
         Integer numZeroes = 4-dashPos;
         // if a dash exists and the branch number is less than 4, left pad with zeroes
         while (numZeroes > 0) {
            newAcctNbr = '0'+newAcctNbr;
            numZeroes--;
         }
         return newAcctNbr;
      } else if (dashPos == 4) {
         String newAcctNbr = acctNbr;
         while (newAcctNbr.startsWith('0')) {
            newAcctNbr = newAcctNbr.substring(1);
         } 
         return newAcctNbr;
      } // if ((dashPos))
      return null;
   } // transformAcctNbr

   // make sure the incoming value is a valid account number. Try to transform it if necessary.
   public static String verifyAcctNbr(String p_checkAcctNbr) {
      System.debug('verifyAcctNbr start for p_checkAcctNbr='+p_checkAcctNbr);
      String returnValue = '';
      // Check for length. It must be at least 6 characters (1 branch, 1 dash, 4 char client number)
      Boolean okayToContinue = (String.isNotBlank(p_checkAcctNbr) && p_checkAcctNbr.length() >= 6);
      // make sure there is a dash
      String branchNbr = '';
      String clientNbr = '';
      if (okayToContinue) {
         Integer dashPos = p_checkAcctNbr.indexOf('-',0);
         // has to be between 1 and 4 characters before the dash
         okayToContinue = ((dashPos >= 1) && (dashPos <= 4));
         if (okayToContinue) {
            branchNbr = p_checkAcctNbr.substring(0,dashPos);
            clientNbr = p_checkAcctNbr.subString(dashPos+1);
            // make sure the branchNbr is all numbers
            okayToContinue = branchNbr.containsOnly(NUMBERS);
            System.debug('verifyAcctNbr branchNbr='+branchNbr+' clientNbr='+clientNbr+' okayToContinue='+okayToContinue);
            if (okayToContinue) {
               // remove the leading zeroes
               branchNbr = Utilities.removeLeadingZero(branchNbr);
               // remove any extra characters from the client number section
               clientNbr = Utilities.removeExtraChars(clientNbr.toUpperCase(),ALPHA_NUMERIC);
               // make sure the client number is no more than 8 characters
               okayToContinue = clientNbr.length() <= 8;
               System.debug('verifyAcctNbr after length check branchNbr='+branchNbr+' clientNbr='+clientNbr+' okayToContinue='+okayToContinue);
               if (okayToContinue) {
                  // make sure client number is exactly 4 or exactly 8
                  while ((clientNbr.length() < 4) || ((clientNbr.length() > 4 && clientNbr.length() < 8))) {
                     System.debug('verifyAcctNbr adding zero in while loop');
                     clientNbr = '0'+clientNbr;
                  } // while
               } // if (okayToContinue
            } // if (okayToContinue
         } // if (okayToContinue
      } // if (String.isNotBlank
      if (okayToContinue) {
         returnValue = branchNbr+'-'+clientNbr;
      } else {
         // return the original value if not okay
         returnValue = p_checkAcctNbr;
      }
      System.debug('verifyAcctNbr finish p_checkAcctNbr='+p_checkAcctNbr+' returnValue='+returnValue);
      return returnValue;
   } // verifyAcctNbr
   
   // Used to validate all values in the branch portion are numbers.
   public static final String NUMBERS='0123456789';
   public static final String ALPHA_NUMERIC='0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ';
   
   /* Validate that the account number is in a valid format. 
      A valid format is assuming at least 1, but no more than 4, 
      characters before the dash, and at least 4 characters after 
      the dash. It validates that the branch portion is all number, but
      does not validate the client number portion.
      TEST-TEST would be invalid, but 17-TEST would be valid.
    */
   public static boolean isAcctNbrValid(String acctNbr) {
      // Check for length. It must be at least 6 characters (1 branch, 1 dash, 4 char client number)
      if ((acctNbr == null) || (acctNbr.length() < 6)) {
         return false;
      } 
      // check for dash. Do not continue is there is not a dash.
      Integer dashPos = acctNbr.indexOf('-',0);
      /* the only valid dash positions are 
         1 - 8-TEST
         2 - 17-TEST
         3 - 400-TEST
         4 - 1030-TEST
       */
      if ((dashPos >= 1) && (dashPos <= 4)) {
         // verify there are at least 4 positions after the dash
         if ((acctNbr.length() - (dashPos+1)) >= 4) {
            // verify that the branch portion of the string is all numbers
            for (Integer pos=0; pos< dashPos; pos++) {
               if (NUMBERS.indexOf(acctNbr.substring(pos,pos+1)) == -1) {
                   return false;
               }
            } // for (Integer pos=0

            return true;
         }
      } // if ((dashPos
      
      return false;     
   } // isAcctNbrValid
   
   // is the passed in account a current client?
   public static Boolean isCurrentClient(Account acct) {
      Boolean currentClient = false;
      if (acct != null) {
         currentClient = (acct.Bis_ID__c != null && acct.Bis_ID__c > 0 && acct.Lost_Date__c == null && acct.First_Run_Date__c != null && acct.Type != 'Lost Client');
      } // if (acct != null
      return currentClient; 
   } // isCurrentClient

   public static Integer getBranchNumber(Account acct) {
      Integer branchNbr = null;
      if (acct != null && String.isNotBlank(acct.AccountNumber)) {
         try {
            Integer dashPos = acct.AccountNumber.indexOf('-',0);
            if (dashPos >= 1) {
               branchNbr = Integer.valueOf(acct.AccountNumber.left(dashPos));
            }
         } catch (Exception e) {
            System.debug('getBranchNumber e='+e);
         }
      } // if (acct != null
      return branchNbr;
   } // getBranchNumber
    
   // TODO - this code should be removed!
   // Get the record type based on the incoming parameters.
    // @param recordTypeName the name of the record type
    // @param sObjectType the type of object. This assists when the names are not unique. This parameter can be null.
   public static RecordType getRecordType(String recordTypeName, String sObjectType) {
      RecordType rt = null;
      String key = 'OneRt'+recordTypeName+(sObjectType != null ? sObjectType : '');
      List<RecordType> recordTypes = allRts.get(key);
      if (recordTypes != null) {
         if (!recordTypes.isEmpty()) {
            // should only be one record
            rt = recordTypes.get(0);
         }
      } else {
         if (sObjectType == null) {
            rt = [Select Id, Name, SobjectType from RecordType where name = :recordTypeName];
         } else {
            rt = [Select Id, Name, SobjectType from RecordType where name = :recordTypeName and SobjectType = :sObjectType];
         }
         if (rt != null) {
            recordTypes = new List<RecordType>();
            recordTypes.add(rt);
            allRts.put(key,recordTypes);
         } // if (rt != null
      } // if (recordTypes != null
      return rt;
   } // getRecordType
    

} // class AccountHelper