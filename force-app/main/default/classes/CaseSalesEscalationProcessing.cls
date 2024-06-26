/* 
 * A class used to route Sales Escalation Cases to the proper owner
 *
 * History
 * -------
 * 05/30/2017 	Jermaine Stukes		Created
 * 06/07/2017	Jermaine Stukes	  	Added ChatterPost logic
 * 07/11/2017	Jermaine Stukes	  	Added Alternative Contact to chatterpost
 * 08/01/2017	Jermaine Stukes	  	Added Criteria for ChatterPost
 * 11/01/2017	Jermaine Stukes	  	Updated RouteToQueue to include control field and SLA
 * 11/14/2017	Jermaine Stukes	  	Updated to set account for MPSC logic
 * 12/12/2017	Jermaine Stukes	  	Remove SLA logic
 * 12/19/2017	Jermaine Stukes		Add additional control field logic
 * 01/11/2018	Jermaine Stukes		Changed Routing to make process more generic
 * 01/29/2018	Jermaine Stukes		Updated routing process
 * 03/20/2018	Jermaine Stukes		Added Call to Round Robin class
 * 05/08/2018	Jermaine & Dan		Updated routing process
 * 06/11/2018	Jermaine Stukes		Updated Check Condition Method
 * 06/28/2018	Jermaine Stukes		Fix Round Robin logic
 * 07/19/2018	Jermaine Stukes		Added UC Routing logic
 * 08/29/2018	Jermaine Stukes		Added Update case logic for UC
 * 10/17/2018	Jermaine Stukes		Added Comments
 * 04/30/2019	Jermaine Stukes		Updated UpdateCase logic to create Web Service Log
 * 11/25/2019	Matt Fritschi		Commented out routing rules that reference the Migration_Status__c field
 * 12/04/2019	Jermaine Stukes		Updated UpdateCase Method
 * 07/14/2020	Jake Hinds			Change to support resubmit checkbox and small refactor to avoid null error in tests
 */
public with sharing class CaseSalesEscalationProcessing 
{	
    //Custom Setting List
    private static list<S2S_Assignment__c> caseAssignmentList = S2S_Assignment__c.getAll().Values();
    private static list<S2S_Assignment_Maps__c> assignMap = S2S_Assignment_Maps__c.getAll().Values();
    private static list<S2S_Mapping_Defaults__c> defaultQueueList = S2S_Mapping_Defaults__c.getAll().Values();
    
    public class CaseAssignWrapper    
    {
        public Case cs;
        public Id accountId;
        public Id contactId;
        public String cs_Product;
        public String product_assignment=null;
    } // class CaseAssignWrapper
    
    public static void RouteToQueue(list<case> caseList)
    {
        //Properties
        Map<String,CaseAssignWrapper[]> wrapperMapByProduct = new Map<String,CaseAssignWrapper[]>();
        Map<Id,CaseAssignWrapper[]> wrapperMapByCtctId = new Map<Id,CaseAssignWrapper[]>();
        Map<Id,CaseAssignWrapper[]> wrapperMapByAcctId = new Map<Id,CaseAssignWrapper[]>();
        //Set of wrappers containing each product/Account combination
        Set<CaseAssignWrapper> CaseWrapperSet = new Set<CaseAssignWrapper>();
        
        //Update Wrapper and Account Lists
        updateContactWrapper(CaseList, wrapperMapByCtctId, wrapperMapByProduct, CaseWrapperSet);       
        System.debug('CaseWrapperSet SIZE'+CaseWrapperSet.size());
        
        //Update Account Wrapper Map with contact wrapper information
        updateAcctWrapper(wrapperMapByCtctId, wrapperMapByAcctId);
        
        //Used to hold List of Account fields that will be queried
        Set<String> acctFldSet = new Set<String>();
        //Map AccountId to relevant Assignment custom setting
        for(S2S_Assignment__c Product_Mapping : CaseAssignmentList)
        {   
            if (wrapperMapByProduct.containsKey(Product_Mapping.Product__c)) 
            {
                System.debug('*****ENTER ASSIGNMENT LOOP*****');
                // gather the flds
                S2S_Assignment_Maps__c s2sam = S2S_Assignment_Maps__c.getInstance(Product_Mapping.Name);
                if (s2sam != null) 
                {
                    //Add S2S_Assignment_Maps__c Fields
                    parseAssignmentMapping(s2sam, acctFldSet);
                    //Add S2S_Assignment__c Fields
                    parseConditionMapping(Product_Mapping, acctFldSet);
                    System.debug('FINISHED PARSING');
                }
            }
        }
        
        //Map Assignments
        //acctFldSet.add('Migration_Status__c');
        
        mapAssignments(wrapperMapByProduct, acctFldSet, wrapperMapByAcctId);
    }
    //Route updated case, if UC Owner, call queueable class
    public static void updateCase(list<case> caseList,Boolean checkOwner)
    {
        if(checkOwner){
            RouteToQueue(caseList);
        }
        for(Case kase :caseList)
        {
            system.debug('CaseSalesEscalation updateCase:'+kase.OwnerId);
            if(String.valueOf(kase.OwnerId) == label.UC_Queue)
            {
                WebServicesHelper whHelper = new WebServicesHelper();
                whHelper.createWsLog(kase.Id);
            }
        }
    }
    //Update Contact/Case Wrapper as well as Product/Case Wrapper
    public static void updateContactWrapper(List<Case> CaseList, Map<Id,CaseAssignWrapper[]> wrapperMapByCtctId,Map<String,CaseAssignWrapper[]> wrapperMapByProduct, Set<CaseAssignWrapper> CaseWrapperSet )
    {
        for (Case cs : CaseList) 
        {
            CaseAssignWrapper CaseWrap = new CaseAssignWrapper();
            CaseWrap.cs = cs;
            if (cs.ContactId != null) 
            {
                System.debug('CONTACT ID'+cs.ContactId);
                CaseAssignWrapper[] wrappers = wrapperMapByCtctId.containsKey(cs.ContactId) ? wrapperMapByCtctId.get(cs.ContactId) : new CaseAssignWrapper[]{};
                    wrappers.add(CaseWrap);
                wrapperMapByCtctId.put(cs.ContactId, wrappers);
                CaseWrap.contactId = cs.ContactId;
            }
            
            //
            CaseAssignWrapper[] prodWrappers = new CaseAssignWrapper[]{};// = wrapperMapByProduct.containsKey(cs.Product__c) ? wrapperMapByProduct.get(cs.Product__c) : new CaseAssignWrapper[]{};
                prodWrappers.add(CaseWrap);
            wrapperMapByProduct.put(cs.Product__c, prodWrappers);
            System.debug('*****Case PRODUCT*****'+cs.Product__c);
            CaseWrap.cs_Product = cs.Product__c;
            CaseWrapperSet.add(CaseWrap);
            
        }
    }
    //Update Contact/Account Wrapper
    public static void updateAcctWrapper(Map<Id,CaseAssignWrapper[]> wrapperMapByCtctId, Map<Id,CaseAssignWrapper[]> wrapperMapByAcctId)
    {
        if (!wrapperMapByCtctId.isEmpty()) {
            //Find Account information for all contacts in map
            Contact[] ctcts =  [Select Id, AccountId from Contact where Id in :wrapperMapByCtctId.keySet()];
            for (Contact ctct : ctcts) {
                CaseAssignWrapper[] ctctWrappers = wrapperMapByCtctId.get(ctct.Id);
                for (CaseAssignWrapper oneWrapper : ctctWrappers) {
                    oneWrapper.AccountId = (ctct != null ? ctct.AccountId : null);
                    System.debug('*****CONTACT Account*****'+ctct.AccountId);
                    System.debug('*****WRAPPER Account*****'+oneWrapper.AccountId);
                    CaseAssignWrapper[] acctWrappers = wrapperMapByAcctId.containsKey(ctct.AccountId) ? wrapperMapByCtctId.get(ctct.AccountId) : new CaseAssignWrapper[]{};
                        acctWrappers.add(oneWrapper);
                    wrapperMapByAcctId.put(ctct.AccountId, acctWrappers);
                }
            }
        }
    }
    //Create list of account fields to be queried
    public static void addFldAndRelated(String fldName, String relatedLinking, Set<String> acctFldSet) {
        if (String.isNotBlank(fldName)) {
            acctFldSet.add(fldName);
            // we're assuming these are always custom fields
            if (String.isBlank(relatedLinking)) {
                // we're going to assume this is a contact
                String relatedName = fldName.replace('__c','__r');
                acctFldSet.add(relatedName+'.User_Lookup__r.Id');
                acctFldSet.add(relatedName+'.User_Lookup__r.ManagerId');
            } else if (relatedLinking == 'Id') {
                // we're assuming this is a lookup to a user
                String relatedName = fldName.replace('__c','__r');
                acctFldSet.add(relatedName+'.Id');
                acctFldSet.add(relatedName+'.ManagerId');
            }
        }
    } // addFldAndRelated
    //Parse conditions in S2S_Assignment__c custom setting for account fields that need to be queried
    public static void parseConditionMapping(S2S_Assignment__c Product_Mapping, Set<String> acctFldSet) {
        if(Product_Mapping.Condition1_Field__c != Null && Product_Mapping.Condition1_AcctField__c)
        {acctFldSet.add(Product_Mapping.Condition1_Field__c);}
        else if (Product_Mapping.Condition1__c != Null && Product_Mapping.Condition1_AcctField__c)
        {acctFldSet.add(Product_Mapping.Condition1__c);}
        if(Product_Mapping.Condition2_Field__c != Null && Product_Mapping.Condition2_AcctField__c)
        {acctFldSet.add(Product_Mapping.Condition2_Field__c);}
        else if (Product_Mapping.Condition2__c != Null && Product_Mapping.Condition2_AcctField__c)
        {acctFldSet.add(Product_Mapping.Condition2__c);}
        if(Product_Mapping.Condition3_Field__c != Null && Product_Mapping.Condition3_AcctField__c)
        {acctFldSet.add(Product_Mapping.Condition3_Field__c);}
        else if (Product_Mapping.Condition3__c != Null && Product_Mapping.Condition3_AcctField__c)
        {acctFldSet.add(Product_Mapping.Condition3__c);}
        
    } // parseConditionMapping
    //Parse assignment in S2S_Assignment_Maps__c custom setting for account fields to be added to query
    public static void parseAssignmentMapping(S2S_Assignment_Maps__c s2sam, Set<String> acctFldSet) {
        addFldAndRelated(s2sam.AssignmentId1__c, s2sam.FieldAssignment1UserMap__c, acctFldSet);
        addFldAndRelated(s2sam.AssignmentId2__c, s2sam.FieldAssignment2UserMap__c, acctFldSet);
        addFldAndRelated(s2sam.AssignmentId3__c, s2sam.FieldAssignment3UserMap__c, acctFldSet);
        
    } // parseAssignmentMapping
    //Build Account query using generated set
    public static String buildQuery(Set<String> acctFldSet) {
       String query = 'Select Id, Name, MMS_AS__r.Email, Revenue_Location__c ';
        for (String fldName : acctFldSet) {
            query += ','+fldName;
        }
        query += ' from Account';
        System.debug('QUERY**'+query);
        return query;
    } // buildQuery
    
    public static Map<Id,Account> getAcctMap(Set<String> acctFldSet, Set<Id> acctIdSet) {
        String query = buildQuery(acctFldSet);
        Id[] acctIds = new Id[]{};
        acctIds.addAll(acctIdSet);
        query += ' where Id in :acctIds';
        Account[] accts = Database.query(query);
        System.debug('ACCOUNT [] SIZE'+accts.size());
        Map<Id,Account> acctMap = new Map<Id,Account>();
        for (Account acct : accts) {
            System.debug('ACCOUNT Name: '+acct.Name);
            System.debug('ACCOUNT PRS: '+acct.MMS_AS__r.Email);
            acctMap.put(acct.Id, acct);
        }
        return acctMap;
    } // getAcctMap
    
    //For each Case product, map possible custom setting assignment records to user or queue
    public static void mapAssignments(Map<String,CaseAssignWrapper[]> wrapperMapByProduct,  Set<String> acctFldSet,Map<Id,CaseAssignWrapper[]> wrapperMapByAcctId)
     {
        System.debug('MAP ASSIGNMENTS');
        List<Contact> contactAssignList = new List<Contact>();
        List<User> userAssignList = new List<User>();
        
        Map<Id,Account> acctMap = getAcctMap(acctFldSet, wrapperMapByAcctId.keySet());
        //Round robin Lists
        List<Case> rrCaseList = new List<Case>();
        List<Id> rrQueueIdList = new List<Id>();  
        List<String> roundrobinList = Label.sales_2_service_rr_List.Split(',');
        for (String mapName : wrapperMapByProduct.keySet()) 
        {
            System.debug('MAP NAME'+mapName);
            S2S_Assignment_Maps__c assignment = S2S_Assignment_Maps__c.getValues(mapName);
            CaseAssignWrapper[] wrappers = wrapperMapByProduct.get(mapName);
            for (CaseAssignWrapper wrapper : wrappers) 
            {
                Case kase = wrapper.cs;
                Account acct = acctMap.get(kase.AccountId);
                //Set<String> acctMigrationStatus = new Set<String>(Label.Migration_Status_Values.split(','));
                //if(acct != null && acct.Migration_Status__c != null && acctMigrationStatus.contains(acct.Migration_Status__c))
                //{CaseAssignment = Label.Flex_Forward_Queue;}
                //else
                //{
                    //Get Custom Setting Name if available, else null
                    String csAssignName = getAssignmentMap(kase, acct, mapName);
                    String CaseAssignment = csAssignName != Null ? assignCase(wrapper, acct, csAssignName) : Null;
                //}
                if(CaseAssignment != null){
                    kase.ownerId = CaseAssignment;
                }
                else{
                    String defaultQueue = assignDefault(kase);
                    if(defaultQueue!=null){
                        kase.OwnerId = defaultQueue;
                    }
                }
                //Call Round Robin here for an Cases assigned to a queue
                if(String.valueOf(kase.OwnerId).startsWithIgnoreCase('00G') && roundrobinList.contains(kase.Product__c))
                {
                    rrCaseList.add(kase);
                    rrQueueIdList.add(kase.OwnerId);
                }
            } 
        } 
        if(!rrCaseList.isEmpty() && !rrQueueIdList.isEmpty())
        {RoundRobin.prepareCaseRoundRobin(rrCaseList, rrQueueIdList);}
    } // mapAssignments
    
    public static string assignDefault(Case kase)
    {
        S2S_Mapping_Defaults__c defaultMapping = S2S_Mapping_Defaults__c.getInstance(kase.Product__c);
        if(defaultMapping!=null && string.isNotBlank(defaultMapping.QueueId__c)){
            return defaultMapping.QueueId__c;
        }
        else{
            return null;
        }
    }

    public static String assignCase(CaseAssignWrapper wrapper, Account acct, String csName) {
        S2S_Assignment_Maps__c assignment = S2S_Assignment_Maps__c.getValues(csName);
        String product_assignment = null;
        string fieldAssignment = (assignment.AssignmentId1__c != Null && acct.get(assignment.AssignmentId1__c)!=Null ? assignment.AssignmentId1__c :
                                  (assignment.AssignmentId2__c != Null && acct.get(assignment.AssignmentId2__c)!=Null ? assignment.AssignmentId2__c :
                                   (assignment.AssignmentId3__c != Null && acct.get(assignment.AssignmentId3__c)!=Null ? assignment.AssignmentId3__c : Null)));
        string acctAssign = (fieldAssignment != Null ? String.valueOf(acct.get(fieldAssignment)) : Null);
        
        //Check value of assignment field on the account
        if(acctAssign != Null)
        {	
            List<String> escalationExempt = Label.S2S_escalation_exclude_list.Split(',');
            //Verify if assignment is a contact or a user 
            Boolean assignContact = (acctAssign.startsWith('003') ? true : false);
            if(assignContact)
            {
                List<Contact> contactAssignList = [Select User_Lookup__r.Id, User_Lookup__r.ManagerId  from Contact where id =:acctAssign];
                if(!contactAssignList.isEmpty())
                {product_assignment = (assignment.Escalated__c && !escalationExempt.contains(fieldAssignment) ? contactAssignList[0].User_Lookup__r.ManagerId : contactAssignList[0].User_Lookup__r.Id);}
            }
            else
            {
                String userField = (fieldAssignment == assignment.AssignmentId1__c ? assignment.FieldAssignment1UserMap__c :
                                    fieldAssignment == assignment.AssignmentId2__c ? assignment.FieldAssignment2UserMap__c :
                                    fieldAssignment == assignment.AssignmentId3__c ? assignment.FieldAssignment3UserMap__c : Null);
                
                String userString = 'Select Id, ManagerId  from User where Alias=\''+ String.valueOf(acct.get(fieldAssignment))+'\' OR AD_Username__c=\''+ String.valueOf(acct.get(fieldAssignment))+'\' OR '+ UserField +' =\''+ String.valueOf(acct.get(fieldAssignment))+'\' limit 1';
                
                User[] userAssignList  = (userString != Null ? Database.query(userString) : Null );
                if(!userAssignList.isEmpty())
                {product_assignment = (assignment.Escalated__c && !escalationExempt.contains(fieldAssignment) ? userAssignList[0].ManagerId : userAssignList[0].Id);}
            }
        }
        if(string.isBlank(product_assignment) && assignment.DefaultQueueId__c != Null)
        {product_assignment = assignment.DefaultQueueId__c;}
        System.debug('S2S PRODUCT ASSIGN: '+assignment.Name+' ASSIGNMENT '+product_assignment);
        if (String.isNotBlank(product_assignment)) {
            wrapper.product_assignment = product_assignment;
        }
        return product_assignment;      
    } // checkAssignment
	//Verify each condition in custom setting
    public static Boolean checkCondition(String condition, String conditionField, Boolean notEqual) 
    {
        Boolean conditionMet;
        if(conditionField!=Null)
        {
            Set<String> conditionValues = new Set<string>(condition.split('_'));
            if(notEqual)
            {conditionMet = !conditionValues.contains(conditionField) ? true : false;}
            else
            {conditionMet = conditionValues.contains(conditionField) ? true : false;}
        }
        else
        {conditionMet = condition != Null ? Boolean.valueOf(condition) : true;}
                
        return conditionMet;
    } //S2SConditionsWrapper
    //Key is used to link case list with assignments based on custom setting conditions being met
    public static String getAssignmentMap(Case kase, Account acct, String caseProduct )
    {
        String productKey = null;
        for(S2S_Assignment__c Queue_Mapping : caseAssignmentList)
        {               
            if(Queue_Mapping.Product__c == caseProduct)
            {
                //Set Variables
                String conditionField = (Queue_Mapping.Condition1_Field__c == Null ? Null:
                                         Queue_Mapping.Condition1_AcctField__c ? String.valueOf(acct.get(Queue_Mapping.Condition1_Field__c)):
                                         String.valueOf(kase.get(Queue_Mapping.Condition1_Field__c)));
                String conditionField2 = (Queue_Mapping.Condition2_Field__c == Null ? Null:
                                          Queue_Mapping.Condition2_AcctField__c ? String.valueOf(acct.get(Queue_Mapping.Condition2_Field__c)):
                                          String.valueOf(kase.get(Queue_Mapping.Condition2_Field__c)));
                String conditionField3 = (Queue_Mapping.Condition3_Field__c == Null ? Null: 
                                          Queue_Mapping.Condition3_AcctField__c ? String.valueOf(acct.get(Queue_Mapping.Condition3_Field__c)):
                                          String.valueOf(kase.get(Queue_Mapping.Condition3_Field__c)));
                String conditionValue1 = (Queue_Mapping.Condition1__c == Null? Null: 
                                          Queue_Mapping.Condition1_Field__c != Null ? Queue_Mapping.Condition1__c:
                                          Queue_Mapping.Condition1_AcctField__c ? String.valueOf(Boolean.valueOf(acct.get(Queue_Mapping.Condition1__c))):
                                          String.valueOf(Boolean.valueOf(kase.get(Queue_Mapping.Condition1__c))));
                String conditionValue2 = (Queue_Mapping.Condition2__c == Null? Null: 
                                          Queue_Mapping.Condition2_Field__c != Null ? Queue_Mapping.Condition2__c:
                                          Queue_Mapping.Condition2_AcctField__c ? String.valueOf(Boolean.valueOf(acct.get(Queue_Mapping.Condition2__c))):
                                          String.valueOf(Boolean.valueOf(kase.get(Queue_Mapping.Condition2__c))));
                String conditionValue3 = (Queue_Mapping.Condition3__c == Null? Null: 
                                          Queue_Mapping.Condition3_Field__c != Null ? Queue_Mapping.Condition3__c:
                                          Queue_Mapping.Condition3_AcctField__c ? String.valueOf(Boolean.valueOf(acct.get(Queue_Mapping.Condition3__c))):
                                          String.valueOf(Boolean.valueOf(kase.get(Queue_Mapping.Condition3__c))));
                //Evaluate each condition    
                Boolean condition1 = checkCondition(conditionValue1,conditionField,Queue_Mapping.Condition1_Field_Not_Equal__c);
                Boolean condition2 = checkCondition(conditionValue2,conditionField2,Queue_Mapping.Condition2_Field_Not_Equal__c);
                Boolean condition3 = checkCondition(conditionValue3,conditionField3,Queue_Mapping.Condition3_Field_Not_Equal__c);
                System.Debug('***CONDITION1**********'+String.valueOf(condition1)+'***CONDITION2************'+String.valueOf(condition2)+'***CONDITION3**************'+String.valueOf(condition3));
                if(condition1 && condition2 && condition3)
                {
                    productKey = Queue_Mapping.Name; 
                    System.debug('PRODUCTKEY: '+productKey);
                }
            }
        }
        return productKey;
    }
}