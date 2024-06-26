({
    helperMethod: function () {

    },

    searchRecords: function (cmp, searchString) {
        var action = cmp.get("c.getRecords");
        var test = cmp.get("v.extendedWhereClause");
        //console.log('extended where clause in search Records: ' + test);
        action.setParams({
            "searchString": searchString,
            "objectApiName": cmp.get("v.objectApiName"),
            "idFieldApiName": cmp.get("v.idFieldApiName"),
            "valueFieldApiName": cmp.get("v.valueFieldApiName"),
            "extendedWhereClause": cmp.get("v.extendedWhereClause"),
            "maxRecords": cmp.get("v.maxRecords")
        });
        action.setCallback(this, function (res) {
            var state = res.getState();
            if (state === "SUCCESS") {
                const serverResult = res.getReturnValue();
                console.log('returned Industry:' + serverResult);
                //var results = [];
                var results2 = [];

                var problemList = cmp.get('v.queryFilter');
                console.log(problemList);
                // if (problemList != null && problemList.length > 0) {
                //     for (var i = 0; i < problemList.length; i++) {
                //         var newList = [];
                //         console.log("result: " + results);

                //         if (results != null && results.length > 0) {
                //             console.log("yay");

                //             newList = results;
                //             console.log(newList);

                //             newList = results.filter(reco => !reco.Name.includes(problemList[i]));
                //             console.log(problemList[i]);
                //             console.log("second filter: " + newList);

                //         } else {
                //             newList = serverResult.filter(rec => !rec.Name.includes(problemList[i]));
                //         }
                //         console.log("new list :" + newList);

                //         results = newList;
                //     }
                   
                // } else {
                    serverResult.forEach(function (element) {
                        console.log("ServerResult for Each");
                        console.log(element.PicklistType__c);
                        // if( element['PicklistType__c']=='Competitor'){
                            results2.push(element);
                        // }
                    });
                // }

                // results.forEach(function (element) {
                //     console.log('outside if/else forEach!');
                //     const result = { id: element[cmp.get("v.idFieldApiName")], value: element[cmp.get("v.valueFieldApiName")] };
                //     results2.push(result);
                // });


                cmp.set("v.results", results2);
                console.log(results2);
                console.log('^^^ new Results we\'re using');
                if (serverResult.length > 0) {
                    cmp.set("v.openDropDown", true);
                    // set flag to show err msg to false & update UI
                    cmp.set('v.emptyResult', false);
                } else {
                    // set flag to show err msg to true  & update UI
                    cmp.set('v.emptyResult', true);
                }
            } else {
                console.log(res.getError());
                let msg = "Something went wrong!! Could not find Competitors. Please contact admin for support";
                this.raiseMessage("ERROR", msg, "error");
            }
        });
        $A.enqueueAction(action);
        return;
    },
    raiseMessage: function (title, msg, type) {
        var toastEvent = $A.get("e.force:showToast");
        if (toastEvent) {
            toastEvent.setParams({
                "title": title,
                "type": type,
                "message": msg
            });
            toastEvent.fire();
        }
        return;
    },
    saveRecord:function(cmp){
        cmp.set("v.saved",false);
        var action = cmp.get("c.saveToOpp2");
        console.log("Client side competitors:" + JSON.stringify(cmp.get("v.selectedCompetitors")));
        action.setParams({
            "competitors": JSON.stringify(cmp.get("v.selectedCompetitors"))
        });
    action.setCallback(this,(res)=>{
        let state = res.getState();
        if(state=="SUCCESS"){
            cmp.set("v.saved",true);
            let msg = `Competitors have been saved on Opportunity: ${cmp.get('v.recordId')}`;
        this.raiseMessage( "Success", msg,"success");
        //this.init(cmp,e,helper);   
        $A.enqueueAction(cmp.get('c.init'));//reinitializes list


        return;
        }else{
            cmp.set("v.saved",true);
            let error = res.getError();
            console.log(error);
            let msg = 'There was an issue saving Competition to the Opportunity.';
            this.raiseMessage( "ERROR", msg,"error");

        }
    });
    $A.enqueueAction(action);

    },
    testSave:function(cmp){
        let testaction = cmp.get("c.testSave");
        console.log("selected Competitors Component content vvv");
        console.log(JSON.stringify(cmp.get("v.selectedCompetitors")));
        testaction.setParams({
            "competitors": JSON.stringify(cmp.get("v.selectedCompetitors"))
        });
        testaction.setCallback(this,(res)=>{
            let state = res.getState();
            if(state=="SUCCESS"){
                console.log("server call worked");
                let msg = `Competition has been saved on Opportunity: ${cmp.get('v.recordId')}`;
        this.raiseMessage( "Success", msg,"success");
                return;
            }else{
                let error = res.getError();
                console.log("error encountered: "+error);
            }
        });
        $A.enqueueAction(testaction);

    },

})