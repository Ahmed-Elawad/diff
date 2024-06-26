({
    myAction : function(component, event, helper) {
        var NavEvt = $A.get("e.force:navigateToComponent");
        let getRunningUser = component.get('c.getRunningUser');
        let checkPermissions = component.get('c.checkPermissions');
        
        getRunningUser.setCallback(this, function(data){
            if (data.getState() !== 'SUCCESS' || !data.getReturnValue()) {
                component.set('v.loading', false);
                component.set('v.allowAccess', false);
                helper.displayMsg('Error',
                                  'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                                  'Error');
                console.log(data.getState());
                console.log(data.getError());
                return;
            }
            
            let user = data.getReturnValue();
            
            checkPermissions.setParams({
                currUser: user
            });
            
            checkPermissions.setCallback(this, function(result) {
                let missingPermissions = result.getReturnValue();
                console.log(missingPermissions);
                if (result.getState() != 'SUCCESS') {
                    console.log('failed server action')
                    component.set('v.allowAccess', false);
                    component.set('v.loading', false);
                    helper.displayMsg('Error',
                                  'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.',
                                  'Error');
                    return;
                } else if(missingPermissions.includes('BETA Access')){
                    console.log('missing permission')
                    helper.displayMsg('Failed Verification',
                                      'You do not have permission to use this functionality.  For assistance, please contact Sales Enablement',
                                      'Error');
                    component.set('v.allowAccess', true);
                    component.set('v.loading', false);
                    return;
                } 
                console.log('updating view to show form')
                component.set('v.allowAccess', true);
                component.set('v.loading', false);
            })
            $A.enqueueAction(checkPermissions);
        })
        $A.enqueueAction(getRunningUser);
    },
    
})