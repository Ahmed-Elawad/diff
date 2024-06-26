/* 
 * Allow the users to manage their quotas
 *
 * History
 * -------
 * 12/20/2011 Anil Savaliya   Created
   10/29/2018 Dan Carmen      Increment API to version 44. Moved testMethod to a new class.
   09/25/2020 Jake Hinds	  Changing return pageReference to avoid parameter from URL

 */

public with sharing class MyCasesMassDeleteController {
    public List<Id> listIds;
    public ApexPages.StandardSetController stdCon;
    public MyCasesMassDeleteController(ApexPages.StandardSetController stdSetController){
        stdCon = stdSetController;
        listIds = new List<Id>();
        // Store selected records Id
        SObject[] listSelectedRecs = stdSetController.getSelected();
        for(SObject so : listSelectedRecs){
            listIds.add(so.Id);
        }
    } // MyCasesMassDeleteController
    
    public List<Case> listAllCases{
        get{
            if (listAllCases == null){
                listAllCases = new List<Case>();
                if (listIds != null && listIds.size() > 0){
                    listAllCases = [Select Id From Case Where Id IN :listIds];
                }
            }
            return listAllCases;
        } // get
        set;
    } // listAllCases
    
    public List<Case> listMyCases{
        get{
            if (listMyCases == null){
                listMyCases = new List<Case>();
                if (listAllCases != null && listAllCases.size() > 0){
                    listMyCases = [Select Id,ContactId, Type, CaseNumber, Subject, Status, RecordType.Name, OwnerId From Case 
                                Where CreatedById = :UserInfo.getUserId() AND Id IN :listAllCases];
                }
            }
            return listMyCases;
        }
        set;
    } // listMyCases
    
    public List<Case> listOtherCases{
        get{
            if (listOtherCases == null){
                listOtherCases = new List<Case>();
                if (listAllCases != null && listAllCases.size() > 0){
                    listOtherCases = [Select Id, ContactId, Type, CaseNumber, Subject, Status, RecordType.Name, OwnerId From Case 
                                Where CreatedById != :UserInfo.getUserId() AND Id IN :listAllCases];
                }
            }
            return listOtherCases;
        }
        set;
    } // listOtherCases
    
    public PageReference doDelete(){
        String strIds = ApexPages.currentPage().getParameters().get('CaseIds');

        if (listIds == null || listIds.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No cases created by this user available to delete.'));
            System.debug('Error: no records to delete.');
            return null;
        }
        if (listMyCases == null || listMyCases.size() == 0){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'No cases created by this user available to delete.'));
            System.debug('Error: no records to delete.');
            return null;
        }
        
        try{
            delete listMyCases;
        }
        catch(System.DMLException e){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.FATAL, 'Exception: ' + e.getMessage()));
            System.debug('Exception: ' + e.getMessage());
            return null;
        }
        
        /*String strRet = ApexPages.currentPage().getParameters().get('retURL');
        if (strRet == null || strRet == ''){
            strRet = '/500/o';
        }*/
        PageReference pageList = new PageReference('/500/o');
        pageList.setRedirect(true);
        return pageList;
    } // doDelete
    

} // MyCasesMassDeleteController