({
	handleOnChange : function(component, event, helper) {
		let curRecord = component.get("v.miRec");
        curRecord.isChanged=true;
	},
    openModel: function(component, event, helper) {
      // Set isModalOpen attribute to true
      let miRc = component.get("v.miRec");
      miRc.isChanged=true;
        component.set("v.miRec.removFromFirm", true); 
        //if(miRc.removFromFirm){
        	component.set("v.isModalOpen", true);

        //}
    },
	closeModel: function(component, event, helper) {
      
        component.set("v.miRec.removFromFirm", false); 
      // Set isModalOpen attribute to false  
      component.set("v.isModalOpen", false);
    },
    
    updateMember: function(component, event, helper){
   	  let miRc = component.get("v.miRec"); 
      miRc.isChanged=true;        
      helper.updateMemberShips(component, event)  
    },
    
    submitDetails: function(component, event, helper) {
    	let miRc = component.get("v.miRec");
        if($A.util.isEmpty(miRc.unenrollReason)){
            var prgRecCmp = component.find('prgRec');//.reduce(function (validSoFar, inputCmp) {
        	prgRecCmp.reportValidity();
        }else{
        	helper.createRequests(component, event); 
          //  helper.removeFromFirm(component, event,mpJSON);            
      		component.set("v.isModalOpen", false);
        }
    }
})