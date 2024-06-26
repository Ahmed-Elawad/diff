/* 
 * A class implementing TriggerInterface to call the Oppty Before Trigger
 *
 * History
 * -------
 * 08/01/2017   Jermaine Stukes     Created
 * 09/22/2017   Josh Cartwright     Added Sales Profile Logic
 * 09/25/2017   Jermaine Stukes     Updated Sold Validation logic
 * 12/04/2017   Cindy Freeman       added code for FLEX BenAdmin product, rewrote code to work with HandBook Contact logic 
                                    only checks for Handbook if runningUser is a SalesRep
 * 01/31/2018   Cindy Freeman       fix if statement to handle ProductCode = Null
 * 03/16/2020   Matt Fritschi       Now checks for Oracle Quote products in addition to Steelbrick products 
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
   05/19/2021  Dan Carmen          Changed to use Probability vs StageName

 */
public without sharing class OpptyProductCheck implements TriggerInterface
{
    Public void checkAllBeforeTrigger(SObject[] recs, Map<Id,Object> oldMap){}
    
    Public void checkAllAfterTrigger(SObject[] recs, Map<Id,Object> oldMap){}
    
    Public void checkAfterTrigger(SObject newRec, SObject oldRec){}
    
    Public void processAfterTriggerActions(){}
    
  public static Map<Id, Opportunity> idOptyBenAdminMap = new Map<Id, Opportunity>();
  public static Map<Id, Opportunity> idOptyHandbookMap = new Map<Id, Opportunity>();
  public static Set<Id> alreadyProcessedOptySet = new Set<Id>();
    
    Public void checkBeforeTrigger(SObject newRec, SObject oldRec) 
    {   //only want to do some checks if Sales User or running a test
      User runningUser = UserHelper.getRunningUser();
      Boolean userOKtoCheck = (runningUser.Job_Name__c != Null || Test.isRunningTest()? true : false); 
      System.debug('**OpptyProductCheck.userOKtoCheck='+userOktoCheck);     

      Opportunity newOpty = (Opportunity)newRec;
      Opportunity oldOpty = (Opportunity)oldRec;      
      if (oldRec != null && !alreadyProcessedOptySet.contains(newRec.Id))
      {  if (userOKtoCheck)
        {  alreadyProcessedOptySet.add(newOpty.Id);
//          if (OpportunityCreateCase.SOLD_STATUS_SET.contains(newOpty.StageName)
          if ((newOpty.Probability >= 80 && newOpty.Probability < 100)
                && oldOpty.stageName != newOpty.StageName)          // stage changed to Sold
              {  idOptyBenAdminMap.put(newOpty.Id, newOpty);
                idOptyHandbookMap.put(newOpty.Id, newOpty);
              }
//              if (OpportunityCreateCase.SOLD_STATUS_SET.contains(newOpty.StageName)
              if ((newOpty.Probability >= 80 && newOpty.Probability < 100)
                && newOpty.Handbook_Contact__c == null
                && oldOpty.Handbook_Contact__c != null)                  // already sold but Handbook Ctct was cleared
              {  idOptyHandbookMap.put(newOpty.Id, newOpty);  }
        } // if (userOKtoCheck)
      }  // if (oldOpty!=null)
              
    } // checkBeforeTrigger
    
    Public void processBeforeTriggerActions(){
       if (!idOptyBenAdminMap.isEmpty() || !idOptyHandbookMap.isEmpty()) {
          verifyProductsAndFields();
       }
       alreadyProcessedOptySet.clear();
    }    
    
    /*    
    public static Set<String> PRODUCT_NAMES = new Set<String> {'Employee Handbook Builder'
        ,'Paychex Productivity Package'
        ,'Paychex Professional'
        ,'Paychex Flex Enterprise'
        ,'Paychex Flex Pro'};
    */
    
    public static void verifyProductsAndFields() 
    {
     String flexBAProdCode = Label.FLEX_BenAdmin_Product_Code;     
     Set<String> handbookProdNames = new Set<String>(Label.Handbook_Product_Code.split(','));
       // select the line items
       List<OpportunityLineItem> lineItems = [Select Id, OpportunityId
                                               ,Product2.Name
                                               ,Product2.ProductCode
                                               ,Oracle_Quote_Line__r.cafsl__Product__c
                                               From OpportunityLineItem
                                               Where OpportunityId in:idOptyBenAdminMap.keyset()
                                                   Or OpportunityId in:idOptyHandbookMap.keyset()];               
       System.debug('** OpptyProductCheck verifyProductsAndFields oli='+lineItems.size());
       
       // find optys that have BenAdmin or Handbook product
       Set<Id> benAdminOptyIdSet = new Set<Id>();
       Set<Id> handbookOptyIdSet = new Set<Id>();
       for (OpportunityLineItem oli : lineItems) 
       {   if (handbookProdNames.contains(oli.Product2.Name))
           {  handbookOptyIdSet.add(oli.OpportunityId);  }           
           if (oli.Product2.ProductCode != Null && oli.Product2.ProductCode.startsWith(flexBAProdCode))
           {  benAdminOptyIdSet.add(oli.OpportunityId);  }
       } // for
       
       // loop thru optys to see if they have the product then check if they have the related field filled in
       for (Opportunity opty:idOptyBenAdminMap.values())
       {  if (benAdminOptyIdSet.contains(opty.Id))
           {  if (String.isBlank(opty.Benefit_Types_Offered__c))
             {  opty.Benefit_Types_Offered__c.addError('This opty has a Flex Ben Admin product so you must select a Benefit Type before marking it Sold.');    }  
           } // if           
       }  // for
       for (Opportunity opty:idOptyHandbookMap.values())
       {  if (handbookOptyIdSet.contains(opty.Id))
           {  if (String.isBlank(opty.Handbook_Contact__c))
             {  opty.Handbook_Contact__c.addError('A \"Handbook Contact\" must be entered for this opportunity.');      }
           } // if
       } // for 
       
   } // verifyHandbookContact

 
}