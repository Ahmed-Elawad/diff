/* Methods for the P_C_Carrier_Data__c object - created and updated by Huckleberry API calls to Salesforce

 * History
 * -------
  12/14/2023 Vinay Krishna Medishetty 	Created
  12/22/2023 Carrie Marciano			Added Policy Carrier Id and Carrier Name updates, creation of additional oppties for LOBs

*/

public class PCCarrierDataMethods implements TriggerInterfaceC {
    public static final String CLASSNAME = 'PCCarrierDataMethods';
    public static final String BINDABLE = 'BINDABLE';
    public static Boolean SKIP_TRIGGER=false;
    private static Map<String,String> HuckToOpplobMap = new Map<String,String>();
    private static Map<String,String> OppToHucklobMap = new Map<String,String>();
    private static Set<String> pccDataNonOpptyLOB = new Set<String>();
    private static Opportunity originalOpp;
	
    public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
        System.debug('PCCarrierData.handleTrigger SKIP_TRIGGER='+SKIP_TRIGGER+' recs='+recs.size()+' isBefore='+isBefore+' isAfter='+isAfter);
        if (SKIP_TRIGGER) {
            return;
      	}
        SObjectType objType = null;
     	if (recs != null && !recs.isEmpty()) {
            objType = recs[0].getSObjectType();
      	}
        if (objType == P_C_Carrier_Data__c.sObjectType) {
            if (isBefore){
            	handlePCCarrierDataBefore((P_C_Carrier_Data__c[])recs);
        	}
        	if (isAfter) {
            	handlePCCarrierDataAfter((P_C_Carrier_Data__c[])recs, (Map<Id,P_C_Carrier_Data__c>)oldMap); 
      		}
        }            
    }

    public static void handlePCCarrierDataBefore(P_C_Carrier_Data__c[] recs){
    	system.debug('handlePCCarrierDataBefore begin');
        List<Id> pcqDataId = new List<Id>();
        Set<String> pccDataValidLOB = new Set<String>();
        Map<String,P_C_Carrier_Data__c> validLOBPCCDmap = new Map<String,P_C_Carrier_Data__c>();
        PC_Quote_Data__c pcqData;
        map<String,Opportunity> lobOppMap = new map<String,Opportunity>();        
        ErrorLog__c log = new ErrorLog__c(ClassName__c='PCCarrierDataMethods',MethodName__c='handlePCCarrierDataBefore', CodeKey__c='LOG_DATA');
        
        // get mapping of Opportunity Type to Huckleberry Lines of Business
        for (HuckLOBMapping__mdt lobMapping : [Select MasterLabel, Label, HuckLOB__c, OpportunityType__c from HuckLOBMapping__mdt]) {
             HuckToOpplobMap.put(lobMapping.HuckLOB__c,lobMapping.OpportunityType__c);
             OppToHucklobMap.put(lobMapping.OpportunityType__c,lobMapping.HuckLOB__c);
        }        
        
        for (P_C_Carrier_Data__c newRec : recs){
            pcqDataId.add(newRec.P_C_Quote_Data__c);
            if (HuckToOpplobMap.containsKey(newRec.Line_of_Business__c)){
            	pccDataValidLOB.add(newRec.Line_of_Business__c);
                validLOBPCCDmap.put(newRec.Line_of_Business__c,newRec);
            } 
            if (!HuckToOpplobMap.containsKey(newRec.Line_of_Business__c)){
            	pccDataNonOpptyLOB.add(newRec.Line_of_Business__c);    
            } 
        }       
        System.debug('handlePCCarrierDataBefore Non-Oppty LOB: '+pccDataNonOpptyLOB.size()+' Oppty LOB: '+pccDataValidLOB);
        
        // get related PC Quote Data record for PC Carrier Data records in recs
        if(!pcqDataId.isEmpty()){
            pcqData = [Select Id, Company_ID__c, Huckleberry_Application_ID__c, Opportunity__c, Opportunity_Type__c, Prospect_Client__c from PC_Quote_Data__c where Id in:pcqDataId LIMIT 1]; 
            log.ObjectId__c= pcqData.Id;
        	log.ObjectAPIName__c='PC_Quote_Data__c';
        }
        
        // get existing opportunities related to the orignal Opportunity->PC Quote Data cobmination
        Opportunity[] existOpps= [Select Id, AccountId, Name, Primary_Opportunity__c, OpportunityType__c, OwnerId, LeadSource, StageName, AdditionalProductsOfInterest__c, Renewal_Date__c
                                                               From Opportunity
                                                              Where Primary_Opportunity__c = :pcqData.Opportunity__c OR Id = :pcqData.Opportunity__c];
        
        system.debug('handlePCCarrierDataBefore existOpps.size(): '+existOpps.size());
        // if there are opportunities we need to see which Opportunity Types they are and if we have an opportunity for the PC Carrier Data Line of Business in recs
        if (!existOpps.isEmpty()){
            String logMsg = 'handlePCCarrierDataBefore there are existing opportunities: '+existOpps.size(); 
            ErrorLog.addToDescription(log,logMsg);
            for (Opportunity existOpp : existOpps){
                lobOppMap.put(existOpp.OpportunityType__c,existOpp);
                system.debug('handlePCCarrierDataBefore existOpp.OpportunityType__c: '+existOpp.OpportunityType__c+' pccDataValidLOB: '+pccDataValidLOB);
                if (OppToHucklobMap.containsKey(existOpp.OpportunityType__c) && pccDataValidLOB.contains(OppToHucklobMap.get(existOpp.OpportunityType__c))){
                    // if we already have an oppty for this LOB, remove LOB from list
                	pccDataValidLOB.remove(OppToHucklobMap.get(existOpp.OpportunityType__c));  
                    system.debug('handlePCCarrierDataBefore pccDataValidLOB.remove existing opp LOB: '+OppToHucklobMap.get(existOpp.OpportunityType__c));
                }
                if (existOpp.Primary_Opportunity__c == null){
                	originalOpp = existOpp;  
                    system.debug('handlePCCarrierDataBefore originalOpp: '+originalOpp.Id);
                }
            }    
        }
        
        System.debug('handlePCCarrierDataBefore number of LOBs that need Oppties created: '+pccDataValidLOB.size());
        String logMsg = 'handlePCCarrierDataBefore number of LOBs that need Oppties created: '+pccDataValidLOB.size(); 
        ErrorLog.addToDescription(log,logMsg);
        // if pccDataValidLOB has records we need to create an opportunity for each one in list
  		Opportunity[] huckCloneOpps = null;
        if (pccDataValidLOB.size() > 0){
            huckCloneOpps = setUpClonedOpportunity(pcqData.Opportunity__c, pccDataValidLOB, validLOBPCCDmap, log);
            System.debug('handlePCCarrierDataBefore huckCloneOpps.size() : '+huckCloneOpps.size());
            
            // add new cloned opps to lobOppMap with original opp, should now be an oppty for each unique LOB
            for(Opportunity huckCloneOpp : huckCloneOpps){
            	lobOppMap.put(huckCloneOpp.OpportunityType__c,huckCloneOpp);    
            }
            System.debug('handlePCCarrierDataBefore pccDataNonOpptyLOB.size() : '+pccDataNonOpptyLOB.size()+' lobOppMap.size(): '+lobOppMap.size());
        }
        
        for (P_C_Carrier_Data__c rec : recs){
            if(rec.Opportunity__c ==  null ){
                System.debug('handlePCCarrierDataBefore rec.Opportunity__c is blank: '+rec.Id);
            	String lobToGet = HuckToOpplobMap.containsKey(rec.Line_of_Business__c) ? HuckToOpplobMap.get(rec.Line_of_Business__c) : null; 
                if (lobToGet != null){
                    rec.Opportunity__c = lobOppMap.containsKey(lobToGet) ? (lobOppMap.get(lobToGet)).Id : null;
                    System.debug('handlePCCarrierDataBefore lobToGet: '+lobToGet+' setting rec.Opportunity__c: '+rec.Opportunity__c);
                }
            }    
        } //for (P_C_Carrier_Data__c     
        
        ErrorLog.saveLog(log);

    } //handlePCCarrierDataBefore
    
    public static void handlePCCarrierDataAfter(P_C_Carrier_Data__c[] recs, Map<Id,P_C_Carrier_Data__c> oldMap) {
        system.debug('handlePCCarrierDataAfter begin');
        map<Id,P_C_Carrier_Data__c> oppsToUpdate = new map<Id,P_C_Carrier_Data__c>();
        map<Id,Reference_P_C__c> refPCToUpdate = new map<Id,Reference_P_C__c>();
        List<Id> pccdOppIds = new List<Id>();   
        ErrorLog__c log = new ErrorLog__c(ClassName__c='PCCarrierDataMethods',MethodName__c='handlePCCarrierDataAfter', CodeKey__c='LOG_DATA');       
        
        for (P_C_Carrier_Data__c newRec : recs){
            P_C_Carrier_Data__c oldRec = (oldMap != null ? oldMap.get(newRec.Id) : null);
            if(newRec.Opportunity__c != null) { 
                pccdOppIds.add(newRec.Opportunity__c);

                switch on Trigger.OperationType {
                    when AFTER_INSERT {
                        if((newRec.Policy_Carrier_ID__c != null && !String.isBlank(newRec.Policy_Carrier_ID__c)) || (newRec.Carrier_Name__c != null && !String.isBlank(newRec.Carrier_Name__c))){
                            oppsToUpdate.put(newRec.Opportunity__c, newRec);  
                            system.debug('handlePCCarrierDataAfter INSERT oppsToUpdate added after Policy Carrier Id or Carrier Name');
                        } //Policy_Carrier_ID__c and Carrier_Name__c
                        
                        if(newRec.Policy_Bind_Date__c != null && !String.isBlank(newRec.Policy_Carrier_ID__c)) {
                            oppsToUpdate.put(newRec.Opportunity__c, newRec); 
                            system.debug('handlePCCarrierDataAfter INSERT oppsToUpdate added after Policy Bind Date and Policy Carrier Id');
                        } //Policy_Bind_Date__c and Policy_Carrier_ID__c
                    } //AFTER_INSERT
                    when AFTER_UPDATE {
                        if (newRec.Quote_Status__c == BINDABLE && (oldRec == null || newRec.Quote_Status__c != oldRec.Quote_Status__c)){
                            oppsToUpdate.put(newRec.Opportunity__c, newRec);
                            system.debug('handlePCCarrierDataAfter UPDATE oppsToUpdate added after BINDABLE');
                        } //Quote_Status__c
                        
                        if((newRec.Policy_Carrier_ID__c != null && newRec.Policy_Carrier_ID__c != oldRec.Policy_Carrier_ID__c) || (newRec.Carrier_Name__c != null && newRec.Carrier_Name__c != oldRec.Carrier_Name__c)){
                            oppsToUpdate.put(newRec.Opportunity__c, newRec);  
                            system.debug('handlePCCarrierDataAfter UPDATE oppsToUpdate added after Policy Carrier Id or Carrier Name');
                        } //Policy_Carrier_ID__c and Carrier_Name__c
                        
                        if(newRec.Policy_Bind_Date__c != null && !String.isBlank(newRec.Policy_Carrier_ID__c) &&
                           (newRec.Policy_Bind_Date__c != oldRec.Policy_Bind_Date__c || newRec.Policy_Carrier_ID__c != oldRec.Policy_Carrier_ID__c)) {                               
                               oppsToUpdate.put(newRec.Opportunity__c, newRec); 
                               system.debug('handlePCCarrierDataAfter UPDATE oppsToUpdate added after Policy Bind Date and Policy Carrier Id');
                           } //Policy_Bind_Date__c and Policy_Carrier_ID__c
                        
                        if(newRec.Renewal_Date__c != null && newRec.Renewal_Date__c != oldRec.Renewal_Date__c){
                            oppsToUpdate.put(newRec.Opportunity__c, newRec); 
                            system.debug('handlePCCarrierDataAfter UPDATE oppsToUpdate added after Renewal Date');    
                        }
                    } //AFTER_UPDATE
                    
                } //switch on Trigger.OperationType  
            } //if(newRec.Opportunity__c != null)
        } //for loop
        
        //list of opps that are tied to a PC Carrier Data Record
        if (!pccdOppIds.isEmpty()){
        	updateRefPC(pccdOppIds);    
        }
        
        if(!oppsToUpdate.isEmpty() || pccDataNonOpptyLOB != null){
        	updateOpps(oppsToUpdate);
    	}
    } //handlePCCarrierDataAfter  

    public static void updateOpps(map<Id,P_C_Carrier_Data__c> oppsMap){
        system.debug('updateOpps begin');
    	Map<Id,Opportunity> opptyUpdateMap = new Map<Id,Opportunity>();
		//query opportunity fields
    	Opportunity[] pccOpps = [SELECT Id, Name, StageName, Probability, Policy_Number__c, PC_Carrier_Sold__c, AdditionalProductsOfInterest__c, Renewal_Date__c, Tarmika_Quote__c, Primary_Opportunity__c, Primary_Opportunity__r.Tarmika_Quote__c  FROM Opportunity WHERE Id in :oppsMap.keySet()];
        system.debug('updateOpps pccOpps: '+pccOpps.size());
        
        for(Opportunity pccOpp : pccOpps){
            P_C_Carrier_Data__c pcc = oppsMap.get(pccOpp.Id);
            Opportunity updateOppty = new Opportunity();
            Boolean updated = False; 
            system.debug('pccOpp.Probability: '+pccOpp.Probability);
            updateOppty.Id = pccOpp.Id;
            if (pccOpp.Probability != 50 && pcc.Quote_Status__c == BINDABLE){
                updateOppty.Probability = 50;
                updateOppty.StageName = 'Proposal';
                updated = True;              
            }
            
            if (pccOpp.Probability != 90 && pcc.Policy_Bind_Date__c != null && !String.isBlank(pcc.Policy_Carrier_ID__c) && 
               (!String.isBlank(pccOpp.Tarmika_Quote__c) || !String.isBlank(pccOpp.Primary_Opportunity__r.Tarmika_Quote__c))){
                updateOppty.Probability = 90;
                updateOppty.StageName = 'Sold-Submitted';
                updated = True;              
            }
            
            if((pccOpp.Policy_Number__c == null || (pccOpp.Policy_Number__c != null && pccOpp.Policy_Number__c != pcc.Policy_Carrier_ID__c)) 
               && (pcc.Policy_Carrier_ID__c != null && pcc.Policy_Carrier_ID__c != '')){
            	updateOppty.Policy_Number__c = pcc.Policy_Carrier_ID__c;  
                updated = True;   
            }
            
            if((pccOpp.PC_Carrier_Sold__c == null || (pccOpp.PC_Carrier_Sold__c != null && pccOpp.PC_Carrier_Sold__c != pcc.Carrier_Name__c)) 
               && (pcc.Carrier_Name__c != null && pcc.Carrier_Name__c != '')){
            	updateOppty.PC_Carrier_Sold__c = pcc.Carrier_Name__c;  
                updated = True;   
            }  
            
            if(pccOpp.Renewal_Date__c == null || (pccOpp.Renewal_Date__c != null && pccOpp.Renewal_Date__c != pcc.Renewal_Date__c)){
            	updateOppty.Renewal_Date__c = pcc.Renewal_Date__c;  
                updated = True;
            }  
            
            if(updated){
                opptyUpdateMap.put(updateOppty.Id, updateOppty);
            } 
        } //for(Opportunity pcqOpp : pcqOpps)

        if (pccDataNonOpptyLOB.size() > 0 && originalOpp != null){
            if(opptyUpdateMap.containsKey(originalOpp.Id)){
            	Opportunity updateUOpp = opptyUpdateMap.get(originalOpp.Id);   
                updateUOpp.AdditionalProductsOfInterest__c = updateUOpp.AdditionalProductsOfInterest__c != null ? (updateUOpp.AdditionalProductsOfInterest__c + String.join(pccDataNonOpptyLOB, ', ')) : String.join(pccDataNonOpptyLOB, ', ');  
            	opptyUpdateMap.put(updateUOpp.Id, updateUOpp);
            	system.debug('handlePCCarrierDataAfter Non-Oppty LOB added to Additional Products of Interest: '+originalOpp.AdditionalProductsOfInterest__c); 
            }
            else{
            	Opportunity updateUOpp = originalOpp;   
                updateUOpp.AdditionalProductsOfInterest__c = updateUOpp.AdditionalProductsOfInterest__c != null ? (updateUOpp.AdditionalProductsOfInterest__c + String.join(pccDataNonOpptyLOB, ', ')) : String.join(pccDataNonOpptyLOB, ', '); 
            	opptyUpdateMap.put(updateUOpp.Id, updateUOpp);
            	system.debug('handlePCCarrierDataAfter Non-Oppty LOB added to Additional Products of Interest: '+originalOpp.AdditionalProductsOfInterest__c);     
            }
                   
        }
            
        if (!opptyUpdateMap.isEmpty()){
        	DmlHelper.performDML2(opptyUpdateMap.values(), DmlHelper.DML_UPDATE, 'PCCarrierDataMethods', 'updateOpps', 'Update Opportunity from P&C Carrier Data', false); 
            system.debug('updateOpps after update opportunities');     
        } //!opptyUpdateMap.isEmpty
    } //updateOpps
    
    public static void updateRefPC(List<Id> pccdOppIds){
        system.debug('updateRefPC begin');
        Map<Id,Reference_P_C__c> refPCUpdateMap = new Map<Id,Reference_P_C__c>();
        //query Reference PC fields
        list<Reference_P_C__c> refPCs = [Select Id, Opportunity_Lookup__c, P_C_Quoted_Tool__c FROM Reference_P_C__c WHERE Opportunity_Lookup__c IN: pccdOppIds];
        system.debug('updateRefPC refPCs: '+refPCs.size());
        
        for(Reference_P_C__c refPC : refPCs){
            Reference_P_C__c updateRefPC = new Reference_P_C__c();
            updateRefPC.Id = refPC.Id;
            if(refPC.P_C_Quoted_Tool__c == null || refPC.P_C_Quoted_Tool__c == ''){
                updateRefPC.P_C_Quoted_Tool__c = 'Huckleberry';
                refPCUpdateMap.put(updateRefPC.Id, updateRefPC);
                system.debug('updateRefPC updateRefPC.P_C_Quoted_Tool__c: '+updateRefPC.P_C_Quoted_Tool__c);
            }    
        } //for(Opportunity refPC : refPCs)

        //set P&C Quoted Tool on related Reference PC records    
        if (!refPCUpdateMap.isEmpty()){
        	DmlHelper.performDML2(refPCUpdateMap.values(), DmlHelper.DML_UPDATE, 'PCCarrierDataMethods', 'updateRefPC', 'Update Reference PC from Oppty related to P&C Carrier Data', false); 
            system.debug('updateRefPC after update Reference PC');     
        } //!refPCUpdateMap.isEmpty
    } //updateRefPC
    
    public static Opportunity[] setUpClonedOpportunity(Id primaryOppId, Set<String> pccDataValidLOB, Map<String,P_C_Carrier_Data__c> validLOBPCCDmap, ErrorLog__c log){
        system.debug('setUpClonedOpportunity begin'); 
        List<Opportunity> clonedOpptyList = new List<Opportunity>();
        List<Id> clonedOppIdList = new List<Id>();
        
        String creatableOppFields = ObjectHelper.getCreatableFields('Opportunity','id=\''+String.escapeSingleQuotes(primaryOppId) +'\'');
        String queryString = creatableOppFields.substringBefore('FROM')
            +',(Select Id , OpportunityId, UserId, Name, PhotoUrl, TeamMemberRole, OpportunityAccessLevel, NSS_Source__c, NSS_Team__c, CommissionEnd__c, CommissionStart__c, Prospect_Ownership__c from OpportunityTeamMembers)'       
            +', (Select Quantity, Payroll_Unit__c,Non_Payroll_Unit__c,TotalPrice, Setup_Fee__c, Total_Calced__c,  Setup_Fee_Original__c, PricebookEntryId, QuoteLineGroupAcct__c, ListPrice, UnitPrice, QuoteLineGroupAcctName__c, Oracle_Quote_Line__r.Prospect_Client__c from OpportunityLineItems)';
        if(!queryString.contains('Primary_Opportunity__c'))
        {
            queryString = queryString + ', Primary_Opportunity__c';
        }      
        queryString = queryString +' from Opportunity where Id=:primaryOppId limit 1';
        String logMsg = 'setUpClonedOpportunity Original Opportunity query: '+queryString; 
        ErrorLog.addToDescription(log,logMsg);
        
        Opportunity originalOpportunity = (Opportunity)Database.query(queryString);
        system.debug('setUpClonedOpportunity queryString: '+queryString); 
        
        List<OpportunityContactRole> opptyCRs = [SELECT Id,
                                            ContactId,
                                            IsPrimary, 
                                            OpportunityId,
                                            Role
                                            FROM OpportunityContactRole WHERE OpportunityId = :originalOpportunity.Id];   
        
        List<OpportunityTeamMember> opptyTMs = [SELECT Id,
                                                  Name,
                                                  OpportunityAccessLevel, 
                                                  OpportunityId,
                                                  PhotoURL,
                                                TeamMemberRole, 
                                                UserId,
                                                  CommissionEnd__c,
                                                   CommissionStart__c, 
                                                  NSS_Source__c,
                                                  NSS_Team__c,
                                                 Prospect_Ownership__c                                           
                                                  FROM OpportunityTeamMember WHERE OpportunityId = :originalOpportunity.Id];
        
        for(String pccLOB : pccDataValidLOB){
        	Opportunity clonedOpp;
            Boolean cloneWithProducts = false;
            Boolean cloneHandbookContact = false;
            
            clonedOpp = originalOpportunity.clone(false, true, false, false);
            clonedOpp.OppSource__c = 'Huckleberry Clone';
            if (validLOBPCCDmap.containsKey(pccLOB) && validLOBPCCDmap.get(pccLOB).Quote_Status__c == BINDABLE){
                clonedOpp.Probability = 50;
                clonedOpp.StageName = 'Proposal';  
            }
            else if (validLOBPCCDmap.containsKey(pccLOB) && validLOBPCCDmap.get(pccLOB).Policy_Bind_Date__c != null && !String.isBlank(validLOBPCCDmap.get(pccLOB).Policy_Carrier_ID__c)){
                clonedOpp.Probability = 90;
                clonedOpp.StageName = 'Sold-Submitted';             
            }
            else{
            	clonedOpp.StageName = label.OppStage_IEUP; 
            	clonedOpp.Probability=30;    
            }
            system.debug('setUpClonedOpportunity insert Opp at: '+clonedOpp.StageName+' '+clonedOpp.Probability);
            clonedOpp.OpportunityType__c = HuckToOpplobMap.containsKey(pccLOB) ? HuckToOpplobMap.get(pccLOB) : originalOpportunity.OpportunityType__c;
            //clonedOpp.Renewal_Date__c            
            if(originalOpportunity.Auto_Close_Date__c!=null){
                clonedOpp.Auto_Close_Date__c = originalOpportunity.Auto_Close_Date__c; 
            }
            if(originalOpportunity.Primary_Opportunity__c == null)
            {
                clonedOpp.Primary_Opportunity__c = originalOpportunity.Id;
            }
            else {
                clonedOpp.Primary_Opportunity__c = originalOpportunity.Primary_Opportunity__c;
            }
            
            clonedOpptyList.add(clonedOpp);              
        }
        
        if(!clonedOpptyList.isEmpty()){
            system.debug('setUpClonedOpportunity clonedOpptyList is not empty, insert opportunities');
          	DmlHelper.performDML2(clonedOpptyList, DmlHelper.DML_INSERT, CLASSNAME, 'setUpClonedOpportunity', 'Insert Huck Clone Opps', true);
            ErrorLog.addToDescription(log, 'setUpClonedOpportunity after insert of cloned opps');
        }
        
        for(Opportunity clonedOpp : clonedOpptyList){
        	clonedOppIdList.add(clonedOpp.Id);    
        }
        
        // set default products on inserted opportunities
        /*if (!clonedOppIdList.isEmpty()) {
            system.debug('setUpClonedOpportunity clonedOppIdList is not empty, insert default product OLI for new opportunitites'); 
            DmlHelper.performDML2(clonedOpptyList, DmlHelper.DML_UPDATE, CLASSNAME, 'setUpClonedOpportunity', 'Update Huck Clone Opps', true);
            OpptyProducts.addDefaultOpptyLineItem(clonedOppIdList);
            ErrorLog.addToDescription(log, 'setUpClonedOpportunity after insert of default product on cloned opps');
        } */
        
        // insert opportunity contact roles
        if(!opptyCRs.isEmpty()){    
            system.debug('setUpClonedOpportunity original oppty has contact roles');
            list<OpportunityContactRole> newRoleList = new List<OpportunityContactRole>();
            
            for (OpportunityContactRole opptyCR:opptyCRs ) {
                for(Opportunity clonedOpp : clonedOpptyList){
                	OpportunityContactRole newRoles = opptyCR.clone(false, false, false, false);
                	newRoles.OpportunityId = clonedOpp.id;
                	newRoleList.add(newRoles);    
                } //for clonedOpp               
            } //for opptyCR
            if(newRoleList.size()>0){
                system.debug('setUpClonedOpportunity insert new contact roles: ' + newRoleList.size()); 
                DmlHelper.performDML2(newRoleList, DmlHelper.DML_INSERT, CLASSNAME, 'setUpClonedOpportunity', 'Insert Huck Clone Contact Roles', true);
                ErrorLog.addToDescription(log, 'setUpClonedOpportunity after insert of contact role on cloned opps');
            }//if                     
        } //if(!opptyCRs.isEmpty()    

        // insert opportunity team members
        if (!opptyTMs.isEmpty()){
            system.debug('setUpClonedOpportunity original oppty has team members');
            list<OpportunityTeamMember> newTeamList = new List<OpportunityTeamMember>();
            
            for (OpportunityTeamMember opptyTM : opptyTMs) {
                for(Opportunity clonedOpp : clonedOpptyList){
                	OpportunityTeamMember newTeam = opptyTM.clone(false, false, false, false);
                	newTeam.OpportunityId = clonedOpp.id;
                	newTeamList.add(newTeam);    
                }
            }//for
            if(newTeamList.size()>0){
                system.debug('setUpClonedOpportunity insert new team members: ' + newTeamList.size());
                DmlHelper.performDML2(newTeamList, DmlHelper.DML_INSERT, CLASSNAME, 'setUpClonedOpportunity', 'Insert Huck Clone Opportunity Team', false);
                ErrorLog.addToDescription(log, 'setUpClonedOpportunity after insert of opportunity team members on cloned opps');
            }//if          
        }    
        
        return clonedOpptyList;
    } //setUpClonedOpportunity

}