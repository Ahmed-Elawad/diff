/* 
 * Select the profile for the running user
 *
 * History 
 * -------
   09/10/2018 Dan Carmen        Change to handle bulk activity
   
 */
public with sharing class ProfileDA {
   
   public static Profile curProfile = null;
   
   public static Profile getCurrentProfile(){
      // to only select once
      if (curProfile == null) {
         curProfile = [SELECT Id, Name FROM Profile WHERE Id = :UserInfo.getProfileId() LIMIT 1];
      }
      return curProfile;
   } // getCurrentProfile
} // class ProfileDA