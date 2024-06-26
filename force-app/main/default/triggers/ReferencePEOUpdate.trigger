/* 
   If the current step field changes on the Reference PEO object, update the current step
   field on the case. 
   
  History
  -------
  09/19/2011  Dan Carmen   Created
  04/15/2016  Lynn Michels  Added criteria for PEO Risk Assessment to update Case Status or Owner
  12/21/2017  Lynn Miches   Added before update and triggermethods code
  03/30/2018  Pooja Singh/Cindy Freeman     Added code to push Service Model up to Account.Safety Service Model
  04/13/2018  Jacob Hinds   Adding peo UW check
  05/09/2018  Sunnish Annu  Added criteria for updating the Safety Service model When not equal to 0
  02/27/2020  Dan Carmen      Add in TriggerMethods call

*/
trigger ReferencePEOUpdate on Reference_PEO__c(before update, after update, before insert, after insert) {
    
        if (CalculateDateFields.SKIP_TRIGGER) {
                return;
         }
    
    TriggerMethods.checkBeforeLoop('ReferencePEOUpdate', Trigger.new, Trigger.oldMap, Trigger.IsBefore, Trigger.IsAfter);

        // Map of account id and account record with updated value   
        Map <Id, Account> AccountWithServicedModel = new Map <Id, Account> ();
        
        ID PEORecordTypeId = RecordTypeHelper.getRecordType('PEO Client Risk Assessment', 'Reference_PEO__c').getRecordTypeID();    
           
        /* The records to be updated. */
        Map < Id, String > caseStepMap = new Map < Id, String > ();
        Map < Id, String > updateCaseStatus = new Map < Id, String > ();
        Map < Id, Id > updateOwnerMap = new Map < Id, Id > ();
        // for updating the Opportunity from the reference object
        // all of the opportunity ids that are going to be updated
        Set < Id > opptyIds = new Set < Id > ();

        // update the opportunity to Sold: Submitted
        Reference_PEO__c[] updateToSoldSub = new Reference_PEO__c[] {};
        // update the opportunity to Sold - Run
        Reference_PEO__c[] updateToSoldRun = new Reference_PEO__c[] {};
        
        Reference_PEO__c[] peoToCheckUW = new Reference_PEO__c[] {};
        
        for (Reference_PEO__c newRec: Trigger.new) {
            //LM
            Reference_PEO__c oldRec = Trigger.isUpdate ? Trigger.oldMap.get(newRec.id) : null;
            system.debug('LM oldRec ' + oldRec);
            TriggerMethods.checkInLoop('ReferencePEOUpdate', newRec, oldRec, Trigger.IsBefore, Trigger.IsAfter);

            if (Trigger.isAfter) {
                System.debug('ReferencePEOUpdate checking record newRec.Current_Step__c=' + newRec.Current_Step__c);
                if (Trigger.isUpdate) {                  
                    if (newRec.Status__c != oldRec.Status__c && newRec.RecordTypeID == PEORecordTypeId) {
                        updateCaseStatus.put(newRec.Parent_Case__c, newRec.Status__c);
                    } //end if status change for PEORecordTypeId
                    
                    // check record type is PEO Client Risk Assessment and service model value is updated and account lookup is not blank
                    if (newRec.RecordTypeID == PEORecordTypeId && Trigger.oldmap.get(newRec.id).Service_Model__c != newRec.Service_Model__c && newRec.Account_lookup__c != null && newRec.Service_Model__c != 0 && newRec.RA_Origin__c !='PEO Prospect') {
                        Account acc = new Account();
                        acc.Id = newRec.Account_lookup__c;
                        acc.Safety_Service_Model__c = newRec.Service_Model__c;
                        AccountWithServicedModel.put(newRec.Account_lookup__c,acc);
                    }

                    // should be a lookup present and a value in the current step field.
                    if ((newRec.Parent_Case__c != null) && (newRec.Current_Step__c != '')) {

                        // if update, only set if there is a value and step field changes 
                        if ((newRec.Current_Step__c != oldRec.Current_Step__c)) {
                            caseStepMap.put(newRec.Parent_Case__c, newRec.Current_Step__c);
                        } //end if Current Step changes

                        // make sure there's an opportunity
                        if (newRec.Opportunity__c != null) {
                            // if the Pass To New Loads flag changes
                            if (newRec.Pass_to_New_Loads__c && !oldRec.Pass_to_New_Loads__c) {
                                updateToSoldSub.add(newRec);
                                opptyIds.add(newRec.Opportunity__c);
                            } //end if newRec.Pass_to_New_Loads__c

                            // if the date is populated
                            if (newRec.Client_Processed__c != null && oldRec.Client_Processed__c == null) {
                                updateToSoldRun.add(newRec);
                                opptyIds.add(newRec.Opportunity__c);
                            } //end if newRec.Client_Processed__c
                        } // if (newRec.Opportunity__c
                    } //end if parent_Case !=null and current step != null
                } //end isUpdate
                else if (Trigger.isInsert) {            //<Pooja Singh>
                    if (newRec.RecordTypeID == PEORecordTypeId && newRec.Service_Model__c != null && newRec.Account_lookup__c != null && newRec.Service_Model__c != 0 && newRec.RA_Origin__c !='PEO Prospect') 
                    {    Account acc = new Account();
                        acc.id = newRec.Account_lookup__c;
                        acc.Safety_Service_Model__c = newRec.Service_Model__c; 
                        AccountWithServicedModel.put(newRec.Account_lookup__c,acc);
                    }
                } // isInsert
            } //end isAfter
            else{
                if(Trigger.isInsert){
                    peoToCheckUW.add(newRec);
                }
            }
        } // for (Reference_PEO__c

        //LM
        TriggerMethods.checkOutsideLoop('ReferencePEOUpdate', Trigger.isBefore, Trigger.isAfter);
        system.debug('ReferencePEOUpdate LM HERE ');

        if (!peoToCheckUW.isEmpty()) {
            ReferencePEOMedicalUWMethods.handleRefPEOs(peoToCheckUW);
        }
        
        if(Trigger.isInsert && Trigger.isAfter && ReferencePEOMedicalUWMethods.peoUWIdByOppIdMap!=null && !ReferencePEOMedicalUWMethods.peoUWIdByOppIdMap.isEmpty()){
            ReferencePEOMedicalUWMethods.processPEOUWLink();
        }
        
        if (!updateOwnerMap.isEmpty()) {
            ReferenceUpdateCase.updateCaseOwner(updateOwnerMap);
        }

        if (!updateCaseStatus.isEmpty()) {
            ReferenceUpdateCase.updateCaseStatus(updateCaseStatus);
        }

        if (!caseStepMap.isEmpty()) {
            ReferenceUpdateCase.updateCaseStep(caseStepMap);
        }

        if (!opptyIds.isEmpty()) {
            RefPEOUpdateOppty.processOpptys(opptyIds, updateToSoldSub, updateToSoldRun);
        } // if
    
        if(AccountWithServicedModel.size()>0)
        {   DmlHelper.performDML2(AccountWithServicedModel.values(), DmlHelper.DML_UPDATE, 'ReferencePEOUpdate', 'ReferencePEOUpdate', 'update Acct safety service model', true);   }

} // trigger ReferencePEOUpdate