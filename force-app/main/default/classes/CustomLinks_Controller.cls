/*
   ** Controller for Home Page sidebar component
   ** uses custom setting to select links displayed based on user role
   *
   ** History
   ** --------
   ** 11/15/2012    Cindy Freeman created
   ** 12/07/2017 	Cindy Freeman	modified to handle users that dont have a role
   ** 04/11/2018	Jermaine Stukes	Add logic to display based on profile
   */
   
   public with sharing class CustomLinks_Controller {

    public class customLinks {
        public String linkLabel {get; set;}
        public String linkUrl {get; set;}
    }
    
    public List<customLinks> custLinks {
      get {
        Map<String, custom_links__c> allLinks = custom_links__c.getAll();
        Map<String, customLinks> tempLinks = new Map<String, customLinks>();
        List<String> sortNames = new List<string>();
        
       
          if (UserInfo.getUserRoleID() != null)
          {	
              for (custom_links__c cl : allLinks.values())        
              {   
                  if (cl.roleId__c == UserInfo.getUserRoleID().left(15) || cl.roleId__c == UserInfo.getUserRoleID())
                  {   customLinks tempcl = new customLinks();
                   tempcl.linkLabel = cl.link_label__c;
                   tempcl.linkUrl = cl.link_url__c;
                   tempLinks.put(cl.Name, tempcl);
                   sortNames.add(cl.Name);
                  }
                  else if(cl.Profile_Names__c!=Null)
                  {
                      List<String> profileList = cl.Profile_Names__c.split(',');
                      List<Id> UserProfileList = new List<Id>();
                      for(String oneProfile : profileList)
                      {
                          try
                          {
                              Profile UserProfile = UserHelper.getProfile(oneProfile, false);
                              UserProfileList.add(UserProfile.Id);
                          }
                          catch(Exception ex)
                          {
                              System.debug('Incorrect profile(s) listed.');
                          }
                      }
                      if(!UserProfileList.isEmpty())
                      {
                          if(UserProfileList.contains(UserInfo.getProfileId()) || UserProfileList.contains(UserInfo.getProfileId().left(15)))
                          {
                              customLinks tempcl = new customLinks();
                              tempcl.linkLabel = cl.link_label__c;
                              tempcl.linkUrl = cl.link_url__c;
                              tempLinks.put(cl.Name, tempcl);
                              sortNames.add(cl.Name);
                          }
                      }
                  }
              }
        }  // if (UserInfo.getUserRoleID() != null)
        
        // if no role match, put in default links, ones that have no role assigned to them
        if (tempLinks.size() == 0)
        {   for (custom_links__c cl : allLinks.values())
            {   if (cl.roleId__c == Null)
                {   customLinks tempcl = new customLinks();
                    tempcl.linkLabel = cl.link_label__c;
                    tempcl.linkUrl = cl.link_url__c;
                    tempLinks.put(cl.Name, tempcl);
                    sortNames.add(cl.Name);
                }
            }
        } 
        
        List<customLinks> cLinks = new List<customLinks>();        
        sortNames.sort();
        for (String nam: sortNames)
        {   customLinks tempcl = new customLinks();
            tempcl = tempLinks.get(nam);
            cLinks.add(tempcl);
        }
            
        return cLinks;
      } // get
    }
}