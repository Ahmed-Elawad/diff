/* Methods for managing field values

  History
  -------
  03/17/2020 Dan Carmen        Created
  
 */
public without sharing class FieldChecker implements TriggerInterfaceC {
   public static final String CLASSNAME='FieldChecker';

   public void handleTrigger(SObject[] recs, Map<Id,SObject> oldMap, Boolean isBefore, Boolean isAfter, Boolean isDelete) {
      if (TriggerMethods.didTriggerRun(CLASSNAME,recs,oldMap,isBefore,isAfter,isDelete)) {
         return;
      }
      SObjectType objType = TriggerMethods.objType;
      String objTypeName = TriggerMethods.objectTypeName;
      System.debug(CLASSNAME+' objTypeName='+objTypeName+' recs='+(recs != null ? recs.size() : -1)+' isBefore='+isBefore+' isAfter='+isAfter+' isDelete='+isDelete);

      if (isBefore) {
         if (objType == Contact.sObjectType) {
            handleContacts((Contact[])recs,(Map<Id,Contact>)oldMap);
         } else if (objType == Account.sObjectType) {
            handleAccounts((Account[])recs,(Map<Id,Account>)oldMap);
         } else if (objType == Lead.sObjectType) {
            handleLeads((Lead[])recs,(Map<Id,Lead>)oldMap);
         }

      }

   } // checkAllBeforeTrigger
    
    public static void handleLeads(Lead[] recs, Map<Id,Lead> oldMap) {
        for (Lead ld : recs) {
           Lead oldRec = (oldMap != null ? oldMap.get(ld.Id) : null);
           // if it's a new record or the state value changes
            if (String.isNotBlank(ld.State) && (oldRec == null || ld.State != oldRec.State)) {
               checkStateField(ld,'State');
            }
        } // for (Lead ld : recs
    } // handleLeads
    
    public static void handleContacts(Contact[] recs, Map<Id,Contact> oldMap) {
        for (Contact ctct : recs) {
           Contact oldRec = (oldMap != null ? oldMap.get(ctct.Id) : null);
           // if it's a new record or the state value changes
            if (String.isNotBlank(ctct.MailingState) && (oldRec == null || ctct.MailingState != oldRec.MailingState)) {
               checkStateField(ctct,'MailingState');
            }
        } // for (Contact ctct : recs
    } // handleContacts
    
    public static void handleAccounts(Account[] recs, Map<Id,Account> oldMap) {
        for (Account acct : recs) {
           Account oldRec = (oldMap != null ? oldMap.get(acct.Id) : null);
           // if it's a new record or the state value changes
           if (String.isNotBlank(acct.ShippingState) || String.isNotBlank(acct.BillingState)
               && (oldRec == null
                    || (acct.ShippingState != oldRec.ShippingState
                        || acct.BillingState != oldRec.BillingState))) {
              checkStateField(acct,'ShippingState');
              checkStateField(acct,'BillingState');
           }
        } // for (Account acct : recs
    } // handleAccounts

    public static void checkStateField(SObject rec, String fldName) {
       String stateValue = (String)rec.get(fldName);
        // if two characters or less, don't do anything with it.
        if (String.isBlank(stateValue) || stateValue.length() <= 2) {
           System.debug('checkStateField stateValue='+stateValue);
           return;
        }
        stateValue = stateValue.toLowerCase();
        String newValue = null;
        switch on stateValue {
            when 'alabama' {newValue='AL';}
            when 'alaska' {newValue='AK';}
            when 'arizona' {newValue='AZ';}
            when 'arkansas' {newValue='AR';}
            when 'california' {newValue='CA';}
            when 'colorado' {newValue='CO';}
            when 'connecticut' {newValue='CT';}
            when 'delaware' {newValue='DE';}
            when 'florida' {newValue='FL';}
            when 'georgia' {newValue='GA';}
            when 'hawaii' {newValue='HI';}
            when 'idaho' {newValue='ID';}
            when 'illinois' {newValue='IL';}
            when 'indiana' {newValue='IN';}
            when 'iowa' {newValue='IA';}
            when 'kansas' {newValue='KS';}
            when 'kentucky' {newValue='KY';}
            when 'louisiana' {newValue='LA';}
            when 'maine' {newValue='ME';}
            when 'maryland' {newValue='MD';}
            when 'massachusetts' {newValue='MA';}
            when 'michigan' {newValue='MI';}
            when 'minnesota' {newValue='MN';}
            when 'mississippi' {newValue='MS';}
            when 'missouri' {newValue='MO';}
            when 'montana' {newValue='MT';}
            when 'nebraska' {newValue='NE';}
            when 'nevada' {newValue='NV';}
            when 'new hampshire' {newValue='NH';}
            when 'new jersey' {newValue='NJ';}
            when 'new mexico' {newValue='NM';}
            when 'new york' {newValue='NY';}
            when 'north carolina' {newValue='NC';}
            when 'north dakota' {newValue='ND';}
            when 'ohio' {newValue='OH';}
            when 'oklahoma' {newValue='OK';}
            when 'oregon' {newValue='OR';}
            when 'pennsylvania' {newValue='PA';}
            when 'rhode island' {newValue='RI';}
            when 'south carolina' {newValue='SC';}
            when 'south dakota' {newValue='SD';}
            when 'tennessee' {newValue='TN';}
            when 'texas' {newValue='TX';}
            when 'utah' {newValue='UT';}
            when 'vermont' {newValue='VT';}
            when 'virginia' {newValue='VA';}
            when 'washington' {newValue='WA';}
            when 'west virginia' {newValue='WV';}
            when 'wisconsin' {newValue='WI';}
            when 'wyoming' {newValue='WY';}
        } // switch on
        System.debug('checkStateField stateValue='+stateValue+' newValue='+newValue);
        if (String.isNotBlank(newValue)) {
            rec.put(fldName,newValue);
            StringHelper.addToProcessNotes(rec,'Changed '+fldName+' from '+stateValue+' to '+newValue);
        }
    } // checkStateField
    
} // class FieldChecker