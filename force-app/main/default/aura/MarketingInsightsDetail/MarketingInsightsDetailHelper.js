({
    setTab : function(component, event, helper ){
        var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: this.focusedTabId,
                label: "Customer Intent Signals"
            });
        
            workspaceAPI.setTabIcon({
            tabId: this.focusedTabId,
            icon: "utility:fallback", //set icon you want to set      
    
            });             
        })
        .catch(function(error) {
            console.log(error);
        });  
    
    }
})