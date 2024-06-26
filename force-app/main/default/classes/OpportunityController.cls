/*
    
    07/06/2020  Jacob Hinds         Added without sharing per PMD
    05.19/2021  Dan Carmen          Update to use label for opp stages

*/
public without sharing class OpportunityController {
    private final ApexPages.StandardController theController;
    public Opportunity theOpp{get;set;}
    private String oppId;
    public String Status{get;set;}
    public Boolean rejected {get;set;}
    public Boolean showPage {get;set;}
    
    public OpportunityController(ApexPages.StandardController controller) {
        theController = controller;
        theOpp = (Opportunity)controller.getRecord();
        rejected=false;
        showPage = theOpp.StageName == theOpp.Referral_Partner_Stage__c;
    }
    
    public pagereference approve() {
        try{
            theOpp.StageName = Label.OppStage_Gained_Access;
            update theOpp;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Opportunity successfully approved.'));
            showPage = theOpp.StageName == theOpp.Referral_Partner_Stage__c;
            return null;
        }
        catch(Exception e){ ApexPages.addMessages(e); }
        return null;
    }
    
    public pageReference reject(){
        try{
            theOpp.StageName = Label.OppStage_Lost;
            rejected = true;
            return null;
        }
        catch(Exception e){ ApexPages.addMessages(e); }
        return null;
    }
    
    public pageReference save(){
        try{
            theOpp.Reason_Not_Sold__c = Status;
            update theOpp;
            ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.INFO,'Opportunity successfully updated.'));
            showPage = theOpp.StageName == theOpp.Referral_Partner_Stage__c;
        }
        catch(Exception e){ ApexPages.addMessages(e); }
        return null;
    }
}