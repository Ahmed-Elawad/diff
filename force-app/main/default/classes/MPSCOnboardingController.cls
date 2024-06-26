/*
*
*   HISTORY
*  ---------
*   3/20/2024  Carrie Marciano    CanBeDeleted old MPSC tech debt
*
*/

public class MPSCOnboardingController {
    public MPSCOnboardingController() {}
/*
    private Reference_MPSC__c mpsc;
    
    public list<onboardingOverviewController.refWrapper> refCollection {get;set;} 
    public list<onboardingOverviewController.refWrapper> refGradCollection {get;set;}
    private  set<string> mpscProdSet;

    public onboardingOverviewController ooc {get;set;}

    public MPSCOnboardingController(ApexPages.StandardController controller){
        list<Client_Overview_Configuration__c> coc = Client_Overview_Configuration__c.getAll().Values();
        system.debug('JGS coc' + coc);
        refCollection = new list<onboardingOverviewController.refWrapper>();
        refGradCollection = new list<onboardingOverviewController.refWrapper>();
        mpscProdSet = new set<string>();
        this.mpsc = (Reference_MPSC__c)controller.getRecord();
        system.debug('JGS mpsc' + mpsc);
    
        ooc = new onboardingOverviewController(mpsc.Case_Lookup__r.Accountid);
        system.debug('JGS ooc' + ooc);
        
        for(Client_Overview_Configuration__c co : coc){
            if(co.mpsc__c){
                mpscProdSet.add(co.product_name__c);
            }
        }
        system.debug('JGS mpscProdSet' + mpscProdSet);
        for(onboardingOverviewController.refWrapper rw : ooc.singleRefCollection){
            if(mpscProdSet.contains(rw.product)){
                refCollection.add(rw);
            }       
        }
        
        for(onboardingOverviewController.refWrapper rw : ooc.singleRefGradCollection){
            if(mpscProdSet.contains(rw.product)){
                refGradCollection.add(rw);
            }       
        }
    }
   */
   
}