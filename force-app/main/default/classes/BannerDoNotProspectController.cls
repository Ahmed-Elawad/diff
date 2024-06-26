public class BannerDoNotProspectController {
    public Boolean onboardingInProgress = false;
    public Boolean onboardingComplete = false;
    Public String onboardingStatus = '';
    public BannerDoNotProspectController(Id accountId){
        OnboardingOverviewController ooc = new OnboardingOverviewController(accountId);
        if(!ooc.refCollection.isEmpty()){
            onboardingInProgress = true;
            onboardingStatus = 'In Progress';
        }
        if(ooc.refCollection.isEmpty()&&!ooc.refGradCollection.isEmpty()){
            onboardingComplete = true;
            onboardingStatus = 'Complete';
        }
    }
}