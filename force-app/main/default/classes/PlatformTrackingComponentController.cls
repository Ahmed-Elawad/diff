/*
    
07/06/2020  Jacob Hinds         Added without sharing per PMD
03/08/2021  Dan Carmen          Added ability to not save tracker
   11/10/2023 Dan Carmen       Comment out code

*/

global without sharing class PlatformTrackingComponentController {
    public string recId {get;set;}
    public string objType {get;set;}
    
    public static Boolean SAVE_TRACKER=(Label.PlatformTracker_SaveTracker=='Y');
    
    @RemoteAction
    global static void save(string recordID, string objectType, String uiTheme){
       if (String.isBlank(uiTheme)) {
          uiTheme = UserInfo.getUiThemeDisplayed();
       }
       if (SAVE_TRACKER) {
           insert new PlatformTracker__c(RecordId__c=recordId,
                                      ObjectType__c=objectType,
                                      UITheme__c=uiTheme,
                                     UsageType__c='Read');       
       }
    } // save
} // class PlatformTrackingComponentController