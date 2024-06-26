/* 
 * Reassigns stuff.  Accept sObject?
 *
 * History
 * -------
 * 04/13/2017 Jacob Hinds        Created
 */
public with sharing class RecordReassignmentController {
    public String objId;
    public sObject objectToUpdate;
    public User runningUser;
    public String selectedQueue{get;set;}
    public ReferralWrapper selectedReferralWrap{get;set;}
    public Boolean multipleReferrals{get;set;}
    public List<ReferralWrapper> wraps{get;set;}
    public Referral__c selectedUser{get;set;}
    public static String selectedTransferReason{get;set;}
    
    public RecordReassignmentController(){
        objId = ApexPages.currentPage().getParameters().get('objId');
        String objPrefix = objId.left(3);
        String objType;
        //using a dummy referral object for the user selection because we need it to create a lookup field.  We're using the Referring User field because a user lookup was needed.
        //using the owner field would result in a queue/user lookup and we're doing queue ownership via the picklist so that wouldn't work.
        selectedUser = new Referral__c();
        //Date minimumDay = Date.today().addDays(Integer.valueOf(Label.PartnerReferralExpiration)*-1);
        //String minimumDate = datetime.newInstance(minimumDay.year(), minimumDay.month(),minimumDay.day()).format('yyyy-MM-dd\'T\'HH:mm:ss\'Z\'');
        
        multipleReferrals = false;
        
        runningUser = [SELECT Id,NSS_Team__c FROM User WHERE Id =:UserInfo.getUserId()];
        
        if(objId!=null){
            String queryString = 'SELECT Id, CreatedDate, OwnerId,Name,SourceContact__c,SourceLead__c,Selling_Opportunity__c,Account__c,Referral_Type__c FROM Referral__c WHERE ';
            if(objPrefix == Contact.sObjectType.getDescribe().getKeyPrefix()){
                //queryString += 'SourceContact__c = '+'\''+objId+'\''+ ' AND CreatedDate >= '+minimumDate;  
                queryString += 'SourceContact__c = '+'\''+String.escapeSingleQuotes(objId)+'\'';
            }
            else if (objPrefix == Lead.sObjectType.getDescribe().getKeyPrefix()){
                //queryString += 'SourceLead__c = '+'\''+objId+'\''+ ' AND CreatedDate >= '+minimumDate;  
                queryString += 'SourceLead__c = '+'\''+String.escapeSingleQuotes(objId)+'\'';
            }
            else if (objPrefix == Opportunity.sObjectType.getDescribe().getKeyPrefix()){
                //queryString += 'Selling_Opportunity__c = '+'\''+objId+'\''+ ' AND CreatedDate >= '+minimumDate;  
                queryString += 'Selling_Opportunity__c = '+'\''+String.escapeSingleQuotes(objId)+'\'';
            }
            else if (objPrefix == Account.sObjectType.getDescribe().getKeyPrefix()){
                //queryString += 'Account__c = '+'\''+objId+'\''+ ' AND CreatedDate >= '+minimumDate;  
                queryString += 'Account__c = '+'\''+String.escapeSingleQuotes(objId)+'\'';
            }
            else{
                queryString = null;
            }
            system.debug('queryString: '+queryString);
            if(queryString!=null){
                Referral__c[] queryResults = Database.query(queryString);
                if(queryResults!=null && queryResults.size()>1){
                    multipleReferrals = true;
                    if(wraps==null){
                        wraps = new List<ReferralWrapper>();
                    }
                    for(Referral__c ref:queryResults){
                        ReferralWrapper wrap = new ReferralWrapper();
                        wrap.ref = ref;
                        wraps.add(wrap);
                    }
                }
                else if(queryResults!=null && queryResults.size()==1){
                    multipleReferrals = false;
                    objectToUpdate = queryResults[0];
                }
                else{
                    multipleReferrals = false;
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'No eligible records found.  If the problem persists, please contact Salesforce Support'));
                }
            }
            
            //objectToUpdate = Database.query(queryString);
        }
    }
    //get the mapping of what queues the user can assign to
    public List<SelectOption> getQueueOptions() {
        List<SelectOption> queueOptions = new List<SelectOption>();
        queueOptions.add(new SelectOption('','-None-'));
        String[] options = Label.Reassign_Component_Queues.split(';');
        options.sort();
        for(String option:options){
            queueOptions.add(new SelectOption(option,option));
        }
        /*if(runningUser!=null && String.isNotBlank(runningUser.NSS_Team__c)){
            NSSTeamMap__c nssMap = NSSTeamMap__c.getInstance(runningUser.NSS_Team__c);
            if(nssMap!=null){
                String[] options = nssMap.Available_Queues__c.split(';');
                if(options!=null && !options.isEmpty()){
                    for(String option:options){
                        queueOptions.add(new SelectOption(option,option));
                    }
                }
            }
        }*/
        //queueOptions.add(new SelectOption('NSS Inbound Queue','NSS Inbound Queue'));

        return queueOptions;
    }
    public List<SelectOption> getTransferReasons() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('','-None-'));
        List<Schema.PicklistEntry> fieldValues = Transfer_Tracking__c.Reason__c.getDescribe().getPicklistValues();
        for(Schema.PicklistEntry fv:fieldValues){
            options.add(new SelectOption(fv.getValue(),fv.getValue()));
        }
        return options;
    }
    public void storeSelectedReferral(){
        for(ReferralWrapper wrap:wraps){
            if(selectedReferralWrap!=null && wrap.selected && wrap.ref.Id != selectedReferralWrap.ref.Id){
                selectedReferralWrap.selected=false;
                selectedReferralWrap = wrap;
            }
            else if(selectedReferralWrap!=null && !wrap.selected && wrap.ref.Id == selectedReferralWrap.ref.Id){
                selectedReferralWrap = null;
            }
            else if(selectedReferralWrap==null&&wrap.selected){
                selectedReferralWrap=wrap;
            }
        }
        objectToUpdate = (selectedReferralWrap!=null ? selectedReferralWrap.ref : null);
    }
    public PageReference save(){
        PageReference returnURL;
        system.debug('objectToUpdate: '+objectToUpdate+ 'selectedQueue: '+selectedQueue+ 'selectedUser: '+selectedUser);
        if(selectedQueue != null && selectedUser != null && selectedUser.Referring_User__c != null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'A User and Queue have both been selected.  Please clear one of the fields to proceed.'));
        }
        else if(objectToUpdate != null && selectedQueue == null && (selectedUser == null || selectedUser.Referring_User__c == null)){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Select a Queue or User to assign to'));
        }
        else if(objectToUpdate == null && multipleReferrals && selectedReferralWrap == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Please Select a Record to Reassign'));
        }
        else if(objectToUpdate != null && selectedQueue != null){
            Group q = [SELECT Id FROM Group WHERE Type = 'Queue' AND Name = :selectedQueue LIMIT 1];
            if(q != null){
                try{
                    objectToUpdate.put('OwnerId',(Id)q.get('Id'));
                    objectToUpdate.put('NotifyOwner__c',true);
                    ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
                    ChatterMessageSend.notifyOwnerIdSet.add((Id)objectToUpdate.get('Id'));
                    update objectToUpdate;
                    returnURL = new PageReference('/'+objId);
                }
                catch(Exception e){
                    ApexPages.addMessages(e);
                }
                
            }
        }
        else if(objectToUpdate != null && selectedUser!=null && selectedUser.Referring_User__c != null){
            try{
                objectToUpdate.put('OwnerId',selectedUser.Referring_User__c);
                objectToUpdate.put('User__c',selectedUser.Referring_User__c);
                objectToUpdate.put('NotifyOwner__c',true);
                ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
                //ChatterMessageSend.notifyOwnerIdSet.add((Id)objectToUpdate.get('Id'));
                update objectToUpdate;
                returnURL = new PageReference('/'+objId);
            }
            catch(Exception e){
                    ApexPages.addMessages(e);
            }
        }
        return returnURL;
    }
    public PageReference cancel(){
        PageReference returnURL = new PageReference('/'+objId);
        return returnURL;
    }
    
    
}