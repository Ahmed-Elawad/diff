/*********************************************************************************************************************************
 Name:  DG_CampaignAttributionAnalyzerHelper_Class
 Created by DemadnGen Inc.
==================================================================================================================================
Purpose: Contains logic for Campaign Attribution Analyzer.
==================================================================================================================================
History
-------
VERSION     AUTHOR          DATE(dd/mm/yyyy)    DETAIL      Description
1.0         Gram Bischof    11/09/2018          Created     Created
            Dan Carmen       08/09/2023          Increment API
*********************************************************************************************************************************/

public class DG_CampaignAttributionAnalyzerHelper {
    
    public static List<CAA_Record__c> createCAARecords(List<CampaignMember> theCMList,Opportunity theOpp,DG_CAA_Settings__mdt CASettings,String datefield, Boolean IsWon) {
        List<CAA_Record__c> theCAARecordsList = new List<CAA_Record__c>();
        //Pipeline
        
        List<CampaignMember> propsectCMs = new List<CampaignMember>();
        List<CampaignMember> possibleAccelerators = new List<CampaignMember>();
        DateTime attributionStart = theOpp.createdDate.addDays(-1 * (Integer)CASettings.Attribution_Window__c);
        System.debug(attributionStart);
        System.debug(theOpp.CreatedDate);
        for(CampaignMember cm: theCMList){
            // Attribution window will be CAA_Settings__c.Attribution_Window__c days prior Opportunity.CreatedDate to Opportunity.CreatedDate
            System.debug((DateTime)cm.get(datefield));
            if((DateTime)cm.get(datefield) >= attributionStart && ((DateTime)cm.get(datefield)).date() <= theOpp.CreatedDate) propsectCMs.add(cm);
            else possibleAccelerators.add(cm);
        }
        System.debug(propsectCMs);
        System.debug(possibleAccelerators);
        
        if(CASettings.Model_Pipeline_First_Touch__c == true) {
            system.debug('!! Pipeline - First Touch');
            theCAARecordsList.add(processFirstTouch(propsectCMs,theOpp,dateField,'Pipeline - First Touch'));    
        }  
        if(CASettings.Model_Pipeline_Last_Touch__c == true) {
            theCAARecordsList.add(processLastTouch(propsectCMs,theOpp,dateField,'Pipeline - Last Touch'));     
        } 
        if(CASettings.Model_Pipeline_Linear__c  == true) {
            theCAARecordsList.addall(processMTLinear(propsectCMs,theOpp,dateField,'Pipeline - Linear (MT)'));     
        } 
        if(CASettings.Model_Pipeline_Position_Based__c   == true) {
            theCAARecordsList.addall(processMTPosition(propsectCMs,theOpp,dateField,CASettings,'Pipeline - Position (MT)'));     
        } 
        if(CASettings.Model_Pipeline_Weighted__c   == true) {
            theCAARecordsList.addall(processMTWeighted(propsectCMs,theOpp,dateField,'Pipeline - Weighted (MT)'));     
        }
        
        
        //Bookings
        if(IsWon) {
            List<CampaignMember> acceleratorCMs = new List<CampaignMember>();
            for(CampaignMember cm: possibleAccelerators){
                // if CAA_Setting__c.Include_Accelerator__c
                // Attribution window will be CAA_Settings__c.Attribution_Window__c days prior Opportunity.CreatedDate to Opportunity.CloseDate
                if(CASettings.Include_Accelerators_for_Bookings__c){
                    if((DateTime)cm.get(datefield) >= attributionStart && ((DateTime)cm.get(datefield)).date() <= theOpp.CloseDate) acceleratorCMs.add(cm);
                }
                else{
                    // Attribution window will be CAA_Settings__c.Attribution_Window__c days prior Opportunity.CreatedDate to Opportunity.CreatedDate
                    if((DateTime)cm.get(datefield) <= attributionStart && ((DateTime)cm.get(datefield)).date() >= theOpp.CreatedDate) acceleratorCMs.add(cm);
                }
            }
            if(CASettings.Model_Bookings_First_Touch__c == true) {
                theCAARecordsList.add(processFirstTouch(theCMList,theOpp,dateField,'Bookings - First Touch'));    
            }  
            if(CASettings.Model_Bookings_Last_Touch__c == true) {
                theCAARecordsList.add(processLastTouch(theCMList,theOpp,dateField,'Bookings - Last Touch'));     
            } 
            if(CASettings.Model_Bookings_Linear__c  == true) {
                theCAARecordsList.addall(processMTLinear(theCMList,theOpp,dateField,'Bookings - Linear (MT)'));     
            } 
            if(CASettings.Model_Bookings_Position_Based__c   == true) {
                theCAARecordsList.addall(processMTPosition(theCMList,theOpp,dateField,CASettings,'Bookings - Position (MT)'));     
            } 
            if(CASettings.Model_Bookings_Weighted__c   == true) {
                theCAARecordsList.addall(processMTWeighted(theCMList,theOpp,dateField,' Bookings - Weighted (MT)'));     
            }
        }
        return theCAARecordsList;    
    }
    
    // Model 1
    public static CAA_Record__c processFirstTouch(List<CampaignMember> theCMList,Opportunity theOpp,String dateField,String Model){
        System.debug(findFirstCampaignMember(theCMList,dateField));
        return createCAARecord(findFirstCampaignMember(theCMList,dateField),theOpp,Model,1);
    }
    
    // Model 2
    public static CAA_Record__c processLastTouch(List<CampaignMember> theCMList,Opportunity theOpp,String dateField,String Model){
        return createCAARecord(findLastCampaignMember(theCMList,dateField),theOpp,Model,1);
    }
    
    // Model 3
    public static List<CAA_Record__c> processMTLinear(List<CampaignMember> theCMList,Opportunity theOpp,String dateField,String Model){
        List<CAA_Record__c> theCAALinearList = new List<CAA_Record__c>();
        System.debug('theCMListM1'+theCMList.size());
        Decimal M3Weight = 0;
        Double CMSize = theCMList.size();
        M3Weight = 1/CMSize;
        for(CampaignMember theCM : theCMList) {
            theCAALinearList.add(createCAARecord(theCM,theOpp,Model,M3Weight));            
        }
        return theCAALinearList;
    }
    
    // Model 4
    public static List<CAA_Record__c> processMTPosition(List<CampaignMember> theCMList,Opportunity theOpp,String dateField,DG_CAA_Settings__mdt CASettings,String Model){
        List<CAA_Record__c> theCAAPositionList = new List<CAA_Record__c>();
        Map<Id,CAA_Record__c> theCMIdCAAMap = new Map<Id,CAA_Record__c>(); 
        Decimal Weight = 0;
        Decimal FirstWeight = 0;
        Decimal LastWeight = 0;
        Double FP = CASettings.First_Position__c;
        Double LP = CASettings.Last_Position__c;
        System.debug('theCMListM2'+theCMList);
        if(theCMList.size() == 1) {
            Weight = 1;
            theCAAPositionList.add(createCAARecord(theCMList[0],theOpp,Model,Weight));                       
        } 
        if(theCMList.size() == 2) {
            FirstWeight = FP/(FP+LP);
            LastWeight = LP/(FP+LP);
            theCAAPositionList.add(createCAARecord(findFirstCampaignMember(theCMList,dateField),theOpp,Model,FirstWeight));
            theCAAPositionList.add(createCAARecord(findLastCampaignMember(theCMList,dateField),theOpp,Model,LastWeight));
        } 
        if(theCMList.size() > 2) {
            FirstWeight = FP/100;
            LastWeight = LP/100;
            Weight = ((100 - FP - LP)/100) / (theCMList.size()-2);
            System.debug(Weight);
            CampaignMember firstCM = findFirstCampaignMember(theCMList,dateField);
            CampaignMember LastCM = findLastCampaignMember(theCMList,dateField);
            theCAAPositionList.add(createCAARecord(firstCM,theOpp,Model,FirstWeight));
            theCAAPositionList.add(createCAARecord(LastCM,theOpp,Model,LastWeight));
            for(CampaignMember theCM : theCMList) {
                if(theCM != firstCM && theCM != LastCM){
                    System.debug(theCM);
                    System.debug(firstCM);
                    System.debug(LastCM);
                    theCAAPositionList.add(createCAARecord(theCM,theOpp,Model,Weight));
                }             
            } 
        }
        return theCAAPositionList;
    }
    
    // Model 5
    public static List<CAA_Record__c> processMTWeighted(List<CampaignMember> theCMList,Opportunity theOpp,String dateField,String Model){
        List<CAA_Record__c> theCAAWeightedList = new List<CAA_Record__c>();
        Map<String, DG_CAA_Campaign_Weight__mdt> mapCampaignWeight = DG_CampaignAttributionAnalyzer_Class.getCAACampaignWeights();
        Decimal TotalWeight = 0;
        System.debug('theCMListM3'+theCMList);
        for(CampaignMember theCM : theCMList) {
            if(mapCampaignWeight.containskey(theCM.Campaign.Type)) TotalWeight = TotalWeight + mapCampaignWeight.get(theCM.Campaign.Type).Weight__c;
        }
        System.debug('TotalWeight: '+TotalWeight);
        for(CampaignMember theCM : theCMList) {
            Decimal weight = 0;
            if(mapCampaignWeight.containskey(theCM.Campaign.Type)) weight = mapCampaignWeight.get(theCM.Campaign.Type).Weight__c / TotalWeight;
            System.debug('weight: '+weight);
            theCAAWeightedList.add(createCAARecord(theCM,theOpp,Model,weight));            
        }
        return theCAAWeightedList;
    }
    
    public static CAA_Record__c createCAARecord(CampaignMember theCM,Opportunity theOpp,String Model, Decimal Weight) {
        CAA_Record__c theCAA = new CAA_Record__c();
        Decimal Amount = theOpp.Amount == null? 0 : theOpp.Amount;
        theCAA.Campaign__c = theCM.CampaignId;
        theCAA.Opportunity__c = theOpp.Id;
        theCAA.Contact__c = theCM.ContactId;
        theCAA.Model__c = Model;
        theCAA.Split_Amount__c =  Amount * Weight;
        theCAA.Membership_Date__c = theCM.CreatedDate;
        theCAA.Response_Date__c = theCM.FirstRespondedDate;
        theCAA.Weight__c = Weight * 100;
        return theCAA;
    }
    
    public static CampaignMember findFirstCampaignMember(List<CampaignMember> theCMList,String dateField){
      System.debug('!! ' + theCMList);
      System.debug('!! dateField: ' + dateField);  
      CampaignMember FirstCampaign;
      for(CampaignMember theCM : theCMList) {
          if(FirstCampaign == null) FirstCampaign = theCM;  
          if(dateField == 'CreatedDate'){
              if(theCM.CreatedDate < FirstCampaign.CreatedDate) FirstCampaign = theCM;
          }
          else if(theCM.FirstRespondedDate < FirstCampaign.FirstRespondedDate) FirstCampaign = theCM;
      }
      return FirstCampaign;  
    }
    
    public static CampaignMember findLastCampaignMember(List<CampaignMember> theCMList,String dateField){
      CampaignMember LastCampaign;
      for(CampaignMember theCM : theCMList) {
          if(LastCampaign == null) LastCampaign = theCM;  
          if(dateField == 'CreatedDate' && theCM.CreatedDate > LastCampaign.CreatedDate) LastCampaign = theCM;
          else if(theCM.FirstRespondedDate > LastCampaign.FirstRespondedDate) LastCampaign = theCM;
          else if(theCM.FirstRespondedDate == LastCampaign.FirstRespondedDate && theCM.CreatedDate > LastCampaign.CreatedDate) LastCampaign = theCM;
      }
      return LastCampaign;  
    }
}