({

    onTabCreated: function(cmp, event, helper) {
        var workspace = cmp.find("workspace");
        var limit = cmp.get("v.limit");
        
        workspace.getAllTabInfo().then(function (tabInfo) {
            console.log("tab lenth " +tabInfo.length); 
            if (tabInfo.length > limit) {
             for(var i=0; i < tabInfo.length -1; i++){
                 if (tabInfo[i].pinned == false ) {
                 //    alert("Closing a tab: " + tabInfo[i].title); 
                 	 workspace.closeTab({
                     tabId: tabInfo[i].tabId
                      
                    });
			helper.showToast(cmp, event,helper);   
                     break; 
                 } 
       		  }//for
             }//if 


        });
    }
  
})