public without sharing class CPA_PortalRequetController {
	
    @AuraEnabled
    public static String insertCPAPortalRequest(String inputJson) {
        try {
            Map<String, String> dataMap = (Map<String, String>) JSON.deserialize(inputJson, Map<String, String>.class);
            CPA_Portal_New_user_Request__c cpaPortal = new CPA_Portal_New_user_Request__c();
            Set<String> numberFields = new Set<String>{'Firm_Zip_Code__c'};
            for(String fieldAPIName : dataMap.keySet()) {
                String value = dataMap.get(fieldAPIName);
                System.debug('fieldAPIName='+fieldAPIName+', value='+value);
                if(numberFields.contains(fieldAPIName)) {
                    cpaPortal.put(fieldAPIName, Integer.valueOf(value));
                } else {
                    cpaPortal.put(fieldAPIName, value);
                }
            }
            insert cpaPortal;
            if(cpaPortal.Id != null) {
                sendNotificationEmail(dataMap);
            }
            return cpaPortal.id;
        }
        catch(Exception ex) {
            System.debug('Exception ='+ex);
        }
        return null;
    }
    
    public static void sendNotificationEmail(Map<String, String> dataMap) {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
    	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('Request has been submitted successfully!');
        String htmlBody = 
            'The following individual has requested to be part of the Paychex Accountant Program, please investigate to see if this is an existing referral contact or firm within salesforce- if not add them in. Please coordinate with the referral account owner to invite this firm and leverage referrals:<br/><br/>';
        htmlBody +=
            'First Name: '+dataMap.get('First_Name__c')+'<br/>';
        htmlBody +=
            'Last Name: '+dataMap.get('Last_Name__c')+'<br/>';
        htmlBody +=
            'Email: '+dataMap.get('Email__c')+'<br/>';
        htmlBody +=
            'Firm Name: '+dataMap.get('Firm_Name__c')+'<br/>';
        htmlBody +=
            'Firm ZipCode: '+dataMap.get('Firm_Zip_Code__c')+'<br/>';
        htmlBody +=
            'Phone Number: '+dataMap.get('Phone_Number__c')+'<br/>';
        mail.setHtmlBody(htmlBody);
        mail.setToAddresses(new List<String>{'accountingresources@paychex.com'});
        emailList.add(mail);
        Messaging.sendEmail(emailList);
    }
    
}