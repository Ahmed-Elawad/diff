/**********************************************************/
//Created by: Gram Bischof 11/13/2018
//Last Modified: Gram Bischof 11/13/2018
//
//Description: 
//Class to map UTM fields on Campaign Member
//from Leads & Contacts
//
//Test Class: 
//DG_UTMControllerTest
/**********************************************************/
/* 

  History
  -------
  04/18/2019 Dan Carmen        Fix NPE
  07/06/2020  Jacob Hinds         Added without sharing per PMD
  
 */
public without sharing class DG_UTMController {
    
    /*public static void UpdateCMsFromLead(Map<Id,Lead> newMap,Map<Id,Lead> oldMap){
        Set<Id> LeadKeySet = new Set<Id>();
        List<CampaignMember> theCMList = new List<CampaignMember>();
        for(Lead theLead : newMap.values()) {
            if(oldMap != null) {
                if ((theLead.UTM_Campaign_Most_Recent__c != oldMap.get(theLead.Id).UTM_Campaign_Most_Recent__c
                   && !String.isempty(theLead.UTM_Campaign_Most_Recent__c))
                   ||
                   (theLead.UTM_Content_Most_Recent__c  != oldMap.get(theLead.Id).UTM_Content_Most_Recent__c 
                   && !String.isempty(theLead.UTM_Content_Most_Recent__c))
                   ||
                   (theLead.UTM_Medium_Most_Recent__c  != oldMap.get(theLead.Id).UTM_Medium_Most_Recent__c 
                   && !String.isempty(theLead.UTM_Medium_Most_Recent__c))
                   ||
                   (theLead.UTM_Source_Most_Recent__c  != oldMap.get(theLead.Id).UTM_Source_Most_Recent__c 
                   && !String.isempty(theLead.UTM_Source_Most_Recent__c ))) {
                       
                    LeadKeySet.add(theLead.Id);    
                }
            }
            else {
                if (!String.isempty(theLead.UTM_Campaign_Most_Recent__c)
                   ||
                   !String.isempty(theLead.UTM_Content_Most_Recent__c)
                   ||
                   !String.isempty(theLead.UTM_Medium_Most_Recent__c)
                   ||
                   !String.isempty(theLead.UTM_Source_Most_Recent__c )) {
                       
                    LeadKeySet.add(theLead.Id);    
                }    
            }
        }   
        
        List<CampaignMember> allCMs = [Select Id,LeadId,UTM_Source_Most_Recent__c,UTM_Medium_Most_Recent__c,UTM_Content_Most_Recent__c
                                       ,UTM_Campaign_Most_Recent__c From CampaignMember 
                                       Where LeadId IN :LeadKeySet];
        
        for(CampaignMember theCM : allCMS) {
            theCM.UTM_Campaign_Most_Recent__c = newMap.get(theCM.LeadId).UTM_Campaign_Most_Recent__c;
            theCM.UTM_Content_Most_Recent__c = newMap.get(theCM.LeadId).UTM_Content_Most_Recent__c;
            theCM.UTM_Medium_Most_Recent__c = newMap.get(theCM.LeadId).UTM_Medium_Most_Recent__c;
            theCM.UTM_Source_Most_Recent__c = newMap.get(theCM.LeadId).UTM_Source_Most_Recent__c;
            theCMList.add(theCM);
        }
        
        if(theCMList.size() > 0) update theCMList;
    }*/
    
    public static void UpdateCMs(List<CampaignMember> theCMList){
        Set<Id> theLeadIdsSet = new Set<Id>();
        //Map<Id,Contact> theContactMap = new Map<Id,Contact>();
        Set<Id> theContactIdsSet = new Set<Id>();
        
        for(CampaignMember theCM : theCMList) {
            if(theCM.LeadId != null) theLeadIdsSet.add(theCM.LeadId); 
            if(theCM.ContactId != null) theContactIdsSet.add(theCM.ContactId); 
        }
        
        Map<Id,Lead> theLeadMap = (!theLeadIdsSet.isEmpty() ? new Map<Id,Lead>([SELECT Id,UTM_Campaign_Most_Recent__c,UTM_Content_Most_Recent__c,UTM_Medium_Most_Recent__c,
                            UTM_Source_Most_Recent__c FROM Lead WHERE Id IN : theLeadIdsSet]) : new Map<Id,Lead>());
        
        Map<Id,Contact> theContactMap = (!theContactIdsSet.isEmpty() ? new Map<Id,Contact>([SELECT Id,UTM_Campaign_Most_Recent__c,UTM_Content_Most_Recent__c,UTM_Medium_Most_Recent__c,
                            UTM_Source_Most_Recent__c FROM Contact WHERE Id IN : theContactIdsSet]) : new Map<Id,Contact>());
        
        for(CampaignMember theCM : theCMList) {
            if (theCM.ContactId != null) {
               Contact ctct = theContactMap.get(theCM.ContactId);
               if (ctct != null) {
                  theCM.UTM_Campaign_Most_Recent__c = ctct.UTM_Campaign_Most_Recent__c;
                  theCM.UTM_Content_Most_Recent__c = ctct.UTM_Content_Most_Recent__c;
                  theCM.UTM_Medium_Most_Recent__c = ctct.UTM_Medium_Most_Recent__c;
                  theCM.UTM_Source_Most_Recent__c = ctct.UTM_Source_Most_Recent__c;
               }
            } else if (theCM.LeadId != null) {
               Lead ld = theLeadMap.get(theCM.LeadId);
               if (ld != null) {
                  theCM.UTM_Campaign_Most_Recent__c = ld.UTM_Campaign_Most_Recent__c;
                  theCM.UTM_Content_Most_Recent__c = ld.UTM_Content_Most_Recent__c;
                  theCM.UTM_Medium_Most_Recent__c = ld.UTM_Medium_Most_Recent__c;
                  theCM.UTM_Source_Most_Recent__c = ld.UTM_Source_Most_Recent__c;
               }
            }
        }
    } // UpdateCMs
    
    /*public static void UpdateCMsFromContact(Map<Id,Contact> newMap,Map<Id,Contact> oldMap){
        Set<Id> ContactKeySet = new Set<Id>();
        List<CampaignMember> theCMList = new List<CampaignMember>();
        for(Contact theContact : newMap.values()) {
            if(oldMap != null) {
                if ((theContact.UTM_Campaign_Most_Recent__c != oldMap.get(theContact.Id).UTM_Campaign_Most_Recent__c
                   && !String.isempty(theContact.UTM_Campaign_Most_Recent__c))
                   ||
                   (theContact.UTM_Content_Most_Recent__c  != oldMap.get(theContact.Id).UTM_Content_Most_Recent__c 
                   && !String.isempty(theContact.UTM_Content_Most_Recent__c))
                   ||
                   (theContact.UTM_Medium_Most_Recent__c  != oldMap.get(theContact.Id).UTM_Medium_Most_Recent__c 
                   && !String.isempty(theContact.UTM_Medium_Most_Recent__c))
                   ||
                   (theContact.UTM_Source_Most_Recent__c  != oldMap.get(theContact.Id).UTM_Source_Most_Recent__c 
                   && !String.isempty(theContact.UTM_Source_Most_Recent__c ))) {
                       
                    ContactKeySet.add(theContact.Id);    
                }
            }
            else {
                if (!String.isempty(theContact.UTM_Campaign_Most_Recent__c)
                   ||
                   !String.isempty(theContact.UTM_Content_Most_Recent__c)
                   ||
                   !String.isempty(theContact.UTM_Medium_Most_Recent__c)
                   ||
                   !String.isempty(theContact.UTM_Source_Most_Recent__c )) {
                       
                    ContactKeySet.add(theContact.Id);    
                }    
            }
        }   
        
        List<CampaignMember> allCMs = [Select Id,ContactId,UTM_Source_Most_Recent__c,UTM_Medium_Most_Recent__c,UTM_Content_Most_Recent__c
                                       ,UTM_Campaign_Most_Recent__c From CampaignMember 
                                       Where ContactId IN :ContactKeySet];
        
        for(CampaignMember theCM : allCMS) {
            theCM.UTM_Campaign_Most_Recent__c = newMap.get(theCM.ContactId).UTM_Campaign_Most_Recent__c;
            theCM.UTM_Content_Most_Recent__c = newMap.get(theCM.ContactId).UTM_Content_Most_Recent__c;
            theCM.UTM_Medium_Most_Recent__c = newMap.get(theCM.ContactId).UTM_Medium_Most_Recent__c;
            theCM.UTM_Source_Most_Recent__c = newMap.get(theCM.ContactId).UTM_Source_Most_Recent__c;
            theCMList.add(theCM);
        }
        
        if(theCMList.size() > 0) update theCMList;
    }*/

} // class DG_UTMController