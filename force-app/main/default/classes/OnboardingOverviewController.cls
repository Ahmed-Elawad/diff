/* Controller for the Onboarding Overview Component of the Client Overview Page. 
History
-------
08/24/2012 Justin Stouffer and Carrie Marciano   Created  
06/21/2013 Justin Stouffer                       Complete Redesign to Use Custom Setting
03/31/2017 Justin Stouffer/Jermaine Stukes       Updated to use Lightning Design System
07/30/2018 Cindy Freeman                         Added to Case loop logic to exclude Closed-Duplicate cases
08/05/2019 Jacob Hinds                           Allow for multiple accounts 
06/08/2020 Jake Hinds      added in without sharing per pmd
6/24/2020 Josh Cartwright added null check and debugging to methods 
*/
public without sharing class OnboardingOverviewController {
   
    
    public boolean showGraduated {get; set;}
    public string currentId {get; set;}
    public Id[] accountIds {get;set;}
    private refWrapper refData;
    public Map<Id,refWrapper[]> refCollection {get;set;} 
    public Map<Id,refWrapper[]> refGradCollection {get;set;}
    public refWrapper[] singleRefCollection {get;set;} 
    public refWrapper[] singleRefGradCollection {get;set;}
    
    // Is this displaying in Salesforce1?
    public Boolean isSF1 {get; set;}
    
    public OnboardingOverviewController(set<id> p_acctIds) {//For Using the OOC Outside of the Account Page.   
        System.debug('OnboardingOverviewController p_acctIds='+p_acctIds.size());
        accountIds = new Id[]{};
        for (Id acctId : p_acctIds) {
            if (acctId != null) {
               accountIds.add(acctId);
            }
        }
        //accountIds = new List<Id>(p_acctIds);
        initialize();
    }
    
    public OnboardingOverviewController(string acctId) {//For Using the OOC Outside of the Account Page.   
        if (acctid != null) {
           accountIds = new Id[]{Id.valueOf(acctId)};
        }
        initialize();
        if(refCollection!=null && refCollection.containsKey(acctId)){
            singleRefCollection = refCollection.get(acctId);
        }
        if(refGradCollection!=null && refGradCollection.containsKey(acctId)){
            singleRefGradCollection = refGradCollection.get(acctId);
        }
    }  
    
    public OnboardingOverviewController(ApexPages.StandardController controller) {//For the OOC when part of the Account Page.
        String acctId = ApexPages.currentPage().getParameters().get('Id');
        accountIds = new Id[]{Id.valueOf(acctId)};
        initialize();   
        if(refCollection!=null && refCollection.containsKey(acctId)){
            singleRefCollection = refCollection.get(acctId);
        }
        if(refGradCollection!=null && refGradCollection.containsKey(acctId)){
            singleRefGradCollection = refGradCollection.get(acctId);
        }
    }
    
    public OnboardingOverviewController() {//For the OOC when part of the Account Page.
        String acctId = ApexPages.currentPage().getParameters().get('Id');
        accountIds = new Id[]{Id.valueOf(acctId)};
        initialize(); 
        if(refCollection!=null && refCollection.containsKey(acctId)){
            singleRefCollection = refCollection.get(acctId);
        }
        if(refGradCollection!=null && refGradCollection.containsKey(acctId)){
            singleRefGradCollection = refGradCollection.get(acctId);
        }
    }
    
    public void initialize(){
        isSF1 = Utilities.isSF1();
        showGraduated = false;
        refCollection = new Map<Id,refWrapper[]>(); 
        refGradCollection = new Map<Id,refWrapper[]>();
        singleRefCollection = new List<refWrapper>();
        singleRefGradCollection = new List<refWrapper>();
        System.debug('initialize accountIds='+(accountIds != null ? accountIds.size() : -1));
        If (accountIds!=null && !accountIds.isEmpty())
        {
            //
            set<string> refObjRTs = new Set<string>();
            list<string> recTypes = new list<string>();
            set<string> refApiNames = new set<string>();
            set<string> refApiRunDates = new set<string>();
            set<string> refApiPoc= new set<string>();
            set<string> currentSteps= new set<string>();
            map<string,string>refObjectMap = new map<string,string>();
            map<string,set<string>> compStatusMap = new map<string,set<string>>();
            map<string, list<Client_Overview_Status_Info__c>>rtStatusMap = new map<string, list<Client_Overview_Status_Info__c>>();
            list<Client_Overview_Configuration__c> coc = Client_Overview_Configuration__c.getAll().Values();//Get Client Overview Configuration Data   
            list<Client_Overview_Status_Info__c> cos = Client_Overview_Status_Info__c.getAll().Values();//Get Client Overview Configuration Data  
            string caseSelect = 'SELECT AccountId,Status, CaseNumber, Id, LastModifiedDate, CreatedDate, Owner.Name, Owner.Phone, Owner.email, Contact.Name, Contact.Phone, Contact.email, ClosedDate, RecordType.Name';              
            //Build reference object query string
            for(Client_Overview_Configuration__c RefObjCo : coc)
            {
                if(!RefObjCo.Case_Only__c && RefObjCo.Reference_Object_Relationship_API_Name__c != NULL && RefObjCo.Case_Record_Type_Name__c != NULL)
                {
                    if(!refObjectMap.containsKey(RefObjCo.Reference_Object_Relationship_API_Name__c))
                    {
                        string refObjStaticFields = ' Current_Step__c, LastModifiedDate, Name, Id, Owner.Name, Owner.Phone, Owner.email';
                        refObjectMap.put(RefObjCo.Reference_Object_Relationship_API_Name__c, refObjStaticFields);
                    }
                    if(RefObjCo.Reference_Object_Exp_Run_Date_api__c!=Null)
                    {
                        if(!refApiRunDates.contains(RefObjCo.Reference_Object_Relationship_API_Name__c+'_'+RefObjCo.Reference_Object_Exp_Run_Date_api__c))
                        {
                            string refObjFields = RefObjCo.Reference_Object_Exp_Run_Date_api__c +', '+ refObjectMap.get(RefObjCo.Reference_Object_Relationship_API_Name__c);
                            refObjectMap.put(RefObjCo.Reference_Object_Relationship_API_Name__c, refObjFields);
                            refApiRunDates.add(RefObjCo.Reference_Object_Relationship_API_Name__c+'_'+RefObjCo.Reference_Object_Exp_Run_Date_api__c);
                        }
                    }
                    if(RefObjCo.OnboardingPOC_api__c!=Null && !RefObjCo.OnboardingPocFromCase__c)
                    {
                        if(!refApiPoc.contains(RefObjCo.Reference_Object_Relationship_API_Name__c+'_'+RefObjCo.OnboardingPOC_api__c))
                        {
                            string refObjPOCFields = RefObjCo.OnboardingPOC_api__c +'.Name, '+ RefObjCo.OnboardingPOC_api__c +'.Phone, '+RefObjCo.OnboardingPOC_api__c +'.email, '+refObjectMap.get(RefObjCo.Reference_Object_Relationship_API_Name__c);
                            refObjectMap.put(RefObjCo.Reference_Object_Relationship_API_Name__c, refObjPOCFields);
                            refApiPoc.add(RefObjCo.Reference_Object_Relationship_API_Name__c+'_'+RefObjCo.OnboardingPOC_api__c);
                        }
                    }
                    if(RefObjCo.Current_Step_API_Name__c!=Null)
                    {
                        if(!currentSteps.contains(RefObjCo.Reference_Object_Relationship_API_Name__c+'_'+RefObjCo.Current_Step_API_Name__c))
                        {
                            string currentStepFields = RefObjCo.Current_Step_API_Name__c +', '+ refObjectMap.get(RefObjCo.Reference_Object_Relationship_API_Name__c);
                            refObjectMap.put(RefObjCo.Reference_Object_Relationship_API_Name__c, currentStepFields);
                            currentSteps.add(RefObjCo.Reference_Object_Relationship_API_Name__c+'_'+RefObjCo.Current_Step_API_Name__c);
                        }
                    }
                }
            }
            for(Client_Overview_Configuration__c co : coc)
            {
                caseSelect += (co.Case_Exp_Run_Date_api__c!=NULL?','+co.Case_Exp_Run_Date_api__c :'');
                if(co.OnboardingPOC_api__c!=Null && co.OnboardingPocFromCase__c)
                {
                    caseSelect += ','+co.OnboardingPOC_api__c;
                }
                set<string> compStatusSet = new set<string>();
                
                if (compStatusMap.containskey(co.Case_Record_Type_Name__c))
                {
                    compStatusSet = compStatusMap.get(co.Case_Record_Type_Name__c);
                }
                List<String> completedStatuses = co.Completed_Onboarding_Status__c.split(',');             
                compStatusSet.addAll(completedStatuses);
                system.debug('compStatusSet'+compStatusSet);
                compStatusMap.put(co.Case_Record_Type_Name__c,compStatusSet);
                rectypes.add(co.Case_Record_Type_Name__c);
                if(!co.Case_Only__c && co.Reference_Object_Relationship_API_Name__c != NULL
                   && !refApiNames.contains(co.Reference_Object_Relationship_API_Name__c) && co.Case_Record_Type_Name__c != NULL)
                {
                    caseSelect += ',(SELECT '+refObjectMap.get(co.Reference_Object_Relationship_API_Name__c)+' FROM ' + co.Reference_Object_Relationship_API_Name__c + ' ORDER  BY CreatedDate DESC LIMIT 1) '; 
                    refApiNames.add(co.Reference_Object_Relationship_API_Name__c);
                }
            }
            // ------Status Sort and Map Building------
            system.debug('JS cos='+ cos);
            list<cosWrapper> cowList = new list<COSWrapper>();
            for(Client_Overview_Status_Info__c cs : cos){
                cowList.add(new cosWrapper(cs));        
            }
            cowList.sort();
            for(cosWrapper cow : cowList){
                if(rtStatusMap.keySet().contains(cow.cs.Key__c)){
                    rtStatusMap.get(cow.cs.Key__c).add(cow.cs);
                }
                else{
                    rtStatusMap.put(cow.cs.Key__c,new Client_Overview_Status_Info__c[]{cow.cs});
                }
            }
            system.debug('JGS rtStatusMap' + rtStatusMap);
            // --------------------------------------------
        //caseSelect += ' FROM Case WHERE (ClosedDate = Null or ClosedDate = LAST_N_DAYS:30) AND CreatedDate = LAST_N_DAYS:365 AND AccountID = \'' + currentId + '\' AND RecordType.Name IN :recTypes ORDER BY CreatedDate DESC';
        caseSelect += ' FROM Case WHERE (ClosedDate = Null or ClosedDate = LAST_N_DAYS:30) AND CreatedDate = LAST_N_DAYS:365 AND AccountID IN: accountIds AND RecordType.Name IN :recTypes ORDER BY CreatedDate DESC';
        system.debug('OnboardingOverviewController initialize caseSelect' + caseSelect);
        list<Case> cases = Database.query(caseSelect);//Build primary SOQL string and Select Cases and Reference Objects.
        system.debug('OnboardingOverviewController initialize cases' + cases);
        If(cases.Size() > 0){   //Iterate through Cases, Compare to Configuration Data, and Create Wrapper Data.
            For(Case c : Cases){
                // exclude Service Onboarding MPSC Core cases if Status = Closed-Duplicate
                if (c.RecordTypeId == '01270000000UP7CAAW' && c.Status.contains('Duplicate'))
                {   continue;   }       // skip this case
                //rtStatusMap.put(c.RecordType.Name, StatusSet);
                If(!refObjRTs.contains(c.RecordType.Name) && c.RecordType.Name != NULL)
                {
                    system.debug('OnboardingOverviewController initialize in refObjRTs');
                    for(Client_Overview_Configuration__c co : coc){
                        SObject pointOfContact; 
                        date case_runDate = (co.Case_Exp_Run_Date_api__c!=Null?date.valueOf(c.get(co.Case_Exp_Run_Date_api__c)) : Null);
                        
                        If(co.Case_Record_Type_Name__c == c.RecordType.Name && compStatusMap.get(c.RecordType.Name) != NULL)
                        {   
                            //No Reference Object associated with Case
                            if(co.Case_Only__c)
                            {
                                if(co.OnboardingPocFromCase__c && co.OnboardingPOC_api__c != Null)
                                {
                                    pointOfContact = (co.OnboardingPOC_api__c != Null ? c.getSObject(co.OnboardingPOC_api__c) :c.getSobject('OwnerId')); 
                                }
                                 
                                system.debug(compStatusMap);
                                //Status is complete
                                if(compStatusMap.get(c.RecordType.Name).contains(c.status))
                                {
                                    if(refGradCollection.containsKey(c.AccountId)){
                                        refWrapper[] existingList = refGradCollection.get(c.AccountId);
                                        existingList.add(new refWrapper(c,pointOfContact,co.Product_Name__c,co.Owner_Custom_Label__c,case_runDate, rtStatusMap.get(co.Name)));
                                        refGradCollection.put(c.AccountId,existingList);
                                    }
                                    else{
                                        refWrapper[] newList = new refWrapper[]{new refWrapper(c,pointOfContact,co.Product_Name__c,co.Owner_Custom_Label__c,case_runDate, rtStatusMap.get(co.Name))};
                                        refGradCollection.put(c.AccountId,newList);
                                    }
                                    
                                }
                                else if(c.CaseNumber != NULL && c.CaseNumber != '')
                                {
                                    if(refCollection.containsKey(c.AccountId)){
                                        refWrapper[] existingList = refCollection.get(c.AccountId);
                                        existingList.add(new refWrapper(c,pointOfContact,co.Product_Name__c,co.Owner_Custom_Label__c,case_runDate, rtStatusMap.get(co.Name)));
                                        refCollection.put(c.AccountId,existingList);
                                    }
                                    else{
                                        refWrapper[] newList = new refWrapper[]{new refWrapper(c,pointOfContact,co.Product_Name__c,co.Owner_Custom_Label__c, case_runDate, rtStatusMap.get(co.Name))};
                                        refCollection.put(c.AccountId,newList);
                                    }
                                    
                                }
                            }
                            else if(co.Reference_Object_Relationship_API_Name__c != NULL)
                            {
                                if(c.getSObjects(co.Reference_Object_Relationship_API_Name__c) != NULL){
                                    SObject[] refObjects = c.getSObjects(co.Reference_Object_Relationship_API_Name__c);
                                    system.debug('OnboardingOverviewController initialize refObjects'+refObjects);
                                    boolean useCasePOC = co.OnboardingPocFromCase__c;
                                    string currStep = (co.Current_Step_API_Name__c != NULL ? String.valueOf(refObjects[0].get(co.Current_Step_API_Name__c)) : String.valueOf(refObjects[0].get('Current_Step__c')));
                                    string recName = String.valueOf(refObjects[0].get('Name'));
                                    boolean useCaseRunDate = co.Case_Run_Date__c;
                                    date refObject_runDate = (co.Reference_Object_Exp_Run_Date_api__c != Null ? date.valueOf(refObjects[0].get(co.Reference_Object_Exp_Run_Date_api__c)) : Null);
                                    date runDate = (refObject_runDate!= Null ? refObject_runDate: case_runDate);
                                    if(String.valueOf(co.OnboardingPOC_api__c) != Null)
                                    {
                                        pointOfContact = (useCasePOC ? c.getSObject(co.OnboardingPOC_api__c) : refObjects[0].getSobject(co.OnboardingPOC_api__c));
                                    }
                                    else
                                    {
                                        pointOfContact = refObjects[0].getSobject('Owner');
                                    }
                                    system.debug('OnboardingOverviewController initialize compStatusMap.get(c.RecordType.Name)'+compStatusMap.get(c.RecordType.Name)+' currStep '+currStep);
                                    if(compStatusMap.get(c.RecordType.Name).contains(currStep))
                                    {   //Verify reference object api for date field entered
                                        if(refGradCollection.containsKey(c.AccountId)){
                                            refWrapper[] existingList = refGradCollection.get(c.AccountId);
                                            existingList.add(new refWrapper(c,refObjects[0],pointOfContact,co.Product_Name__c,co.Owner_Custom_Label__c,currStep,recName,runDate, rtStatusMap.get(co.Name)));
                                            refGradCollection.put(c.AccountId,existingList);
                                        }
                                        else{
                                            refWrapper[] newList = new refWrapper[]{new refWrapper(c,refObjects[0],pointOfContact,co.Product_Name__c,co.Owner_Custom_Label__c,currStep,recName,runDate, rtStatusMap.get(co.Name))};
                                            refGradCollection.put(c.AccountId,newList);
                                        }
                                    }
                                    else if(recName != NULL && recName != '' && currStep != NULL && currStep != '')
                                    {
                                        if(refCollection.containsKey(c.AccountId)){
                                            refWrapper[] existingList = refCollection.get(c.AccountId);
                                            existingList.add(new refWrapper(c,refObjects[0],pointOfContact,co.Product_Name__c,co.Owner_Custom_Label__c,currStep,recName,runDate, rtStatusMap.get(co.Name)));
                                            refCollection.put(c.AccountId,existingList);
                                        }
                                        else{
                                            refWrapper[] newList = new refWrapper[]{new refWrapper(c,refObjects[0],pointOfContact,co.Product_Name__c,co.Owner_Custom_Label__c,currStep,recName,runDate, rtStatusMap.get(co.Name))};
                                            refCollection.put(c.AccountId,newList);
                                        }
                                    }
                                }
                            }
                            compStatusMap.put(c.RecordType.Name,NULL);
                            refObjRTs.add(c.RecordType.Name);
                        } // If(co.Case_Record_Type_Name__c == c.RecordType.Name && compStatusMap.get(c.RecordType.Name) != NULL)
                    } // for(Client_Overview_Configuration__c co : coc)
                } // If(!refObjRTs.contains(c.RecordType.Name) && c.RecordType.Name != NULL)
            } // For (Cases c : Cases)
        } // If(cases.Size() > 0)                             
    } // If (currentId != NULL)   
} //Initialize()

public class refWrapper{
    public string product {get; set;}
    public string status {get; set;}
    public boolean showStatusText {get;set;}
    public string title {get; set;}
    public string refname {get; set;}
    public string OwnerName {get; set;}
    public string OwnerPhone {get; set;}
    public string OwnerEmail {get;set;}
    public string ContactName {get; set;}
    public string ContactPhone {get; set;}
    public string ContactEmail {get;set;}
    public date runDate{get;set;}
    public dateTime closedDate {get; set;} 
    public string formattedClosedDate {get; set;} 
    public string createdDate {get; set;}
    public string caseNumber {get;Set;} 
    public list<Client_Overview_Status_Info__c> statuses{get;set;}
    public double statusNumber {get;set;}
    public string displayStatus {get; set;}
    public id id {get; set;}
    public boolean showTimeline {get;set;}
    
    public pagereference openTimeline(){
        showTimeLine = !showTimeLine;
        return Null;
    }
    
    public refWrapper(Case c, SObject refOwner, string p, string t, date caseCompleteDate, list<Client_Overview_Status_Info__c> s){//For Case only Onboarding Scenarios
        closedDate = c.closedDate; 
        formattedClosedDate = (c.closedDate != NULL ? c.closedDate.format() : '');    
        createdDate = c.createdDate.format();
        product = p;
        title = t;
        status = c.Status;
        if(refOwner!=Null)
        {
            OwnerName = (refOwner.get('Name')!=null ? String.valueOf(refOwner.get('Name')) : null);
            OwnerPhone = (refOwner.get('Phone')!=null ? String.valueOf(refOwner.get('Phone')) : null);
            OwnerEmail = (refOwner.get('Email')!=null ? String.valueOf(refOwner.get('Email')) : null);
        }
        else
        {
            OwnerName = (c.Owner!=null ? c.Owner.Name : null);
            OwnerPhone = (c.Owner!=null ? c.Owner.Phone : null);
            OwnerEmail = (c.Owner!=null ? c.Owner.Email : null);
        }
        if(c.Contact!=null){
            ContactName = c.Contact.Name;
            ContactPhone = c.Contact.Phone;
            ContactEmail = c.Contact.Email; 
        }
        id = c.id;
        refname = c.CaseNumber;
        caseNumber = c.CaseNumber; 
        runDate = caseCompleteDate;
        setupStatuses(s);
    }
    
    public refWrapper(Case c, SObject refRec, SObject refOwner, string p, string t, string currStep, string recName, date roCompleteDate, list<Client_Overview_Status_Info__c> s){//For Case + Reference Object Onboarding Scenarios
        closedDate = c.closedDate;
        formattedClosedDate = (c.closedDate != NULL ? c.closedDate.format() : ''); 
        createdDate = c.createdDate.format();      
        product = p;
        title = t;
        status = currStep;
        if(refOwner!=null){
            OwnerName = (refOwner.get('Name')!=null ? String.valueOf(refOwner.get('Name')) : null);
            OwnerPhone = (refOwner.get('Phone')!=null ? String.valueOf(refOwner.get('Phone')) : null);
            OwnerEmail = (refOwner.get('Email')!=null ? String.valueOf(refOwner.get('Email')) : null);
        }
        if(c.Contact!=null){
            ContactName = c.Contact.Name;
            ContactPhone = c.Contact.Phone;
            ContactEmail = c.Contact.Email; 
        }
        id = String.valueOf(refRec.get('id'));
        refname = recName;  
        caseNumber = c.CaseNumber; 
        runDate = roCompleteDate;//(roRunDate != NULL ? roRunDate : Null);
        showTimeline = FALSE;
        statusNumber = 0;
        setupStatuses(s);
    }
    
    private void setupStatuses(list<Client_Overview_Status_Info__c> s){
        showStatusText = TRUE;
        showTimeline = FALSE;
        statusNumber = 0;
        displayStatus = status;
        statuses = new list<Client_Overview_Status_Info__c>();
        map<string,integer> displayMap = new map<string,integer>();
        if(s != NULL){
            for(Client_Overview_Status_Info__c cosi: s){
                if(cosi.DisplayText__c == NULL || cosi.DisplayText__c == ''){
                    cosi.DisplayText__c = cosi.Status__c;                    
                }
                if(cosi.Number__c == NULL){
                    cosi.Number__c = -1;    
                }
                if(cosi.status__c == status){
                    showStatusText = FALSE;
                    statusNumber = cosi.number__c;
                    displayStatus = cosi.displayText__c;
                    if(displayMap.keySet().contains(cosi.DisplayText__c)){
                        statuses.remove(displayMap.get(cosi.DisplayText__c));
                        displayMap.remove(cosi.DisplayText__c);
                    }
                }
                if(!displayMap.keySet().contains(cosi.DisplayText__c)){
                        statuses.add(cosi);
                        displayMap.put(cosi.DisplayText__c,statuses.size()+1);    
                }
            }
        }        
    }
} 
public class COSWrapper implements Comparable {

    public Client_Overview_Status_Info__c cs;
    
    // Constructor
    public COSWrapper(Client_Overview_Status_Info__c c) {
        cs = c;
    }
    
    // Compare Client_Overview_Status_Info__c based on the Number field.
    public Integer compareTo(Object compareTo) {
        COSWrapper compareToCS = (COSWrapper)compareTo;
        
        // The return value of 0 indicates that both elements are equal.
        Integer returnValue = 0;
        if (cs.Number__c > compareToCS.cs.Number__c) {
            // Set return value to a positive value.
            returnValue = 1;
        } else if (cs.Number__c < compareToCS.cs.Number__c) {
            // Set return value to a negative value.
            returnValue = -1;
        }
        
        return returnValue;       
    }
}
}