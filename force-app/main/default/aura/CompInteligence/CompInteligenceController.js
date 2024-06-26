({
    myAction : function(component, event, helper) {

    },
    init: function(cmp) {
    let action = cmp.get("c.getCompetitors");
    action.setParams({'oppId':cmp.get("v.recordId")});
    action.setCallback(this,(res)=>{
        const serverResult = res.getReturnValue();
        //console.log("Initial data "+JSON.stringify(serverResult));
        //console.log('initial data length'+serverResult.length);
        let isNull = serverResult==null;
        //console.log('Initial Data is null?'+ isNull);
        //console.log("server result greater than zero? "+serverResult.length>0);
            if(serverResult == null|| serverResult==undefined){
                // safeguards users that arent relevant to the Competitor reporting
            }else{
                if(serverResult.length>0){ // if data in rest
                    // set component to say there is a primary already
                    cmp.set("v.containsPrimary",true);
                    if(serverResult.length>=4){
                        // raise message "all competition selected"
                        cmp.set("v.allSelected",true);
                        // disable save button 
                        cmp.set("v.disable",true);
                        cmp.set("v.disableButton",true);
                        cmp.set("v.selectedNotSaved",false);


                    }
        
                }else{
                    cmp.set("v.containsPrimary",false);
        
                }
                var srMod = JSON.parse(JSON.stringify(serverResult));
                let selectedNames = [];
                srMod.forEach((comp)=>{
                    console.log(JSON.stringify(comp));
                    const selectedName = {Name : comp.Name, Primary__c:comp.Primary__c,ManualEntry__c:comp.ManualEntry__c};
        
                    selectedNames.push(selectedName);
                });
                cmp.set("v.selectedCompetitors",srMod);
                cmp.set("v.selectedNamesView",selectedNames);
                return;
            }
            
        
        
      

    });
    $A.enqueueAction(action);
    },
    optionClickHandler : function (cmp, e, helper) {
        //handles the option in question
        const selectedId = e.target.closest('li').dataset.id;
        const selectedValue = e.target.closest('li').dataset.value;
        const selectedManualEntry = e.target.closest('li').dataset.record;
        console.log("Manual Entry: "+selectedManualEntry);
        console.log("Manual Entry type: "+typeof(selectedManualEntry));
        cmp.set("v.inputValue", selectedValue.split('-')[0]);
        cmp.set("v.openDropDown", false);
        cmp.set("v.selectedOption", selectedId);
        cmp.set("v.optionSelected", true);
        console.log(selectedId);
        let competitor = cmp.get("v.selectedCompetitor");
        console.log("competitor before  selection"+JSON.stringify(competitor));
        let selectedCompetitorList = cmp.get("v.selectedCompetitors");
        var selectedOptions = cmp.get("v.selectedOptions");
        var selectedOptionsText = cmp.get("v.selectedOptionsText");
        let newList2 = selectedOptionsText;
        
        
        
        // new competitor functionality
        if(selectedManualEntry=='true'){
            // set boolean to show enter name field input
            let newCompetitor = cmp.get("v.selectedCompetitor");
            let oppId = cmp.get("v.recordId");
            newCompetitor.Opportunity__c = oppId;
            newCompetitor.PickListValue__c = selectedId;
            console.log("We made it to the lost client/ not listed functionality");
            cmp.set("v.selectedCompetitor",newCompetitor);
            cmp.set("v.showNameInput", true);
             
            return;
            // when name is captured and select button is selected  add name to nameList2
            
        }else{
            // normal functionality
        }
        if(selectedCompetitorList==null || selectedCompetitorList.length==0){ //if nothing in the list 
            console.log("if true selectedCompList");
            competitor.Name = selectedValue;
            competitor.PickListValue__c = selectedId;
            let oppId = cmp.get("v.recordId");
            competitor.Opportunity__c = oppId;
            competitor.Primary__c = false;
            console.log('Competitor'+JSON.stringify(competitor));
            selectedCompetitorList.push(competitor);
            cmp.set("v.selectedCompetitor",{});

        }else{ //if adding to selected competitors 
           
            console.log("else case selectedCompList ");
            competitor.Name = selectedValue;
            competitor.PickListValue__c = selectedId;
            let oppId = cmp.get("v.recordId");
            competitor.Opportunity__c = oppId;
            console.log('Competitor'+JSON.stringify(competitor));
            
            selectedCompetitorList.push(competitor);
            console.log("selComp Length: "+selectedCompetitorList.length);
            if(selectedCompetitorList.length>=4){
                // raise message "all competition selected"
                // cmp.set("v.allSelected",true);
                // disable save button 
                cmp.set("v.selectedNotSaved",true);
                cmp.set("v.disable",true);


            }else{
                cmp.set("v.allSelected",false);
                // disable save button 
                cmp.set("v.disable",false); 
                cmp.set("v.disableButton",false);
           
            }
            cmp.set("v.selectedCompetitor",{});
            
        }
        console.log("competitor after  selection"+JSON.stringify(competitor));

            cmp.set("v.selectedCompetitors",selectedCompetitorList);
            let selComp = cmp.get('v.selectedCompetitors');
            console.log("selComp :"+JSON.stringify(selComp));
        //helper.testSave(cmp);
        
        let extendedWhere = '';

        //handles the list of options selected visually and functionally
        //view is the component for the showing underneath
        //List 
        

        
        //handle selected Options
        if(selectedOptions== undefined){
            let selectedPLVIds = [selectedId];
            cmp.set('v.selectedOptions', selectedPLVIds);
        }else{
            let newList = selectedOptions;
            newList.push(selectedId);
            cmp.set('v.selectedOptions', newList);

        }
        //End Selected Options
        // handle SelectedOptionsText
        if(selectedOptionsText== undefined){
            console.log("True case for Selected Options Text!!!");
            let PLVName = selectedValue.split('-');
            let PLVNameModified2 = PLVName[1].trim().concat(':',PLVName[0].trim());
            let PLVNameModified = PLVName[0].trim();
            let selectedPLVNames = [PLVNameModified];
            let selectedPLVNames2 = [PLVNameModified2];
            cmp.set('v.selectedOptionsText', selectedPLVNames);
            cmp.set('v.selectedOptionsText2',selectedPLVNames2);
            cmp.set('v.selectedNamesViewList',selectedPLVNames2);
            let selectedNames = [];
            selectedCompetitorList.forEach(comp=>{
                const selectedName = {Name : comp.Name, Primary__c:comp.Primary__c};
                selectedNames.push(selectedName);
            });
            cmp.set('v.selectedNamesView',selectedNames);
        }else{       
            console.log("else case for Selected Options Text!!!");
            let PLVName = selectedValue.split('-');
            let PLVNameModified = PLVName[0].trim();

            console.log(selectedValue);
           
            // list to use for visuals 
            newList2.push(PLVNameModified);
                       
            cmp.set('v.selectedOptionsText', newList2);
            cmp.set('v.selectedOptionsText2', newList2);
            
            console.log("newList2: "+newList2);
            // console.log("newList3: "+newList3);
            let selectedNames = [];
            selectedCompetitorList.forEach(comp=>{
                const selectedName = {Name : comp.Name, Primary__c:comp.Primary__c};
                selectedNames.push(selectedName);
            });
            cmp.set('v.selectedNamesView',selectedNames);
            console.log("selected Names: "+JSON.stringify(selectedNames));
            
            
          
        }
        var selected2 = cmp.get("v.selectedOptions");
        console.log("selected Options: "+selected2);
        var selected3 = cmp.get("v.selectedOptionsText");
        console.log("selected options Text: "+selected3);
        var selected4 = cmp.get('v.selectedNamesView');
        console.log("selected Names View: "+ selected4);
        var selected5 = cmp.get('v.selectedOptionsText2');
        console.log("selected Options Text 2: "+ selected5);
        
        return;
    },
    updateInput: function(cmp, e, helper) {
        console.log(e.target.value)
        cmp.set('v.inputValue', e.target.value);
        return;
    },
    searchHandler : function (cmp, e, helper) {
        const searchString = e.target.value;
        if (searchString.length >= 1) {
            //Ensure that not many function execution happens if user keeps typing
            if (cmp.get("v.inputSearchFunction")) clearTimeout(cmp.get("v.inputSearchFunction"));
            var inputTimer = setTimeout($A.getCallback(() => helper.searchRecords(cmp, searchString)), 500);
            cmp.set("v.inputSearchFunction", inputTimer);
        } else{
            cmp.set("v.results", []);
            cmp.set("v.openDropDown", false);
        }
        return;
    },
    save: function(cmp,e,helper){
        helper.saveRecord(cmp);     
    },
    cancel: function(cmp,helper){
    },
    newCompNamehandler: function(cmp,e){
        const newName = e.target.value;
        cmp.set("v.newCompName",newName);
    },
    addLostClientOrNotListed:function(cmp){
        var selectedOptionsText = cmp.get("v.selectedOptionsText");
        let newList2 = selectedOptionsText;
        let selectedCompetitorList = cmp.get("v.selectedCompetitors");

        let newCompetitor = cmp.get("v.selectedCompetitor");
        console.log("newCompetitor: "+JSON.stringify(newCompetitor));
        let competitorName = cmp.get("v.newCompName");
        if(competitorName != undefined){ // entered something
            competitorName = competitorName.trim();
            if(competitorName===""){
                cmp.set("v.manualEntryNameNotEntered",true);
                return;
            }else{
                cmp.set("v.manualEntryNameNotEntered",false);
    
            }
        }else{// didn't enter anything and compName is undefined
            competitorName = '';
            if(competitorName===""){
                cmp.set("v.manualEntryNameNotEntered",true);
                return;
            }else{
                cmp.set("v.manualEntryNameNotEntered",false);
    
            }
        }
        

         newCompetitor.Name = competitorName;
        
         selectedCompetitorList.push(newCompetitor);
         if(selectedCompetitorList.length>=4){
            // raise message "all competition selected"
            // cmp.set("v.allSelected",true);
            // disable save button 
            cmp.set("v.disable",true);
            cmp.set("v.selectedNotSaved",true);
        }else{
            cmp.set("v.allSelected",false);
            // disable save button 
            cmp.set("v.disable",false);            
            cmp.set("v.disableButton",false);            
        }
         newList2.push(newCompetitor.Name);
         cmp.set('v.selectedCompetitors', selectedCompetitorList);
         cmp.set('v.selectedOptionsText', newList2);
         cmp.set('v.selectedOptionsText2', newList2);
         console.log(JSON.stringify(selectedCompetitorList));
         console.log("newList2: "+newList2);
         // console.log("newList3: "+newList3);
         let selectedNames = [];
         console.log("selected Competitors: "+JSON.stringify(selectedCompetitorList));
         selectedCompetitorList.forEach(comp=>{
            const selectedName = {Name : comp.Name, Primary__c:comp.Primary__c};
             selectedNames.push(selectedName);
         });
         cmp.set('v.selectedNamesView',selectedNames);
         console.log("selected Names: "+JSON.stringify(selectedNames));
         cmp.set("v.selectedCompetitor",{});
         cmp.set("v.showNameInput", false);


    },
    remove: function(cmp,e,helper){
        console.log("Remove selection!");
        const selectedValue = e.target.closest('div').dataset.value;
        console.log("selectedValue:"+selectedValue);

        //console.log('selected Item of Removal: '+selectedValue);
        let NameList= selectedValue.split(":");
        //let selectionType = NameList[0];
        let selectionName = NameList[0];
        //let qf = cmp.get("v.queryFilter");
        let selectedOptions = cmp.get("v.selectedOptions");
        let selectedOptionsText = cmp.get("v.selectedOptionsText");
        let selectedOptionsText2 = cmp.get("v.selectedOptionsText2");
        let selectedNamesView = cmp.get('v.selectedNamesView');
        let selectedCompetitors = cmp.get('v.selectedCompetitors');

        // console.log(JSON.stringify(qf));
        // if(selectionType == "Primary Competition Level 1"){
        //     selectionType="Level 1";
        // }
        // if(selectionType == "Primary Competition Level 2"){
        //     selectionType="Level 2";
        // }
       // console.log(selectionType);
        //console.log(qf);
        var removedindex = null;
        let newSelComps = [];
        for(let i=0;i<selectedCompetitors.length;i++){
            console.log(selectedCompetitors[i].Name);
            console.log(selectedValue);
            if(selectedValue.includes(selectedCompetitors[i].Name)&& selectedCompetitors[i]!=null){
               
                console.log('true');
                removedindex = i;
                break;
            }else{
                removedindex=0;
                newSelComps.push(selectedCompetitors[i]);
                console.log('false');
            }
        }
        // console.log("newqf: "+newqf);
        console.log("Index: "+removedindex);

        // removes selected Competition from query filters, selected Options, SelectedOptionsText
        if(removedindex!=null){
           //qf = qf.filter(filter=>{ filter!= selectionType});
        //    cmp.set("v.queryFilter",newqf);
           console.log("selectedCompetitors[removedindex]: "+JSON.stringify(selectedCompetitors[removedindex]));
           console.log(selectedCompetitors.toString());
           let newSelOps =[];
           selectedCompetitors.forEach(op=>{if(op!==selectedCompetitors[removedindex]){newSelOps.push(op);}});
           selectedCompetitors = newSelOps;
           console.log("sel. Comps size: "+selectedCompetitors.length+"Selected Competitors: "+JSON.stringify(selectedCompetitors));
           if(selectedCompetitors.length>=4){
            // raise message "all competition selected"
            cmp.set("v.allSelected",true);
            // disable save button 
            cmp.set("v.disable",true);

        }else{
            cmp.set("v.allSelected",false);
            // disable save button 
            cmp.set("v.disable",false);  
            cmp.set("v.disableButton",false);          
        }
           
           console.log("new filtered selectedCompetitors:"+selectedCompetitors);
           //remove server call
           let removeAction = cmp.get("c.removeCompetitor");
           removeAction.setParams({"removeIndex":removedindex,"selectedCompetitors":JSON.stringify(cmp.get("v.selectedCompetitors"))});
           removeAction.setCallback(this,(res)=>{
            if(res.getState() === "SUCCESS"){
                console.log("remove worked");
            } else{
                console.log(res.getError());
                console.log("remove failed");
            }
        });
            $A.enqueueAction(removeAction);

           cmp.set("v.selectedCompetitors",selectedCompetitors);
           
           console.log("old selected options Text: "+selectedOptionsText.toString());
           let newSelectedOptionsText =[];
           selectedOptionsText.forEach(op=>{if(op!==selectedOptionsText[removedindex]){newSelectedOptionsText.push(op)}});
           selectedOptionsText = newSelectedOptionsText;
        //    console.log(selectedOptionsText[removedindex]);
           console.log("new selected options Text: "+selectedOptionsText.toString());

        //    selectedOptionsText = selectedOptionsText.filter(option=>{option != selectedOptionsText[removedindex]});
           
        //    console.log(selectedOptionsText.toString());
           cmp.set("v.selectedOptionsText",selectedOptionsText);
           let newSelectedNamesView = [];
           
           selectedNamesView.forEach(op=>{ 
               console.log("selected Names View Op: "+op.Name);
               console.log("selected Names View removed Index: "+selectedNamesView[removedindex].Name);
               if(op.Name!==selectedNamesView[removedindex].Name){
                   newSelectedNamesView.push(op);
               }
            });
            selectedNamesView = newSelectedNamesView;
            console.log("new Selected Names View: "+JSON.stringify(newSelectedNamesView));
        //    selectedNamesView = selectedNamesView.filter(option=>{option != selectedNamesView[removedindex]});
           let selectedNames = [];
           selectedNamesView.forEach(comp=>{
            const selectedName = {Name : comp.Name, Primary__c:comp.Primary__c};
            selectedNames.push(selectedName);
           });
           cmp.set('v.selectedNamesView',selectedNames);
        let newSelectedOptionsText2 =[];
            selectedOptionsText2.forEach(op=>{
                if(op!==selectedOptionsText2[removedindex]){
                    newSelectedOptionsText2.push(op);
                }
            });
            console.log("SelectedOptionsText2: "+newSelectedOptionsText2.toString());
            selectedOptionsText2 = newSelectedOptionsText2;
        //    selectedOptionsText2 = selectedOptionsText2.filter(option=>{option != selectedOptionsText2[removedindex]});
           cmp.set('v.selectedOptionsText2',selectedOptionsText2);
           
           




           // new functionality instructions 
           // find the record that needs to be changed (use code in change primary or previously you decide)
           // use index to remove from "selectedOptions", "selectedOptionsText", and "selectedOptionsText2"
           // update the component to remove the things aka cmp.set("v.blahblahblah",newListorObjToChange);
           // ~fin~ 


        }


        console.log("SELECTED OPTIONS: "+selectedOptions.toString());
        console.log("Selected Options Text: "+selectedOptionsText.toString());
        console.log("selected Options Text 2 : "+ selectedOptionsText2.toString());
        console.log("selectedNamesView : "+JSON.stringify(selectedNamesView));
        let initialize = cmp.get('c.init');

        $A.enqueueAction(initialize);
    },
    clearOption : function (cmp, e, helper) {
        cmp.set("v.results", []);
        cmp.set("v.openDropDown", false);
        cmp.set("v.inputValue", "");
        cmp.set("v.selectedOption", "");
        return;
    },
    changetoPrimary: function(cmp,e,helper){
        //find the selection to change with name.includes 
        const selectedValue = e.target.closest('div').dataset.value;
        let selectedCompetitors = cmp.get("v.selectedCompetitors");
        let oldPrimCompIndex = null;
        let newPrimCompIndex =null;
        selectedCompetitors.forEach((comp,index)=>{
            console.log(JSON.stringify(comp));
            if(comp.Name.includes(selectedValue)){
                //console.log('new Index Found');
                newPrimCompIndex = index;
                console.log("new Index: "+newPrimCompIndex);
            }
            if(comp.Primary__c == true){
                oldPrimCompIndex = index;
                console.log("old Index: "+oldPrimCompIndex);
            }
        });
        let action = cmp.get("c.changePrimary");
        action.setParams({'oldIndex': oldPrimCompIndex,'newIndex':newPrimCompIndex,'selectedCompetitors':JSON.stringify(selectedCompetitors)});
        action.setCallback(this,(res)=>{
            let state = res.getState();
            if(state=="SUCCESS"){
                const returnedCompetitors = res.getReturnValue();
                let selectedNames = [];
                returnedCompetitors.forEach(comp=>{
                    const selectedName = {Name : comp.Name, Primary__c:comp.Primary__c};
                    selectedNames.push(selectedName);
         });
         cmp.set('v.selectedNamesView',selectedNames);

         return;

                

            }
        });
        $A.enqueueAction(action);

        // use index to find the changed Competitior to upgrade to primary
        // change old primary to non primary 

        // return new list to component and set to component 




    },


})