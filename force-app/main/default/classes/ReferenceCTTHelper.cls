/*
* Helper class for Reference CTT Object
* 
* 11/30/2020	Matt Fritschi	Created
* 05/14/2021	Carrie Marciano	Added skip trigger check to prevent duplicate chatterposts (one from code and one was happening after workflow update)
* 07/07/2022	Chris Santoro	Added RefCTT Status update when Payroll and 401k Statuses are set to Submitted to CTT. Also added the Ref CTT Owner as Onboarding/Account Team Member
* 07/13/2022	Chris Santoro	Added Sales_Manager to be assigned within RefCTT
  08/01/2022    Dan Carmen      Clean up code

*/

public class ReferenceCTTHelper {
    public static Boolean SKIP_TRIGGER=false;
    
    //Populate the Account on the Reference CTT from the Opportunity
    public static void updateProspectClient(List<Reference_CTT__c> refCTTUpdateAccount, List<Id> opportunityIds)
    {
        Map<Id, Opportunity> opptyMap = new Map<Id, Opportunity>([SELECT Id, Name, AccountId, Mandate_Sale__c, OwnerId FROM Opportunity WHERE Id IN :opportunityIds]);
        for(Reference_CTT__c refCTT : refCTTUpdateAccount)
        {
            Opportunity oppty = opptyMap.get(refCTT.Opportunity__c);
            
            if(oppty.AccountId != null && (refCTT.Prospect_Client__c == null || (refCTT.Prospect_Client__c != null && oppty.AccountId != refCTT.Prospect_Client__c)))
            {
				refCTT.Prospect_Client__c = oppty.AccountId;
                
                if(oppty.Mandate_Sale__c)
            	{ 
                    System.debug('Ref CTT updateProspectClient');
                    List<User> user = [SELECT ManagerId from User where Id = :oppty.OwnerId];
                    refCTT.Sales_Manager__c = user[0].ManagerId;
                    
                    Onboarding_Tool__c ncp = [SELECT Id, Multi_ID__c, All_Children_Submitted__c from Onboarding_Tool__c where Opportunity_Id__c = :oppty.Id];

                    if(ncp != null)
                    {
                        refCTT.Onboarding_Tool__c = ncp.Id;
						refCTT.Ready_to_be_Worked__c = true;
                        
                        if(!ncp.Multi_ID__c)
                        {
                            refCTT.Number_of_Ids__c = 1;
                        }
                        else
                        {    
                            decimal numOfIds = 1;
                            //find out how many total NCPs there are for this Ref CTT
                            for(Opportunity opp : opptyMap.values())
                            {
                                if(opp.Primary_Opportunity__c != null &&  opp.Primary_Opportunity__c == ncp.Opportunity_Id__c)
                                {
                                    numOfIds = numOfIds + 1;
                                }
                            }
                            
                            refCTT.Number_of_Ids__c = numOfIds;
                            
                            //Check the child NCPs to see if any have not been submitted. If so, this is not ready to be worked.
                            if(!ncp.All_Children_Submitted__c)
                            {
                                refCTT.Ready_to_be_Worked__c = false;
                            }
                        }
                    }
                    
                    //Check to make sure the Ref CTT Owner is assigned to an actual user, not the Queue
                    if(refCTT.OwnerId != null)// && refCTT.OwnerId != queue.Id)
                    {
                        System.debug('Add OTM');
                        OpportunityTeamMember[] otms = new OpportunityTeamMember[]{};
                        OpportunityTeamMember otm = new OpportunityTeamMember(OpportunityId=oppty.Id,UserId=refCTT.OwnerId,TeamMemberRole='Client Transition Specialist', OpportunityAccessLevel = 'Edit');
                        otms.add(otm);
                        List<Database.SaveResult> otmResults = Database.insert(otms,false);
                        
                        AccountTeamMember[] atms = new AccountTeamMember[]{};
                        AccountTeamMember atm = new AccountTeamMember(AccountId=oppty.AccountId,UserId=refCTT.OwnerId,TeamMemberRole='Client Transition Specialist', AccountAccessLevel = 'Edit');
                        atms.add(atm);
                        List<Database.SaveResult> atmResults = Database.insert(atms,false);
                    }
                }
            } 
            
            //Only run code below if it's a Mandate Sale
            if(oppty.Mandate_Sale__c)
            {
                if(refCTT.X401_k_Status__c == 'Submitted to Service' && refCTT.Payroll_Status__c == 'Submitted to Service')
                {
                    refCTT.Status__c = 'Submitted to Service';            
                } 
            }            
        }
    } // updateProspectClient
    
    public static void postChatters(List<Reference_CTT__c> postChatterMessage, Id[] onbToolIds) {
        System.debug('postChatters postChatterMessage='+postChatterMessage.size()+' onbToolIds='+onbToolIds.size());
        
        Map<Id, Onboarding_Tool__c> onbToolMap = new Map<Id, Onboarding_Tool__c>([SELECT Id, Name, NCP_Submitted__c, NCP_Submitter__c, NCP_Submitter__r.ManagerId FROM Onboarding_Tool__c WHERE Id IN :onbToolIds]);
        
        for (Reference_CTT__c refCTT : postChatterMessage) {
            Onboarding_Tool__c onbTool = onbToolMap.get(refCTT.Onboarding_Tool__c);
            String messageBody = '';
            System.debug('onbTool='+onbTool);
            if (onbTool != null && onbTool.NCP_Submitted__c == true && onbTool.NCP_Submitter__c != null) {
                
                if(refCTT.Status__c == 'Returned to Sales-Client Unresponsive') {
                    messageBody = 'This client has been unresponsive to our requests for information. Please re-engage client to ensure that expectations have been set and resubmit the client profile after any required updates.';
                } else if(refCTT.Status__c == 'Sales Action Required/Unresponsive') {
                    messageBody = 'Reference CTT Number ' + refCTT.Name + ' Status has been updated to ' + refCTT.Status__c + '. Please see RCTT comments for details.'; 
                } else if(refCTT.Status__c == 'Submitted to Service') {
                    messageBody = 'Reference CTT Number ' + refCTT.Name + ' Status has been updated to ' + refCTT.Status__c + '. Please see RCTT comments for details.';
                } else if(refCTT.Status__c == 'Returned to Sales - Sales Requirements Not Met') {
                    messageBody = 'Reference CTT Number ' + refCTT.Name + ' Status has been updated to ' + refCTT.Status__c + '.';
                } else {
                    messageBody = 'Reference CTT Number ' + refCTT.Name + ' Status has been updated to ' + refCTT.Status__c + '.';
                    if(refCTT.Fed_Doc_Missing__c) {
                        messageBody += 'Fed Doc was either missing or not a match, ';
                    }
                    if(refCTT.Sign_Quote_or_Fee_Schedule_Missing__c) {
                        messageBody += 'Signed quote and/or discount length and % justification is missing, ';
                    }
                    if(refCTT.Client_Profile_Incomplete_or_Missing__c) {
                        messageBody += 'Client Profile was incomplete, missing or provided contradictiong information, ';
                    }
                    if(refCTT.Other_Missing__c) {
                        messageBody += refCTT.Other_Reason__c + ', ';
                    }
                    messageBody = messageBody.substring(0, messageBody.length() - 2);
                    messageBody += '.';
                }
                List<Id> groupToMention = new List<Id>();
                groupToMention.add(onbTool.NCP_Submitter__c);
                if(onbTool.NCP_Submitter__r.ManagerId != null) {
                    groupToMention.add(onbTool.NCP_Submitter__r.ManagerId);
                }
                
                String[] messageString = new List<String>();
                messageString.add(messageBody);
                System.debug('ReferenceCTTHelper createChatterPosts sending the chatter message...');
                ChatterMentionPost.createChatterMentionPost(refCTT.Id, groupToMention, messageString, true, false);
                SKIP_TRIGGER=true;
            } // if (onbTool != null && onbTool.NCP_Submitted__c == true
        } // or (Reference_CTT__c refCTT : postChatterMessage
        ChatterMentionPost.checkPostFeedElements();
    } // postChatters
    
} // class ReferenceCTTHelper