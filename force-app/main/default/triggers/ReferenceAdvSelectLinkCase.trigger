/* 
   Link Case object to Reference Select Advisor object pushed from ePlan.
   
  History
  -------
  01/19/2012 Cindy Freeman   Created
  04/05/2017 Saketh Mysa     Updated opptys[0].StageName from 'Sold: Submitted' to 'Sold - Submitted'
  06/13/2017 Saketh Mysa     Updated opptys[0].StageName from 'Sold:' to 'Sold'
  05/11/2018 Frank Lurz      Commented out update of Opportunity Stage per Case 28594622
   
 */
    
trigger ReferenceAdvSelectLinkCase on Reference_Advisor_Select__c (before insert, before update) {
    Map<String, Group> qMap = new Map<String, Group>(); // queue map
    /***List <Opportunity> opptyToUpdate = new List<Opportunity>(); // opptys to be updated to Sold: Submitted***/
    
    Group que = new UserHelper().getQueue('HRS Advisor Select');
    
    if (Trigger.isInsert)
    {   for ( Reference_Advisor_Select__c newAS: Trigger.new)   
        {   if (newAS.ConnectionReceivedID != Null || Test.isRunningTest())
            {   if (newAS.Paychex_Case_Nbr__c != Null)
                {   List<Case> kases = new List<Case>([SELECT ID, CaseNumber, Opportunity__c 
                            from Case where CaseNumber = :newAS.Paychex_Case_Nbr__c limit 1]);
                    if (kases.size() > 0)
                    {   newAS.Case_Lookup__c = kases[0].ID;
                        /*** FL commented out Opportunity.Stage updates 5/11/18 ***/
                        /***List<Opportunity> opptys = new List<Opportunity>([Select ID, StageName 
                                        from Opportunity where Id = :kases[0].Opportunity__c limit 1]);
                        if (opptys.size() > 0)
                        {   if (opptys[0].StageName == 'Sold')
                            {   opptys[0].StageName = 'Sold - Submitted';
                                opptyToUpdate.add(opptys[0]);
                            }
                        }***/
                    }
                    else
                    {   newAS.Message_from_ePlan__c = 'Bad case from ePlan, can not find case to link to';  }
                }
                else
                {   newAS.Message_from_ePlan__c = 'Missing case from ePlan, unable to link case';   }
            }
            newAS.OwnerId = que.ID; 
        }   
    }   // before insert
    else 
    {   for ( Reference_Advisor_Select__c newAS: Trigger.new) {
            if (newAS.ConnectionReceivedID != Null || Test.isRunningTest())
            {   Reference_Advisor_Select__c oldAS = Trigger.oldMap.get(newAS.id);
                if (newAS.Paychex_Case_Nbr__c != Null && (newAS.Paychex_Case_Nbr__c != oldAS.Paychex_Case_Nbr__c || oldAS.Case_lookup__c == Null))
                {   List<Case> kases = new List<Case>([SELECT ID, CaseNumber, Opportunity__c 
                            from Case where CaseNumber = :newAS.Paychex_Case_Nbr__c limit 1]);
                    if (kases.size() > 0)
                    {   newAS.Case_Lookup__c = kases[0].id; 
                        newAS.Message_from_ePlan__c = Null;
                        /*** FL commented out Opportunity.Stage updates 5/11/18 ***/
                        /***List<Opportunity> opptys = new List<Opportunity>([Select ID, StageName 
                                        from Opportunity where Id = :kases[0].Opportunity__c limit 1]);
                        if (opptys.size() > 0)
                        {   if (opptys[0].StageName == 'Sold')
                            {   opptys[0].StageName = 'Sold - Submitted';
                                opptyToUpdate.add(opptys[0]);
                            }
                        }***/
                    }
                    else
                    {   newAS.Message_from_ePlan__c = 'Bad case from ePlan, can not find case to link to';  }
                }
            }
            
        }   
    }   // before update
    
    /*** FL commented out Opportunity.Stage updates 5/11/18 ***/
    /***if (!opptyToUpdate.isEmpty())  {
        update opptyToUpdate;           
    }***/
    
}   // trigger