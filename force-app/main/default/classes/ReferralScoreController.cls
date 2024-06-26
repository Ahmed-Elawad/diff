/* 
 * Controller for maintain the referral score ranges
 *
 * History
 * -------
   05/16/2016 Dan Carmen   Created
 *
 */
public without sharing class ReferralScoreController {

   // The different types of referral sources available for maintainance. 
   public static String[] REFERRAL_SOURCES = Label.ReferralTypeSources.split(',');

   public ReferralScoreController() {
      refSourceOptions = null;
      setupForm();
   } // ReferralScoreController

   public SelectOption[] refSourceOptions{get;set;}
   
   public void setupForm() {
      if (refSourceOptions == null) {
         refSourceOptions = new SelectOption[]{};
         for (String refSource : REFERRAL_SOURCES) {
            refSourceOptions.add(new SelectOption(refSource,refSource));
         }
      } // if (refSourceOptions == null
      retrieveSetups();
   } // setupForm
   
   public Boolean hasSetups{
      get {return (setups != null && !setups.isEmpty()); }
   }

   public ReferralScoreSetup__c[] setups{get;set;}
   
   public void retrieveSetups() {
      setups = [Select Id, Name
                      ,RangeMax__c
                      ,RangeMin__c
                      ,ReferralSource__c
                      ,ReferralType__c
                      ,SoldReferrals__c
                  From ReferralScoreSetup__c
              order by ReferralSource__c, SoldReferrals__c, RangeMin__c asc];
      if (setups.isEmpty()) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'No records are setup! Click Add New Record to start the setup.'));
      }
   } // retrieveSetups
   
   public PageReference addNewRecord() {
      setups.add(new ReferralScoreSetup__c());
      return null;
   } // addNewRecord
      
   public PageReference cancelAdd() {
      setupForm();
      return null;
   } // cancelAdd
   
   public static Integer NAME_LENGTH=ReferralScoreSetup__c.Name.getDescribe().getLength()-1;

   public PageReference saveRecords() {
      if (hasSetups) {
         Map<String,ReferralScoreSetup__c[]> bySourceMap = new Map<String,ReferralScoreSetup__c[]>();
         for (ReferralScoreSetup__c setup : setups) {
            String source=setup.ReferralSource__c+(setup.SoldReferrals__c ? 'Sold' : 'NotSold');
            ReferralScoreSetup__c[] sourceList = bySourceMap.get(source);
            if (sourceList == null) {
               sourceList = new ReferralScoreSetup__c[]{};
               bySourceMap.put(source, sourceList);
            }
            sourceList.add(setup);
            if (setup.Id == null) {
               String refType = Utilities.removeExtraChars(setup.ReferralType__c,Utilities.ALL_ALPHAS+Utilities.ALL_NUMBERS);
               setup.Name = (source+refType+';'+setup.RangeMin__c+'-'+setup.RangeMax__c).left(NAME_LENGTH);
            }
         } // for (ReferralScoreSetup__c setup
         Boolean allOkay = true;
         for (ReferralScoreSetup__c[] sourceList : bySourceMap.values()) {
            if (!verifyRecords(sourceList)) {
               allOkay = false;
            }
         } // for (ReferralScoreSetup__c
         
         if (allOkay) {
            upsert setups;
            setupForm();
			referralScorePL(); //JC added to create new Pick vals to referral score    
            
         } // if (allOkay
      } // if (hasSetups
      return null;
   } // saveRecords
   
   // make sure there's no overlap within each referral source
   public Boolean verifyRecords(ReferralScoreSetup__c[] sourceList) {
      Map<Integer, ReferralScoreSetup__c> byMinRangeMap = new Map<Integer, ReferralScoreSetup__c>();
      Boolean okay = true;
      for (ReferralScoreSetup__c setup : sourceList) {
         if (byMinRangeMap.containsKey((Integer)setup.RangeMin__c)) {
            // we have a range overlap - we can stop here.
            okay = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'There is more than one '+setup.ReferralSource__c+' with the starting range of '+setup.RangeMin__c+'. Range values cannot overlap!'));
            break;
         } else {
            byMinRangeMap.put((Integer)setup.RangeMin__c, setup);
         }
         
      } // for
      
      if (okay) {
         Integer[] keyList = new Integer[]{};
         keyList.addAll(byMinRangeMap.keySet()); 
         keyList.sort();
      
         ReferralScoreSetup__c prevSetup = null;
         for (Integer key : keyList) {
            ReferralScoreSetup__c thisSetup = byMinRangeMap.get(key);
            if (prevSetup != null) {
               if (thisSetup.RangeMin__c <= prevSetup.RangeMax__c) {
                  okay = false;
                  thisSetup.addError('The ranges for the Referral Score setup cannot overlap each other for the same Referral Source!');
               }
            } // if (prevSetup != null
            prevSetup = thisSetup;
         } // for (Integer key
      } // if (okay
      return okay;
   } // verifyRecords
   
   public PageReference deleteSetup() {
      String setupId = System.currentPageReference().getParameters().get('setupId');
      try {
         delete [select Id from ReferralScoreSetup__c where Id=:setupId];
         setupForm();
      } catch (Exception e) {
         ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Error deleting Setup record! '+e.getMessage()));
      }
      return null;
   } // deleteSetup
   
   //JC select custom setting values to compare to Referral Score fields and update field picklist values:
       
  	 public void referralScorePL(){
   		set <string> acctSPLSet = new set <string>(); //acct sold pl 
   		set <string> acctTPLSet = new set <string>(); // acct total 
   		set <string> ctctSPLSet = new set <string>(); //ctct sold 
		set <string> ctctTPLSet = new set <string>(); //ctct total 	
		
		set <string> cSValuesSet = new set <string>(); //values of the custom setting 	
			
		/*
		set <string> aSCSValuesSet = new set <string>(); //acct sold value 
		set <string> aTCSValuesSet = new set <string>(); //acct total value 
		
		set <string> cSCSValuesSet = new set <string>(); //ctct sold 
		set <string> CTCSValuesSet = new set <string>(); //ctct total 
		*/
		
		string aSMissingvals = ''; //acct sold missing values 
		string aTMissingvals = '';  //acct total missing values 
		
		
		string cSMissingVals = ''; //ctct sold missing values 
		string cTMissingVals = '';  //ctct total missing values 
		
		
		

		//piclklist values for acct referrals sold 
   		Schema.DescribeFieldResult aSfieldResult = Account.ScoreRfrlsSold__c.getDescribe();	
   		List<Schema.PicklistEntry> aSples = aSfieldResult.getPicklistValues();
   		
		//picklist values for acct total referrals 
		Schema.DescribeFieldResult aTfieldResult = Account.ScoreTotalRfrls__c.getDescribe();	
   		List<Schema.PicklistEntry> aTples = aSfieldResult.getPicklistValues();   		
   		
		//picklist values for ctct referrals sold    		
   		Schema.DescribeFieldResult cSfieldResult = Contact.ScoreRfrlsSold__c.getDescribe();	
   		List<Schema.PicklistEntry> cSples = cSfieldResult.getPicklistValues();
   		
		//picklist values for ctct referrals total     		
   		Schema.DescribeFieldResult cTfieldResult = Contact.ScoreTotalRfrls__c.getDescribe();	
   		List<Schema.PicklistEntry> cTples = cTfieldResult.getPicklistValues();   		
   		
		//add account current sold picklist vals to set 
   		for(schema.picklistEntry ple: aSples){
   			acctSPLSet.add (ple.getvalue()); 
   		}//for 
   		
		//add account current total picklist vals to set 
   		for(schema.picklistEntry ple: aTples){
   			acctTPLSet.add (ple.getvalue()); 
   		}//for 
   		   		   	
   		   		  		
   		//add contact current sold picklist vals to set
   		for(schema.picklistEntry cple: cSples){
   			ctctSPLSet.add (cple.getvalue()); 
   		}//for 

   		//add contact current total picklist vals to set
   		for(schema.picklistEntry cple: cTples){
   			ctctTPLSet.add (cple.getvalue()); 
   		}//for    		
   		
   		//get values from custom setting  and add to a set 
 		for (ReferralScoreSetup__c rss : ReferralScoreSetup__c.getAll().values()) {
 	 		/*aSCSValuesSet.add(rss.ReferralType__c);
			aTCSValuesSet.add(rss.ReferralType__c); 	 		
 	 		
 	 		cSCSValuesSet.add (rss.ReferralType__c);
 	 		cTCSValuesSet.add (rss.ReferralType__c);
		*/
			if(!acctSPLSet.contains(rss.ReferralType__c)) {
				aSMissingvals += (string.isNotBlank(aSMissingvals) ? ', ' : '') + rss.ReferralType__c; 
			}//if 
			
			if(!acctTPLSet.contains(rss.ReferralType__c)) {
				aTMissingvals += (string.isNotBlank(aTMissingvals) ? ', ' : '') + rss.ReferralType__c; 
			}//if 			

			if(!ctctSPLSet.contains(rss.ReferralType__c)) {
				cSMissingvals += (string.isNotBlank(cSMissingvals) ? ', ' : '') + rss.ReferralType__c; 
			}//if 
			
			if(!ctctTPLSet.contains(rss.ReferralType__c)) {
				cTMissingvals += (string.isNotBlank(cTMissingvals) ? ', ' : '') + rss.ReferralType__c; 
			}//if 			
			
			
			//if statement for each of the other 3 	 		
 	 		
   	    } //for 
   	    //display messages on page if values are missing 
   	       	if(aSMissingvals != ''){
   			apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'The following values are missing from the Account "Score - Referrals Sold" Picklist field' + aSMissingvals )); 	
   			}
   			
   			if(aTMissingvals != ''){
   			apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'The following values are missing from the Account "Score - Total Referrals" Picklist field' + aTMissingvals )); 
   			}
   			
			if(cSMissingvals != ''){
   			apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'The following values are missing from the Contact "Score - Referrals Sold" Picklist field' + cSMissingvals ));    			
			}
			
   			if(cTMissingvals != ''){
   			apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'The following values are missing from the Contact "Score - Total Referrals" Picklist field' + cTMissingvals));   	    
   			}
   	    //if statemetns for each of the other 3 
   	    
   	 /*     		
   		//Account Remove existing values from Custom setting set - sold 
   		for(string plValue: acctSPLSet){
   			
   			aSCSValuesSet.remove(plvalue); 
   			
   		}//for 
   		
   		//Account Remove existing values from Custom setting set - Total 
   		for(string plValue: acctTPLSet){
   			
   			aTCSValuesSet.remove(plvalue); 
   			
   		}//for    		
   		
   		if(!aSCSValuesSet.isempty() && aSCSValuesSet != null){
   			
   			for(string s: aSCSValuesSet){
   				aSMissingvals += s + ', ' ;
   				
   			}//for
   			
   			if(aSMissingvals != ''){
   			apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'The following values are missing from the Account "Score - Referrals Sold" Picklist field' + aSMissingvals )); 
   				
   			}
   			
   		 }  //if

   		
   		if(!aTCSValuesSet.isempty() && aTCSValuesSet != null){
   			
   			for(string s: aTCSValuesSet){
   				aTMissingvals += s + ', ' ;
   				
   			}//for
   			
   			if(aTMissingvals != ''){
   			apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error,'The following values are missing from the Account "Score - Total Referrals" Picklist field' + aTMissingvals )); 
   				
   			}
   			
   		 }  //if   		 
   		 
   		//Contact Remove existing values from Custom setting set -sold 
   		for(string cplValue: ctctSPLset){
   			
   			cSCSValuesSet.remove(cplvalue); 
   			
   		}//for 
   		
   		//Contact Remove existing values from Custom setting set - total  
   		for(string cplValue: ctctTPLset){
   			
   			cTCSValuesSet.remove(cplvalue); 
   		}//for 

   				   		
   		
   		if(!cSCSValuesSet.isempty() && cSCSValuesSet != null){
   			
   			for(string s: cSCSValuesSet){
   				cSMissingvals += s + ', ' ;
   				
   			}//for
   			
   			if(cSMissingvals != ''){
   			apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'The following values are missing from the Contact "Score - Referrals Sold" Picklist field' + cSMissingvals )); 
   				
   			}
   			
   		 }  //if
   		
   		if(!cTCSValuesSet.isempty() && cTCSValuesSet != null){
   			
   			for(string s: ctCSValuesSet){
   				cTMissingvals += s + ', ' ;
   				
   			}//for
   			
   			if(cTMissingvals != ''){
   			apexPages.addMessage(new ApexPages.Message(ApexPages.severity.error, 'The following values are missing from the Contact "Score - Total Referrals" Picklist field' + cTMissingvals)); 
   				
   			}
   			
   		 }  //if   		 
   		*/
   	
   }//referralscore
   
  
   
   
   //end jc new code 
   
   
   
} // class ReferralScoreController