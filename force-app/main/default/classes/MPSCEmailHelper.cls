/*
* This class will process messages received from email services.  The email is sent from multiple power apps used by MPSC  
*
* History
* --------
* 04/10/2024   Carrie Marciano created
*/

public class MPSCEmailHelper {
    public class pAppInfo {
        public Map<String,String> fldMap = new Map<String,String>();
        public string CaseNumber;
        public string CaseId;
        public string ProcessType;
        public string Status;
        public String parseMsg;
        public String plainTextBody;
    } // Update with the correct xml tags
    
    private static PaychexSettings__c payxSetting = null;
    public static String rMPSCQuery=null;
    
    public static void processInfo(List<pAppInfo> pAppInfoList) {
        system.debug('MPSCEmailHelper enter processInfo');
        ErrorLog__c log = new ErrorLog__c(ClassName__c='MPSCEmailHelper',MethodName__c='processInfo', CodeKey__c='LOG_DATA');
        Schema.RecordTypeInfo caseRT;
        Case[] casesToUpdate = new Case[]{}; // list used to collect the cases to be updated as they are processed.      
        Set<Id> casesToUpdateId = new Set<Id>();
        Reference_MPSC_Service_Submission__c[] refMPSCToUpdate = new Reference_MPSC_Service_Submission__c[]{}; // list used to collect the refMPSCs to be updated as they are processed.
        
        // Map<PowerAppStatus, Case_Status__c>    
        Map<String,String> statusMap = new Map<String,String>();
        for (MPSCStatusMapping__mdt statusMapping : [Select MasterLabel, Label, Case_Status__c, PowerAppStatus__c, PowerApp__c from MPSCStatusMapping__mdt]){
        	statusMap.put(statusMapping.PowerAppStatus__c,statusMapping.Case_Status__c);
       	} //for
        
        for (pAppInfo pAI: pAppInfoList){
            Case pAppCase = getCase(pAI.CaseId); // query case fields
            log.ObjectId__c = (pAppCase == null ? null : pAppCase.Id);
            log.ObjectAPIName__c='Case';
            system.debug('processInfo pAppCase: '+pAppCase+' pAppCase.Status_Description__c: '+ pAppCase.Status_Description__c+' pAI.Status: '+pAI.Status);
            if (pAppCase != null && pAppCase.Status_Description__c != pAI.Status){
                pAppCase.Status_Description__c = pAI.Status;
                pAppCase.status = statusMap.keySet().contains(pAI.Status) != null ? statusMap.get(pAI.Status) : null;
                //Amended Return Escalation PowerApp will return Pending on initial send, all others will return Submitted
                //only update if blank Submitted Date on the case 
                system.debug('processInfo Status: '+pAI.status+' Submitted Date: '+ pAppCase.Submitted_Date__c);
                if(pAppCase.Submitted_Date__c == null && (pAI.status == 'Submitted' || pAI.status == 'Pending')){
                    pAppCase.Submitted_Date__c = DateTime.now();
                    system.debug('processInfo update Case Submitted Date: '+ pAppCase.Submitted_Date__c);
                }                
            }//pAppCase != null
            casesToUpdate.add(pAppCase);
            casesToUpdateId.add(pAppCase.Id);
            
        } //for
        
        system.debug('processInfo casesToUpdate: '+casesToUpdate.size());
        if(!casesToUpdate.isEmpty()){
            try{
                DmlHelper.performDML2(casesToUpdate, DmlHelper.DML_UPDATE, 'MPSCEmailHelper', 'processInfo', 'Update MPSC Case', false); 
            	system.debug('processInfo after update Case recs');
            }
            catch(Exception ex){
                if(!Test.isRunningTest()){
                    Throw new MPSCEmailException('Unable to Process MPSC Information: '+pAppInfoList[0]);
                }
            } 
        } //!casesToUpdate.isEmpty()
        
        // Map<CaseId, Reference_MPSC_Service_Submission__c>
        Map<Id,Reference_MPSC_Service_Submission__c> caseRefMap = getRefMPSC(casesToUpdateId);
        for (pAppInfo pAI: pAppInfoList){
            Reference_MPSC_Service_Submission__c fRef = (caseRefMap.keySet().contains(pAI.CaseId) != null ? caseRefMap.get(pAI.CaseId) : null);                   
            if(fRef != null){
                String[] otherValues = new String[]{};  
                for (String fldName : pAI.fldMap.keySet()) {
                    String fldValue = pAI.fldMap.get(fldName);
                    system.debug('processInfo fldName: '+fldName+' fldValue: '+fldValue);
                    if (String.isNotBlank(fldValue)) {
                        if (fldName == 'IsClientASO') {
                            fRef.Is_the_Client_ASO__c = Boolean.valueOf(fldValue); 
                        } else if (fldName == 'ReasonForLeaving') {
                            fRef.At_Risk_Reason_Reason_for_Leaving__c = (fldValue );
                        } else if (fldName == 'ReasonForLeaving2') {
                            fRef.Reason_for_Leaving_2__c = (fldValue );
                        } else if (fldName == 'ReasonForLeaving3') {
                            fRef.Reason_for_Leaving_3__c = (fldValue );
                        } else if (fldName == 'PayrollTermDate') {
                            fRef.Expected_Term_Date__c = (fldValue );
                        } else if (fldName == 'TrainingType') {
                            fRef.Training_Type__c = (fldValue );
                        } else if (fldName == 'ErrorResponsibilityClient') {
                            fRef.Error_Responsibility_Client__c = boolean.valueof(fldValue );
                        } else if (fldName == 'ErrorResponsibilityPaychex') {
                            fRef.Error_Responsibility_Paychex__c = boolean.valueof(fldValue );
                        } else {
                            otherValues.add(fldName+': '+fldValue); // adds all values that do not have a specific field
                        }
                    }                   
                } // for (String fldName
                otherValues.sort();
                system.debug('processInfo otherValues: '+otherValues);
                if (!otherValues.isEmpty()) {
                    // if Submission_Details__c has data, append any updates to end
                    fRef.Submission_Details__c = (String.isNotBlank(fRef.Submission_Details__c) ? fRef.Submission_Details__c+'\n' : '') + String.join(otherValues,'\n');
                } //!otherValues.isEmpty
                
                refMPSCToUpdate.add(fRef);
            } 
            else{
                ErrorLog.addToDescription(log, 'No Reference MPSC Service Submission record found for CaseId.');    
            } //fRef != null
        } //for
        
        system.debug('processInfo refMPSCToUpdate: '+refMPSCToUpdate.size());
        if(!refMPSCToUpdate.isEmpty()){
            //SKIP_TRIGGER=True;  DO WE NEED THIS??
            DmlHelper.performDML2(refMPSCToUpdate, DmlHelper.DML_UPDATE, 'MPSCEmailHelper', 'processInfo', 'Update Reference MPSC Service Submission', false); 
            system.debug('processInfo after update Reference MPSC Service Submission recs');
            //SKIP_TRIGGER=False;  DO WE NEED THIS??
        } 
        else{
        	ErrorLog.addToDescription(log, 'No Reference MPSC Service Submission records found to update.');    
        } //!casesToUpdate.isEmpty()
        
        ErrorLog.saveLog(log);
    	system.debug('processInfo after ErrorLog.saveLog: '+log);
    } //processInfo
    
    // get case so can fill in values from PowerApps
    public static Case getCase(String CaseId) {
        System.debug('MPSCEmailHelper here at getCases CaseId: '+CaseId);
        Case pAppCase = null;
        if (!String.isBlank(CaseId)){
            Id pAppCaseId = (Id)CaseId;
            pAppCase = [Select Id, CaseNumber, Subject, Description, Status, Status_Description__c, Submitted_Date__c, Product__c, Type, Sub_Type__c, Origin, Account.Name from Case
                        where Id = :pAppCaseId limit 1];
        }       
        return pAppCase;
        
    } // getCase
    
    public static Map<Id,Reference_MPSC_Service_Submission__c> getRefMPSC(Set<Id> casesToUpdateId){
        System.debug('MPSCEmailHelper here at getRefMPSC');
        Map<Id,Reference_MPSC_Service_Submission__c> refMPSCMap = new Map<Id,Reference_MPSC_Service_Submission__c>();
   		/* ONLY the following fields are to be parsed out into individual fields on reference object, all other data will be concatenated into 'Submission Details' field
            Loss Submission:
                Is the client ASO
                At Risk Reason/Reason for Leaving
                Reason for Leaving 2  
                Expected Term Date
            Client Training:
                Training Type
            Taxpay Adjustment
                Error Responsibility - Client
                Error Responsibility - Paychex 
		*/
        
        Set<String> fldSet = new Set<String>();
        Schema.FieldSet rMPSCFldSet = Schema.SObjectType.Reference_MPSC_Service_Submission__c.fieldSets.MPSCEmailServiceFieldSet;
        for (Schema.FieldSetMember fsm : rMPSCFldSet.getFields()) {
            String fldName = fsm.getFieldPath();
            fldSet.add(fldName);
        } //for
        
        String[] fldList = new String[]{};
        fldList.addAll(fldSet);
        fldList.sort();
        rMPSCQuery = 'Select '+String.join(fldList,',')+' From Reference_MPSC_Service_Submission__c Where Case__c in :casesToUpdateId';   
        System.debug('MPSCEmailHelper rMPSCQuery: '+rMPSCQuery);
        Reference_MPSC_Service_Submission__c[] refs = Database.query(rMPSCQuery);
        for(Reference_MPSC_Service_Submission__c ref : refs){
            refMPSCMap.put(ref.Case__c, ref);
        } //for
      
        System.debug('MPSCEmailHelper refMPSCMap: '+refMPSCMap.size());
        return refMPSCMap;     
    } //getRefMPSC
    
    // code to parse an email of just plain text instead of html
    public static pAppInfo parseXml(String toParse){ 
        System.debug('MPSCEmailHelper here at parseXml');
        ErrorLog__c log = new ErrorLog__c(ClassName__c='MPSCEmailHelper',MethodName__c='parseXml', CodeKey__c='LOG_DATA');
        pAppInfo pAppInfo = new pAppInfo();
        pAppInfo.parseMsg = 'Success';
        String errMsg = '';
        try{
            toParse = toParse.replaceAll('&', '&amp;');
            Map<String, String> tempParse = new Map<String, String>();
            pAppInfo.plainTextBody = toParse;
            ErrorLog.addToDescription(log, toParse);
            System.debug('MPSCEmailHelper parseXml toParse: '+toParse);
            DOM.Document doc = new DOM.Document();
            try {
                doc.load(toParse);
                DOM.Xmlnode root = doc.getRootElement();
                System.debug('MPSCEmailHelper parseXml root: '+root);
                tempParse = walkthrough(root, tempParse);
                pAppInfo.fldMap = tempParse;
                pAppInfo.CaseNumber = tempParse.remove('CaseNumber');
                pAppInfo.CaseId = tempParse.remove('CaseId');
                pAppInfo.Status = tempParse.remove('Status');
            }
            catch (System.Xmlexception ex) {
                errMsg += ' parseXml Parsing error: '+ ex.getMessage();
                ErrorLog.logError('MPSCEmailHelper', 'parseXML', 'System.Xmlexception', null, errMsg+''+toParse, null, true);
                System.debug('parseXml xmlexception errMsg: '+errMsg);           
            }   
            /*if (String.isBlank(errMsg)){             
                if (String.isBlank(pAppInfo.CaseNumber)){
                    errMsg += ' Missing Case Number  ';   
                }
                if (String.isBlank(pAppInfo.CaseId)){
                    errMsg += ' Missing CaseId ';  
                }
                if (String.isBlank(pAppInfo.Status)){
                    errMsg += ' Missing Status ';  
                }
            }   */     
        }
        catch(Exception ex1){
            errMsg += ex1.getMessage()+'; '+ex1.getStackTraceString();
            ErrorLog.logError('MPSCEmailHelper', 'parseXML', 'Exception', null, errMsg+''+toParse, null, true);
        }
        
        if (String.isBlank(errMsg)){             
            if (String.isBlank(pAppInfo.CaseNumber)){
                errMsg += ' Missing Case Number  ';   
            }
            if (String.isBlank(pAppInfo.CaseId)){
                errMsg += ' Missing CaseId ';  
            }
            if (String.isBlank(pAppInfo.Status)){
                errMsg += ' Missing Status ';  
            }
        }       
        
        if (String.isNotBlank(errMsg)) {
            System.debug('parseXml isNotBlank(errMsg): '+errMsg);
            pAppInfo.parseMsg = errMsg;
            ErrorLog.logError('MPSCEmailHelper', 'parseXML', 'Missing required values', null, errMsg+''+toParse, null, true);
            //Throw new MPSCEmailException('Missing required values: '+errMsg);
        }
        ErrorLog.saveLog(log);
        return pAppInfo;    
    } // parseXML 
    
    private static Map<String, String> walkthrough(DOM.XMLnode node, Map<String, String> tempParse){
        if (node.getNodeType() == DOM.XMLNodeType.ELEMENT){ 
            String nam = node.getName();
            String txt = node.getText().trim();
            txt = txt.replaceAll('\n', '');
            txt = txt.replaceAll('\r', '');
            tempParse.put(nam,txt);
        }
        
        for (Dom.XMLNode child: node.getChildElements()){ 
            tempParse = walkThrough(child, tempParse);  
        }   
        System.debug('MPSCEmailHelper  walkthrough tempParse: '+tempParse);
        return tempParse;
    } // walkthrough 
    
    // this exception is used to throw missing attachment messages
    public class MPSCEmailException extends Exception {}  
}