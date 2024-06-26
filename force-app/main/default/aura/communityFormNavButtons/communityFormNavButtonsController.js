({
    init: function(cmp, e, helper) {
        if(cmp.get('v.isUploadSection')){
             var cmpTarget = cmp.find('applyCSS');
        	$A.util.addClass(cmpTarget, 'fileuploadcss');
        }
        helper.manageLabel(cmp, e, helper);
    },
    // navigate backwards between the tablists
    // get the current tab and the immidiete parents to this tab:
    // Ex: account general info > hit next > tabNamesForCurrentLevel are company info, general info etc. Passes in by parent
    // if nextPosition look at the next level. In the current state thats the account tabs.
    // Finally if not matched send an event to navigate the chevron
    handlePrevious : function(cmp, e, helper) {
        // get the name of all the tabs in the component that renders this one
        let tabNamesForCurrentLevel = cmp.get('v.tabNameList');
        let nextPosition;
        //Benchmark
        console.log('Current position:'+cmp.get('v.currentPos'));
        if(cmp.get('v.currentPos') == 'BenchMarkAvgWages'){
            tabNamesForCurrentLevel.push('BenchMarkAvgWages');
        }else if(cmp.get('v.currentPos') == 'BenchMarkMedPart'){
            tabNamesForCurrentLevel.push('BenchMarkMedPart');
        }else if(cmp.get('v.currentPos') == 'BenchMarkTurnover'){
            tabNamesForCurrentLevel.push('BenchMarkTurnover');
        }
        
        let params = {
            currentPos: cmp.get('v.currentPos'),
            possibleTabs: tabNamesForCurrentLevel
        };
        
        nextPosition = helper.loopForPreviousMatch(cmp,e,helper, params);
        
        // if a next position is found on the parent tabs set the currentPos attribute
        // Current pos should be passed in as a reference from the parent level
        // when this gets updated it should be updating the 'Active Tab Id' reference
        // for the rendered component that owns this one
        if (nextPosition) {
            cmp.set('v.currentPos', nextPosition);
        } else {
            // if a match is not found at the parent we need to consider the parents parent
            // to have tabs of it's own. Exmaple is the Community Account Edit Forms or Medical
            // Questionnaire. They use an iteration to render a tab per account with two tabs in each
            // of the account tabs.
            params = {
                currentPos: cmp.get('v.activeParent'),
                possibleTabs: cmp.get('v.allPossibleParents')
            };
            
            nextPosition = helper.loopForPreviousMatch(cmp,e,helper, params);
            // If the next position returns null for the loop on the parents parent tabs
            // we can update the community forms component to navigate to the next chevron
            // step/tab
            if (!nextPosition) helper.sendCommunityFormsTabUpdate(cmp, e, helper, -1);
            else cmp.set('v.activeParent', nextPosition);
            
        }
        // always update the label
        helper.manageLabel(cmp, e, helper);
    },
    
    // navigate forwards between the tablists
    // get the current tab and the immidiete parents to this tab:
    // Ex: account general info > hit next > tabNamesForCurrentLevel are company info, general info etc. Passes in by parent
    // if nextPosition look at the next level. In the current state thats the account tabs.
    // Finally if not matched send an event to navigate the chevron
    handleNext : function(cmp, e, helper) {
        console.log('handleNext');
        let docslist =  cmp.get('v.UploadDocsList');
        console.log(docslist);
        // save function of parent tab
        let providedSaveLogic = cmp.get('v.saveFunc'); // Promise
        // the current tabs position. String value: 'Medical Info' or 'Covid Questionnaire'
        let currentPos = cmp.get('v.currentPos');
        let skipSave = cmp.get('v.skipSaveEvt'); // bool
        //sfdc-14129
        //debugger;
		var nmbrOfAttchments = cmp.get('v.nmbrOfAttchments');
        console.log('nmbrOfAttchments:'+nmbrOfAttchments);
        var skipNumber = cmp.get('v.skipNumber');
        console.log('skipNumber:'+skipNumber);
        var isCommunityUser = cmp.get('v.isCommunityUser');
        var isExceptionTabs;
        if(currentPos =='Misc Files - Medical' || currentPos == "Misc Files - Workers' Comp"){
            isExceptionTabs = true;
        }
        else{
            isExceptionTabs = false;
        }
      //  console.log('isCommunityUser:'+isCommunityUser);
      //  console.log('isExceptionTabs:'+isExceptionTabs);
        console.log('isUploadSection:'+cmp.get('v.isUploadSection'));
       // console.log('UploadDocsList: ', JSON.stringify(UploadDocsList));
       
       	var doctab;
        if(cmp.get('v.isUploadSection')){
             console.log('currentPos: '+ currentPos);
           var fndrow = docslist.filter(function (el)
                   {	return  el.TabLabel==currentPos;
                                     });
            if(fndrow[0]!=undefined)
            {
                //console.log('row: '+ JSON.stringify(fndrow[0]));
                doctab=fndrow[0];
            }
        
        	console.log(doctab);
        // if(nmbrOfAttchments == 0 && cmp.get('v.isUploadSection') && isCommunityUser && !isExceptionTabs){
          if(doctab.Status__c==undefined || doctab.Status__c==null) {
              console.log('Document Status:' ,doctab.Status__c);
              var skipSaveForNoDocs = false;
              if(doctab.PEO_Doc_Required__c=='Needed'){
                  skipSaveForNoDocs = true;
                  let dets = {ty: 'error', t: 'A document has not been uploaded', m:  'Please upload your file'};
                  helper.showUserMsg(null, dets);
                  //skipNumber = skipNumber+1;
                  //cmp.set('v.skipNumber',skipNumber);
              }           
          }
        }
        // if save function provided and not skipping save
        // update the load state trigger the save function
        // then find the next tab
        console.log('-->', skipSave,skipNumber, skipSaveForNoDocs);
        if (providedSaveLogic && !skipSave && !skipSaveForNoDocs) { 
            console.log('1');
            helper.switchLoadState(cmp, e, helper)
            providedSaveLogic()
            .then(function(res) {
                helper.handleNext(cmp, e, helper);
                helper.switchLoadState(cmp, e, helper)
            })
            .catch(function(err) {
                helper.switchLoadState(cmp, e, helper)
                console.log(err)
            });
        } else {
            // find the next tab
            console.log('2');
            if (!providedSaveLogic) console.log('No save function provided');
            if (skipSave) console.log('Provided argument skipSaveEvt to nav component to skip the save function')
            if(!skipSaveForNoDocs && skipNumber !=1){
                console.log('handleNext else if');
                helper.handleNext(cmp, e, helper)
            }
        }       
        // always update the label
        helper.manageLabel(cmp, e, helper);
    },
    
    //SFDC-14128 Start Rohith
    handleSave : function(cmp, e, helper) {
        let providedSaveLogic = cmp.get('v.saveFunc'); // assuming it's a promise as of now
        let currentPos = cmp.get('v.currentPos');  
          console.log('isUploadSection' , cmp.get('v.isUploadSection'));
       	console.log('handleSave' , cmp.get('v.nmbrOfAttchments'));
         console.log('handleSave' , cmp.get('v.currentPos'));
       
        if(cmp.get('v.nmbrOfAttchments')==0 && cmp.get('v.isUploadSection')){
            let dets = {ty: 'warning', 
                        t: currentPos, 
                        m:  'Please upload your file'};
                helper.showUserMsg(null, dets);
        }
        if(cmp.get('v.nmbrOfAttchments')!=0 && cmp.get('v.isUploadSection')){
            let dets = {ty: 'success', 
                        t: currentPos, 
                        m:  'Documents has been Saved'};
                helper.showUserMsg(null, dets);
        }
         let skipSave = cmp.get('v.skipSaveEvt');
        if (providedSaveLogic /*&& !skipSave*/) { 
            // helper.switchLoadState(cmp, e, helper)
            if(cmp.get('v.temp')){
                var parent = cmp.get('v.parent');
                parent.save('Save', cmp.get('v.skipValidation'))
            }else{
                providedSaveLogic(cmp)
                .catch(function(err) {
                    console.log(err)
                });
            }
        }else {
            if (!providedSaveLogic) console.log('No save function provided');
            if (skipSave) console.log('Provided argument skipSaveEvt to nav component to skip the save function')
            
                }   
        helper.manageLabel(cmp, e, helper);
    },
    
    
    //SFDC-14128 End
    resetValues : function(cmp, e, helper) {
        cmp.set('v.skipNumber',0);
        console.log('Setting skip number to 0 value:'+cmp.get('v.skipNumber'));
    },
    
    //JDA SPA
    handleChange : function(cmp, e, helper) {
        let nextTab;
        let params = {
            possibleTabs: cmp.get('v.tabNameList'),
            currentPos: cmp.get('v.currentPos')
        };
        console.log(params);
        //debugger;
        nextTab = helper.loopForNextMatch(cmp, e, helper, params);
        console.log('handleChange - nextTab:'+nextTab);
        if(!nextTab){
            cmp.set('v.displayFinish', true);
            cmp.set('v.isLastTab', true);
        }
        else{
            cmp.set('v.displayFinish', false);
            cmp.set('v.isLastTab', false);
        }
        console.log('handleChange - isLastTab:'+cmp.get('v.isLastTab'));
    },
})