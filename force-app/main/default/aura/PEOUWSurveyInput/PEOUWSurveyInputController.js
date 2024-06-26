({
    myAction : function(cmp, event, helper) {
        console.log('Inside survey');
       // cmp.set("v.firstQuestion","Thank you for submitting your feedback to Paychex through our portal");
    	cmp.set("v.loaded",false);
        
        var action = cmp.get("c.getSurvey");
        
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
                let responseValue = response.getReturnValue();
             //   cmp.set("v.showFeedBack",responseValue); // SFDC-19924
            }
            else if (state === "ERROR") {
                
            }
            
        });
        $A.enqueueAction(action);
    },
    
    getRating : function(cmp, event, helper) {
        //debugger;
        var rating = event.getSource().getLocalId();
        cmp.set('v.Rating',rating);
        if(rating == 1){
            cmp.set('v.no1',true);
        }else
        {
            cmp.set('v.no1',false);
        }
        if(rating == 2){
            cmp.set('v.no2',true);
        }else
        {
            cmp.set('v.no2',false);
        }
        if(rating == 3){
            cmp.set('v.no3',true);
        }else
        {
            cmp.set('v.no3',false);
        }
        if(rating == 4){
            cmp.set('v.no4',true);
        }else
        {
            cmp.set('v.no4',false);
        }
        if(rating == 5){
            cmp.set('v.no5',true);
        }else
        {
            cmp.set('v.no5',false);
        }
        if(rating == 6){
            cmp.set('v.no6',true);
        }else
        {
            cmp.set('v.no6',false);
        }
        if(rating == 7){
            cmp.set('v.no7',true);
        }else
        {
            cmp.set('v.no7',false);
        }
        let showAnotherQuestion = ['1','2','3','4'];
        if(showAnotherQuestion.includes(rating)){
            cmp.set("v.truthy",true);
        } else {
            cmp.set("v.truthy",false);
        }
    },
    
    doSubmit : function(cmp, event, helper){
        cmp.set("v.loaded",true);
        let rating = cmp.get('v.Rating');
        let showAnotherQuestion = ['1','2','3','4'];
        let secondQuestion = '';
        let answers = '';
        if(showAnotherQuestion.includes(rating)){
            secondQuestion = cmp.get("v.secondQuestion");
            answers = cmp.get("v.feedbacktext");
        }
        
        var action = cmp.get("c.submitSurvey");
        action.setParams({ 
            rating : rating,
            secondQuestion : secondQuestion,
            answers : answers
        });
        action.setCallback(this, function(response) {
            var state = response.getState();
            
            if (state === "SUCCESS") {
               
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type":"success",
                    "message": "The feedback has been saved"
                });
                toastEvent.fire();
                cmp.set("v.showFeedBack",false);
                
                cmp.set("v.loaded",false);
               
            }
            else if (state === "ERROR") {
                let toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type": "error",
                    "message": "Error occured!"
                });
                toastEvent.fire();
                cmp.set("v.loaded",false);
            }
            
        });
        $A.enqueueAction(action);
        
    },
    handleOutsideClick : function(cmp, event, helper){
        cmp.set('v.no1',false);
        cmp.set('v.no2',false);
        cmp.set('v.no3',false);
        cmp.set('v.no4',false);
        cmp.set('v.no5',false);
        cmp.set('v.no6',false);
        cmp.set('v.no7',false);
        
       
    }
})