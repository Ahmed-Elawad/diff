({
	//action called by the aura:handler in the LinkOppsFromAccount.cmp file
    setUpForOpp : function(component, event, helper) {
    console.log("LM LOAD FROM OPPORTUNITY");
	component.set('v.loaded', false);   
        //set the column headers
        component.set("v.Columns", [
            {label:"Opportunity", fieldName:"Name", type:"text"},
            {label:"Status", fieldName:"StageName", type:"status"},
            {label:"Date", fieldName:"CloseDate", type:"text"},
            {label:"Owner", fieldName:"Owner_Name",type:"text"},
            {label:"Type", fieldName:"OpportunityType__c", type:"text"}
        ]);
        var myOppId = component.get("v.opportunityId");
        helper.getData(component, event, 'getOpps', 'Opportunities', myOppId);
   },
    

    //used for onrowselection
    updateSelected: function(component, event, helper){
        component.set('v.error', false);
        var selectedRows = event.getParam('selectedRows'); //getting the selectedRows attribute value
        component.set('v.selectedRowsCount', selectedRows.length);
        component.set("v.selectedRowsList" ,event.getParam('selectedRows'));//set the value of selectedRowsList to be used in the button code   
    },
    
   handleSelected: function (component, event, helper) {
        var selectedRows = component.get('v.selectedRowsCount');
              
        //make sure there are 2 records selected
         if (selectedRows != 2){
             component.set('v.error', true);
             component.set('v.errorMessage', "You must select two opportunitites.");
         }
        //if 2 are selected, display success message, reload opp page, process opps
         else{ 
			 component.set('v.loaded', false);
             component.set('v.error', false);
             var objList =  component.get("v.selectedRowsList");
           
             //a javascript object is returned.
             //server takes the Apex object, turns them into JSON strings, sends them to the client,
             //then the client turns the JSON into JavaScript objects that are passed to the code.
             //Here you turn the javascript object back to JSON string
             var objectList = JSON.stringify(objList);
             //here you turn the JSON string to a javascript object
             var jsonObject = JSON.parse(objectList);
             console.log('JSON jsonObject' + jsonObject);
             var i;
             //a javascript object is not an array and does not have a length. You have to count its properties
             var iLength = Object.keys(jsonObject).length;
             console.log('ilength ' +iLength);
             var rt;

             for (i = 0; i < iLength; i++){
                 console.log('opp RT' + jsonObject[i].RecordTypeId);
                 if(rt == null || rt == undefined){  
                     rt = jsonObject[i].RecordTypeId;
                 }
                 else{
                     if(rt === jsonObject[i].RecordTypeId){ 
                         component.set('v.error', true);
                         component.set('v.errorMessage', 'You have selected two opportunties of the same record type. Please reselect the opportunitites.');
                         component.set("v.spinnerVisible" ,false);
                         component.set('v.loaded', true);
                         return false;
                     }
                 }
             }//end for
                 var updateAction = component.get("c.processOpportunities");
                     updateAction.setParams({ "opps" : objList});
                     updateAction.setCallback(this, function(a) {
                          
                         var reloadRecord = $A.get("e.force:navigateToSObject"); //reload the record
                             reloadRecord.setParams({
                                "recordId": component.get("v.opportunityId")
                             });
                         	reloadRecord.fire();
                component.set("v.spinnerVisible" ,true);
                    
                });  //end updateAction.setCallback
                $A.enqueueAction(updateAction);   
          }//end else      	
    },//handleSelected
})