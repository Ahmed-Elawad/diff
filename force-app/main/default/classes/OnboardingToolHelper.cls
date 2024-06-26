/*
* Helper Class for Onboarding Tool Records
* 
* 11/30/2020	Matt Fritschi	Created
* 03/01/2021	Matt Fritschi	Change to prevent extra Reference CTT records being created from Account merges.
* 05/25/2022	Chris Santoro	Added queue for Virtual Ret Sales
* 07/13/2022	Chris Santoro	Added createCTTCase() to create Case instead of Ref CTT for Mandate sales.  
  08/01/2022    Dan Carmen      Clean up code
  09/01/2023    Dan Carmen      Add methods to set record attributes consistently
  09/27/2023    Dan Carmen      Set additional parent attribute

*/

public class OnboardingToolHelper {
    
    public static Boolean SKIP_TRIGGERS=false;
    
    public static void checkAllBefore(Onboarding_Tool__c[] onboards, Map<Id,Onboarding_Tool__c> oldMap) {
        
       Onboarding_Tool__c[] checkEntryRecs = new Onboarding_Tool__c[]{};
       Id[] entryAcctIds = new Id[]{};
       Id[] entryOppIds = new Id[]{};
       
       for (Onboarding_Tool__c onb : onboards) {
          Onboarding_Tool__c oldRec = (oldMap != null ? oldMap.get(onb.Id) : null);
          if (oldRec == null || onb.CheckEntryAttributes__c) {
             // if a new record check the lookups and some basic settings
             onb.CheckEntryAttributes__c = false;
             checkEntryRecs.add(onb);
             if (onb.AccountId__c != null) {
                entryAcctIds.add(onb.AccountId__c);
             }
             if (onb.Opportunity_Id__c != null) {
                entryOppIds.add(onb.Opportunity_Id__c);  
             }
          }
       } // for (Onboarding_Tool__c onb : onboards
        
       if (!checkEntryRecs.isEmpty()) {
          checkEntryAttribsBefore(checkEntryRecs, entryAcctIds, entryOppIds);
          checkOnboardingEntryAfter = true;
       }
    } // checkAllBefore
    
    public static Boolean checkOnboardingEntryAfter=false;
    
    public static void checkEntryAttribsBefore(Onboarding_Tool__c[] recs, Id[] acctIds, Id[] oppIds) {
       Map<Id,Account> acctMap = getAcctMap(acctIds);
       Map<Id,Opportunity> oppMap = (!oppIds.isEmpty() 
                                    ? new Map<Id,Opportunity>([Select Id, Name, AccountId
                                                                     ,Account.Id, Account.Name, Account.SalesParent__c, Account.IsParent__c, Account.IsChild__c
                                                                     ,ClientTracking__c 
                                                                 from Opportunity where Id in :oppIds])
                                    : new Map<Id,Opportunity>());
       Integer onboardingNameSize = Onboarding_Tool__c.Name.getDescribe().getLength();
       for (Onboarding_Tool__c onb : recs) {
          Opportunity opp = (onb.Opportunity_Id__c != null ? oppMap.get(onb.Opportunity_Id__c) : null);
          Account acct = (onb.AccountId__c != null ? acctMap.get(onb.AccountId__c) : (opp != null ? opp.Account : null));
          System.debug('checkEntryAttribsBefore acct='+acct);
          onb.Name = (opp != null ? opp.Name : (acct != null ? acct.Name : onb.Name)).left(onboardingNameSize);
          onb.AccountId__c = (onb.AccountId__c == null ? (acct != null ? acct.Id : onb.AccountId__c) : onb.AccountId__c);
          if (acct != null && acct.isParent__c) {
             onb.Is_Parent__c = true;
             onb.isMultiIdParent__c = true;
          }
          if (acct != null && acct.isChild__c) {
             onb.Is_Child__c = true;
          }
          onb.Sales_Parent__c = (acct != null ? acct.SalesParent__c : onb.Sales_Parent__c);
       }
    } // checkEntryAttribsBefore
    
    public static void checkAllAfter(Onboarding_Tool__c[] onboards, Map<Id,Onboarding_Tool__c> oldMap) {
       Id[] parentAcctIds = new Id[]{};
       // if we have parents, make sure they're marked appropriately
       Set<Id> markAsParentIds = new Set<Id>();
       Onboarding_Tool__c[] checkForParents = new Onboarding_Tool__c[]{};
       for (Onboarding_Tool__c onb : onboards) {
          Onboarding_Tool__c oldRec = (oldMap != null ? oldMap.get(onb.Id) : null);
          if (checkOnboardingEntryAfter && onb.Is_Child__c && onb.Parent_Onboarding_Record__c==null && onb.Sales_Parent__c != null) {
             checkForParents.add(onb);
             parentAcctIds.add(onb.Sales_Parent__c);
          } else if (checkOnboardingEntryAfter && onb.Is_Child__c && onb.Parent_Onboarding_Record__c != null) {
             markAsParentIds.add(onb.Parent_Onboarding_Record__c);
          }
       } // for (Onboarding_Tool__c onb : onboards
       
       System.debug('checkAllAfter onboards='+onboards.size()+' checkForParents='+checkForParents.size());
       if (!checkForParents.isEmpty() || !markAsParentIds.isEmpty()) {
          checkForParentOnboarding(checkForParents, parentAcctIds, markAsParentIds);
       }
        
       checkOnboardingEntryAfter = false;
    } // checkAllAfter
    
    public static void checkForParentOnboarding(Onboarding_Tool__c[] checkForParents, Id[] parentAcctIds, Set<Id> markAsParentIds) {
       Map<Id,Onboarding_Tool__c> onbUpdateMap = new Map<Id,Onboarding_Tool__c>();
       if (!checkForParents.isEmpty()) {
          Map<Id,Account> acctMap = getAcctMap(parentAcctIds);
           
          for (Onboarding_Tool__c onb : checkForParents) {
             Account parentAcct = acctMap.get(onb.Sales_Parent__c);
             System.debug('checkForParentOnboarding onb='+onb.Name+' parentAcct='+(parentAcct != null));
             if (parentAcct != null) {
                Onboarding_Tool__c parentOnboard = (!parentAcct.Onboarding_Tools__r.isEmpty() ? parentAcct.Onboarding_Tools__r[0] : null);
                System.debug('checkForParentOnboarding parentOnboard='+(parentOnboard != null));
                if (parentOnboard != null) {
                   Boolean childIsCombo = (onb.Combo__c == 'Yes');
                    System.debug('checkForParentOnboarding childIsCombo='+childIsCombo);
                   if (!parentOnboard.Is_Parent__c || !parentOnboard.isMultiIdParent__c || (childIsCombo && parentOnboard.Combo__c != 'Yes')) {
                      Onboarding_Tool__c updateParent = (onbUpdateMap.containsKey(parentOnboard.Id) ? onbUpdateMap.get(parentOnboard.Id)
                                                        :new Onboarding_Tool__c(Id=parentOnboard.Id, Is_Parent__c=true, isMultiIdParent__c=true));
                      if (childIsCombo) {
                         updateParent.Combo__c = 'Yes';
                      }
                      onbUpdateMap.put(updateParent.Id, updateParent);
                      // make sure it's not in the set if we handle it here.
                      markAsParentIds.remove(parentOnboard.Id);
                   }
                   Onboarding_Tool__c updateOnb = new Onboarding_Tool__c(Id=onb.Id, Parent_Onboarding_Record__c=parentOnboard.Id);
                   if (onb.Opportunity_Id__c == null && parentOnboard.Opportunity_Id__c != null) {
                      System.debug('checkForParentOnboarding setting opportunity to parent opp');
                      updateOnb.Opportunity_Id__c = parentOnboard.Opportunity_Id__c;
                   }
                   onbUpdateMap.put(updateOnb.Id, updateOnb);
                }
             } // if (parentAcct != null
          } // for (Onboarding_Tool__c onb : checkForParents

       } // if (!checkForParents.isEmpty
        
        for (Id parentOnboardId : markAsParentIds) {
           Onboarding_Tool__c parentOnb = new Onboarding_Tool__c(Id=parentOnboardId, Is_Parent__c=true, isMultiIdParent__c=true);
           onbUpdateMap.put(parentOnb.Id, parentOnb);
        }
        
       if (!onbUpdateMap.isEmpty()) {
          SKIP_TRIGGERS=true;
          DmlHelper.performDML2(onbUpdateMap.values(), DmlHelper.DML_UPDATE, 'OnboardingToolHelper', 'checkForParentOnboarding', 'Update the parent on the onboarding', true); 
       }
    } // checkForParentOnboarding
                      
    public static Map<Id,Account> getAcctMap(Id[] acctIds) {
       Map<Id,Account> acctMap = (!acctIds.isEmpty() 
                                    ? new Map<Id,Account>([Select Id, Name, SalesParent__c, IsParent__c, IsChild__c
                                                                 ,(Select Id, AccountId__c, Opportunity_Id__c, Combo__c, Is_Parent__c, isMultiIdParent__c
                                                                     from Onboarding_Tools__r order by CreatedDate desc limit 1) 
                                                             from Account where Id in :acctIds])
                                    : new Map<Id,Account>());
       return acctMap;
    } // getAcctMap
    
    public static void checkIfAlreadySplit(List<Onboarding_Tool__c> checkIfParent) {
        //Get all Opptys
        Map<Id,Onboarding_Tool__c> oppToolMap = new Map<Id,Onboarding_Tool__c>();
        for(Onboarding_Tool__c ot : checkIfParent) {
            if(ot.Opportunity_Id__c != null) {
                oppToolMap.put(ot.Opportunity_Id__c, ot);
            }
        } // for(Onboarding_Tool__c ot : checkIfParent
        if (!oppToolMap.isEmpty()) {
            
           //Get all children of the Onboarding Record's Opptys.
           Map<Id, Opportunity> childOpptyMap = new Map<Id, Opportunity>([SELECT Id, Name, Primary_Opportunity__c FROM Opportunity WHERE Primary_Opportunity__c IN :oppToolMap.keySet()]);
        
           for (Opportunity childOpp : childOpptyMap.values()) {
               Onboarding_Tool__c parentOT = oppToolMap.get(childOpp.Primary_Opportunity__c);
               if(parentOT != null && !parentOT.Is_Parent__c ) {
                  parentOT.Is_Parent__c = true;
               }
           } // for (Opportunity childOpp : childOpptyMap.values
        } // if (!oppToolMap.isEmpty
        
    } // checkIfAlreadySplit
    
    public static void checkForAccounts(Onboarding_Tool__c[] onboards, Id[] oppIds) {
       Map<Id,Opportunity> oppMap = new Map<Id,Opportunity>([Select Id, Name, AccountId from Opportunity where Id in :oppIds]);
       for (Onboarding_Tool__c onboard : onboards) {
          Opportunity opp = oppMap.get(onboard.Opportunity_Id__c);
          if (opp != null) {
             onboard.AccountId__c = opp.AccountId;
          }
       } // for (Onboarding_Tool__c onboard : onboards
    } // checkForAccounts
    
    //Check to see if all Onboarding tools have been submitted.
    public static void checkAllSubmitted(List<Id> parentOnboardingIds, List<Id> newlyUpdatedChildren, Map<Id, Onboarding_Tool__c> onboardingToolRecsToUpdate) { 
        
        List<Onboarding_Tool__c> parentOnboardingRecs = new List<Onboarding_Tool__c>();
        parentOnboardingRecs = [SELECT Id, Name, All_Children_Submitted__c, NCP_Submitted__c, Is_Parent__c FROM Onboarding_Tool__c WHERE Id IN :parentOnboardingIds AND Is_Parent__c = true];
        List<Onboarding_Tool__c> childOnboardingRecs = new List<Onboarding_Tool__c>();
        List<Onboarding_Tool__c> parentsToUpdate = new List<Onboarding_Tool__c>();
        childOnboardingRecs = [SELECT Id, Name, NCP_Submitted__c, Is_Child__c, Parent_Onboarding_Record__c FROM Onboarding_Tool__c WHERE Parent_Onboarding_Record__c IN :parentOnboardingIds AND Is_Child__c = true];
        boolean allSubmitted = true;
        List<Id> allChildrenSubmitted = new List<Id>();
        
        for(Onboarding_Tool__c parent : parentOnboardingRecs)
        {
            if(parent.NCP_Submitted__c)
            {
                for(Onboarding_Tool__c child : childOnboardingRecs)
                {
                    System.debug('child.NCP_Submitted__c='+child.NCP_Submitted__c);
                    if(child.Parent_Onboarding_Record__c == parent.Id && !child.NCP_Submitted__c && !newlyUpdatedChildren.contains(child.Id))
                    {
                        allSubmitted = false;
                    }
                }
            }
            
            if(allSubmitted)
            {
                parent.All_Children_Submitted__c = true;
                allChildrenSubmitted.add(parent.Id);
                //createChatterPost.add(parent);
                onboardingToolRecsToUpdate.put(parent.Id, parent);
            }
            
        }
        
        Reference_CTT__c[] refCTTRecsToUpdate = [SELECT Id, Name, Ready_To_Be_Worked__c FROM Reference_CTT__c WHERE Onboarding_Tool__c IN :allChildrenSubmitted];
        for(Reference_CTT__C refCTT : refCTTRecsToUpdate) {
            refCTT.Ready_To_Be_Worked__c = true;
        }
        
        DmlHelper.performDML2(refCTTRecsToUpdate, DmlHelper.DML_UPDATE, 'OnboardingToolHelper', 'checkAllSubmitted', 'Update Reference CTTs', true);
    } //checkAllSubmitted
    
    //If the parent is submitted after the children, update the children to have parent's data.
    public static void updateChildrenToHaveParentData(List<Onboarding_Tool__c> updateChildren, Map<Id, Onboarding_Tool__c> onboardingToolRecsToUpdate) {
        //Get the fields needed to copy from parent -> child
        //String[] fldList = new String[]{};
        //    Schema.FieldSet oppFldSet = Schema.SObjectType.Onboarding_Tool__c.fieldSets.Fields_Copied_to_Child;
        //for (Schema.FieldSetMember fsm : oppFldSet.getFields()) {
        //    String fldName = fsm.getFieldPath();
        //    fldList.add(fldName);
        //}
        Set<String> fldSet = new Set<String>();
        DmlHelper.addFieldsToSet(Schema.SObjectType.Onboarding_Tool__c.fieldSets.Fields_Copied_to_Child, '', fldSet);

        System.debug('updateChildrenToHaveParentData updateChildren='+updateChildren.size()+' onboardingToolRecsToUpdate='+onboardingToolRecsToUpdate.size());
        List<Id> parentOpptyIds = new List<Id>();
        for (Onboarding_Tool__c parentOnb : updateChildren) {
            if (parentOnb.Opportunity_Id__c != null) {
               parentOpptyIds.add(parentOnb.Opportunity_Id__c);
            }
        } // for (Onboarding_Tool__c parentOnb : updateChildren
        System.debug('updateChildrenToHaveParentData parentOpptyIds='+parentOpptyIds);
        Map<Id, Opportunity> childOpptys = (!parentOpptyIds.isEmpty() ?
                   new Map<Id, Opportunity>([SELECT Id, Name, Primary_Opportunity__c FROM Opportunity WHERE Primary_Opportunity__c IN :parentOpptyIds])
                   : new Map<Id,Opportunity>());
        //System.debug('updateChildrenToHaveParentData childOpptys='+childOpptys);
        
        List<Onboarding_Tool__c> childOnboardingRecs = new List<Onboarding_Tool__c>();
        
        List<Id> childOpptyIds = new List<Id>();
        childOpptyIds.addAll(childOpptys.keySet());
        if(!childOpptyIds.isEmpty()) {
           String query = (String)CacheManager.getOrg('OnboardingToolHelperOnboardingQuery');
           if (query == null) {
              query = DmlHelper.buildQueryFromSet(fldSet,'Onboarding_Tool__c');
              CacheManager.putOrg('OnboardingToolHelperOnboardingQuery',query);
           }
           query += ' WHERE Opportunity_Id__c IN :childOpptyIds';
            //String queryString = 'SELECT '
            //    + String.join(fldList,',') 
                //+ ' FROM Onboarding_Tool__c WHERE Opportunity_Id__c IN (\''+ String.join(childOpptyIds, '\',\'') + '\')'; 
            //    + ' FROM Onboarding_Tool__c WHERE Opportunity_Id__c IN :childOpptyIds'; 
            
            //System.debug('childOpptyIds='+childOpptyIds);
            childOnboardingRecs = Database.query(query);
        }
        
        //Update the children
        for(Onboarding_Tool__c parentOnb : updateChildren) {
            //System.debug('updateChildrenToHaveParentData parentOnb='+parentOnb);
            for(Opportunity childOppty : childOpptys.values()) {
                if(childOppty.Primary_Opportunity__c == parentOnb.Opportunity_Id__c) {
                    //System.debug('updateChildrenToHaveParentData childOppty='+childOppty);
                    for(Onboarding_Tool__c onboardingChildRec : childOnboardingRecs) {
                        if(onboardingChildRec.Opportunity_Id__c == childOppty.Id) {
                            System.debug('1 onboardingChildRec.Id='+onboardingChildRec.Id+' parentOnb.Id='+parentOnb.Id);
                            //System.debug('updateChildrenToHaveParentData onboardingChildRec='+onboardingChildRec);
                            //onboardingChildRec = parentOnb.clone(false, true, false, false);
                            for (String field : fldSet) {
                                if(onboardingChildRec.get(field) != parentOnb.get(field) && !field.equalsIgnoreCase('Id') && !field.equals('Opportunity_Id__c')) {
                                    onboardingChildRec.put(field, parentOnb.get(field));
                                }
                            } // for (String field : fldSet
                            System.debug('2 onboardingChildRec.Id='+onboardingChildRec.Id+' parentOnb.Id='+parentOnb.Id);
                            onboardingChildRec.Name = childOppty.Name;
                            //onboardingChildRec.Opportunity_Id__c = childOppty.Id;
                            onboardingChildRec.Is_Child__c = true;
                            onboardingChildRec.Is_Parent__c = false;
                            
                            onboardingChildRec.Parent_Onboarding_Record__c = parentOnb.Id;
                            
                            onboardingToolRecsToUpdate.put(onboardingChildRec.Id, onboardingChildRec);
                            //onbRecsToDelete.add(onboardingChildRec);
                        } // if(onboardingChildRec.Opportunity_Id__c == childOppty.I
                    } // for(Onboarding_Tool__c onboardingChildRec : childOnboardingRec
                } // if(childOppty.Primary_Opportunity__c == parentOnb.Opportunity_Id__c
            } // for(Opportunity childOppty : childOpptys.values
        } // for(Onboarding_Tool__c parentOnb : updateChildren)
    } // updateChildrenToHaveParentData
    
    public static String[] queueNames = new String[]{Label.Client_Transition_MMS_Queue, Label.Client_Transition_VNB_Queue, Label.Client_Transition_Virtual_Queue
                                                       ,Label.Client_Transition_Channels_Queue, Label.Client_Transition_Acquisitions_Queue, 'NCP Paco Submission Team Test Queue'
                                                       ,Label.Virtual_Ret_Sales_CTS_Round_Robin};
    
    //Creates the RefCTT record
    public static void createCTT(List<Onboarding_Tool__c> createReferenceCTT, Onboarding_Tool__c[] mandateOnboards, Id[] oppIds) {	
        System.debug('createCTT createReferenceCTT='+createReferenceCTT.size()+' mandateOnboards='+mandateOnboards.size()+' oppIds='+oppIds.size());
        User runningUser = UserHelper.getRunningUser();
        
        Reference_CTT__c[] insertCTTs = new Reference_CTT__c[]{};
        //Grab all opportuinities linked to the Onboarding records
        Map<Id,Opportunity> oppMap = (!oppIds.isEmpty() ? new Map<Id,Opportunity>([Select Id, AccountId, Name, Primary_Opportunity__c, OwnerId, LeadSource, StageName
                                                               From Opportunity
                                                              Where Primary_Opportunity__c IN :oppIds OR Id in :oppIds
                                                              ])
                                                        : new Map<Id,Opportunity>());
        Map<String,Group> queueMap = UserHelper.getQueueMapByName(queueNames);
        Map<Id,Case> caseMap = new Map<Id,Case>();
        if (!mandateOnboards.isEmpty()) {
            caseMap = createCTTCase(mandateOnboards, oppMap, queueMap);
        }
        String[] closedStatus = Label.Reference_CTT_Closed_Status.split(',');
        // check for existing
        Reference_CTT__c[] refCTTs = [SELECT Id, Name, Opportunity__c, Onboarding_Tool__c, Status__c FROM Reference_CTT__c WHERE Onboarding_Tool__c IN :createReferenceCTT];
        Map<Id, Reference_CTT__c> refCTTMap = new Map<Id, Reference_CTT__c>();
        
        //Get all currently existing reference CTT records
        for(Reference_CTT__c cttrec : refCTTs) {
            if(cttrec.Onboarding_Tool__c != null && !refCTTMap.containsKey(cttrec.Onboarding_Tool__c) && !closedStatus.contains(cttrec.Status__c)) {
                refCTTMap.put(cttrec.Onboarding_Tool__c, cttrec);
            }
        } // for(Reference_CTT__c cttrec : refCTT
        
        Map<Id, Onboarding_Tool__c> childNCPMap = new Map<Id, Onboarding_Tool__c>([SELECT Id, Name, Opportunity_Id__c, Parent_Onboarding_Record__c, NCP_Submitted__c 
                                                                                     FROM Onboarding_Tool__c 
                                                                                    WHERE Parent_Onboarding_Record__c IN :createReferenceCTT]);    
        
        for (Onboarding_Tool__c ncp : createReferenceCTT) {
            //Make sure a Ref CTT doesn't already exist. If not, create the Ref CTT
            if (!refCTTMap.containsKey(ncp.Id) && ncp.SubmissionDate__c != null && ncp.SubmissionDate__c == date.today()) {
                Opportunity opp = oppMap.get(ncp.Opportunity_Id__c);
                Reference_CTT__c newRefCTT = new Reference_CTT__c(Onboarding_Tool__c = ncp.Id, Opportunity__c = ncp.Opportunity_Id__c, Ready_to_be_Worked__c=true
                                                                  , Number_of_Ids__c=1);
                newRefCTT.Sales_Rep__c = (opp != null ? opp.OwnerId : null);
                if (ncp.Multi_ID__c) {
                    //find out how many total NCPs there are for this Ref CTT
                    for(Opportunity oppty : oppMap.values()) {
                        if(oppty.Primary_Opportunity__c != null &&  oppty.Primary_Opportunity__c == ncp.Opportunity_Id__c) {
                            newRefCTT.Number_of_Ids__c = newRefCTT.Number_of_Ids__c + 1;
                        }
                    } // for(Opportunity oppty : oppMap.values
                    
                    //Check the child NCPs to see if any have not been submitted. If so, this is not ready to be worked.
                    if(!ncp.All_Children_Submitted__c) {
                        newRefCTT.Ready_to_be_Worked__c = false;
                    }
                    
                } // if(!ncp.Multi_ID__c
                if(newRefCTT.Opportunity__c != null) {
                    newRefCTT.Parent_Onboarding_Tool_Link__c = URL.getSalesforceBaseUrl().toExternalForm()+'/apex/Onboarding?id='+newRefCTT.Opportunity__c;
                }
                if(ncp.ReadyChex__c == null || ncp.ReadyChex__c == 'ReadyChex' || ncp.ReadyChex__c == 'Decline Both') {
                    newRefCTT.Check_Signing_Received__c = 'N/A';
                }
                if(ncp.Skylight__c == null || ncp.Skylight__c == 'Decline Both') {
                    newRefCTT.Skylight_Card_Received__c = 'N/A';
                }
                if(ncp.GL__c == null || ncp.GL__c == 'GL Report' || ncp.GL__c == 'Decline Both') {
                    newRefCTT.Chart_of_Accounts__c = 'N/A';
                }
                if(ncp.Pay_Demand__c == null || ncp.Pay_Demand__c == 'Decline') {
                    newRefCTT.Paid_On_Demand_Received__c = 'N/A';
                }
                if(ncp.Workers_Compensation__c == null || ncp.Workers_Compensation__c == 'WC Payment Service' || ncp.Workers_Compensation__c == 'Decline Both') {
                    newRefCTT.Workers_Comp_Declaration_Page__c = 'N/A';
                }
                if(ncp.Business_Structure__c != null && ncp.Business_Structure__c != 'Non-Profit') {
                    newRefCTT.X501c_Proof_Received__c = 'N/A';
                }
                if(!ncp.Tax_Credit_Service_Opt_In__c) {
                    newRefCTT.Tax_Credit_Service_Received__c = 'N/A';
                }
                
                Case cs = caseMap.get(ncp.Id);
                System.debug('createCTT cs='+(cs != null)+' newRefCTT='+newRefCTT);
                
                //Assign the Ref CTT to the Proper Queue
                if (cs != null) {
                    // assign the owner of the reference object to the owner of the Case
                    newRefCTT.OwnerId = cs.OwnerId;
                    newRefCTT.Case__c = cs.Id;
                } else if (runningUser.Sales_Org__c == 'MMS' || Test.isRunningTest()) {
                    if (opp != null && opp.LeadSource != null && opp.LeadSource == 'Acquisition') {
                        setOwner(newRefCTT, queueMap.get(Label.Client_Transition_Acquisitions_Queue));
                    } else {
                        String queueName = (!Test.isRunningTest() ? Label.Client_Transition_MMS_Queue : 'NCP Paco Submission Team Test Queue');
                        setOwner(newRefCTT, queueMap.get(queueName));
                        System.debug('createCTT going to MMS Queue queueName='+queueName);
                    }
                    
                } else if (opp != null && opp.LeadSource != null && opp.LeadSource == 'Acquisition') {
                    setOwner(newRefCTT, queueMap.get(Label.Client_Transition_Acquisitions_Queue));
                } else if (runningUser.Sales_Division__c == 'SMB Channel') {
                    setOwner(newRefCTT, queueMap.get(Label.Client_Transition_Channels_Queue));
                } else if (runningUser.Sales_Division__c == 'Virtual SMB Inbound') {
                    setOwner(newRefCTT, queueMap.get(Label.Client_Transition_Virtual_Queue));
                } else if (runningUser.Sales_Division__c == 'SMB New Business' || runningUser.Sales_Division__c == 'SMB Virtual Channel') {
                    setOwner(newRefCTT, queueMap.get(Label.Client_Transition_VNB_Queue));
                }
                newRefCTT.Status__c = 'Submitted to CTT';
                insertCTTs.add(newRefCTT); 
            } // if (!refCTTMap.containsKey(ncp.Id) &&
            
        } // for (Onboarding_Tool__c ncp : createReferenceCTT
        if (!insertCTTs.isEmpty()) {
          DmlHelper.performDML2(insertCTTs, DmlHelper.DML_INSERT, 'OnboardingToolHelper', 'createCTTCase', 'Update Opportunities', true);
        }
        //insert refCTTToInsert;
    } // createCTT
    
    public static void setOwner(Reference_CTT__c refCTT, Group queue) {
       if (queue != null) {
          refCTT.OwnerId = queue.Id;
       }
    } // setOwner 
    
    public static String caseQueueName = Label.Virtual_Ret_Sales_CTS_Round_Robin;
    
    public static Map<Id,Case> createCTTCase(Onboarding_Tool__c[] onboardingRecords,Map<Id,Opportunity> oppMap, Map<String,Group> queueMap) {
       System.debug('createCTTCase onboardingRecords='+onboardingRecords.size()+'oppMap='+oppMap+' queueMap='+queueMap.size());
       Map<Id, Opportunity> oppsToUpdate = new Map<Id, Opportunity>();
       Case[] newCases = new Case[]{};
       Map<Id, Case> caseMap = new Map<Id, Case>();
        
       for(Onboarding_Tool__c onbTool : onboardingRecords) {
           Group queue = queueMap.get(caseQueueName);
                
           Opportunity onboardingOpp = oppMap.get(onbTool.Opportunity_Id__c);
           //Database.DMLOptions dmo = new Database.DMLOptions();
           Schema.RecordTypeInfo CTTRt = RecordTypeHelper.getRecordType('Sales CTT', 'Case');
           Case kase = new Case(RecordTypeId = CTTRt.getRecordTypeId()
                                     , OwnerId = queue.Id
                                     , Opportunity__c = onbTool.Opportunity_Id__c
                                     , Sales_Rep__c = onboardingOpp.OwnerId
                                     , AccountId = onboardingOpp.AccountId
                                     , Origin = 'Email'
                                     , Priority = 'Medium'
                                     , Status = 'New');       
           onboardingOpp.StageName = 'Sold - Submitted to CTT';
           if (onboardingOpp != null) {
              oppsToUpdate.put(onboardingOpp.Id, onboardingOpp);
           }
           newCases.add(kase);
       } // for(Onboarding_Tool__c onbTool  

       if (!newCases.isEmpty()) {
          //dmo.assignmentRuleHeader.useDefaultRule=true;
          // we can skip the triggers that use TriggerMethods. CaseRoundRobin currently does not and might have to be looked at in the future.
          TriggerMethods.SKIP_TRIGGERS=true;
          Database.SaveResult[] results = Database.insert(newCases, false); //  (kase, dmo);
          TriggerMethods.SKIP_TRIGGERS=false;
          for (Integer cnt=0; cnt<results.size(); cnt++) {
             Database.SaveResult sr = results[cnt];
             Onboarding_Tool__c onbRec = onboardingRecords[cnt];
             if (!sr.isSuccess()) {
                String errorMsg = 'Error Saving Case: '+DmlHelper.getErrorMsg(sr.getErrors());
                ErrorLog.logError('OnboardingToolHelper', 'createCase', 'error creating Sales CTT case', onbRec.Opportunity_Id__c, errorMsg);
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, errorMsg));  
             }
          } // for (Integer cnt=0; cnt<results.size()
          
          Id[] caseIds = new Id[]{};
          for (Case cs : newCases) {
             if (cs.Id != null) {
                caseIds.add(cs.Id);
             }
          } // for (Case cs : newCases
          // reselect to get the OwnerId from Round Robin
          Case[] cases = [Select Id, AccountId, OwnerId, Opportunity__c from Case where Id in :caseIds];
          Map<Id,Case> tempCaseMap = new Map<Id,Case>();
          for (Case cs : cases) {
             tempCaseMap.put(cs.Opportunity__c, cs);
          }
          for (Onboarding_Tool__c onbTool : onboardingRecords) {
             Case cs = tempCaseMap.get(onbTool.Opportunity_Id__c);
             if (cs != null) {
                caseMap.put(onbTool.Id, cs);
             }
          } // for (Onboarding_Tool__c onbTool : onboardingRecords
       } // if (!newCases.isEmpty
             
       if (!oppsToUpdate.isEmpty()) {
          // TODO not sure if we should skip triggers here.
          OpptyMethods.SKIP_OPPTY_TRIGGERS=true; 
          DmlHelper.performDML2(oppsToUpdate.values(), DmlHelper.DML_UPDATE, 'OnboardingToolHelper', 'createCTTCase', 'Update Opportunities', true);
          OpptyMethods.SKIP_OPPTY_TRIGGERS=false; 
       }
      return caseMap;
   } // createCTTCase
    
    //Creates the chatter post to send to the Queue after the Reference CTT is Ready to be worked.
    public static void createChatterPosts(List<Reference_CTT__c> createChatterPost) {
        List<String> queues = new List<String>();
        Map<Id,Reference_CTT__c> refCTTMap = new Map<Id,Reference_CTT__c>(createChatterPost);

        Reference_CTT__c[] refCTTs = [SELECT Id, Name, OwnerId, Owner.Type, Owner.Name, Onboarding_Tool__c, Onboarding_Tool__r.Multi_Id__c, Sales_Rep__c 
                                        FROM Reference_CTT__c WHERE Id IN :refCTTMap.keySet()];
        System.debug('OnboardingToolHelper createChatterPosts refCTTs=' + refCTTs);
        
        for (Reference_CTT__C refCTT : refCTTs) {
            System.debug('OnboardingToolHelper refCrefCTTTTs.Owner.Name=' + refCTT.Owner.Name + ' refCTT.Owner.Type=' + refCTT.Owner.Type);
            if(refCTT.Owner.Type == 'queue' && !queues.contains(refCTT.Owner.Name)) {
                queues.add(refCTT.Owner.Name);
            } else {
                queues.add(Label.Virtual_Ret_Sales_CTS_Round_Robin);
            }
        } // for (Reference_CTT__C refCTT
        
        CollaborationGroup[] chatterGroups = [SELECT Id, Name From CollaborationGroup WHERE CollaborationType='Public' AND IsArchived=false AND Name IN :queues];
        System.debug('OnboardingToolHelper ChatterGroups.size()='+ chatterGroups.size());
        
        if((chatterGroups != null && !chatterGroups.isEmpty())) {
            String messageBody = '';
            //boolean okayToPost = false;
            for (Reference_CTT__C refCTT : refCTTs) {
                for (CollaborationGroup chatterGroup : chatterGroups) {
                    boolean okayToPost = false;
                    List<Id> groupToMention = new List<Id>();
                    
                    if((chatterGroup.Name == refCTT.Owner.Name && !refCTT.Onboarding_Tool__r.Multi_Id__c) || chatterGroup.Name == Label.Virtual_Ret_Sales_CTS_Round_Robin) {
                        System.debug('OnboardingToolHelper createChatterPosts posting Non multi Id');
                        if (chatterGroup.Name == Label.Virtual_Ret_Sales_CTS_Round_Robin) { //Post specific for CA Mandate
                            messageBody='Reference ' + refCtt.Name + ' has been created and assigned to ' + refCTT.Owner.Name + '.';
                            groupToMention.add(refCTT.OwnerId);
                            groupToMention.add(refCTT.Sales_Rep__c);
                        } else {
                            messageBody='The client profile has been submitted and will be reviewed by Client Transition as soon as possible.';
                            groupToMention.add(chatterGroup.Id);
                    	}
                        okayToPost = true;  
                    } else if((chatterGroup.Name == refCTT.Owner.Name && refCTT.Onboarding_Tool__r.Multi_Id__c) 
                               || (Test.isRunningTest() && chatterGroup.Name == 'Test Chatter Group' && refCTT.Onboarding_Tool__r.Multi_Id__c)) {
                        System.debug('OnboardingToolHelper createChatterPosts posting Multi Id');
                        messageBody='The client profiles for this Multi-Id submission has been submitted and will be reviewed by Client Transition as soon as possible.';
                        groupToMention.add(chatterGroup.Id);
                        okayToPost = true;
                    }
                    if(okayToPost) {
                        String[] messageString = new List<String>();
                        messageString.add(messageBody);
                        System.debug('OnboardingToolHelper createChatterPosts sending the chatter message...');
                        ChatterMentionPost.createChatterMentionPost(refCTT.Id, groupToMention, messageString, false, false);
                    }
                    //okayToPost = false;
                } // for (CollaborationGroup chatterGroup
            } // for (Reference_CTT__C refCTT : refCTTs
        } // if((chatterGroups != null
        ChatterMentionPost.checkPostFeedElements();
    } // createChatterPosts
    
} // class OnboardingToolHelper