/* 
   Methods for the NSS Sales methods.
   
  History
  -------
  01/19/2015 Dan Carmen      Created
  04/27/2015 Dan Carmen      Change to test methods based on opportunity splits being active
  05/06/2015 Dan Carmen      Fix for matching up to opportunity
  03/31/2016 Dan Carmen      Change to match product based on NSS Source
  05/24/2016 Dan Carmen      Add the ability to accept not sold opportunities
  07/18/2016 Dan Carmen      Added a check for the length of the other link info field.
  09/12/2016 Dan Carmen      Ability to extend the length of time to check for commission period.
   
 */
public with sharing class NSSSalesMethods {

   public static Boolean SKIP_TRIGGERS=false; 

   // associate the product record with the client record.
   public static void findClientRecs(NSSSalesProduct__c[] productRecs, Set<String> clientNbrSet) {
      // store in a map for easy reference
      Map<String, NSSSalesClient__c> clientMap = new Map<String, NSSSalesClient__c>();
      NSSSalesClient__c[] clients = [select Id, Name 
                                       from NSSSalesClient__c 
                                      where Name in :clientNbrSet
                                        and IsDuplicate__c = false
                                        and CheckedForDupe__c = true];
      for (NSSSalesClient__c client : clients) {
         clientMap.put(client.Name, client);
      } // for (NSSSalesClient__c client
      
      for (NSSSalesProduct__c product : productRecs) {
         NSSSalesClient__c client = clientMap.get(product.BranchClientNumber__c);
         if (client != null) {
            product.NSSSalesClient__c = client.Id;
         }
      } // for (NSSSalesProduct__c product
   } // findClientRecs
   
   // link the sales rep to the product record.
   public static void findSalesReps(NSSSalesProduct__c[] productRecs, Set<String> salesRepPersonIdSet) {
      System.debug('findSalesReps salesRepPersonIdSet='+salesRepPersonIdSet);
      User[] users = [Select Id, Name, Sales_Org__c, IsActive, HR_Person_Id__c 
                        from User 
                       where HR_Person_Id__c in :salesRepPersonIdSet and Sales_Org__c in :UserHelper.DIVISION_LIST
                       order by HR_Person_Id__c, LastLoginDate desc nulls last];
      // map for easy recall
      Map<String,User> userByPersonIdMap = new Map<String,User>();
      for (User usr : users) {
         // only add to map if not already there
         if (!userByPersonIdMap.containsKey(usr.HR_Person_Id__c)) {
            userByPersonIdMap.put(usr.HR_Person_Id__c,usr);
         }
      } // for (User usr
      
      for (NSSSalesProduct__c nsp : productRecs) {
         User usr = userByPersonIdMap.get(nsp.SalesRepPersonId__c);
         if (usr != null) {
            nsp.SalesRep__c = usr.Id;
         }
      } // for (NSSSalesProduct__c nsp
   } // findSalesReps
   
  //private static NSSSalesAcctLink__c[] newLinks = new NSSSalesAcctLink__c[]{};
   //private static NSSSalesAcctLink__c[] updateLinks = new NSSSalesAcctLink__c[]{};
   
   // keep track of the links by key of {id of nss client record}{accountid}
   private static Map<String,NSSSalesAcctLink__c> newLinkMap = new Map<String,NSSSalesAcctLink__c>();
   private static Map<String,NSSSalesAcctLink__c> updateLinkMap = new Map<String,NSSSalesAcctLink__c>();
   
   public static void setupSaveLinks() {
      //newLinks = new NSSSalesAcctLink__c[]{};
      //updateLinks = new NSSSalesAcctLink__c[]{};
      newLinkMap.clear();
      updateLinkMap.clear();
   } // setupSaveLinks

   public static void checkLinksForSave(String methodName, String idToLog) {
      System.debug('checkLinksForSave start methodName='+methodName+' newLinkMap='+newLinkMap.size()+' updateLinkMap='+updateLinkMap.size());
      //DmlHelper.performDML(newLinks, DmlHelper.DML_INSERT, 'NSSSalesMethods', methodName, 'inserting new links', false);
      //DmlHelper.performDML(updateLinks, DmlHelper.DML_UPDATE, 'NSSSalesMethods', methodName, 'updating links', false);
      SKIP_TRIGGERS=true;
      DmlHelper.performDML2(newLinkMap.values(), DmlHelper.DML_INSERT, 'NSSSalesMethods', methodName, 'inserting new links', false);
      DmlHelper.performDML2(updateLinkMap.values(), DmlHelper.DML_UPDATE, 'NSSSalesMethods', methodName, 'updating links', false);
      SKIP_TRIGGERS=false;

      ErrorLog.checkSave();
      System.debug('checkLinksForSave end methodName='+methodName);
   } // checkLinksForSave
   
   public static void findAccountRecords(Id[] nssSalesCltIds) {
      // reselect the records and pull back any existing links.
      NSSSalesClient__c[] clients = [Select Id, Name
                                           ,ZipCode__c
                                           ,(Select Id, Name, Account__c, NSSSalesClient__c, BranchClientMatch__c, ImportMatch__c
                                                   ,MultiIdParentId__c,MultiIdSalesParent__c,MultiIdSameFEIN__c
                                               from NSSSalesAcctLinks__r)
                                       From NSSSalesClient__c
                                      Where Id in :nssSalesCltIds
                                        and CheckedForDupe__c=true
                                        and IsDuplicate__c=false];
      // collect the branch-client numbers
      Map<String,List<NSSSalesClient__c>> acctNbrMap = new Map<String,List<NSSSalesClient__c>>();
      for (NSSSalesClient__c client : clients) {
         List<NSSSalesClient__c> clientList = acctNbrMap.get(client.Name);
         if (clientList == null) {
            clientList = new List<NSSSalesClient__c>();
            acctNbrMap.put(client.Name, clientList);
         }
         clientList.add(client);
      } // for (NSSSalesClient__c client
      
      // search for account records based on account number
      Account[] accts = [Select Id, Name, AccountNumber, ParentId, SalesParent__c, FEIN_Parent_ID__c
                           From Account
                          Where AccountNumber in :acctNbrMap.keySet()];
      
      setupSaveLinks();
      setupMultiIdCheck();
      
      for (Account acct : accts) {
         String branchClt = acct.AccountNumber;
         List<NSSSalesClient__c> clientList = acctNbrMap.get(branchClt);
         if (clientList != null) {
            checkMultiIdCheckForSameFein(acct, clientList);
            
            for (NSSSalesClient__c clnt : clientList) {
               checkForSalesAcctLink(clnt, acct.Id, 'BranchClientMatch__c');
               checkMultiIdInClntLoop(acct, clnt);
               
            } // for (NSSSalesClient__c clnt
            
         } // if (clientList != null
      } // for (Account acct
      
      checkMultiIdSameFein();
      checkLinksForSave('findAccountRecords',nssSalesCltIds[0]);
   } // findAccountRecords
   
   // if there's a value in the FEIN field, save the records and requery accounts
   private static Map<String,NSSSalesClient__c[]> byFeinMap = new Map<String,NSSSalesClient__c[]>();
   private static Set<Id> excludeAccountIdSet = new Set<Id>();

   public static Boolean PROCESS_MULTI_ID=Label.NSSSalesUseMultiId=='Y';
   public static Boolean PROCESS_MULTI_SAME_FEIN=Label.NSSSalesSameFein=='Y';
   
   public static void setupMultiIdCheck() {
      byFeinMap.clear();
      excludeAccountIdSet.clear();
   } // setupMultiIdCheck
   
   public static void checkMultiIdInClntLoop(Account acct, NSSSalesClient__c clnt) {
      if (PROCESS_MULTI_ID) {
         if (acct.ParentId != null) {
            checkForSalesAcctLink(clnt, acct.ParentId, 'MultiIdParentId__c');
         }
         if (acct.SalesParent__c != null) {
            checkForSalesAcctLink(clnt, acct.SalesParent__c, 'MultiIdSalesParent__c');
         }
      } // if (PROCESS_MULTI_ID
   } // checkMultiIdInClntLoop

   public static void checkMultiIdCheckForSameFein(Account acct, NSSSalesClient__c[] clientList) {
      if (PROCESS_MULTI_SAME_FEIN) {
         if (String.isNotBlank(acct.FEIN_Parent_ID__c)) {
            excludeAccountIdSet.add(acct.Id);
            NSSSalesClient__c[] checkClientList = byFeinMap.get(acct.FEIN_Parent_Id__c);
            if (checkClientList == null) {
               checkClientList = new NSSSalesClient__c[]{};
               byFeinMap.put(acct.FEIN_Parent_Id__c, checkClientList);
            }
            checkClientList.addAll(clientList);
         } // if (String.isNotBlank(acct.FEIN_Parent_ID__c
      } // if (PROCESS_MULTI_SAME_FEIN
   } // checkMultiIdCheckForSameFein

   public static void checkMultiIdSameFein() {
      if (!byFeinMap.isEmpty()) {
         Account[] feinAccts = [Select Id, Name, FEIN_Parent_ID__c
                                  From Account
                                 Where FEIN_Parent_ID__c in :byFeinMap.keySet()
                                   and FEIN_Parent_ID__c != null
                                   and Id not in :excludeAccountIdSet];
         for (Account acct : feinAccts) {
            NSSSalesClient__c[] checkClientList = byFeinMap.get(acct.FEIN_Parent_Id__c);
            if (checkClientList != null) {
               for (NSSSalesClient__c clnt : checkClientList) {
                  checkForSalesAcctLink(clnt, acct.Id, 'MultiIdSameFEIN__c');
               }
            }
         } // for (Account acct : fienAccts
      } // if (!byFeinMap.isEmpty
   } // checkMultiIdSameFein

   public static NSSSalesAcctLink__c checkForLink(String key) {
      NSSSalesAcctLink__c foundLink = updateLinkMap.get(key);
      if (foundLink == null) {
         foundLink = newLinkMap.get(key);
      }
      return foundLink;
   } // checkForLink
   
   // check if link already exists. Create a new one if it doesn't
   public static void checkForSalesAcctLink(NSSSalesClient__c clnt, Id acctId, String fieldNameToCheck ) {
      String key = ''+clnt.Id+acctId;
      NSSSalesAcctLink__c foundLink = checkForLink(key);
      System.debug('checkForSalesAcctLink key='+key+' clnt='+clnt.Name+' fieldNameToCheck='+fieldNameToCheck+' foundLink='+foundLink);
      Boolean linkFound = (foundLink != null);
      
      if (foundLink == null && clnt.NSSSalesAcctLinks__r != null) {
         for (NSSSalesAcctLink__c checkLink : clnt.NSSSalesAcctLinks__r) {
            if (checkLink.Account__c == acctId) {
               foundLink = checkLink;
            }
         } // for (NSSSalesAcctLink__c checkLink
         
         System.debug('checkForSalesAcctLink checking existing links foundLink='+foundLink);
      } // if (foundLink == null &&
      
      if (foundLink != null) {
         System.debug('checkForSalesAcctLink has a foundLink before updateLinkMap='+updateLinkMap.size()+' fieldNameToCheck='+fieldNameToCheck+' foundLink='+foundLink);
         Boolean fieldValueToCheck = (Boolean)foundLink.get(fieldNameToCheck);
         if (fieldValueToCheck == null || !fieldValueToCheck) {
            System.debug('checkForSalesAcctLink set '+fieldNameToCheck+' to true');
            foundLink.put(fieldNameToCheck,true);
            updateLinkMap.put(key,foundLink);
            //updateLinks.add(checkLink);
           /*
         } else if (fromImport && !foundLink.ImportMatch__c) {
            System.debug('checkForLink ImportMatch__c=true');
            foundLink.ImportMatch__c = true;
            updateLinkMap.put(key,foundLink);
            //updateLinks.add(checkLink);
           */
         }
         System.debug('checkForSalesAcctLink has a foundLink after updateLinkMap='+updateLinkMap.size());
      } // if (foundLink != null
      
      if (foundLink == null) {
         System.debug('checkForSalesAcctLink create new link');
         NSSSalesAcctLink__c newLink = new NSSSalesAcctLink__c(Name=clnt.Name, Account__c=acctId, NSSSalesClient__c=clnt.Id);
         newLink.put(fieldNameToCheck,true);
//                                                    ,BranchClientMatch__c=fromBranchClt, ImportMatch__c=fromImport);
         newLinkMap.put(key,newLink);
         //newLinks.add(newLink);
      }
   } // checkForSalesAcctLink
   
   // check if the account ids exist
   public static void checkAccountIdExists(NSSSalesAcct__c[] checkAccountIdList, Set<String> accountIdSet) {
      Map<Id, Account> acctMap = new Map<Id,Account>([Select Id, Name from Account where Id in :accountIdSet]);
      for (NSSSalesAcct__c nsa : checkAccountIdList) {
         nsa.AccountIdChecked__c = true;
         try {
            Id checkAcctId = (Id)nsa.AccountId__c;
            nsa.AccountIdIsValid__c = acctMap.containsKey(checkAcctId);
         } catch (Exception e) {
            // do nothing here - if there's an exception the id is not valid
         }
      } // for (NSSSalesAcct__c nsa
   } // checkAccountIdExists
   
   public static void handleNssSalesAccts(Map<String,List<NSSSalesAcct__c>> acctByBranchNbrMap) {
      
      // retrieve the client records
      NSSSalesClient__c[] clients = [Select Id, Name
                                           ,ZipCode__c
                                           ,(Select Id, Name, Account__c
                                                   ,NSSSalesClient__c, BranchClientMatch__c, ImportMatch__c
                                                   ,MultiIdParentId__c,MultiIdSalesParent__c,MultiIdSameFEIN__c
                                               from NSSSalesAcctLinks__r)
                                           ,(Select Id, Name
                                               From NSSSalesAccts__r)
                                       From NSSSalesClient__c
                                      Where Name in :acctByBranchNbrMap.keySet()
                                        and IsDuplicate__c = false
                                        and CheckedForDupe__c = true];
                                      
      System.debug('handleNssSalesAccts clients='+clients.size());
      if (!clients.isEmpty()) {      
         setupSaveLinks();
      
         Map<String, NSSSalesClient__c[]> clntByAccountIdMap = new Map<String, NSSSalesClient__c[]>();
         
         // link the client to the acct record
         for (NSSSalesClient__c clnt : clients) {
            List<NSSSalesAcct__c> acctList = acctByBranchNbrMap.get(clnt.Name);
            if (acctList != null) {
            
               for (NSSSalesAcct__c acct : acctList) {
                  // link to the client record
                  acct.NSSSalesClient__c = clnt.Id;
               
                  if (acct.AccountIdIsValid__c) {
                     checkForSalesAcctLink(clnt, acct.AccountId__c, 'ImportMatch__c');
                     // store the client information to look for multi ids
                     NSSSalesClient__c[] clntList = clntByAccountIdMap.get(acct.AccountId__c);
                     if (clntList == null) {
                        clntList = new NSSSalesClient__c[]{};
                        clntByAccountIdMap.put(acct.AccountId__c,clntList);
                     }
                     clntList.add(clnt);
                  }
               } // for (NSSSalesAcct__c acct
            } // if (acctList != null
         } // for (NSSSalesClient__c client
         if (!clntByAccountIdMap.isEmpty()) {
            checkForMultiIds(clntByAccountIdMap);
         }
         checkLinksForSave('handleNssSalesAccts',clients[0].Id);
      } // if (!clients
   } // handleNssSalesAccts
   
      
   public static void checkForMultiIds(Map<String, NSSSalesClient__c[]> clntByAccountIdMap) {
      Account[] accts = [Select Id, Name,  AccountNumber, ParentId, SalesParent__c, FEIN_Parent_ID__c
                           From Account
                          Where Id in :clntByAccountIdMap.keySet()
                            and (ParentId != null or SalesParent__c != null or FEIN_Parent_ID__c != null)];

      setupMultiIdCheck();
      for (Account acct : accts) {
         NSSSalesClient__c[] clientList = clntByAccountIdMap.get(acct.Id);
         if (clientList != null) {
            checkMultiIdCheckForSameFein(acct, clientList);
            
            for (NSSSalesClient__c clnt : clientList) {
               checkMultiIdInClntLoop(acct, clnt);
            } // for (NSSSalesClient__c clnt
         } // if (clientList != null
      } // for (Account acct : accts
      checkMultiIdSameFein();
   } // checkForMultiIds
   
   public static final Integer NAME_FIELD_LENGTH = ProductGroupMapping__c.Name.getDescribe().getLength();

   public static String MAPPING_TYPE='NSSSales';
   
   public static ProductGroupMapping__c getMapping(String productName) {
      String key=((MAPPING_TYPE+'-'+(String.isNotBlank(productName) ? productName : '')).replace(' ','')).left(NAME_FIELD_LENGTH);
      ProductGroupMapping__c mapping = ProductGroupMapping__c.getInstance(key);
      return mapping;
   } // getMapping
   
   public static Map<String,Set<String>> recordTypeByProductNameMap = new Map<String,Set<String>>();
   // keep track of which NSS Source can get credit for a product (Inbound/Outbound/Both)
   public static Map<String,Set<String>> nssSourceByProductNameMap = new Map<String,Set<String>>();
   
   public static Set<String> getRecordTypeNames(String productName) {
      Set<String> recordTypeNameSet = recordTypeByProductNameMap.get(productName);
      if (recordTypeNameSet == null) {
         recordTypeNameSet = new Set<String>();
         ProductGroupMapping__c mapping = getMapping(productName);
         if (mapping != null) {
            checkSalesOrgRecordTypes(mapping.Sales_Org__c,recordTypeNameSet);
            checkSalesOrgRecordTypes(mapping.Sales_Org2__c,recordTypeNameSet);
            String nssSource = String.isNotBlank(mapping.NSS_Source__c) ? mapping.NSS_Source__c : 'Both';
            Set<String> nssSourceSet = (nssSource == 'Both' ? ProspectOwnershipMethods.NSS_SOURCE_SET : new Set<String>{nssSource});
            nssSourceByProductNameMap.put(productName, nssSourceSet);
         } // if (mapping != null
         recordTypeByProductNameMap.put(productName,recordTypeNameSet);
      } // if (recordTypeNameSet == null

      System.debug('getRecordTypeNames productName='+productName+' recordTypeNameSet='+recordTypeNameSet);
      return recordTypeNameSet;
   } // getRecordTypeNames
   
   // check for the record type names in the Sales Org custom object
   public static void checkSalesOrgRecordTypes(String p_salesOrg, Set<String> recordTypeNameSet) {
      if (String.isNotBlank(p_salesOrg)) {
         SalesOrg__c salesOrg = SalesOrg__c.getInstance(p_salesOrg);
         if (salesOrg != null) {
            if (String.isNotBlank(salesOrg.OpptyRecordTypeName__c)) {
               recordTypeNameSet.add(salesOrg.OpptyRecordTypeName__c);
            }
            if (String.isNotBlank(salesOrg.OpptyRecordTypeName2__c)) {
               recordTypeNameSet.add(salesOrg.OpptyRecordTypeName2__c);
            }
         } // if (salesOrg != null
      } // if (String.isNotBlank(p_salesOrg
     
   } // checkSalesOrgRecordTypes
   
   public static Set<Id> nssOppProductIdSet = new Set<Id>();
   public static Set<Id> nssOppClientIdSet = new Set<Id>();
   
   public static Boolean ALLOW_NOT_SOLD=(Label.NSSSalesAllowNotSoldOpps=='Y');

   // from the NSS Sales Product records, link to the opportunities
   public static void checkOppLinks(Set<Id> p_nssClientIdSet, Set<Id> p_nssProductIdSet) {
      System.debug('checkOppLinks ALLOW_NOT_SOLD='+ALLOW_NOT_SOLD+' p_nssClientIdSet='+p_nssClientIdSet.size()+' p_nssProductIdSet='+p_nssProductIdSet.size());
      // get the links to the accounts
      NSSSalesAcctLink__c[] links = [Select Id
                                           ,NSSSalesClient__c
                                           ,Account__c
                                           ,BranchClientMatch__c, ImportMatch__c
                                           ,MultiIdParentId__c,MultiIdSalesParent__c,MultiIdSameFEIN__c
                                       From NSSSalesAcctLink__c
                                      Where NSSSalesClient__c in :p_nssClientIdSet];
      System.debug('checkOppLinks links='+links.size());
      // assumption is that only one client id will be pulled out for each account id.
      // key is account id, value is client id
      Map<Id,Id> acctIdClientIdMap = new Map<Id,Id>();
      for (NSSSalesAcctLink__c link : links) {
         acctIdClientIdMap.put(link.Account__c, link.NSSSalesClient__c);
      } // for (NSSSalesAcctLink__c
      
      Map<Id,ClientWrapper> clientMap = new Map<Id,ClientWrapper>();
      
      // retrieve the products from the trigger
      NSSSalesProduct__c[] prods = [Select Id, Name
                                          ,FirstRunDate__c
                                          ,NSSSalesClient__c
                                          ,ProductCode__c
                                          ,(Select Id
                                                  ,FirstRunWithinCommPeriod__c
                                                  ,NSSSalesClient__c, NSSSalesProduct__c 
                                                  ,Opportunity__c, Opportunity__r.Referring_Employee__r.HR_Person_Id__c
                                                  ,Opportunity__r.CreatedById, Opportunity__r.CreatedDate
                                                  ,Prospect_Ownership__c
                                                  ,NSR_Name__c, NSR_Name__r.HR_Person_Id__c
                                                  ,SortOrder__c 
                                              from NSSSalesOppLinks__r)
                                      From NSSSalesProduct__c
                                     Where Id in :p_nssProductIdSet];
      System.debug('checkOppLinks prods='+prods.size());
      Set<String> allRecordTypeNames = new Set<String>();
      
      for (NSSSalesProduct__c prod : prods) {
         // only proceed if there are record type names for the product
         Set<String> recordTypeNames = getRecordTypeNames(prod.Name);
         if (recordTypeNames != null && !recordTypeNames.isEmpty()) {
            allRecordTypeNames.addAll(recordTypeNames);
            ClientWrapper cw = clientMap.get(prod.NSSSalesClient__c);
            if (cw == null) {
               cw = new ClientWrapper();
               clientMap.put(prod.NSSSalesClient__c,cw);
            }
            cw.addProduct(prod);
         } // if (recordTypeName
      } // for (NSSSalesProduct__c prod
                 
      // select only open or won opportunities
      OpportunityTeamMember[] otms = [Select Id
                                            ,CommissionEnd__c
                                            ,CommissionStart__c
                                            ,NSS_Source__c
                                            ,NSS_Team__c
                                            ,OpportunityId
                                            ,Opportunity.Id
                                            ,Opportunity.AccountId
                                            ,Opportunity.CloseDate
                                            ,Opportunity.CreatedById
                                            ,Opportunity.CreatedDate
                                            ,Opportunity.IsClosed
                                            ,Opportunity.IsWon
                                            ,Opportunity.LastModifiedDate
                                            ,Opportunity.Name
                                            ,Opportunity.StageName
                                            ,Opportunity.RecordTypeId
                                            ,Opportunity.RecordType.Name
                                            ,Opportunity.Referring_Employee__r.HR_Person_Id__c
                                            ,Prospect_Ownership__c
                                            ,Prospect_Ownership__r.NSS_Source__c
                                            ,UserId
                                            ,User.HR_Person_Id__c
                                        From OpportunityTeamMember
                                       Where Opportunity.AccountId in :acctIdClientIdMap.keySet()
                                         and TeamMemberRole=:OpptyMethods.ROLE_NSR
                                         and CommissionStart__c != null
                                         and Opportunity.RecordType.Name in :allRecordTypeNames
                                         //and (Opportunity.IsClosed = false or (Opportunity.IsClosed = true and Opportunity.IsWon = true))
                                     ];
      System.debug('checkOppLinks otms='+otms.size());
      NSSSalesOppLink__c[] insertLinks = new NSSSalesOppLink__c[]{};
      NSSSalesOppLink__c[] updateLinks = new NSSSalesOppLink__c[]{};

      for (OpportunityTeamMember otm : otms) {
         if (ALLOW_NOT_SOLD || (!otm.Opportunity.IsClosed ) || (otm.Opportunity.IsClosed && otm.Opportunity.IsWon)) {
            Id clientId = acctIdClientIdMap.get(otm.Opportunity.AccountId);
            if (clientId != null) {
               ClientWrapper cw = clientMap.get(clientId);
               if (cw != null) {
                  cw.checkOpp(otm);
                  //insertLinks.addAll(cw.checkOpp(otm));
               }
            } // if (clientId != null
         } // if (ALLOW_NOT_SOLD
      } // for (OpportunityTeamMember otm
      
      
      
      for (ClientWrapper clientWrap : clientMap.values()) {
         clientWrap.sortLinks();
         insertLinks.addAll(clientWrap.insertLinks);
         updateLinks.addAll(clientWrap.updateLinks);
      }
      
      DmlHelper.performDML2(insertLinks, DmlHelper.DML_INSERT, 'NSSSalesMethods', 'checkOppLinks', 'insert new Opp Links', false);
      DmlHelper.performDML2(updateLinks, DmlHelper.DML_UPDATE, 'NSSSalesMethods', 'checkOppLinks', 'update Opp Links', false);
      /*
      if (!newOppLinks.isEmpty()) {
         try {
            insert newOppLinks;
         } catch (Exception e) {
            ErrorLog.logError('NSSSalesMethods', 'checkOppLinks', 'insert new Opp Links', newOppLinks[0].NSSSalesProduct__c, e);
         }
      }
      */
      ErrorLog.checkSave();
   } // checkOppLinks
   
   // how many months (before or after) the product first run date has to be close to the actual commission start and end dates
   public static Integer COMMISSION_MONTHS_OFFSET=Integer.valueOf(Label.NSSSalesCommMonthOffset);
   // the minimum number of months to check if we're creating a link record - this may cause it to be greater than the actual commission month.
   public static Integer MIN_MONTHS=Integer.valueOf(Label.NSSSalesMinCommMonths);
   
   public class ClientWrapper {
      public void addProduct(NSSSalesProduct__c prod) {
         prods.add(prod);
      }
      public NSSSalesProduct__c[] prods = new NSSSalesProduct__c[]{};
      
      public Map<Id,NSSSalesOppLink__c[]> newLinksByProdMap = new Map<Id,NSSSalesOppLink__c[]>();
      
      // if a link to the prospect ownership does not currently exist then create one
      public NSSSalesOppLink__c[] checkOpp(OpportunityTeamMember otm) {
         NSSSalesOppLink__c[] newOppLinks = new NSSSalesOppLink__c[]{};
         if (otm != null) {
            for (NSSSalesProduct__c prod : prods) {
               Set<String> recordTypeNameSet = recordTypeByProductNameMap.get(prod.Name);
               System.debug('checkOpp name='+prod.Name+' recordTypeNameSet='+recordTypeNameSet.size());
               // get the nss source set
               Set<String> nssSourceSet = nssSourceByProductNameMap.get(prod.Name);
               // only proceed if the record type, nss source, and product match - connect only the right type of opportunities
               
               if (recordTypeNameSet != null && recordTypeNameSet.contains(otm.Opportunity.RecordType.Name)
                          && nssSourceSet != null && otm.Prospect_Ownership__r != null && nssSourceSet.contains(otm.Prospect_Ownership__r.NSS_Source__c)) {
                  NSSSalesOppLink__c[] newLinksByProd = newLinksByProdMap.get(prod.Id);
                  if (newLinksByProd == null) {
                     newLinksByProd = new NSSSalesOppLink__c[]{};
                     newLinksByProdMap.put(prod.Id,newLinksByProd);
                  }
                  checkForOppLink(otm, prod, newLinksByProd);
               }
            } // for (NSSSalesProduct__c prod
         } // if (po
         return newOppLinks;
         
      } // checkPO
      
      // check for existing links to the opportunity
      private void checkForOppLink(OpportunityTeamMember otm, NSSSalesProduct__c prod, NSSSalesOppLink__c[] newOppLinks) {
         // see if product is close enough to the date range of the PO.
         Date comStart = otm.CommissionStart__c.addMonths(-COMMISSION_MONTHS_OFFSET);
         Date comEnd = comStart.addMonths(MIN_MONTHS);
         if (otm.CommissionEnd__c > comEnd) {
            comEnd = otm.CommissionEnd__c;
         }
         comEnd = comEnd.addMonths(COMMISSION_MONTHS_OFFSET);
         System.debug('checkForOppLink comStart='+comStart+' comEnd='+comEnd+' firstRun='+prod.FirstRunDate__c+' otm='+otm);
         if (prod.FirstRunDate__c < comStart || prod.FirstRunDate__c > comEnd) {
            // do nothing here
            System.debug('checkForOppLink date not in range - exiting');
            return;
         }
         Boolean dateInRange = (prod.FirstRunDate__c >=  otm.CommissionStart__c && prod.FirstRunDate__c <= otm.CommissionEnd__c);
         System.debug('checkForOppLink Date in range - continuing');
         Boolean linkFound = false;
         if (prod.NSSSalesOppLinks__r != null) {
            for (NSSSalesOppLink__c checkLink : prod.NSSSalesOppLinks__r) {
               // should only be one link per user per opportunity
               if (checkLink.Opportunity__c == otm.OpportunityId && checkLink.NSR_Name__c == otm.UserId) {
                  linkFound = true;
                  checkLink.FirstRunWithinCommPeriod__c=dateInRange;
                  System.debug('checkForOppLink linkFound checkLink='+checkLink);
                  break;
               } // if (checkLink.Prospect_Ownership__c
            } // for (NSSSalesPOLink__c checkLink
         } // if (prod.NSSSalesPOLinks__r != null
         
         if (!linkFound) {
            NSSSalesOppLink__c newLink = new NSSSalesOppLink__c(NSSSalesClient__c=prod.NSSSalesClient__c, NSSSalesProduct__c=prod.Id
                                                               ,Prospect_Ownership__c=otm.Prospect_Ownership__c
                                                               ,Opportunity__c=otm.OpportunityId, Opportunity__r=otm.Opportunity
                                                               ,NSR_Name__c=otm.UserId, NSR_Name__r=otm.User
                                                               ,FirstRunWithinCommPeriod__c=dateInRange);
            System.debug('checkForOppLink link not found - creaking new link newLink='+newLink);
            newOppLinks.add(newLink);
         } // if (!linkFound
      } // checkForOppLink
      
      public NSSSalesOppLink__c[] insertLinks = new NSSSalesOppLink__c[]{};
      public NSSSalesOppLink__c[] updateLinks = new NSSSalesOppLink__c[]{};

      // sort the links, marking the sort order for each
      // set the most relevant as sort order 1, the rest as 2. By product, by NSR
      public void sortLinks() {
         insertLinks.clear();
         updateLinks.clear();
         
         for (NSSSalesProduct__c prod : prods) {
            NSSSalesOppLink__c[] prodLinks = new NSSSalesOppLink__c[]{};
            prodLinks.addAll(prod.NSSSalesOppLinks__r);
            if (newLinksByProdMap.containsKey(prod.Id)) {
               prodLinks.addAll(newLinksByProdMap.get(prod.Id));
            }
            if (prodLinks.size() == 1) {
               checkAddToUpsertList(prodLinks[0],1);
            } else if (prodLinks.size() > 1) {
               // divide by NSR
               checkLinksByNSR(prodLinks);
            }
         } // for (NSSSalesProduct__c
      } // sortLinks
      
      // break up the links by the NSR
      public void checkLinksByNSR(NSSSalesOppLink__c[] prodLinks) {
         Map<Id,NSSSalesOppLink__c[]> linksByNsrMap = new Map<Id,NSSSalesOppLink__c[]>();
         // group all prod links by the NSR - we'll prioritize each group within that.
         for (NSSSalesOppLink__c prodLink : prodLinks) {
            NSSSalesOppLink__c[] linksByNsr = linksByNsrMap.get(prodLink.NSR_Name__c);
            if (linksByNsr == null) {
               linksByNsr = new NSSSalesOppLink__c[]{};
               linksByNsrMap.put(prodLink.NSR_Name__c,linksByNsr);
            }
            linksByNsr.add(prodLink);
         } // for
         
         for (NSSSalesOppLink__c[] linksByNsr : linksByNsrMap.values()) {
            if (linksByNsr.size() == 1) {
               checkAddToUpsertList(linksByNsr[0],1);
            } else if (linksByNsr.size() > 1) {
               prioritizeNsrOpps(linksByNsr);
            }
         } // for (NSSSalesOppLink__c[] linksByNsr
      } // checkLinksByNSR
      
      // for all of the links for an NSR, prioritize them by 
      //   1) opps NSR created by descending date
      //   2) opps where NSR is referring employee
      //   3) NSR is on Opp team
      public void prioritizeNsrOpps(NSSSalesOppLink__c[] linksByNsr) {
         // save in maps, use the date as the key   .format('yyyyMMddHHmmss')
         // if two records have the exact same date one of them will be left out. This should not ever happen, but just so it's known...
         Map<String,NSSSalesOppLink__c> nsrCreateOppMap = new Map<String,NSSSalesOppLink__c>();
         Map<String,NSSSalesOppLink__c> referringEmpMap = new Map<String,NSSSalesOppLink__c>();
         Map<String,NSSSalesOppLink__c> allOthersMap = new Map<String,NSSSalesOppLink__c>();
         for (NSSSalesOppLink__c prodLink : linksByNsr) {
            if (prodLink.FirstRunWithinCommPeriod__c && prodLink.NSR_Name__c != null && prodLink.Opportunity__r != null) {
               if (prodLink.Opportunity__r.CreatedById == prodLink.NSR_Name__c) {
                  addToMap(prodLink, prodLink.Opportunity__r.CreatedDate, nsrCreateOppMap);
               } else if (prodLink.Opportunity__r.Referring_Employee__r != null
                          && prodLink.NSR_Name__r != null
                          && prodLink.Opportunity__r.Referring_Employee__r.HR_Person_Id__c == prodLink.NSR_Name__r.HR_Person_Id__c) {
                  addToMap(prodLink, prodLink.Opportunity__r.CreatedDate, referringEmpMap);
               } else {
                  addToMap(prodLink, prodLink.Opportunity__r.CreatedDate, allOthersMap);
               }
            }
         } // for (NSSSalesOppLink__c prodLink
         Integer priorityNbr = prioritizeMap(1,nsrCreateOppMap);
         priorityNbr = prioritizeMap(priorityNbr,referringEmpMap);
         priorityNbr = prioritizeMap(priorityNbr,allOthersMap);
      } // prioritizeNsrOpps
      
      public Integer prioritizeMap(Integer startingSortValue, Map<String,NSSSalesOppLink__c> prodMap) {
         Integer returnNumber = startingSortValue;
         if (!prodMap.isEmpty()) {
            String[] keyList = new String[]{};
            keyList.addAll(prodMap.keySet());
            keyList.sort();
            //for (Integer cnt=keyList.size()-1;  cnt>=0; cnt--) {
            //   String key = keyList[cnt];
            for (String key : keyList) {
               NSSSalesOppLink__c prodLink = prodMap.get(key);
               checkAddToUpsertList(prodLink, returnNumber);
               returnNumber++;
            }
         } // if (!prodMap.isEmpty()
         return returnNumber;
      } // prioritizeMap
      
      public void addToMap(NSSSalesOppLink__c prodLink, DateTime dtValue, Map<String,NSSSalesOppLink__c> prodMap) {
         if (dtValue != null) {
            String key = dtValue.format('yyyyMMddHHmmss');
            prodMap.put(key,prodLink);
         }
      } // addToMap
      
      public void checkAddToUpsertList(NSSSalesOppLink__c prodLink, Integer sortNbr) {
         if (!prodLink.FirstRunWithinCommPeriod__c) {
            prodLink.SortOrder__c = -1;
         } else if (prodLink.SortOrder__c != sortNbr || prodLink.Id == null) {
            prodLink.SortOrder__c = sortNbr;
            if (prodLink.Id == null) {
               insertLinks.add(prodLink);
            } else {
               updateLinks.add(prodLink);
            }
         } // if (prodLink.SortOrder__c
      } // checkAddToUpsertList
      
   } // class ClientWrapper
   
   public static Boolean SKIP_SALES_OPP_LINK_TRIGGER=false;
   public static final Integer OTHER_LINK_INFO_LENGTH = NSSSalesOppLink__c.OtherLinkInfo__c.getDescribe().getLength();

   
   // compile information onto the links so that each link has information about the other links that are attached to the same product.
   public static void compileLinkInformation(Set<Id> productIdSet) {
      NSSSalesProduct__c[] products = [Select Id
                                             ,(Select Id
                                                     ,FirstRunWithinCommPeriod__c
                                                     ,LinkInfo__c
                                                     ,NSSSalesClient__c
                                                     ,NSSSalesProduct__c
                                                     ,Opportunity__c
                                                     ,OtherLinkInfo__c
                                                     ,Prospect_Ownership__c 
                                                     ,Rejected__c
                                                     ,SortOrder__c
                                                 from NSSSalesOppLinks__r
                                                Where SortOrder__c != -1)
                                         From NSSSalesProduct__c
                                        Where Id in :productIdSet];

      NSSSalesOppLink__c[] linksToUpdate = new NSSSalesOppLink__c[]{};
                             
      for (NSSSalesProduct__c product : products) {
         if (product.NSSSalesOppLinks__r != null && !product.NSSSalesOppLinks__r.isEmpty()) {
            for (NSSSalesOppLink__c link : product.NSSSalesOppLinks__r) {
               String originalLinkInfo = (String.isBlank(link.OtherLinkInfo__c) ? '' : link.OtherLinkInfo__c);
               link.OtherLinkInfo__c = '';
               String otherLinkInfo = '';
               
               for (NSSSalesOppLink__c otherLink : product.NSSSalesOppLinks__r) {
                  if (otherLink.Id != link.Id && !link.Rejected__c) {
                     if (String.isNotBlank(otherLinkInfo)) {
                        otherLinkInfo += ' \n';
                     }
                     otherLinkInfo += otherLink.LinkInfo__c;
                  }
               } // for (NSSSalesOppLink__c otherLink
               
               // make sure the field isn't too big
               link.OtherLinkInfo__c = otherLinkInfo.left(OTHER_LINK_INFO_LENGTH);
               String newLinkInfo = (String.isBlank(link.OtherLinkInfo__c) ? '' : link.OtherLinkInfo__c);
               if (originalLinkInfo != newLinkInfo) {
                  linksToUpdate.add(link);
               }
               
            } // for (NSSSalesOppLink__c link
         } // if (product.NSSSalesOppLinks__r != null
      } // for (NSSSalesProduct__c product
      
      if (!linksToUpdate.isEmpty()) {
         SKIP_SALES_OPP_LINK_TRIGGER = true;
         DmlHelper.performDML2(linksToUpdate, DmlHelper.DML_UPDATE, 'NSSSalesMethods', 'compileLinkInformation', 'update links', true);
         /*
         try {
            update linksToUpdate;
         } catch (Exception e) {
            ErrorLog.logError('NSSSalesMethods', 'compileLinkInformation', 'update links', linksToUpdate[0].Id, e);
         }
         */
      } // if (!linksToUpdate.isEmpty()
   } // compileLinkInformation

   // check for duplicates - both within the same batch and in records already existing.
   public static void checkForDuplicates(Map<String,List<NSSSalesClient__c>> checkForDupMap) {
      NSSSalesClient__c[] clients = [Select Id, Name
                                       From NSSSalesClient__c
                                      Where Name in :checkForDupMap.keySet()
                                        and IsDuplicate__c = false];
      for (NSSSalesClient__c clt : clients) {
         // remove from the map so only processed once. We will check remaining entries in the map later.
         List<NSSSalesClient__c> clientList = checkForDupMap.remove(clt.Name);
         if (clientList != null && !clientList.isEmpty()) {
            for (NSSSalesClient__c dupClt : clientList) {
               if (dupClt.Id == null || (dupClt.Id != clt.Id)) {
                  dupClt.ParentClientRecord__c = clt.Id;
               }
            }
         } // if (clientList != null
      } // for (NSSSalesClient__c clt
      
      // check for anything remaining in the map. If there is more than one record in the list (which means they both
      // have the same branch-client), mark any extra as duplicates. First will be okay, second would be a duplicate.
      for (List<NSSSalesClient__c> clientList : checkForDupMap.values()) {
         if (clientList.size() > 1) {
            // the first one will be the primary, extras will be dupes. 
            // if there is no id on the first one, reset the flag on the secondary ones so they won't be picked up.
            NSSSalesClient__c primaryClient = null;
            for (NSSSalesClient__c checkClient : clientList) {
               if (primaryClient == null) {
                  primaryClient = checkClient;
               } else {
                  if (primaryClient.Id == null) {
                     checkClient.CheckedForDupe__c = false;
                  } else {
                     checkClient.ParentClientRecord__c = primaryClient.Id;
                  }
               } // if (primaryClient == null
            } // for (NSSSalesClient__c checkClient : clientList
         } // if (clientList.size() > 1
      } // for (List<NSSSalesClient__c> clientList
   } // checkForDuplicates
   
} // class NSSSalesMethods