/* 
 * Close cases that are related to a parent case
 *
 * History
 * -------
   12/12/2012 Dan Carmen   Commented out logic to close related 401k cases - moved to CaseCloseRelated class.
   11/13/2017 Dan Carmen   Clean up code and removed TriggerHelper reference
    07/06/2020  Jacob Hinds         Added without sharing per PMD

 */
global without sharing class IncidentCaseUtilities {
    
   public static integer collectionSize = 200;

    //***************************************************************   
    //***************************************************************
    //A. createMassIncidentCases
    //***************************************************************
    //***************************************************************
    @future
    public static void createMassIncidentCases(List<String> insertedCaseIdList)
    {
        System.debug('createMassIncidentCases(List<String> insertedCaseIdList) starts...');
        
        performCreateMassIncidentCases(insertedCaseIdList);

        System.debug('createMassIncidentCases(List<String> insertedCaseIdList) ends...');
    }       
    
    
   private static String getCaseFieldsSql(){
      String result = 'Select Id';
                
      for (SObjectField fldDef : Schema.SObjectType.Case.fields.getMap().values()) {
         if (fldDef.getDescribe().isCreateable()) {
            result += ','+fldDef.getDescribe().getName();
         }
      }
      result += ', (select id, commentbody from casecomments limit 1) from Case where id in ';

      return result;
   } // getCaseFieldsSql 
        
   private static void performCreateMassIncidentCases(List<String> insertedCaseIdList) { 
      if (insertedCaseIdList.size() == 0) {
         return;    //if there are no cases to insert, return
      }
            
      List<List<Double>> bisIdListOfList = new List<List<Double>>();
      List<Map<Double,String>> listOfAccountIdMap = new List<Map<Double,String>>();
      List <Case> massCases = new List <Case>();
        
      Map<String,String> caseCommentMap = new Map<String,String>();
        
      List<Case> insertedCaseList = new List<Case>();
      
      String[] caseIdList = new String[]{};
      caseIdList.addAll(insertedCaseIdList);
        
      String qry = getCaseFieldsSql() + ' :caseIdList ';
      System.debug('performCreateMassIncidentCases soql :'+qry);
      List<Case> cases = Database.query(qry);

      for (Case aCase : cases) {
         insertedCaseList.add(aCase);
            
         //2. CASE COMMENT
         if (aCase.casecomments != null
               && aCase.casecomments.size() != 0 
               && String.isNotBlank(aCase.casecomments[0].commentbody)
            ) {
            caseCommentMap.put(aCase.Id, aCase.casecomments[0].commentbody);          
         } // if (aCase.casecomments
      } // for (Case aCase
        
      List<Double> bisIdList = new List<Double>();        
      for (Case currentCase : insertedCaseList) {
         System.debug('MCI: '+currentCase.Mass_Create_Indicator__c+' bis_id_file__c: '+currentCase.bis_id_file__c);
        
         //If User wants Bis Id-based mass creation and has provided Bis Id's in bis_id_file__c field
         if ((currentCase.bis_id_file__c != null) && (currentCase.Mass_Create_Indicator__c == 'Bis ID')) {
            //Create a case for every valid Bis Id 
            for (String bisId : currentCase.bis_id_file__c.split (',', 0)) {
               if (bisId != null && bisIdList.size() < collectionSize){
                  try {
                     bisIdList.add(Double.valueOf (bisId.trim()));
                  } catch (Exception e) {}
               }           
            
               //check against our set limit for an array.
               if (bisIdList.size() == collectionSize){
                  System.debug('bisIdList.size() == collectionSize)');
                  bisIdListOfList.add(bisIdList);
                  bisIdList = new List<Double>();             
               }    
            } // for (String bisId
            
            if (!bisIdList.isEmpty()){
               System.debug('if (bisIdList != null && bisIdList.size() > 0){');
               System.debug('bisId.size():' + bisIdList.size());
               bisIdListOfList.add(bisIdList);         
            }    
         } // if ((currentCase.bis_id_file__c
      } // for (Case currentCase 

      for (Double[] aBisIdList : bisIdListOfList) {
         processBisIdList(aBisIdList, listOfAccountIdMap);
      }

      for (Case currentCase : insertedCaseList) {
         System.debug('MCI: '+currentCase.Mass_Create_Indicator__c+' bis_id_file__c: '+currentCase.bis_id_file__c);
        
         //If User wants Bis Id-based mass creation and has provided Bis Id's in bis_id_file__c field
         if ((currentCase.bis_id_file__c != null) && (currentCase.Mass_Create_Indicator__c == 'Bis ID')) {           
            //Create a case for every valid Bis Id 
                String accountId = null;
                for (String bisId : currentCase.bis_id_file__c.split (',', 0))
                {
                   try {
                    System.debug (Double.valueOf(bisId));
                    if (bisId != null && listOfAccountIdMap != null)
                    {
                        for (Integer i = 0; i < listOfAccountIdMap.size(); i++) 
                        {
                            Map<Double,String> accountIdMap = listOfAccountIdMap.get(i);    
                            if (accountIdMap.get(Double.valueOf(bisId.trim())) != null)
                            {
                                accountId = accountIdMap.get(Double.valueOf(bisId));
                                break;
                            }   
                        }
                    }

                    if (accountId != null)
                    {
                        Case massCase = currentCase.clone(false, true);
                        massCase.bis_id_file__c = null;
                        massCase.ParentId = currentCase.Id; 
                        massCase.AccountId = accountId;

                        //CASE
                        if (massCase != null && massCases.size() < collectionSize){
                            massCases.add(massCase);            
                        }           

                        System.debug('heapSizeLimit'+Limits.getLimitHeapSize());
                        System.debug('myHeapSize'+Limits.getHeapSize());
                        //1000 elements is the governor limit for an array.
                        if (massCases != null && massCases.size() == collectionSize){
                            System.debug('if (massCases != null && massCases.size() == collectionSize){');
                            DmlHelper.performDML2(massCases, DmlHelper.DML_INSERT, 'IncidentCaseUtilities', 'performCreateMassIncidentCases', 'Insert Cases in the loop', false);                            massCases = new List<Case>();           
                        }  
                        accountId = null;  
                    }
                   } catch (Exception e) {}
                } // for (String bisId    
            }
        } // for (Case currentCase
        
        if (massCases != null && massCases.size() > 0) {
            DmlHelper.performDML2(massCases, DmlHelper.DML_INSERT, 'IncidentCaseUtilities', 'performCreateMassIncidentCases', 'Insert Cases outside the loop', false);
        }

        //CASE COMMENT
        if (caseCommentMap != null 
            && caseCommentMap.keyset() != null
            && caseCommentMap.keyset().size() > 0)
        {   
            performCreateMassCaseComments(insertedCaseIdList, caseCommentMap);
        }
       ErrorLog.checkSave();
    }

   private static void performCreateMassCaseComments(List<String> insertedCaseIdList, Map<String,String> caseCommentMap) { 
      System.debug('performCreateMassCaseComments begins...');
        
      //retrieve the cases just created whose parents are the newly inserted cases.
      //this logic only works if related cases are only created on case create.
      List<CaseComment> relatedCaseComments = new List<CaseComment>();
      for (Case aCase : [Select c.id, c.parentid
                                FROM Case c 
                                where c.parentid in :insertedCaseIdList]) {
         CaseComment aCaseComment = new CaseComment();
            
         if (aCase != null && relatedCaseComments != null && relatedCaseComments.size() < collectionSize){
            aCaseComment.parentid = aCase.id;
                
            if (caseCommentMap != null && caseCommentMap.get(aCase.parentid) != null) {
               aCaseComment.commentbody = caseCommentMap.get(aCase.parentid); 
               relatedCaseComments.add(aCaseComment);              
            }
         } // if (aCase != null          
            
         //1000 elements is the governor limit for an array.
         if (relatedCaseComments != null && relatedCaseComments.size() == collectionSize){
             System.debug('if (relatedCaseComments != null && relatedCaseComments.size() == 1000){');
             DmlHelper.performDML2(relatedCaseComments, DmlHelper.DML_INSERT, 'IncidentCaseUtilities', 'performCreateMassCaseComments', 'Insert Case Comments in the loop', false);
             relatedCaseComments.clear();              
         }   
      } // for (Case aCase

      if (relatedCaseComments != null && relatedCaseComments.size() > 0){
         System.debug('relatedCaseComments.size():' + relatedCaseComments.size());
         DmlHelper.performDML2(relatedCaseComments, DmlHelper.DML_INSERT, 'IncidentCaseUtilities', 'performCreateMassCaseComments', 'Insert Case Comments outside the loop', false);
      }

      System.debug('performCreateMassCaseComments ends...');
   } // performCreateMassCaseComments

   // create a map of bis ids and account ids
   private static void processBisIdList(List<Double> aBisIdList, List<Map<Double,String>> listOfAccountIdMap) {
      Map<Double, String> accountIdMap = new Map<Double, String>();
        
      // select the accounts to check for valid bis ids
      for (Account aAccount : [SELECT id, bis_Id__c from Account WHERE Bis_Id__c in :aBisIdList]) {
         if (aAccount.bis_id__c != null && accountIdMap.size() < collectionSize){
            accountIdMap.put(aAccount.bis_id__c, aAccount.id);                      
         }           
            
         //collectionSize is the maximum size set for an array.
         if (accountIdMap.size() == collectionSize){
            System.debug('processBisIdList add accountIdMap to listOfAccountIdMap');
            listOfAccountIdMap.add(accountIdMap);
            accountIdMap = new Map<Double, String>();           
         }    
      } // for (Account aAccount
        
      if (accountIdMap != null && !accountIdMap.isEmpty()) {
         listOfAccountIdMap.add(accountIdMap);
      }
   } // processBisIdList
    
   //added 07/10/2009 to handle the issue with the mass create
   WebService static void massCreateIncidentCases(Id caseId){  
      Case[] caseList = [Select bis_id_file__c,Mass_Create_Indicator__c from case where Id=:caseId];          
      System.debug('caseList...'+caseList);
      boolean invalidBisId = false;   
      if (caseList != null && caseList.size() > 0 
          ) {
         List<String> insertedCaseIdList = new List<String>();
         for (Case cse : caseList) {
            
            boolean hasBisId = false;
            //If User wants Bis Id-based mass creation and has provided Bis Id's in bis_id_file__c field
            if ((cse.bis_id_file__c != null) && (cse.Mass_Create_Indicator__c == 'Bis ID')) {
               // check to see if the bis ids are numbers
               for (String bisId : cse.bis_id_file__c.split (',', 0)) {
                  try {
                     Double bisIdDouble = Double.valueOf(bisId.trim());
                     hasBisId = true;
                  } catch(Exception e) {
                     invalidBisId = true;
                     cse.bis_id_file__c.addError('One or more Bis Id is invalid.');
                     break;
                  } // try
               } // for
            } // if ((caseList[i]
            
            if (invalidBisId == false && hasBisId) {
               insertedCaseIdList.add(''+cse.id);
            }
         } // for (Case cse
        
         if (!invalidBisId 
              && insertedCaseIdList != null
              && insertedCaseIdList.size() > 0 
            ) {
            IncidentCaseUtilities.createMassIncidentCases(insertedCaseIdList);
            
         }
      } // if (caseList != null
   } // massCreateIncidentCases 

} // class IncidentCaseUtilities