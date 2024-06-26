/*
 * 01/13/2023  Josh Cartwright Created - used to write back to the referral contact during CPA enrollment in Accountant Program Portal 
 * 
 * */
global class CPAEmailServiceHandler implements Messaging.InboundEmailHandler {
/**
 * When an email is submitted, an email will kick off the process for a particular record id.
 */
   global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      // Create an InboundEmailResult object for returning the result of the  Apex Email Service
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
       system.debug('JC email.plainTextBody' + email.plainTextBody);
      id userId = email.plainTextBody.left(18);
       
       User[] users = [Select Id, Name, FirstName, LastName
                        ,UserRoleId
                        ,ContactId
                        ,email
                        ,Community_User_First_Login__c
                        ,IsActive
                        ,Requested_Invite_Date__c
                        From User
                        Where Id =: userId];
        
        System.debug('doPost users='+users.size());
        Map<Id, User> userMap = new Map<Id, User>();
        for(User userObj : users) {
            if(String.isNotBlank(userObj.ContactId)) {
                userMap.put(userObj.ContactId, userObj);
            }
        }
        System.debug('updateCPAProgStatus userMap:'+userMap);
        if(!userMap.isEmpty()) {
            List<Referral_Contact__c> refContListForUpdate = new List<Referral_Contact__c>();
            for(Referral_Contact__c refCont : [SELECT Id, Name, Contact__c, email__c, CPA_Program_status__c, Referral_Account__c FROM Referral_Contact__c WHERE Contact__c IN :userMap.keySet()]) {
                System.debug('updateCPAProgStatus refCont:'+refCont);
                System.debug('updateCPAProgStatus refCont CPA_Program_status__c:'+refCont.CPA_Program_status__c);
                
                if(userMap.containsKey(refCont.Contact__c)) {
                    User userObj = userMap.get(refCont.Contact__c);
                    if(userObj.email != refCont.Email__c ){
                        refCont.email__c = userObj.Email; 
                    }
                    if(userObj.Community_User_First_Login__c != null && userObj.IsActive && refCont.CPA_Program_status__c !=null && refCont.CPA_Program_status__c == 'Invited') {
                        refCont.CPA_Program_status__c = 'Enrolled';
                        refContListForUpdate.add(refCont);
                    }
                    else if(userObj.IsActive == false) {
                        refCont.CPA_Program_status__c = 'Unenrolled/no longer in Program'; 
                        refContListForUpdate.add(refCont);
                    }
                    else if(userObj.Requested_Invite_Date__c != null && userObj.Community_User_First_Login__c == null) {
                        refCont.CPA_Program_status__c = 'Invited';
                        refContListForUpdate.add(refCont);
                    }
                    else if(userObj.Requested_Invite_Date__c == null) {
                        refCont.CPA_Program_status__c = null;
                        refContListForUpdate.add(refCont);
                    }
                    else {
                        refCont.CPA_Program_status__c = null;
                        refContListForUpdate.add(refCont);
                    }
                    System.debug('refContListForUpdate:'+refContListForUpdate);
                }
            }
            if(!refContListForUpdate.isEmpty()) {
                Database.update(refContListForUpdate,false);
            }
        }
      return result;
   } // handleInboundEmail
   
} // class CPAEmailServiceHandler