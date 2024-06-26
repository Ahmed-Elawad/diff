/* 
 * Check attributes of a record and return relevant information about it
 *
 * History
 * -------
   01/15/2019 Dan Carmen     Created
   02/26/2019 Dan Carmen     Change range of 5-9 pilot to 5-19, do a check for virtual user
   04/18/2019 Dan Carmen     Comment out 20-99 code, add code for Inbound 0-19
   05/21/2019 Jake Hinds     Show the banner when lead/contact has 20-49 emps and there's a level 1 mms rep.
   05/31/2019 Jake Hinds     Changing 0-19 to 0-9, commenting out Pilot code
   08/07/2020 Brandon Vidro  36495195 - FY21 - NSS Inbound Banner for Virtual Territory Leads
   07/28/2021 Josh Cartwright APR0121853 - added NSS Inbound Banner  
   04/11/2022 Shilpa Govindarajulu  APR0133856 - NSS Banner for PEO Product of Interest Lead Routing
   06/01/2022 Pujitha Madamanchi APR0122251 GL CPA deatils message on banner.
   09/01/2022 Carrie Marciano  added show_0_9_Banner = false to Veteran Rep Banner criteria
   01/03/2023 Pujitha Madamanchi APR0141981 Ecom Abandned Banner.
   05/01/2023 Pujitha Madamanchi APR0142150 MultiCultural Banner - Look at Traget Audience instead of Product.
   10/27/2023 Vinay   APR0157779  Speed To Lead updates.
   01/18/2024 Pujitha Madamanchi   Remove all commented code.
   01/18/2024 Pujitha Madamanchi   APR0158354  Strategic Accounts/MMS/PEO Banners.
   05/10/2024 Pujitha Madamanchi   Ecom Backend banners
*/
public with sharing class CheckRecordAura {
      
   public static Map<String, String> bannerNameMessageMap = new Map <String, String>();
   public static Map<String, Decimal> bannerNameEmpMin = new Map<String, Decimal>();
   public static Map<String, Decimal> bannerNameEmpMax = new Map<String, Decimal>();
   public static Map<String, Boolean> bannerActive = new Map<String, Boolean>();
   public static Map<STring, Virtual_Banner_Settings__c> bannerMap = new Map<STring, Virtual_Banner_Settings__c>();
    
   @AuraEnabled
   public static String[] getRecordMsgs(Id recId) {
      System.debug('getRecordMsgs recId='+recId);
      String[] msgs = new String[]{};
      if (recId != null) {
         if (recId.getSobjectType() == Schema.Lead.SObjectType) {
            msgs = checkLeadMsgs(recId);
         } else if (recId.getSobjectType() == Schema.Contact.SObjectType) {
            msgs = checkCtctMsgs(recId);
         } else if (recId.getSobjectType() == Schema.Account.SObjectType) {
            msgs = checkAcctMsgs(recId,null);
         }
      } // if (recId != null
      System.debug('getRecordMsgs msgs='+(msgs != null ? msgs.size() : -1));
      return msgs;
   } // getRecordMsgs
   
   @AuraEnabled
   public static CheckRecordMsg[] getRecordMsgs2(Id recId) {
      String[] msgs = getRecordMsgs(recId);
      CheckRecordMsg[] msgs2 = new CheckRecordMsg[]{};
      for (String msg : msgs) {
         CheckRecordMsg newMsg = new CheckRecordMsg('','Record Msg','color:red; font-weight:bold; font-size:16px', msg);
         msgs2.add(newMsg);
      }
      return msgs2;
   } // getRecordMsgs2   
    
   public static String VIRTUAL_SEG_NAME='Channel';
   
   public static String[] checkLeadMsgs(Id recId) {
      String[] msgs = new String[]{};
      Boolean usrIsInbound = isUserInbound(UserHelper.getRunningUser());
      Boolean show_0_9_Banner = true;
      List<String> lstZipSegName = new List<String>();
      List<String> lstSendtoVirtual = new List<String>();
      List<String> lstSalesDivision = new List<String>();
       
      List<Virtual_Banner_Settings__c> vbs = new List<Virtual_Banner_Settings__c>();
       
      vbs = Virtual_Banner_Settings__c.getall().values();
       
      for (Virtual_Banner_Settings__c vb : vbs) {
            bannerNameMessageMap.put(vb.Name, vb.Message__c);
            bannerNameEmpMin.put(vb.Name, vb.Employee_Count_Min__c);
            bannerNameEmpMax.put(vb.Name, vb.Employee_Count_Max__c);
            bannerActive.put(vb.Name, vb.Active__c);
            bannerMap.put(vb.Name,vb);
      }

      // select into a list so you don't need a try/catch
         Lead[] leads = [Select Id, Name, NumberOfEmployees, PostalCode,Hispanic_Ownership__c,CSSR_Segment__c,X401K_Assets__c,Current_Prior_Method__c,Products__c,
                         LatestCampaign__c,LatestCampaign__r.Product__c, LatestCampaign__r.Target_Audience__c, LatestCampaign__r.Send_To_Virtual__c,
                         Scheduled_Appt_Date_Time__c, Referral_National_Account__c
                         from Lead where Id=:recId];
      Lead checkLd = (!leads.isEmpty() ? leads[0] : null);
      String postalCode = (checkLd != null ? LeadCheckOwner.getZipCode(checkLd.PostalCode) : null);

      Virtual_Banner_Settings__c vb = Virtual_Banner_Settings__c.getInstance('Veteran Rep Banner');
       system.debug('jc active?'+vb.Active__c); 
      if (vb != null && vb.Active__c) {
          //system.debug('inside nss inbound banner'); 
         if (checkLd.NumberOfEmployees != null && usrIsInbound
             && checkLd.NumberOfEmployees >= vb.Employee_Count_Min__c
             && checkLd.NumberOfEmployees <= vb.Employee_Count_Max__c
             && String.isNotBlank(postalCode)) {
             //    system.debug('inside if statement'); 
            Set<String> zipSet = new Set<String>{postalCode};
           // Map<String,List<Zip_Assignment__c>> zipListMap = ZipQueries.getZipAsgnMap(zipSet, false);
           ZipWrapper zipAssignmentMap = ZipCodeLookupController.getZipAssignment(postalCode,'PAY',null,'Channel');
           //system.debug('jc zipAssignmentMap ' + zipAssignmentMap); 
            
           Zip_Assignment__c za = (zipAssignmentMap != null ? zipAssignmentMap.za : null);
           system.debug('checkLeadMsgs za='+(za != null ? za.user__c+' za.User__r.Selling_Start_Date__c='+ za.User__r.Selling_Start_Date__c+'isUserVirtual='+isUserVirtual(za.User__r) : 'za not found'));

            Date dateToCheck = vb.DateToCheck__c;
            Boolean userIsVirtual = (za != null && za.User__c != null && isUserVirtual(za.User__r));
            Boolean dateCheckOkay = (za != null && za.User__c != null && za.User__r.Selling_Start_Date__c != null && za.User__r.Selling_Start_Date__c <= dateToCheck);
            system.debug('checkLeadMsgs dateToCheck='+dateToCheck+' dateCheckOkay='+dateCheckOkay+' userIsVirtual='+userIsVirtual);
                
            if (dateCheckOkay && !userIsVirtual) {
                show_0_9_Banner = false;
                msgs.add(vb.Message__c);
            }
         }
      } // if (vb != null && vb.Active__c
       if(bannerActive.get('Strategic Account') && usrIsInbound && checkLd!=null && checkLd.Referral_National_Account__c!=null){
            msgs.add(bannerNameMessageMap.get('Strategic Account'));
       }

       if (bannerActive.get('Multi-Cultural Banner') && usrIsInbound && checkLd != null
           && checkLd.NumberOfEmployees >= bannerNameEmpMin.get('Multi-Cultural Banner')
           && checkLd.NumberOfEmployees <= bannerNameEmpMax.get('Multi-Cultural Banner')
           && String.isNotBlank(postalCode)) {
               Set<String> zipSet = new Set<String>{postalCode};
               lstZipSegName = bannerMap.get('Multi-Cultural Banner').Zip_Segment_Name__c != null ? bannerMap.get('Multi-Cultural Banner').Zip_Segment_Name__c.split(';') : null;
               lstSendtoVirtual = bannerMap.get('Multi-Cultural Banner').Send_to_Virtual__c != null ? bannerMap.get('Multi-Cultural Banner').Send_to_Virtual__c.split(';') : null;
               List<Zip_Assignment__c> zipAssignments = [Select Id, Name, Zip_Segment__r.Name from Zip_Assignment__c where Name in :zipSet];
            //   List<CampaignMember> cms = [Select CampaignID, LeadID FROM CampaignMember WHERE LeadID = :checkLd.Id LIMIT 1];
            //   if(cms != null && !cms.isEmpty()){
              //     Campaign cp = [Select Id, Send_To_Virtual__c,Target_Audience__c from Campaign where Id = :cms.get(0).CampaignID];
                   for(Zip_Assignment__c zip: zipAssignments) {
                         //if(zip.Zip_Segment__r != null && lstZipSegName != null && lstZipSegName.contains(zip.Zip_Segment__r.Name) && ((cp != null && lstSendtoVirtual != null && lstSendtoVirtual.contains(cp.Send_To_Virtual__c)) || (checkLd.LatestCampaign__c != null && checkLd.LatestCampaign__r.Product__c != null && checkLd.LatestCampaign__r.Product__c.contains('MultiCultural')))) {
                         if(zip.Zip_Segment__r != null && lstZipSegName != null && lstZipSegName.contains(zip.Zip_Segment__r.Name) && ((checkLd.LatestCampaign__c!= null && lstSendtoVirtual != null && lstSendtoVirtual.contains(checkLd.LatestCampaign__r.Send_To_Virtual__c)) || (checkLd.LatestCampaign__c != null && checkLd.LatestCampaign__r.Target_Audience__c != null && checkLd.LatestCampaign__r.Target_Audience__c.contains('Multi-Cultural')))) {
                           show_0_9_Banner = false;
                           msgs.add(bannerNameMessageMap.get('Multi-Cultural Banner'));
                           break;
                       }
                   }
              // }
           }
       
       if (bannerActive.get('Virtual Channel Banner') && usrIsInbound && checkLd != null
           && checkLd.NumberOfEmployees >= bannerNameEmpMin.get('Virtual Channel Banner')
           && checkLd.NumberOfEmployees <= bannerNameEmpMax.get('Virtual Channel Banner')
           && String.isNotBlank(postalCode)) {
               Set<String> zipSet = new Set<String>{postalCode};
               lstSalesDivision = bannerMap.get('Virtual Channel Banner').Sales_Division__c != null ? bannerMap.get('Virtual Channel Banner').Sales_Division__c.split(';') : null;
               List<Zip_Assignment__c> zipAssignmentsUsers = [Select Id, Name, User__r.Sales_Division__c from Zip_Assignment__c where Name in :zipSet]; 
               for(Zip_Assignment__c zip: zipAssignmentsUsers) {
                   if(zip.User__r != null && lstSalesDivision != null && lstSalesDivision.contains(zip.User__r.Sales_Division__c)){
                       show_0_9_Banner = false;
                       msgs.add(bannerNameMessageMap.get('Virtual Channel Banner'));
                       break;
                   }
               }
           }
       
       if (bannerActive.get('NSS PEO Product Banner') && usrIsInbound && checkLd != null
            && checkLd.NumberOfEmployees >= bannerNameEmpMin.get('NSS PEO Product Banner')
            && ((checkLd.Current_Prior_Method__c != null && checkLd.Current_Prior_Method__c.contains('PEO')) || (checkLd.Products__c != null && checkLd.Products__c.contains('PEO')) || (checkLd.LatestCampaign__c != null && checkLd.LatestCampaign__r.Product__c != null && checkLd.LatestCampaign__r.Product__c.contains('PEO')))){
                show_0_9_Banner = false;
                msgs.add(bannerNameMessageMap.get('NSS PEO Product Banner'));       
        }
       
       if (bannerActive.get('Inbound Banner') && usrIsInbound && checkLd != null
           && checkLd.NumberOfEmployees >= bannerNameEmpMin.get('Inbound Banner')
           && checkLd.NumberOfEmployees <= bannerNameEmpMax.get('Inbound Banner') && show_0_9_Banner) {
               msgs.add(bannerNameMessageMap.get('Inbound Banner'));
           }
       
      if (bannerActive.get('MMS Level 1 Banner') && checkLd != null && usrIsInbound
             && checkLd.NumberOfEmployees >= bannerNameEmpMin.get('MMS Level 1 Banner')
             && checkLd.NumberOfEmployees <= bannerNameEmpMax.get('MMS Level 1 Banner')
             && String.isNotBlank(postalCode)) {
         Set<String> zipSet = new Set<String>{postalCode};
         Map<String,List<Zip_Assignment__c>> zipListMap = ZipQueries.getZipAsgnMap(zipSet, false);
         Zip_Assignment__c za = LeadCheckOwner.getZa(zipListMap.get(postalCode), UserHelper.SO_MMS, checkLd.NumberOfEmployees, RecordTypeHelper.MMS_LEAD);
         system.debug('CheckRecordAura checkAcctMsgs za'+za);
         // TODO - check NSS_Team__c
         if (za != null && za.User__c != null && !isUserVirtual(za.User__r) && 
            (String.isBlank(za.ZipTerritory__r.Rep_Name__c) || !za.ZipTerritory__r.Rep_Name__c.contains('Unassigned') && !za.ZipTerritory__r.Rep_Name__c.contains('Unknown'))) {
            msgs.add(bannerNameMessageMap.get('MMS Level 1 Banner'));
         }
      }
      if(bannerActive.get('GL CPA') && usrIsInbound && checkLd != null){
            Marketing_Call_Tracking__c[] mct = [Select Id,gl_Accounting_Professional__c
                                                    ,gl_CPA_Company_Name__c
                                                    ,gl_CPA_Email__c
                                                    ,gl_CPA_First_Name__c
                                                    ,gl_CPA_Last_Name__c
                                                    ,gl_CPA_Phone__c
                                                    ,gl_CPA_Processing_On_Your_Behalf__c
                                                    ,gl_Current_Client__c
                                                    ,gl_Submit_on_behalf_of_Client__c
                                                    ,gl_CPA_ZIP_Code__c
                                                FROM Marketing_Call_Tracking__c 
                                                WHERE Lead__c=:recId 
                                                    AND gl_Current_Client__c='Yes'
                                                    AND gl_Accounting_Professional__c='No'
                                                    AND gl_CPA_Processing_On_Your_Behalf__c='Yes' LIMIT 1];
          if(mct.size() > 0){
                Marketing_Call_Tracking__c chkMCT = (!mct.isEmpty() ? mct[0] : null);
                String formMsg = bannerNameMessageMap.get('GL CPA') + ': ' 
                                        + chkMCT.gl_CPA_First_Name__c + ' ' + chkMCT.gl_CPA_Last_Name__c + ', ' 
                                        + chkMCT.gl_CPA_Company_Name__c+', ' + chkMCT.gl_CPA_Phone__c + ', ' 
                                        + chkMCT.gl_CPA_Email__c + ', ' + chkMCT.gl_CPA_ZIP_Code__c;
                msgs.add(formMsg);           

            }

      }
     
     if(bannerActive.get('Ecom Abandon') && usrIsInbound && checkLd != null
         && checkLd.LatestCampaign__c!=null){
             if(checkLd.LatestCampaign__c == bannerMap.get('Ecom Abandon').Campaign_Id__c){
                msgs.add(bannerNameMessageMap.get('Ecom Abandon')); 
                system.debug(msgs);  
              }   
       } 
        // 10/27/2023 - Vinay - APR0157779
        if ((usrIsInbound || isUserVirtual(UserHelper.getRunningUser())) && checkLd!=null && bannerActive.get('Speed To Lead') && checkLd.Scheduled_Appt_Date_Time__c != null) {
            msgs.add(bannerNameMessageMap.get('Speed To Lead'));
        }
        return msgs;
     } // checkLeadMsgs
   
   public static Boolean isUserVirtual(User usr) {
      return (usr != null && usr.NSS_Team__c != null && usr.NSS_Team__c == 'VS PAY');
   } // isUserVirtual
   
   public static String[] checkCtctMsgs(Id recId) {
      Contact[] ctcts = [Select Id
                               ,AccountId
                               ,Products__c
                           ,Scheduled_Appt_Date_Time__c
                               ,LatestCampaign__c
                               ,LatestCampaign__r.Product__c
                               ,Account.Type
                               ,Active_Sales_Play__c
                               //,Account.Id
                               //,Account.Name
                               //,Account.NumberOfEmployees
                               //,Account.OwnerId
                               //,Account.Owner.Id
                               //,Account.Owner.Hire_Date__c
                               //,Account.Owner.Name
                               //,Account.Owner.NSS_Team__c
                               //,Account.Owner_Zip_Code__c
                           From Contact
                          Where Id = :recId];
      Contact checkCtct = (!ctcts.isEmpty() ? ctcts[0] : null);
      return (checkCtct != null ? checkAcctMsgs(checkCtct.AccountId,checkCtct) : new String[]{});
      //return checkCtctMsgs(checkCtct);
   } // checkCtctMsgs
   
   public static String[] checkAcctMsgs(Id recId, Contact ctct) {
      Account[] accts = [Select Id
                               ,Type
                               ,Name
                               ,LostClient__c
                               ,NumberOfEmployees
                               ,OwnerId
                               ,Owner.Id
                               ,Owner.Hire_Date__c
                               ,Owner.Name
                               ,Owner.NSS_Team__c
                               ,Owner_Zip_Code__c
                               ,X401K_Assets__c
                           ,X401_k__c
                           ,Clientfor6Months__c
                               ,Hispanic_Ownership__c
                               ,CSSR_Segment__c
                               ,CurrentClient__c
                               ,Current_Prior_Method__c
                               ,Ethnicity__c
                           ,Referral_National_Account__c
                           ,Active_Sales_Play__c
                               ,SignificantContact__c
                               ,SignificantContact__r.Products__c
                               ,SignificantContact__r.LatestCampaign__c
                               ,SignificantContact__r.LatestCampaign__r.Product__c
                           ,SignificantContact__r.Scheduled_Appt_Date_Time__c
                               ,(Select id,Products__c,LatestCampaign__c,LatestCampaign__r.Product__c,LastModifiedDate, Scheduled_Appt_Date_Time__c, Active_Sales_Play__c from Contacts where AccountId=:recId order by LastModifiedDate desc limit 1)
                           From Account
                          Where Id = :recId];
        System.debug('checkAcctMsgs accts='+accts);
      Account checkAcct = (!accts.isEmpty() ? accts[0] : null);
        System.debug('significant ctct:'+checkAcct.SignificantContact__c);
      Contact checkCtCt = ctct != null ? ctct : checkAcct.SignificantContact__r!=null ? checkAcct.SignificantContact__r : (checkAcct.Contacts != null && !checkAcct.Contacts.isEmpty()) ? checkAcct.Contacts[0] : null;
      return checkAcctMsgs(checkAcct,checkCtCt);
   } // checkAcctMsgs

   public static String[] checkAcctMsgs(Account acct,Contact ctct) {
      String[] msgs = new String[]{};
      List<String> lstZipSegName = new List<String>();
      List<String> lstSendtoVirtual = new List<String>();
      List<String> lstEthnicity = new List<String>();
      List<CampaignMember> cms = new List<CampaignMember>();
      Boolean usrIsInbound = isUserInbound(UserHelper.getRunningUser());
      System.debug('checkAcctMsgs usrIsInbound='+usrIsInbound);
      String postalCode = (acct != null ? LeadCheckOwner.getZipCode(acct.Owner_Zip_Code__c) : null);
       
       List<Virtual_Banner_Settings__c> vbs = new List<Virtual_Banner_Settings__c>();
       
       vbs = Virtual_Banner_Settings__c.getall().values();
       
       for (Virtual_Banner_Settings__c vb : vbs) {
           bannerNameMessageMap.put(vb.Name, vb.Message__c);
           bannerNameEmpMin.put(vb.Name, vb.Employee_Count_Min__c);
           bannerNameEmpMax.put(vb.Name, vb.Employee_Count_Max__c);
           bannerActive.put(vb.Name, vb.Active__c);
           bannerMap.put(vb.Name,vb);
       }
      Boolean show_0_9_Banner = true;

      Virtual_Banner_Settings__c vb = Virtual_Banner_Settings__c.getInstance('Veteran Rep Banner');
      if (vb != null && vb.Active__c) {
         if (acct.NumberOfEmployees != null && usrIsInbound
             && acct.NumberOfEmployees >= vb.Employee_Count_Min__c
             && acct.NumberOfEmployees <= vb.Employee_Count_Max__c
             && String.isNotBlank(postalCode)) {
            Set<String> zipSet = new Set<String>{postalCode};
            Map<String,List<Zip_Assignment__c>> zipListMap = ZipQueries.getZipAsgnMap(zipSet, false);
                     ZipWrapper zipAssignmentMap;
                 zipAssignmentMap = ZipCodeLookupController.getZipAssignment(postalCode,'PAY', acct,'Channel');
                 Zip_Assignment__c za = zipAssignmentMap.za;

           // Zip_Assignment__c za = LeadCheckOwner.getZa(zipListMap.get(postalCode), UserHelper.SO_CORE, acct.NumberOfEmployees, RecordTypeHelper.CORE_LEAD);
            Date dateToCheck = vb.DateToCheck__c;
            if (za != null && za.User__c != null && za.User__r.Selling_Start_Date__c != null && za.User__r.Selling_Start_Date__c <= dateToCheck && !isUserVirtual(za.User__r)) {
                show_0_9_Banner = false;
                msgs.add(vb.Message__c);
            }
         }
      } // if (vb != null && vb.Active__c
       
        if(bannerActive.get('Strategic Account') && usrIsInbound && acct!=null && acct.Referral_National_Account__c!=null){
            msgs.add(bannerNameMessageMap.get('Strategic Account'));
        }
      
       if (bannerActive.get('Multi-Cultural Banner') && usrIsInbound && acct != null
            && acct.NumberOfEmployees >= bannerNameEmpMin.get('Multi-Cultural Banner')
            && acct.NumberOfEmployees <= bannerNameEmpMax.get('Multi-Cultural Banner')
            && String.isNotBlank(postalCode)) {
                Set<String> zipSet = new Set<String>{postalCode};
                Campaign cp;
                lstZipSegName = bannerMap.get('Multi-Cultural Banner').Zip_Segment_Name__c != null ? bannerMap.get('Multi-Cultural Banner').Zip_Segment_Name__c.split(';') : null;
                lstSendtoVirtual = bannerMap.get('Multi-Cultural Banner').Send_to_Virtual__c != null ? bannerMap.get('Multi-Cultural Banner').Send_to_Virtual__c.split(';') : null;
                lstEthnicity = bannerMap.get('Multi-Cultural Banner').Ethnicity__c != null ? bannerMap.get('Multi-Cultural Banner').Ethnicity__c.split(';') : null;
                List<Zip_Assignment__c> zipAssignments = [Select Id, Name, Zip_Segment__r.Name from Zip_Assignment__c where Name in :zipSet];
                if(ctct != null){
                    cms = [Select CampaignID, ContactID FROM CampaignMember WHERE ContactID = :ctct.Id LIMIT 1];
                }
                if(cms != null && !cms.isEmpty()){
                    cp = [Select Id, Send_To_Virtual__c from Campaign where Id = :cms.get(0).CampaignID];
                }
                for(Zip_Assignment__c zip: zipAssignments) {
                    if(zip.Zip_Segment__r != null && lstZipSegName != null && lstZipSegName.contains(zip.Zip_Segment__r.Name) && ((cp != null && lstSendtoVirtual != null && lstSendtoVirtual.contains(cp.Send_To_Virtual__c)) || (ctct != null && ctct.LatestCampaign__c != null && ctct.LatestCampaign__r.Product__c != null && ctct.LatestCampaign__r.Product__c.contains('MultiCultural')) || (lstEthnicity != null && acct.Ethnicity__c != null && lstEthnicity.contains(acct.Ethnicity__c)))) {
                        show_0_9_Banner = false;
                        msgs.add(bannerNameMessageMap.get('Multi-Cultural Banner'));
                    }
                }
            } 
       
      //NSS PEO Banner
      if (bannerActive.get('NSS PEO Product Banner') && usrIsInbound && acct != null
            && acct.NumberOfEmployees >= bannerNameEmpMin.get('NSS PEO Product Banner')
            && acct.CurrentClient__c != true
            && ((acct.Current_Prior_Method__c != null && acct.Current_Prior_Method__c.contains('PEO')) || (ctct != null && ctct.Products__c != null && ctct.Products__c.contains('PEO')) || (ctct != null && ctct.LatestCampaign__c != null && ctct.LatestCampaign__r.Product__c != null && ctct.LatestCampaign__r.Product__c.contains('PEO')))){
                show_0_9_Banner = false;
                msgs.add(bannerNameMessageMap.get('NSS PEO Product Banner'));       
        }
       
       if (bannerActive.get('Inbound Banner') && usrIsInbound && acct != null
           && acct.NumberOfEmployees >= bannerNameEmpMin.get('Inbound Banner')
           && acct.NumberOfEmployees <= bannerNameEmpMax.get('Inbound Banner') && show_0_9_Banner) {
               msgs.add(bannerNameMessageMap.get('Inbound Banner'));
           }
      
      system.debug('CheckRecordAura checkAcctMsgs in here');
      if (bannerActive.get('MMS Level 1 Banner') && acct != null && usrIsInbound
             && acct.NumberOfEmployees >= bannerNameEmpMin.get('MMS Level 1 Banner')
             && acct.NumberOfEmployees <= bannerNameEmpMax.get('MMS Level 1 Banner')
             && String.isNotBlank(postalCode)) {
         system.debug('CheckRecordAura checkAcctMsgs record meets criteria');
         Set<String> zipSet = new Set<String>{postalCode};
         Map<String,List<Zip_Assignment__c>> zipListMap = ZipQueries.getZipAsgnMap(zipSet, false);
         Zip_Assignment__c za = LeadCheckOwner.getZa(zipListMap.get(postalCode), UserHelper.SO_MMS, acct.NumberOfEmployees, RecordTypeHelper.MMS_LEAD);
         system.debug('CheckRecordAura checkAcctMsgs za'+za+' rep name: '+za.Rep_Name__c);
         // TODO - check NSS_Team__c
         if (za != null && za.User__c != null && !isUserVirtual(za.User__r) && 
            (String.isBlank(za.ZipTerritory__r.Rep_Name__c) || !za.ZipTerritory__r.Rep_Name__c.contains('Unassigned') && !za.ZipTerritory__r.Rep_Name__c.contains('Unknown'))) {
            msgs.add(bannerNameMessageMap.get('MMS Level 1 Banner'));
         }
      }
        // 10/27/2023 - Vinay - APR0157779
	  if ((usrIsInbound || isUserVirtual(UserHelper.getRunningUser())) && bannerActive.get('Speed To Lead') && ctct.Scheduled_Appt_Date_Time__c != null) {
            msgs.add(bannerNameMessageMap.get('Speed To Lead'));
        }
	
        if (bannerActive.get('PEO Sales Play') && acct.Active_Sales_Play__c!=null && acct.Active_Sales_Play__c.contains('PEO') && usrIsInbound) {
            String formMsg = bannerNameMessageMap.get('PEO Sales Play') + ' ' + acct.Active_Sales_Play__c + '.' 
                + ' Please use PEO Override as the referral partner you select and assign this lead to' + ' ' +acct.Owner.Name + '.' + ' Uncheck Integrated Selling.';
            msgs.add(formMsg);
        }
        
        if (bannerActive.get('MMS Sales Play') && acct.Active_Sales_Play__c!=null && acct.Active_Sales_Play__c.contains('MMS') && usrIsInbound) {
            String formMsg = bannerNameMessageMap.get('MMS Sales Play') + ' ' + acct.Active_Sales_Play__c + '.' 
                + ' Please use MMS Override as the referral partner you select and assign this lead to' + ' ' +acct.Owner.Name + '.' + ' Uncheck Integrated Selling.';
            msgs.add(formMsg);
        }
         System.debug('Ecom Backend');
        if(bannerActive.get('Ecom Backend') && usrIsInbound && ctct!=null && ctct.LatestCampaign__c!=null){
            System.debug('Ecom Backend');
            if(bannerMap.get('Ecom Backend').Campaign_Id__c == ctct.LatestCampaign__c){
                msgs.add(bannerNameMessageMap.get('Ecom Backend')); 
                system.debug('Ecom Backend'+msgs);  
            }   
        } 
      return msgs;
   } // checkAcctMsgs
   
   public static Boolean overrideInbound = Label.CheckRecordAura_OverrideInbound == 'Y';
   
   public static Boolean isUserInbound(User usr) {
      String nssSource = ProspectOwnershipMethods.getNSS_Source(usr);
      return (overrideInbound || (String.isNotBlank(nssSource) && (nssSource == ProspectOwnershipMethods.NSS_INBOUND)));
   } // isUserInbound
   
   
} // class CheckRecordAura