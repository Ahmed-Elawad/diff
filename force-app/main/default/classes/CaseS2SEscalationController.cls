/* Page to escalate s2s cases

   History
   -------
   07/08/2020 Jake Hinds        Created 

*/
public without sharing class CaseS2SEscalationController {
    public Case rec{get;set;}
    //public Id assignedSpecialist{get;set;}
	public CaseS2SEscalationController(ApexPages.StandardController stdController){
        system.debug('CaseS2SEscalationController in constructor stdController');
        rec = (Case)stdController.getRecord();
        rec = [SELECT Id,CaseNumber,Subject,Assigned_UC_Agent__c,Assister__c,isEscalated,Reason_for_escalation__c,Sales_Admin_Contact__c FROM Case WHERE Id = :rec.Id LIMIT 1];
        if(string.isnotblank(rec.Assigned_UC_Agent__c)){
            Contact[] possibleSpecialists = [SELECT Id,FirstName,LastName,ReportsToId FROM Contact WHERE (Name = :rec.Assigned_UC_Agent__c OR Email = :rec.Assigned_UC_Agent__c) AND RecordType.Name = 'Paychex Employee' LIMIT 1];
            if(possibleSpecialists!=null && !possibleSpecialists.isEmpty()){
                rec.Assister__c = possibleSpecialists[0].Id;
                rec.Sales_Admin_Contact__c = possibleSpecialists[0].ReportsToId;
            }
        }
        else{
            Contact[] defaultSpecialists = [SELECT Id,FirstName,LastName,ReportsToId FROM Contact WHERE Email = 's2sfeedback@paychex.com' AND RecordType.Name = 'Paychex Employee' LIMIT 1];
            if(defaultSpecialists!=null && !defaultSpecialists.isEmpty()){
                rec.Assister__c = defaultSpecialists[0].Id;
                rec.Sales_Admin_Contact__c = defaultSpecialists[0].ReportsToId;
            }
        }
    } // Constructor
    public void save(){
        if(rec.IsEscalated){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'This case has already been escalated.'));
        }
        else if(rec.Assister__c!=null){
            rec.IsEscalated = true;
            try{
                if(rec.Assister__c!=null && rec.Sales_Admin_Contact__c == null){
                    Contact emp = [SELECT Id,FirstName,LastName,ReportsToId FROM Contact WHERE Id = :rec.Assister__c AND RecordType.Name = 'Paychex Employee' LIMIT 1];
                    rec.Sales_Admin_Contact__c = emp.ReportsToId;
                }
                //sendEmail();
                update rec;
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.CONFIRM, 'Your case has been escalated'));
            }
            catch(Exception e){
                if(string.isnotBlank(e.getMessage()) && e.getMessage().contains('UNABLE_TO_LOCK_ROW')){
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'There was an problem submitting your request, please try again shortly.'));
                }
                else{
                	ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'There was an error with your request:'+e.getMessage()));
                }
            }
        }
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The assigned specialist could not be automatically determined.  Please enter the assigned specialist before continuing.'));
        }
    }
    //MOVED TO WORKFLOW
    /*private void sendEmail(){
        Messaging.Singleemailmessage mail = new Messaging.Singleemailmessage();
        List <String> addrList = new List <String> ();
        addrList.add(runningUser.Email);
        //mail.setToAddresses(addrList);
        mail.setTargetObjectId(createdById);
        mail.setSaveAsActivity(false);
        //mail.setToAddresses (new String[]{payxSetting.Attribute1__c});
        mail.setSubject('Add To Cadence Results');
        if(!Test.isRunningTest() && !addrList.isEmpty()){
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
        }
    }*/
}