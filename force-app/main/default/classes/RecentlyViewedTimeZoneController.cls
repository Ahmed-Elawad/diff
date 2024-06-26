/* 
 *  Controller for RecentlyViewedTimeZone Page.
 *   
 * History
 * -------
 * 06/16/2016 Justin Stouffer Created
 */

public with sharing class RecentlyViewedTimeZoneController {
    public contact cntct {get;set;}
    public string timeZoneName {get;set;}
    public string timeZoneAbbrv {get;set;}
    public boolean okToDisplay {get;set;}
    public integer timeZoneOffset {get;set;}
    public string localTime {get;set;}
    public RecentlyViewedTimeZoneController(){
        cntct = new contact();
    	list<contact> contacts = [SELECT Id, 
                		accountID, 
                		account.Name, 
                		account.billingPostalCode, 
                		account.shippingPostalCode, 
                		account.phone  
                		FROM Contact WHERE LastViewedDate != NULL and accountID != NULL ORDER BY LastViewedDate DESC Limit 1];
        if(test.isRunningTest()){
            contacts = [SELECT Id, 
                		accountID, 
                		account.Name, 
                		account.billingPostalCode, 
                		account.shippingPostalCode, 
                		account.phone  
                		FROM Contact WHERE LastName = 'TestContact' Limit 1];
        }
        okToDisplay = False;
        if(!contacts.isEmpty()){
            cntct= contacts[0];
            checkTimeZone();
        }
    }
    
    private void checkTimeZone(){
        String areaCode = (String.isNotBlank(cntct.account.phone) ? cntct.account.phone.replaceAll('\\D','').left(3) : '');
        string zipCode = (String.isNotBlank(cntct.account.BillingPostalCode) ? cntct.account.BillingPostalCode.left(5) : '');
        if(zipCode == ''){
            zipCode = (String.isNotBlank(cntct.account.ShippingPostalCode) ? cntct.account.ShippingPostalCode.left(5) : '');                
        }
        timeZoneName = '';
        timezoneAbbrv = '';
        TimeZoneOffSet = 0;
        if (String.isNotBlank(zipCode)) {
            try {
                Zip_Code_Information__c zci = [Select Id, Name, TimeZoneName__c, TimeZoneAbbrev__c from Zip_Code_Information__c where Name = :zipCode];
                timeZoneName = zci.TimeZoneName__c;
                timeZoneAbbrv = zci.TimeZoneAbbrev__c;
            } catch (Exception e) {
                // nothing needs to be done here
            }
        } // if
        
        // if we fail to find a zip code record, attempt to find an area code record.
        if (String.isBlank(timeZoneName) && String.isNotBlank(areaCode)) {
            try {
                AreaCode__c ac = [Select Id, Name, TimeZoneName__c, TimeZoneAbbrev__c from AreaCode__c where Name = :areaCode];
                timeZoneName = ac.TimeZoneName__c;
                timeZoneAbbrv = ac.TimeZoneAbbrev__c;
            } catch (Exception e) {
                // nothing needs to be done here
            }
        }
        if(String.isNotBlank(timeZoneName) ){
            Timezone tz = Timezone.getTimeZone(timeZoneName);            
            TimeZone usertz = UserInfo.getTimeZone();
            TimeZoneOffSet = (tz.getOffset(System.Now()) - usertz.getOffset(System.Now()))/3600000;
            checkLocalTime();
            okToDisplay = TRUE;
        }
    }
    
    public pageReference checklocalTime(){
        dateTime t = system.Now().addHours(TimeZoneOffSet);
        localTime = t.format().replace(t.date().format(), '').trim();
        return Null;
    }
}