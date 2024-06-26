/* Methods for the PC_Quote_Data__c object

 * History
 * -------
  12/14/2022 Carrie Marciano	Created

*/

public class PCQuoteDataMethods implements TriggerInterfaceC {
    public static final String CLASSNAME='PCQuoteData';
   	public static Boolean SKIP_TRIGGER=false;
    
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug('PCQuoteData.handleTrigger SKIP_TRIGGER='+SKIP_TRIGGER+' recs='+recs.size()+' isBefore='+isBefore+' isAfter='+isAfter);
      	if (SKIP_TRIGGER) {
            return;
      	}
      	SObjectType objType = null;
     	if (recs != null && !recs.isEmpty()) {
            objType = recs[0].getSObjectType();
      	}
      	System.debug('PCQuoteData.handleTrigger objType='+objType);
        
        if (isAfter) {
            if (objType == PC_Quote_Data__c.sObjectType) {
                System.debug('PCQuoteData.handleTrigger isAfter both insert and update');
            	handlePCQuoteDataAfter((PC_Quote_Data__c[])recs, (Map<Id,PC_Quote_Data__c>)oldMap);
            }
            
            if (Trigger.isInsert){
                System.debug('PCQuoteData.handleTrigger isInsert');
            	handleOrphanTarmikaQuote((PC_Quote_Data__c[])recs);                
            }
            
      	} // if (isAfter        
	}
    
    public static void handleOrphanTarmikaQuote (PC_Quote_Data__c[] recs){
        System.debug('handleOrphanTarmikaQuote inside');
    	map<Id,PC_Quote_Data__c> pcqNeedingOpp = new map<Id,PC_Quote_Data__c>();
        map<String,PC_Quote_Data__c> pcqAgent = new map<String,PC_Quote_Data__c>();
        map<String,User> emailWithUser = new map<String,User>();
        
        for (PC_Quote_Data__c newRec : recs){
        	if (newRec.Opportunity__c == null){
            	pcqNeedingOpp.put(newRec.Id,newRec);
                pcqAgent.put(newRec.Agent_Name__c,newRec);
        	}    
        }
        System.debug('handleOrphanTarmikaQuote pcqNeedingOpp: '+pcqNeedingOpp.Size());
        System.debug('handleOrphanTarmikaQuote pcqAgent: '+pcqAgent.Size());
        User[] pcqUsers = [Select Id, Name, Email, isActive, Profile.UserLicense.Name from User Where Email in :pcqAgent.keySet() and isActive=True and Profile.UserLicense.Name = 'Salesforce'];
        for (User pcqUser : pcqUsers){
            emailWithUser.put(pcqUser.Email,pcqUser);
        }
        System.debug('handleOrphanTarmikaQuote emailWithUser: '+emailWithUser.Size());
        if(!emailWithUser.isEmpty() && !pcqNeedingOpp.isEmpty()){
           System.debug('handleOrphanTarmikaQuote before sendCreateOpptyChatterNotifications');
           sendCreateOpptyChatterNotifications(pcqNeedingOpp, emailWithUser); 
           System.debug('handleOrphanTarmikaQuote after sendCreateOpptyChatterNotifications');
        }
    }
    
    public static void sendCreateOpptyChatterNotifications(map<Id,PC_Quote_Data__c> pcqNeedingOpp, map<String,User> emailWithUser) { 
        System.debug('sendCreateOpptyChatterNotifications inside');
        List<PC_Quote_Data__C> pcQuoteChatters = [Select Id, Agent_Name__c, Tarmika_Request_Number__c, Prospect_Client_Name__c, Contact_First_Name__c, 
                                                  Contact_Last_Name__c, Contact_Phone_Number__c, Carrier_1_Line_of_Business__c 
                                                  from PC_Quote_Data__c where Id IN :pcqNeedingOpp.keySet()];
        List<Id> usersToMention = new List<Id>();
        String postText = '';
        for(PC_Quote_Data__c pcQuoteChatter : pcQuoteChatters){
            User userToChatter = emailWithUser.get(pcQuoteChatter.Agent_Name__c);
            usersToMention.add(userToChatter.Id);
            //postText = 'Hello '+userToChatter.Name+' \n';
            postText = 'Quote #'+pcQuoteChatter.Tarmika_Request_Number__c+' was created in Tarmika. This quote is not currently linked to an opportunity and we need your help linking it to the proper opportunity. \n\n';
            postText += 'Please find or create the opportunity that should be associated with this quote submission. Once you have confirmed the opportunity exists click '+URL.getSalesforceBaseUrl().toExternalForm()+'/'+pcQuoteChatter.Id+' and find the Opportunity field. Search for your opportunity name that relates the this quote in the opportunity field, select the opportunity and then please select save. \n\n';
            postText += 'Quote Submission Details: \n';
            postText += 'Company Name: '+pcQuoteChatter.Prospect_Client_Name__c+' \n';
            postText += 'Contact Name: '+pcQuoteChatter.Contact_First_Name__c+' '+pcQuoteChatter.Contact_Last_Name__c+' \n';
            postText += 'Contact Phone: '+pcQuoteChatter.Contact_Phone_Number__c+' \n';
            postText += 'Quote Line of Business: '+pcQuoteChatter.Carrier_1_Line_of_Business__c+' \n';
            ChatterMentionPost.createChatterMentionPost(pcQuoteChatter.Id, usersToMention, new String[]{postText}, True);
            usersToMention.clear();
   			System.debug('sendCreateOpptyChatterNotifications postText: '+postText);
        }
    }
    
    public static void handlePCQuoteDataAfter(PC_Quote_Data__c[] recs, Map<Id,PC_Quote_Data__c> oldMap) {
    	List<PC_Quote_Data__c> updatePCQuote = new List<PC_Quote_Data__c>();
    	map<Id,PC_Quote_Data__c> pcqOppsToUpdate = new map<Id,PC_Quote_Data__c>();
        map<Id,PC_Quote_Data__c> pcqAcctFEINToUpdate = new map<Id,PC_Quote_Data__c>();
        map<Id,PC_Quote_Data__c> pcqAcctToUpdate = new map<Id,PC_Quote_Data__c>();
    
    	for (PC_Quote_Data__c newRec : recs){
            PC_Quote_Data__c oldRec = (oldMap != null ? oldMap.get(newRec.Id) : null);
        	if (Trigger.isAfter){
            	if (newRec.Opportunity__c != null && newRec.Tarmika_Request_Number__c != null){
                    if (newRec.Carrier_1_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_1_Quote_Status__c != oldRec.Carrier_1_Quote_Status__c)){
                        pcqOppsToUpdate.put(newRec.Opportunity__c,newRec); 
                    } else if(newRec.Carrier_2_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_2_Quote_Status__c != oldRec.Carrier_2_Quote_Status__c)){
                        pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    } else if(newRec.Carrier_3_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_3_Quote_Status__c != oldRec.Carrier_3_Quote_Status__c)){
                    	pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    } else if(newRec.Carrier_4_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_4_Quote_Status__c != oldRec.Carrier_4_Quote_Status__c)){
                        pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                	} else if(newRec.Carrier_5_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_5_Quote_Status__c != oldRec.Carrier_5_Quote_Status__c)){
                    	pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    } else if(newRec.Carrier_6_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_6_Quote_Status__c != oldRec.Carrier_6_Quote_Status__c)){
                        pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    } else if(newRec.Carrier_7_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_7_Quote_Status__c != oldRec.Carrier_7_Quote_Status__c)){
                        pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    } else if(newRec.Carrier_8_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_8_Quote_Status__c != oldRec.Carrier_8_Quote_Status__c)){
                        pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    } else if(newRec.Carrier_9_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_9_Quote_Status__c != oldRec.Carrier_9_Quote_Status__c)){
                        pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    } else if(newRec.Carrier_10_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_10_Quote_Status__c != oldRec.Carrier_10_Quote_Status__c)){
                        pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    } else if(newRec.Carrier_11_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_11_Quote_Status__c != oldRec.Carrier_11_Quote_Status__c)){
                        pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    } else if(newRec.Carrier_12_Quote_Status__c == 'Quoted' && (oldRec == null || newRec.Carrier_12_Quote_Status__c != oldRec.Carrier_12_Quote_Status__c)){    
            			pcqOppsToUpdate.put(newRec.Opportunity__c,newRec);
                    }                    
        		}// newRec.Opportunity__c != null  
                
                if (newRec.Prospect_Client__c != null && newRec.Tarmika_Request_Number__c != null){
                    if((newRec.FEIN_Number__c != null && (oldRec == null || newRec.FEIN_Number__c != oldRec.FEIN_Number__c)) || 
                       (newRec.Organization_Type__c != null && (oldRec == null || newRec.Organization_Type__c != oldRec.Organization_Type__c)) ||
                       (newRec.NAICS_Code__c != null && (oldRec == null || newRec.NAICS_Code__c != oldRec.NAICS_Code__c))){
                        pcqAcctToUpdate.put(newRec.Prospect_Client__c,newRec);   
                    }
                    
                }
    		}//Trigger.isAfter
        }//for
    	
        if(!pcqOppsToUpdate.isEmpty()){
            system.debug('handlePCQuoteDataAfter pcqOppsToUpdate: '+pcqOppsToUpdate.size());
        	updateOpps(pcqOppsToUpdate);
    	}
        
        if(!pcqAcctToUpdate.isEmpty()){
            system.debug('handlePCQuoteDataAfter pcqAcctToUpdate: '+pcqAcctToUpdate.size());
        	updateAccts(pcqAcctToUpdate);
    	}

	} // handlePCQuoteDataAfter
    
    public static void updateOpps(Map<Id,PC_Quote_Data__c> oppsMap){
    	//query opportunity fields
    	Opportunity[] pcqOpps = [Select Id, Name, StageName, Probability from Opportunity Where ID in :oppsMap.keySet()];
        system.debug('updateOpps pcqOpps: '+pcqOpps.size());
        
       	//set stage to proposal for these opportunities
       	Opportunity[] uOpps = new Opportunity[]{};
        for(Opportunity pcqOpp : pcqOpps){
            if (pcqOpp.Probability < 50){
                pcqOpp.Probability = 50;
                pcqOpp.StageName = 'Proposal';
                system.debug('updateOpps set Probability to 50%');
                uOpps.add(pcqOpp);               
            }
        }
        
       	//update oppty 
       	if (!uOpps.isEmpty()) {
            SKIP_TRIGGER=true;
            DmlHelper.performDML2(uOpps, DmlHelper.DML_UPDATE, 'PCQuoteDataMethods', 'updateOpps', 'Update Stage', true);
            SKIP_TRIGGER=false;
            system.debug('updateOpps after update opps');
      	}   
    }
    
    public static void updateAccts(Map<Id,PC_Quote_Data__c> acctsMap){
    	//query account fields
    	Account[] pcqAccts = [Select Id, Name, Type, ClientRegistrationStatus__c, Paychex_CEID__c, Paychex_CAID__c, Federal_ID_Number__c, NAICS_Code__c, Organization_Type__c 
                              from Account Where ID in :acctsMap.keySet()];
        system.debug('updateAccts pcqAccts: '+pcqAccts.size());
        
        //determine if prospect or client - FEIN only on prospects
        //set fields to value from Tarmika - Organization Type and NAICS(only take first 6 char)
        Account[] uAccts = new Account[]{};
        for (Account pcqAcct : pcqAccts){
            PC_Quote_Data__c pcq = acctsMap.get(pcqAcct.Id);
            system.debug('updateAccts pcqAcct.Id: '+pcqAcct.Id+' pcq: '+pcq);
            system.debug('updateAccts before set field values FEIN: '+pcq.FEIN_Number__c+' Business Entity: '+pcq.Business_Entity__c+' NAICS: '+pcq.NAICS_Code__c);
            pcqAcct.Federal_ID_Number__c = ((pcq.FEIN_Number__c !=null && pcq.FEIN_Number__c !='') ? pcq.FEIN_Number__c : '');
            pcqAcct.Organization_Type__c = ((pcq.Business_Entity__c !=null && pcq.Business_Entity__c !='') ? pcq.Business_Entity__c : '');
            pcqAcct.NAICS_Code__c = ((pcq.NAICS_Code__c !=null && pcq.NAICS_Code__c !='') ? pcq.NAICS_Code__c.left(6) : '');
            system.debug('updateAccts set field values FedID: '+pcqAcct.Federal_ID_Number__c+' Organization Type: '+pcqAcct.Organization_Type__c+' NAICS: '+pcqAcct.NAICS_Code__c);
            uAccts.add(pcqAcct);
        }
        
        //update account    
        if (!uAccts.isEmpty()) {
            SKIP_TRIGGER=true;
            DmlHelper.performDML2(uAccts, DmlHelper.DML_UPDATE, 'PCQuoteDataMethods', 'updateAccts', 'Update Fields from Tarmika', true);
            SKIP_TRIGGER=false;
            system.debug('updateAccts after update accts');
      	}  
    }

} //PCQuoteDataMethods