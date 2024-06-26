({
    navToNextStage: function(component, event, helper) {
        try{
            event.preventDefault();
            let tabNavigateEVt = component.getEvent('communityFormsTabNavigate');
            tabNavigateEVt.setParam('direction', 1);
            tabNavigateEVt.fire();  
        }catch(e) {
            console.log(e)
        }
    }
})