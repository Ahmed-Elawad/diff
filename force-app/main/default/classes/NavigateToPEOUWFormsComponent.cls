/*
* Used in Navigate To community forms component to provide user details 
* History
* -------------------------------------------------------
* 12/16/2021	Ahmed Elawad		Created & added get Running user method & checkPermissions
*/

public without sharing class NavigateToPEOUWFormsComponent {
    
    // Return the running user record. Cache results since there should never be a data update to the user record
    @AuraEnabled(cacheable=true)
    public static User getRunningUser() {
        User runningUser = UserHelper.getRunningUser();
        return runningUser;
    }
    
    @AuraEnabled
    public static String[] checkPermissions(User currUser){
        String[] missingPermissions = ConvertContactToCommunityUser.checkPermissions(currUser);
        return missingPermissions;
    }
}