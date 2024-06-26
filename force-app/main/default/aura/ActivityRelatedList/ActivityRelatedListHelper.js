({
	setRecordId : function(component, event, helper) {
        var recordId = component.get("v.pageReference.state.c__recordId");
        component.set("v.recordId", recordId);
	},
     
    getActivitiesForRecordId : function(component, event, helper){
        var recordId = component.get("v.recordId");
        var action = component.get("c.getOpenActivities"); 
        
        action.setParams({recordId: recordId});
        
        action.setCallback(this, function(response){
            var state = response.getState();

            if (state==='SUCCESS'){
                var envelope = response.getReturnValue();
                var activities = envelope.activities;
                helper.formatActivitiesForDisplay(component, event, helper, activities);
                helper.setUpDisplayColumns(component, event, helper, activities);
                helper.setTab (component, event, helper); 
                
            }else{
                var errors = response.getError();
                console.log(errors);
            }
        });
        
        $A.enqueueAction(action);
    },

    formatActivitiesForDisplay : function(component, event, helper, activities){
        for(var i = 0; i < activities.length; i++){

            if(activities[i].type == 'Task'){
                activities[i].ActivityType = 'Task';
                
            }else{
                activities[i].ActivityType = 'Event';                
            }
            
           activities[i].url = '/' + activities[i].recId; 
           activities[i].url = '/' + activities[i].recId;
            
            if(activities[i].whoId){ 
                activities[i].wholink = '/' + activities[i].whoId;
                
            } 
            if(activities[i].whatId){
                activities[i].whatlink = '/'+ activities[i].whatId;
                
            }
        }

        component.set("v.activities", activities);
    },
   
    setTab : function(component, event, helper ){
    var workspaceAPI = component.find("workspace");
        workspaceAPI.getFocusedTabInfo().then(function(response) {
            var focusedTabId = response.tabId;
            workspaceAPI.setTabLabel({
                tabId: focusedTabId,
                label: "Open Activity"
            });
		
            workspaceAPI.setTabIcon({
            tabId: focusedTabId,
            icon: "utility:fallback", //set icon you want to set      
    
         });             
        })
        .catch(function(error) {
            console.log(error);
        });  

     },       


    setUpDisplayColumns : function(component, event, helper, activities){

        var columns = [
            {label: 'Subject', fieldName: 'url', type: 'url', typeAttributes: { label:{fieldName: 'subject'}, target: '_blank'} },
            {label: 'Activity Type', fieldName: 'ActivityType', type: 'text'},
            {label: 'Activity Date', fieldName: 'activityDate', type: 'date'},
          //  {label: 'Duration (Minutes)', fieldName: 'due', type: 'date'},
            {label: 'Contact', fieldName: 'wholink', type: 'url', typeAttributes: {label: { fieldName: 'whoName'}, target: '_blank'} },
            {label: 'Related To', fieldName: 'whatlink', type: 'url', typeAttributes: {label: {fieldName: 'whatName'}, target: '_blank'} },
        ];
        component.set("v.columns", columns);
    }
})