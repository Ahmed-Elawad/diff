/* 
   Methods for the ZipTerritory__c object.
     
   History
   -------
   01/31/2014 Dan Carmen   Created
   10/22/2014 Dan Carmen   Cleaned up code due to NSS coming into Salesforce
   04/01/2015 Cindy Freeman  Added method for override email
   04/28/2015 Dan Carmen   Added actions on insert
   07/15/2015 Dan Carmen   Make sure there are email addresses before sending an email.
   11/08/2016 Dan Carmen   Change the limits on the number of records to process.
   01/18/2017 Dan Carmen   Decrease limit to 1000 records.
   05/25/2021 Dan Carmen   Moved logic to a queueable to be able to handle larger number of zip assignments.
   02/08/2024 Dan Carmen   Try to force the change record creation

 */
public with sharing class ZipTerritoryMethods {
   public static Boolean SKIP_TRIGGER=false;
   // public static because we want to hit it in both the before and after triggers.
   public static Set<Id> updateZipOwnerSet = new Set<Id>();

   public static void handleTriggerActions(ZipTerritory__c[] recs, Map<Id,ZipTerritory__c> oldMap, Boolean isBefore, Boolean isAfter) {
      // if the override assistant or manager changes, send an email
      ZipTerritory__c[] oldZipTerrList = new ZipTerritory__c[]{};   
      ZipTerritory__c[] newZipTerrList = new ZipTerritory__c[]{};

      for (ZipTerritory__c zt : recs) {
         ZipTerritory__c oldZt = (oldMap != null ? oldMap.get(zt.Id) : null);
         if (isBefore) {
            if (zt.Id != null && zt.CheckZipUser__c) {
               updateZipOwnerSet.add(zt.Id);
               zt.CheckZipUser__c = false;
            }
         } else if (isAfter) {
            if (oldZt != null && ((oldZt.TerritoryRep__c != zt.TerritoryRep__c) 
                                  || (oldZt.District__c != zt.District__c)
                                  || (oldZt.Rep_Name__c != zt.Rep_Name__c))) {
               // if any of the user attributes have changed, update the zip assignments.
               updateZipOwnerSet.add(zt.Id);
            }
            if (oldZt != null && (zt.OverrideAssistant__c != oldZt.OverrideAssistant__c 
                                  || zt.OverrideManager__c != oldZt.OverrideManager__c )) {   
               oldZipTerrList.add(oldZt);
               newZipTerrList.add(zt);               
            } // if (Update && override changes)
         }
      } // for (ZipTerritory__c zt : recs
       
      if (isAfter && !updateZipOwnerSet.isEmpty()) {
         // creating a new set so I can clear the public set.
         Set<Id> tempIdSet = new Set<Id>();
         tempIdSet.addAll(updateZipOwnerSet);
         ZipTerritoryQueueable.launchQueueable(tempIdSet,false);
         updateZipOwnerSet.clear();
      }
      if (!oldZipTerrList.isEmpty() ) {
         ZipTerritoryMethods.emailOverrideChange(oldZipTerrList,newZipTerrList);
      }

   } // handleTriggerActions
   
   // when the Override Assistant or Override Manager changes on the Zip Territory, send an email to the old and new assistant
   public static Boolean emailOverrideChange(ZipTerritory__c[] oldZipTerrList, ZipTerritory__c[] newZipTerrList) {
      User curUser = [Select Id, Name, Email, Profile.Name from User where Id = :UserInfo.getUserId()];
      
      Set <Id> assistantIdSet = new Set<Id>();
      Set<Id> districtIdSet = new Set<Id>();
      for (ZipTerritory__c zipTerr: oldZipTerrList)
      {     if (zipTerr.OverrideAssistant__c != null)
            assistantIdSet.add(zipTerr.OverrideAssistant__c);
            if (zipTerr.OverrideManager__c != null)
            assistantIdSet.add(zipTerr.OverrideManager__c);
      }
      for (ZipTerritory__c zipTerr: newZipTerrList)
      {     if (zipTerr.OverrideAssistant__c != null)
            assistantIdSet.add(zipTerr.OverrideAssistant__c);
            if (zipTerr.OverrideManager__c != null)
            assistantIdSet.add(zipTerr.OverrideManager__c);
            districtIdSet.add(zipTerr.District__c);
      }
      Map<Id,User> assistantMap = new Map<Id, User>([select Id, Name, Email from User where Id in :assistantIdSet]);
      Map<Id,Org_Unit__c> orgUnitMap = new Map<Id, Org_Unit__c>([select Id, Name, Org_Unit_Name__c from Org_Unit__c where Id in :districtIdSet and Org_Type__c = 'District']);
              
      // prepare and send emails
      List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
      
      for (integer i = 0; i < oldZipTerrList.size(); i++)         
      {   ZipTerritory__c oldZipTerr = oldZipTerrList.get(i);
          ZipTerritory__c newZipTerr = newZipTerrList.get(i);
          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
          mail.setSubject('Zip Territory Override has changed');
              
          String emailBody = '<body>Zip Territory - ' + newZipTerr.Sales_Org__c + '- District '; 
          emailBody += orgUnitMap.get(newZipTerr.District__c).Name + ' - ' + orgUnitMap.get(newZipTerr.District__c).Org_Unit_Name__c + ' - Territory Name ';
          emailBody += newZipTerr.Name +' has changed. <br/>'; 
          emailBody += 'old Override Assistant = '+ (assistantMap.get(oldZipTerr.OverrideAssistant__c) == null ? null : assistantMap.get(oldZipTerr.OverrideAssistant__c).Name)+'<br/>';
          emailBody += 'new Override Assistant = ' + (assistantMap.get(newZipTerr.OverrideAssistant__c) == null ? null : assistantMap.get(newZipTerr.OverrideAssistant__c).Name)+'<br/>';
          emailBody += 'old Override Manager = '+ (assistantMap.get(oldZipTerr.OverrideManager__c) == null ? null : assistantMap.get(oldZipTerr.OverrideManager__c).Name)+'<br/>';
          emailBody += 'new Override Manager = ' + (assistantMap.get(newZipTerr.OverrideManager__c) == null ? null : assistantMap.get(newZipTerr.OverrideManager__c).Name)+'<br/>';
          emailBody += '<br/>Changed by '+ curUser.Name;
          emailBody += '<br/></body>';
          System.debug('**CMF ** emailbody='+emailBody);
          mail.setHtmlBody(emailBody);      
          
          List<String> toAddrList = new List<String>();
          if (assistantMap.get(oldZipTerr.OverrideAssistant__c) != null)
          {   toAddrList.add(assistantMap.get(oldZipTerr.OverrideAssistant__c).Email);  }
          if (assistantMap.get(newZipTerr.OverrideAssistant__c) != null)
          {   toAddrList.add(assistantMap.get(newZipTerr.OverrideAssistant__c).Email);  }
          
          mail.setToAddresses (toAddrList);
          mail.setUseSignature(false);
          mail.setSaveAsActivity(false);
            
          if (!toAddrList.isEmpty()) {
             emailList.add(mail);
          }
      }
            
      if (!emailList.isEmpty()) {
         Messaging.sendEmail (emailList);
      }
    
      return true;
      
   } // emailOverrideChange
   

} // class ZipTerritoryMethods