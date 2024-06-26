/*  
 * History
 * -------
 * 06/19/2017 Lynn Michels Created
 *
 */
public with sharing class RefPEOPaperCandidatesQuickComplete {
	ApexPages.StandardSetController setCon;

    public RefPEOPaperCandidatesQuickComplete(ApexPages.StandardSetController controller) {
        setCon = controller;        
    }
    
    public pageReference quickComplete()
    {
        dateTime dt = dateTime.Now();
        dt.addHours(-12);
        string currentDate = dt.format('MM/dd/yyyy');
        list<Reference_PEO_Onboarding_Candidates__c> onbrdgCandidates = setCon.getSelected();
        if(!onbrdgCandidates.isEmpty())
        {
            for ( Reference_PEO_Onboarding_Candidates__c candidate : onbrdgCandidates )
            {               
                candidate.Complete__c = true;
            }
            update onbrdgCandidates;
        }
        pageReference previous = new pageReference(ApexPages.currentPage().getParameters().get('retURL'));
        previous.setRedirect(TRUE);
        return previous;   
    }  
}