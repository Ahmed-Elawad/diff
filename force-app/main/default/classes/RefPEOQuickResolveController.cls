/* 
 * 
 * History
 * -------
 * 06/21/2016 Justin Stouffer Created
 * 06/22/2016 Jermaine Stukes Updated
 *
 */
public with sharing class RefPEOQuickResolveController {
    ApexPages.StandardSetController setCon;

    public RefPEOQuickResolveController(ApexPages.StandardSetController controller) {
        setCon = controller;        
    }
    
    public pageReference quickResolve()
    {
        dateTime dt = dateTime.Now();
        dt.addHours(-12);
        string currentDate = dt.format('MM/dd/yyyy');
        list<Reference_PEO_Discrepancy__c> rpcs = setCon.getSelected();
        if(!rpcs.isEmpty())
        {
            for ( Reference_PEO_Discrepancy__c quickResolveCases : rpcs )
            {               
                quickResolveCases.displayDate__c = currentDate;
                quickResolveCases.Quick_Resolve_option__c = true;  
            }
            update RPCs;
        }
        pageReference previous = new pageReference(ApexPages.currentPage().getParameters().get('retURL'));
        previous.setRedirect(TRUE);
        return previous;   
    }  
}