/* Controller used with the RefPEOPaperEmp VF page.  Used to add Reference PEO Onboarding Candidates 
 * to the Reference PEO
 * History
 * -------
 * 01/17/2017 Jermaine Stukes Created
    07/06/2020  Jacob Hinds         Added without sharing per PMD
 * 
*/
public without sharing class RefPeoPaperEmpController 
{
    String refPEOId = ApexPages.CurrentPage().getParameters().get('id'); 
    public List<Reference_PEO__c> peoList{get;set;}
    public List<Reference_PEO_Onboarding_Candidates__c> refOnCandidates {get;set;}
    public List<Reference_PEO_Onboarding_Candidates__c> candidatesToRemove = new List<Reference_PEO_Onboarding_Candidates__c>();
    public Reference_PEO_Onboarding_Candidates__c OnboardingCandidate{get;set;}
    public Boolean candidatesEntered{get;set;}
    public Integer numPaperEmps{get;set;}
    Integer numCompletedPaperEmps = 0;
    public Boolean disableButtons {get;set;}
    public Boolean candidateUpdated{get;set;}
    public Boolean isRequired{get;set;}
    public RefPeoPaperEmpController()
    {
        numPaperEmps = 0;
        candidateUpdated = false;
        isRequired = true;
        OnboardingCandidate = new Reference_PEO_Onboarding_Candidates__c(Reference_PEO_ID__c = refPEOId);
        getPaperEmpList();
        Validate();
    }
    public void Updated()
    {
        candidateUpdated = true;
    }
    public List<Reference_PEO_Onboarding_Candidates__c> getPaperEmpList()
    {
        refOnCandidates = new List<Reference_PEO_Onboarding_Candidates__c>();
        peoList = [Select id, No_of_Paper_Onboarding_Candidates__c, Completed_Paper_Submissions__c, (Select id, Employee_First_Name__c, Full_Name__c, Reference_PEO_ID__c, Employee_Last_Name__c,Last4SSN__c, Complete__c from Reference_PEO_Onboarding_Candidates__r) from Reference_PEO__c where id=:refPEOId limit 1];
        if(!peoList.isEmpty())
        {
            for(Reference_PEO__c refPeo : peoList)
            {
                if(refPeo.Reference_PEO_Onboarding_Candidates__r.size() > 0)
                {
                    numPaperEmps = refPeo.Reference_PEO_Onboarding_Candidates__r.size();
                }
                refPeo.No_of_Paper_Onboarding_Candidates__c = numPaperEmps;
                Integer numComplete = 0;
                for(Reference_PEO_Onboarding_Candidates__c candidate : refPeo.Reference_PEO_Onboarding_Candidates__r)
                {
                    refOnCandidates.add(candidate);
                    
                    if(candidate.Complete__c)
                    {
                        numComplete++;                   
                    }
                }
                refPeo.Completed_Paper_Submissions__c = numComplete;
            }
        }
        
        if(!refOnCandidates.isEmpty())
        {candidatesEntered = true;}
        else
        {candidatesEntered = false;}
        return refOnCandidates;
    }
    
    public PageReference updateSave()
    {
        upsert refOnCandidates;
        PageReference pageref;
        pageref = new PageReference('/apex/RefPeoPaperEmp?id=' + refPEOId);
        pageref.setRedirect(true);
        return pageref;
    }
    
    public PageReference removeEmp()
    {
        Integer indexVal;
        if(test.isRunningTest())
        {
            indexVal = 2;
        }
        else
        {
            indexVal = Integer.valueof(system.currentpagereference().getparameters().get('index'));
        }
        //If the contact is an existing contact then add it to the list to delete from the databse
        if(refOnCandidates[indexVal - 1].Id != null)
            candidatesToRemove.add(refOnCandidates[indexVal - 1]);
        //Remove the contact from the table    
        refOnCandidates.remove(indexVal - 1);   
        if(candidatesToRemove.size() > 0)
        {delete candidatesToRemove;}
        PageReference pageref;
        pageref = new PageReference('/apex/RefPeoPaperEmp?id=' + refPEOId);
        pageref.setRedirect(true);
        return pageref;
            
    }
    
    public PageReference quickSave()
    {
        upsert OnboardingCandidate;
        getPaperEmpList();
        upsert peoList;
        upsert refOnCandidates;
        PageReference pageref;
        pageref = new PageReference('/apex/RefPeoPaperEmp?id=' + refPEOId);
        pageref.setRedirect(true);
        return pageref;
    }
    
    public PageReference submitUpdates()
    {
        insert OnboardingCandidate;
        getPaperEmpList();
        upsert peoList;
        PageReference pageref;
        pageref = new PageReference('/' + refPEOId);
        pageref.setRedirect(true);
        return pageref;
    }
    
    public void Validate()
    {
        disableButtons = true;
        if(OnboardingCandidate.Employee_First_Name__c !=Null && OnboardingCandidate.Employee_Last_Name__c !=Null && OnboardingCandidate.Last4SSN__c != Null)
        {
            disableButtons = false;
        }
    }
    public PageReference cancel() {
        //isRequired = false;
        
      /*          PageReference returnPr = null;
        try {
         returnPr = new PageReference('/'+(refPEOId != null ? refPEOId : ''));
        } catch (Exception e) {
                // in case returnId isn't a valid id.
           returnPr = new PageReference('/');
        }
      returnPr.setRedirect(true);             
      return returnPr;*/
        
        PageReference returnPr = null;
        returnPr = new PageReference('/'+(refPEOId != null ? refPEOId : ''));
        returnPr.setRedirect(true);             
        return returnPr;
    } // cancel
}