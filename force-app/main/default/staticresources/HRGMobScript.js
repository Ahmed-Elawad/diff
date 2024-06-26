    var jqnc = jQuery.noConflict();
    var ready = false;
    jqnc(document).ready(function(){
        jqnc.mobile.loading( 'show', {
          text: "Loading " + accountName,
          textVisible: true,
          theme: "b",
          });
    jqnc("#allRecs").on("focusin", focusText);
    jqnc("#allRecs").on("focusout", blurText);
        jqnc("#allRecs").on( "swipeleft swiperight", navHandler );
        jqnc(".ui-btn-icon-left, .ui-btn-icon-right").on( "tap", navHandler );
        jqnc(".messages").on('click touchstart', closePopUp);
        jqnc("#landing").hide();
        jqnc(".nextButton").hide();
        jqnc("#askNumber").hide();
        jqnc(".navIcons").hide();
        jqnc(".saveButton").hide();
        var callBacks = jqnc.Callbacks();
        callBacks.add(getRefHRG);
        callBacks.add(build_hrgTypes);
        callBacks.add(build_hrgActivityTypes);
        callBacks.add(build_hrgActivities);
        callBacks.fire();
        });

        var accountId;
        var accountName;
        var nbrNew;         
        var newActTable;
        var newActWrapTable;
        var newStndActTable;
        var idx;
        var hrgTypes;
        var hrgActivityTypes;
        var hrgActivities;
        var numberOfActivities;
        var refHRG;
        var isError = false;
        var dateError = false;
        var mtgError = false;
        var picklistError = false;
        var isOnb = false;
        var productFields;
        var openSFActivities;
        var acctList = [];
        var acctListType = '';
    
    function focusText(event) {
            var curr = jqnc(event.target);
        if(curr.hasClass("ui-input-text") &&  curr.val() == "" ) {
        curr.val(" ");
        }   
    }
    
    function blurText(event) {
        var curr = jqnc(event.target);
        if(curr.hasClass("ui-input-text") &&  curr.val() == " " ) {
        curr.val("");
        }           
    }
        
        function gotoLanding() { // Refreshes the entire Mobile Page
            location.reload();
        }// gotoLanding
        
        function getRefHRG() { //Gets the ReferenceHRG associated with this account and updates the button text based on returned values
            HRGActivitiesMobilePageController.getRefHRG(accountId,
            function(refHRGCon, event){
                refHRG = refHRGCon;
                if (event.status) {
                    if (event.type === "exception") {
                        console.log('got exception on remote action');
                    }
                    else if(refHRG.Name){
                        var content = "Onboarding Activities (" + refHRG.Onboarding_Completed__c + "%)";
                        jqnc( "#btnOnbAct"  ).empty().append(content);
                        content = "Onboarding Concerns (" + refHRG.Client_Concern_Count__c + ")";
                        jqnc( "#btnOnbCon" ).empty().append(content);
                        content = "Onboarding Setup (" + refHRG.Setup_Issue_Count__c + ")";
                        jqnc( "#btnOnbSet" ).empty().append(content);
                        content = "Product Utilization (" + refHRG.ProductUtilization__c + "%)";
                        jqnc( "#btnProdUtil" ).empty().append(content);
                        content = "Open Ongoing Activities (" + refHRG.Open_Activities__c + ")";
                        jqnc( "#btnOpenOngAct" ).empty().append(content);
                        if(!refHRG.Onboarding_End_Date__c && refHRG.Expected_Onboarding_End_Date__c < new Date && refHRG.Onboarding_Start_Date__c > new Date("October 01, 2013 00:00:01")){
                            content = " (Over 90 Days)"
                            jqnc( "#btnOnbDates" ).append(content).css('color', 'red');   
                        }
                        else if(refHRG.Onboarding_End_Date__c){
                            content = " (Complete)"
                            jqnc( "#btnOnbDates" ).append(content).css('color', 'green');       
                        }
                    }
                }                   
            });
            HRGActivitiesMobilePageController.getOpenSFActivities(accountId,
                function(openSFActivitiesReturned, event){
                    if (event.status) {
                        if (event.type === "exception") {
                            console.log('got exception on remote action');
                        }
                        else {
                            openSFActivities = openSFActivitiesReturned;
                            var content = "Open Salesforce Activities (" + openSFActivities.length + ")";
                            jqnc( "#btnOpenOpenSFAct"  ).empty().append(content);
                        }
                     }                   
            });
            jqnc("#landing").show();
        } //getRefHRG
        
        function gotoAcctHealth() { //Setup and display the account health update page.
            jqnc("#allRecs").empty();
            jqnc("#landing").hide();
            jqnc.mobile.loading("show");
            HRGActivitiesMobilePageController.getAcctHealth(accountId,
            function(clientHealth, event){
                if (event.status) {
                    if (event.type === "exception") {
                        console.log('got exception on remote action');
                    }
                    else {
                            var healthOpts = "<option value=\"\">Select Type</option>" +
                                             "<option value=\"Stable\">Stable</option>" +
                                             "<option value=\"Potential Risk\">Potential Risk</option>" +
                                             "<option value=\"At Risk\">At Risk</option>"; 
                            var content = ""; 
                            content += "<div class=\"slideDown\"><h1>"+accountName+"</h1> " +
                                "<div class=\"newHealthDiv ui-field-contain\">" +
                                    "<label for=\"newHealthField\">HR Solutions Account Health</label>"+
                                    "<select class=\"newHealthField\" id=\"newHealthField\">"+healthOpts+"</select>" +
                                "</div>"+
                                "<div class=\"healthReasonDiv ui-field-contain\">" +
                                    "<label for=\"healthReasonField\">Reason for Change</label>"+
                                    "<textarea class=\"healthReasonField\" id=\"healthReasonField\" ></textarea>" +
                                "</div>"+
                                "<div>"+
                                    "<button type=\"button\" onclick=\"processAcctHealth()\">Save Changes</button>"+
                                    "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>"+
                                "</div>"+
                                "</div>";                                                                   
                            jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                            jqnc("#newHealthField").val(clientHealth).selectmenu('refresh');// Refresh the select menu for JQuery Mobile
                            jqnc(".newHealthField, .healthReasonField").on("change", errorCheck );
                            jqnc("#allRecs").show();
                            jqnc("#main").show();                                         
                        }
                        jqnc.mobile.loading("hide");
                    }                   
                });
        } // gotoAcctHealth
        
        function processAcctHealth() { //Save the Account Health and create the Acivity for the update
            if(!isError){
                var accountHealth = jqnc("#allRecs").find("select.newHealthField").val();
                var notes = jqnc("#allRecs").find("textarea.healthReasonField").val();
                jqnc.mobile.loading("show");
                HRGActivitiesMobilePageController.processAcctHealth(accountHealth, notes, accountId,
                    function(result,event){
                        if (event.status) {
                            if (event.type === "exception") {
                                console.log('got exception on remote action');
                            }
                            else {
                                gotoLanding();
                            }
                        }                   
                    });
           }
           else{
                jqnc(".messages").show();   
           }
        } // processAcctHealth
        
        function gotoProdUtil() { //Gets the product utilization fields and displays the page to update it.
                jqnc("#allRecs").empty();
                jqnc("#landing").hide();
                jqnc.mobile.loading("show");
                HRGActivitiesMobilePageController.getProductFields(accountId,
                function(prodUtilFields, event){
                    if (event.status) {
                        if (event.type === "exception") {
                            console.log('got exception on remote action');
                        }
                        else {
                            productFields = prodUtilFields;
                            var prodOpts = "<option value=\"\">-None-</option>" +
                                "<option value=\"Not Activated\">Not Activated</option>" +
                                "<option value=\"Activated\">Activated</option>" +
                                "<option value=\"At Risk\">At Risk</option>";
                            var content = "<div><h1>"+accountName+"</h1>";
                            jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                            for (var i=0, j=productFields.length; i<j; i++) {
                                for (var f in productFields[i]){
                                    content = "<fieldset class=\"ui-field-contain\">" +
                                            "<label for=\"select-" + f + "\">" + productFields[i][f] + "</label>"+
                                            "<select data-role=\"select\"  id=\"select-" + f + "\">"+prodOpts+"</select>" +
                                        "</fieldset>";
                                    jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                                    console.log(f + ' ' + refHRG[f]);
                                    if(refHRG[f]){
                                        jqnc( '#select-'+f).val(refHRG[f]).selectmenu('refresh');
                                    }
                                }
                            }
                            content =   "<div>" +
                                            "<button type=\"button\" onclick=\"saveRefHRG(\'prodUtil\')\">Save Changes</button>" +
                                            "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>" +
                                        "</div>" +
                                        "</div>";                                                                   
                            jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                            jqnc("#allRecs").show();
                            jqnc("#main").show();                                         
                        }
                        jqnc.mobile.loading("hide");
                    }                   
                });   
        } // gotoProdUtil
                
        function gotoOnboardingDates() { //Setup and display the Onboarding Dates page
                jqnc("#allRecs").empty();
                jqnc("#landing").hide();
                jqnc.mobile.loading("show");
                var Opts = "<option value=\"\">-None-</option>" +
                                "<option value=\"Yes\">Yes</option>" +
                                "<option value=\"No\">No</option>";
                var content = "<div class=\"slideDown\"><h1>"+accountName+"</h1>"+
                    "<div class=\"CompDateDiv ui-field-contain\">" +
                            "<label for=\"startDateField\">Onboarding Start Date</label>"+
                            "<text class=\"startDateField\" id=\"startDateField\">"+formatDate(refHRG.Onboarding_Start_Date__c)+"</text>" +
                    "</div>"+
                    "<div class=\"CompDateDiv ui-field-contain\">" +
                            "<label for=\"expEndDateField\">Expected Onboarding End Date</label>"+
                            "<text class=\"expEndDateField\" id=\"expEndDateField\">"+formatDate(refHRG.Expected_Onboarding_End_Date__c)+"</text>" +
                    "</div>"+
                    "<div class=\"CompDateDiv ui-field-contain\">" +
                            "<label for=\"endDateField\">Onboarding End Date</label>"+
                            "<text class=\"endDateField\" id=\"endDateField\">"+formatDate(refHRG.Onboarding_End_Date__c)+"</text>" +
                    "</div>"+
                    "<fieldset class=\"ui-field-contain\">" +
                        "<label for=\"select-ccMeeting\">Sales Rep Attended CC Meeting</label>"+
                        "<select data-role=\"select\"  id=\"select-ccMeeting\">"+Opts+"</select>" +
                    "</fieldset>"+
                    "<div>" +
                        "<button type=\"button\" onclick=\"saveRefHRG(\'onbDates\')\">Save Changes</button>" +
                        "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>" +
                    "</div>" +
                    "</div>";                                                                   
                jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                if(refHRG.Sales_Rep_Attended_CC_Meeting__c){
                    jqnc( '#select-ccMeeting').val(refHRG.Sales_Rep_Attended_CC_Meeting__c).selectmenu('refresh');
                }
                jqnc("#allRecs").show();
                jqnc("#main").show();
                jqnc.mobile.loading("hide");
        } // gotoOnboardingDates
        
        function saveRefHRG(saveFrom) { //Save the Reference HRG Onboarding Record and refresh the mobile page
            var isChanged = false;
            if(saveFrom == 'prodUtil'){ //Is the save coming from the Product Utilization update page?
                for (var i=0, j=productFields.length; i<j; i++) {
                    for (var f in productFields[i]){
                        if(jqnc( '#select-'+f).val() != refHRG[f]){
                            refHRG[f] = jqnc( '#select-'+f).val();
                            isChanged = true;
                        }
                    }
                }
            }
            else if(saveFrom == 'onbDates'){ //Is the save coming from the Onboarding Dates page?
                if(jqnc( '#select-ccMeeting').val() != refHRG.Sales_Rep_Attended_CC_Meeting__c){
                    refHRG.Sales_Rep_Attended_CC_Meeting__c = jqnc( '#select-ccMeeting').val();
                    isChanged = true;
                }
            }
            if(isChanged){ //Finalize the save
                jqnc.mobile.loading("show");
                HRGActivitiesMobilePageController.saveRefHRG(accountId, refHRG,
                    function(result,event){
                        if (event.status) {
                            if (event.type === "exception") {
                                console.log('got exception on remote action');
                            }
                            else {
                                gotoLanding();
                            }
                        }                   
                    });
              }
        } // saveRefHRG
        
        function gotoOnboarding(onbType) { // Create page 1 for entering onboarding activities. The type is passed in to determine what will be returned
            if(ready){
                jqnc.mobile.loading("show");
                jqnc("#allRecs").empty();
                jqnc("#landing").hide();
                isOnb = true;
                HRGActivitiesMobilePageController.getOnboardingActivities(accountId, onbType,
                function(newActWrappers, event){
                    if (event.status) {
                        if (event.type === "exception") {
                            console.log('got exception on remote action');
                        }
                        else {
                            newActTable = newActWrappers;
                            console.log('newActTable='+newActTable);
                            idx = 0;  
                            var content = "";
                            numberOfActivities = newActTable.length * 2;
                            var typeOpts = "<option value=\"\">Select Type</option>";
                            for (var i=0, j=hrgTypes.length; i<j; i++) {
                                typeOpts += "<option value=\"" +hrgTypes[i]+ "\">" + hrgTypes[i] + "</option>";   
                            }
                            for (var i=0, j=newActTable.length; i<j; i++) {
                                var recNum = i+1;
                                var actDate = new Date(newActTable[i].activity.Activity_Date__c).toISOString().substring(0, 10);
                                var iNotes = "";
                                if(newActTable[i].activity.Notes__c){
                                    iNotes += newActTable[i].activity.Notes__c;
                                }
                                if(i==0 && newActTable.length > 1){
                                    content += "<div class=\"rec slideDown\">Swipe to go to the next "+ onbType +" Activity";
                                }
                                else if (i==0){
                                    content += "<div class=\"rec slideDown\">";
                                }
                                else{
                                    content += "<div class=\"rec\" style=\"display:none;\">Swipe to go to the next "+ onbType +" Activity";
                                } 
                                content +=  "<div class=\"TypeDiv ui-field-contain\">" +
                                    "<label for=\"TypeField" + i + "\">Log Activity?</label>";
                                if(newActTable[i].activity.Closed__c){
                                    content += "<text class=\"TypeField\" id=\"TypeField" + i + "\">"+newActTable[i].activity.Type__c+"</text>";    
                                }
                                else{
                                    content += "<select class=\"TypeField\" id=\"TypeField" + i + "\">"+typeOpts+"</select>";
                                }
                                content += "</div>"+
                               "<div class=\"ActivityTypePDiv ui-field-contain\">" +
                                "<label for=\"ActivityTypeP" + i + "\">Activity Name</label>"+
                                "<text class=\"ActivityTypePField\" id=\"ActivityTypeP" + i + "\">"+newActTable[i].activity.Activity_Type__c+"-"+newActTable[i].activity.Activity__c+"</text>" +
                               "</div>"+
                               "<div class=\"DateDiv ui-field-contain\">" +
                                "<label for=\"DateField" + i + "\">Activity Date</label>"+
                                "<input class=\"DateField\" id=\"DateField" + i + "\" type=\"date\" value="+actDate+"></input>" +
                               "</div>"+
                               "<div class=\"CompDateDiv ui-field-contain\">" +
                                "<label for=\"CompDateField" + i + "\">Completed Date</label>"+
                                "<text class=\"CompDateField\" id=\"CompDateField" + i + "\">"+formatDate(newActTable[i].activity.Complete_Date__c)+"</text>" +
                               "</div>"+
                               "<div class=\"NotesDiv ui-field-contain\">" +
                                "<label for=\"NotesField" + i + "\">Notes</label>"+
                                "<textarea class=\"NotesField\" id=\"NotesField" + i + "\" >" + iNotes + "</textarea>" +
                               "</div>"+
                               "<div style=\"display:none;\">"+ 
                                    "<select class=\"ActivityTypeField\" id=\"ActivityTypeField" + i + "\"><option value=\""+
                                        newActTable[i].activity.Activity_Type__c+
                                        "\" selected=\"selected\">"+newActTable[i].activity.Activity_Type__c+"</option>"+
                                   "</select>" +
                                   "<select class=\"ActivityField\" id=\"ActivityField" + i + "\">"+
                                   "<option value=\""+newActTable[i].activity.Activity__c+"\" selected=\"selected\">"+
                                        newActTable[i].activity.Activity__c+"</option>"+
                                   "</select>" +
                               "</div>"+
                               "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>"+
                               "</div>";                                                                            
                            } // for 
                            jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                            jqnc("#main").show();
                            jqnc("#allRecs").show();
                            jqnc(".nextButton").show(); 
                            jqnc.mobile.loading("hide"); 
                        }
                    }                   
                });
            }
        } // getOnboardingActivities
        
        
        function gotoOngoing(onbType) { // Create page 1 for entering onboarding activities. The type is passed in to determine what will be returned
            if(ready && refHRG && refHRG.Open_Activities__c > 0){
                jqnc.mobile.loading("show");
                jqnc("#allRecs").empty();
                jqnc("#landing").hide();
                HRGActivitiesMobilePageController.getOngoingActivities(accountId, onbType,
                function(newActWrappers, event){
                    if (event.status) {
                        if (event.type === "exception") {
                            console.log('got exception on remote action');
                        }
                        else {
                            newActTable = newActWrappers;
                            console.log('newActTable='+newActTable);
                            idx = 0;  
                            var content = "";
                            numberOfActivities = newActTable.length * 2;
                            var typeOpts = "<option value=\"\">Select Type</option>";
                            for (var i=0, j=hrgTypes.length; i<j; i++) {
                                typeOpts += "<option value=\"" +hrgTypes[i]+ "\">" + hrgTypes[i] + "</option>";   
                            }
                            if(newActTable.length > 0){
                                for (var i=0, j=newActTable.length; i<j; i++) {
                                    var notes = "";
                                    if(newActTable[i].activity.Notes__c){
                                        notes += newActTable[i].activity.Notes__c;    
                                    }
                                    var recNum = i+1;
                                    var actDate = new Date(newActTable[i].activity.Activity_Date__c).toISOString().substring(0, 10);
                                    if(i==0 && newActTable.length > 1){
                                        content += "<div class=\"rec slideDown\">Swipe to go to the next "+ onbType +" Activity";
                                    }
                                    else if (i==0){
                                        content += "<div class=\"rec slideDown\">";
                                    }
                                    else{
                                        content += "<div class=\"rec\" style=\"display:none;\">Swipe to go to the next "+ onbType +" Activity";
                                    } 
                                    //content +=    "<div class=\"TypeDiv ui-field-contain\">" +
                                    //    "<label for=\"TypeField" + i + "\">Type</label>" +
                                    //    "<select class=\"TypeField\" id=\"TypeField" + i + "\">"+typeOpts+"</select>";
                                    content += "<div class=\"TypeDiv ui-field-contain\">" +
                                        "<label for=\"TypeField" + i + "\">Type</label>" +
                                        "<text class=\"TypeField\" id=\"TypeField" + i + "\">"+newActTable[i].activity.Type__c+"</text>" + 
                                    "</div>"+
                                   "<div class=\"ActivityTypePDiv ui-field-contain\">" +
                                    "<label for=\"ActivityTypeP" + i + "\">Activity Name</label>"+
                                    "<text class=\"ActivityTypePField\" id=\"ActivityTypeP" + i + "\">"+newActTable[i].activity.Activity_Type__c+"-"+newActTable[i].activity.Activity__c+"</text>" +
                                   "</div>"+
                                   "<div class=\"DateDiv ui-field-contain\">" +
                                    "<label for=\"DateField" + i + "\">Activity Date</label>"+
                                    "<text class=\"DateField\" id=\"DateField" + i + "\">"+formatDate(newActTable[i].activity.Activity_Date__c)+"</text>" +
                                   "</div>"+
                                   "<div class=\"NotesDiv ui-field-contain\">" +
                                    "<label for=\"NotesField" + i + "\">Notes</label>"+
                                    "<textarea class=\"NotesField\" id=\"NotesField" + i + "\" >" + notes + "</textarea>" +
                                   "</div>"+
                                   "<div style=\"display:none;\">"+ 
                                        "<select class=\"ActivityTypeField\" id=\"ActivityTypeField" + i + "\"><option value=\""+
                                            newActTable[i].activity.Activity_Type__c+
                                            "\" selected=\"selected\">"+newActTable[i].activity.Activity_Type__c+"</option>"+
                                       "</select>" +
                                       "<select class=\"ActivityField\" id=\"ActivityField" + i + "\">"+
                                       "<option value=\""+newActTable[i].activity.Activity__c+"\" selected=\"selected\">"+
                                            newActTable[i].activity.Activity__c+"</option>"+
                                       "</select>" +
                                   "</div>"+
                                   "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>"+
                                   "</div>";                                                                            
                                } //for
                                jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                                //for (var i=0, j=newActTable.length; i<j; i++) {
                                //    jqnc( '#TypeField'+i).val(newActTable[i].activity.Type__c).selectmenu('refresh');
                                //} //for
                            } //if
                            else{
                                content = "<div><text>No Open Ongoing Activities found.</text>" +
                                "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>"+
                                "</div>";
                                jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                            } //else
                            jqnc("#main").show();
                            jqnc("#allRecs").show();
                            jqnc(".nextButton").show(); 
                            jqnc.mobile.loading("hide"); 
                        }
                    }                   
                });
            }
        } // getOngoingActivities
        
        function gotoOpenSFActivities() { //Display open SF activities.
            if(openSFActivities){
                jqnc("#allRecs").empty();
                jqnc("#landing").hide();
                jqnc.mobile.loading("show");
                    var content = "<div><h1>"+accountName+"</h1>" +
                                   "<p style=\"color:red;\" >Warning! Pressing the Delete button will permanently delete the activity.</p>" +
                                   "<table data-role=\"table\" class=\"ui-body-d ui-shadow ui-responsive table-stripe\">" +
                                   "<thead>" +
                                    "<tr>" +
                                      "<th>Delete?</th>" +
                                      "<th>Type</th>" +
                                      "<th>Date</th>" +
                                      "<th>Subject</th>" +
                                    "</tr>" +
                                  "</thead>" +
                                  "</tbody>";
                    for (var i=0, j=openSFActivities.length; i<j; i++) {
                        content += "<tr>" +
                                "<td>" + "<a data-role=\"button\" data-mini=\"true\" class=\"ui-btn ui-shadow ui-btn-corner-all ui-mini ui-btn-inline ui-btn-up-c\"" +
                                " onclick=\"deleteActivity(\'" + openSFActivities[i].key + "\')\">Delete</a>" + "</td>"+
                                "<td>" + openSFActivities[i].taskOrEvent + "</td>";
                        if(openSFActivities[i].isEvent){
                          content += "<td>" + openSFActivities[i].javaDate + "</td>"+
                                     "<td>" + openSFActivities[i].evnt.Subject + "</td>";
                        }
                        else if(openSFActivities[i].isTask){
                          content += "<td>" + openSFActivities[i].javaDate + "</td>"+
                                     "<td>" + openSFActivities[i].tsk.Subject + "</td>";
                        }
                        content += "</tr>";
                    }
                    content +=  "</tbody>" +
                                "</table>" +
                                "<div>" +
                                    "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>" +
                                "</div>" +
                                "</div>";                                                                   
                    jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                    jqnc("#allRecs").show();
                    jqnc("#main").show();
                    jqnc.mobile.loading("hide");                                         
                }  
        } // gotoOpenSFActivities
        
        function deleteActivity(key) { // Delete Activity
            jqnc.mobile.loading("show");
            HRGActivitiesMobilePageController.deleteActivity(accountId, key,
                function(newActWrappers, event){
                    if (event.status) {
                        if (event.type === "exception") {
                            console.log('got exception on remote action');
                        }
                        else {
                            HRGActivitiesMobilePageController.getOpenSFActivities(accountId,
                            function(openSFActivitiesReturned, event){
                                if (event.status) {
                                    if (event.type === "exception") {
                                        console.log('got exception on remote action');
                                    }
                                    else {
                                        openSFActivities = openSFActivitiesReturned;
                                        gotoOpenSFActivities();
                                    }
                                 }                   
                            });
                            
                        }
                    }                   
                }); 
            jqnc.mobile.loading("hide");              
        } // deleteActivity
        
        function gotoNewOngoing() { // Setup and display the ask number page for adding new ongoing activities
            jqnc("#landing").hide(); 
            jqnc("#askNumber").show();    
        } // gotoOngoing

        function addButtonClick() {
            nbrNew = document.getElementById("nbrNewOngoing").value;
            console.log('AccountId = '+accountId);
            console.log('Step 1: Entered number of activities.'+nbrNew);
            
            if (nbrNew == '') {   
                jqnc('#errorLabel').text('Please pick a number between 1 and 10.');             
            }    
            else if (nbrNew > 10 || nbrNew < 0) {
                jqnc('#errorLabel').text('Please pick a number between 1 and 10.');
            }                     
            else {
                jqnc('#errorLabel').text('');  
                createHRGActivities();
                jqnc("#askNumber").hide();
            }
        } // addButtonClick

        function createHRGActivities() { //Setup and display page 1 for adding new ongoing activities
        jqnc("#allRecs").empty();
        jqnc.mobile.loading("show");
        HRGActivitiesMobilePageController.createHrgActivities(accountId, nbrNew,
        function(newActWrappers, event){
            console.log('got activities list back');                   
            console.log('newActWrappers='+newActWrappers);
            if (event.status) {
                if (event.type === "exception") {
                    console.log('got exception on remote action');
                }
                else {
                    newActTable = newActWrappers;
                    console.log('newActTable='+newActTable);
                        idx = 0;
                        var now = new Date();
                        var day = ("0" + now.getDate()).slice(-2);
                        var month = ("0" + (now.getMonth() + 1)).slice(-2);
                        var today = now.getFullYear()+"-"+(month)+"-"+(day) ;
                        console.log('today='+today+'.');
                        var typeOpts = "<option value=\"\" selected=\"selected\">Select Type</option>"; 
                        var actTypeOpts = "<option value=\"\" selected=\"selected\">Select Activity Type</option>"; 
                        var content = "";
                        numberOfActivities = newActTable.length * 2;
                        for (var i=0, j=hrgTypes.length; i<j; i++) {
                            typeOpts += "<option value=\"" +hrgTypes[i]+ "\">" + hrgTypes[i] + "</option>";   
                        }
                        for (var i=0, j=hrgActivityTypes.length; i<j; i++) {
                            actTypeOpts += "<option value=\"" +hrgActivityTypes[i]+ "\">" + hrgActivityTypes[i] + "</option>";   
                        }
                        for (var i=0, j=newActTable.length; i<j; i++) {
                            var recNum = i+1;
                            if(i==0 && newActTable.length > 1){
                                content += "<div class=\"rec slideDown\">Swipe to go to the next Activity";
                            }
                            else if (i==0){
                                content += "<div class=\"rec slideDown\">";
                            }
                            else{
                                content += "<div class=\"rec\" style=\"display:none;\">Swipe to go to the next Activity";
                            } 
                            content += "<div class=\"DateDiv ui-field-contain\">" +
                           "<label for=\"DateField" + i + "\">Date</label>"+
                           "<input class=\"DateField\" id=\"DateField" + i + "\" type=\"date\" value="+today+"></input>" +
                           "</div>"+
                           "<div class=\"TypeDiv ui-field-contain\">" +
                           "<label for=\"TypeField" + i + "\">Type</label>"+
                           "<select class=\"TypeField\" id=\"TypeField" + i + "\">"+typeOpts+"</select>" +
                           "</div>"+
                           "<div class=\"ActivityTypeDiv ui-field-contain\">" +
                           "<label for=\"ActivityTypeField" + i + "\">Activity Type</label>"+
                           "<select class=\"ActivityTypeField\" id=\"ActivityTypeField" + i + "\">"+actTypeOpts+"</select>" +
                           "</div>"+
                           "<div class=\"ActivityFieldDiv ui-field-contain\">" +
                            "<label for=\"ActivityField" + i + "\">Activity</label>"+
                            "<select class=\"ActivityField\" id=\"ActivityField" + i + "\">"+
                            "<option value=\"\" selected=\"selected\">Select Activity</option></select>" +
                           "</div>"+
                           "<div class=\"NotesDiv ui-field-contain\">" +
                            "<label for=\"NotesField" + i + "\">Notes</label>"+
                           "<textarea class=\"NotesField\" id=\"NotesField" + i + "\" >" + newActTable[i].activity.Notes__c + "</textarea>" +
                           "</div>"+
                           "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>"+     
                           "</div>";                                                                   
                        } // for 
                        jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                        jqnc("#main").show();
                        jqnc("#allRecs").show();
                        jqnc(".ActivityTypeField").on( "change", updateActivityOpts );
                        jqnc(".TypeField, .ActivityTypeField, .ActivityField").on("change", errorCheck );
                        jqnc(".nextButton").show();
                        //This method will activate the publish button so the form can be submitted
                        jqnc.mobile.loading("hide");
                    }
                }                   
            });
        } // createHRGActivities
      
        function recCheck(){ //Check that each new ongoing record is completed before going to page 2 (processHRGAcivities)
             if(!isError){
                var incomplete = false;
                if(!isOnb){
                    jqnc(".rec").each(function() {
                        if( jqnc(this).find("select.TypeField").prop('selectedIndex') == 0){
                            incomplete = true;
                            return false;
                        }
                    }); // each
                }
                if(incomplete){
                    jqnc(".recMessage").show();     
                }
                else{
                    processHRGActivities();
                }
             }//if(!isError)     
             else{
                jqnc(".messages").show();   
            }   
        } //recCheck
              
        function processHRGActivities(){ //Take the input from Page 1 (Onboarding & Ongoing), process, and display page 2
          jqnc(".recMessage").hide();
          jqnc(".rec").hide();
          jqnc.mobile.loading("show");
          var stndDate;
          var stndTime;
          var stndSubj;
          var stndDateCompl;
          var stndDescrip;
          var stndReasonCncl;
          var stndClientSumm;
          var stndMtgNotHeld;
          console.log('at processHRGActivities, newActTable='+newActTable);
          
          jqnc(".rec").each(function(idx) {
            if(jqnc(this).find("select.TypeField").val()){
                console.log('processHRGact, Act_Date__c back from user='+Date.parse(jqnc(this).find("input.DateField").val()));
                newActTable[idx].activity.Activity_Date__c = Date.parse(jqnc(this).find("input.DateField").val());
                newActTable[idx].activity.Type__c = jqnc(this).find("select.TypeField").val();
                newActTable[idx].activity.Activity_Type__c = jqnc(this).find("select.ActivityTypeField").val();
                newActTable[idx].activity.Activity__c = jqnc(this).find("select.ActivityField").val();                      
                newActTable[idx].activity.Notes__c = jqnc(this).find("textarea.NotesField").val();
                console.log('newActTable[idx].activity.Notes__c='+newActTable[idx].activity.Notes__c);
            }
          }); // each
          
          console.log('ActTable with user input='+newActTable);        
          HRGActivitiesMobilePageController.processHRGActivities(newActTable, accountId,
          function(newStndActWrappers, event){;
             if(event.status){
             if (event.type === 'exception'){
                console.log('back from processHRGActivites, exception='+result);
            } else {
                jqnc("#allRecs").empty();
                jqnc(".nextButton").hide();
                var content = "";
                newStndActTable = newStndActWrappers;
                console.log('back from processHRGActivities, newStndActTable='+newStndActTable);    
                var now = new Date();
                var day = ("0" + now.getDate()).slice(-2);
                var month = ("0" + (now.getMonth() + 1)).slice(-2);
                var today = now.getFullYear()+"-"+(month)+"-"+(day) ;                        
                for (var i=0, j=newStndActTable.length; i<j; i++) {
                if(i==0 && newStndActTable.length > 1){
                    content += "<div class=\"rec slideDown\">Swipe to go to the next record";                               
                }
                else if (i==0){
                    content += "<div class=\"rec slideDown\">";
                }
                else{
                    content += "<div class=\"rec\" style=\"display:none;\">Swipe to go to the next record";
                } 

                if (newStndActTable[i].isNew)
                {   content += "<div class=\"newActText\">New "+newStndActTable[i].taskOrEvent+"</div>";   }
                else
                {   content += "<div class=\"previousActText\">This is a previously opened "+newStndActTable[i].taskOrEvent+"</div>";  }

                if ( newStndActTable[i].isEvent) 
                {   stndDate = newStndActTable[i].javaDate;
                    stndTime = newStndActTable[i].selectedTime;
                    stndSubj = newStndActTable[i].evnt.Subject; 
                    //stndDateCompl = newStndActTable[i].evnt.Date_Activity_Completed__c;  //default = today
                    stndDateCompl = '';
                    stndDescrip = newStndActTable[i].evnt.Description;
                    //stndMtgNotHeld = newStndActTable[i].evnt.Meeting_Not_Held__c;
                    stndMtgNotHeld = false;                                  
                    stndReasonCncl = newStndActTable[i].evnt.Reason_Canceled__c;                                    
                    stndClientSumm = newStndActTable[i].evnt.Client_Summary__c;
                    content += "<div class=\"StndDateDiv ui-field-contain\">"+
                       "<label for=\"DateField\">Date</label>"+
                       "<input class=\"DateField\" type=\"date\" value="+stndDate+"></input>"+
                       "<input class=\"TimeField\" type=\"time\" value="+stndTime+"></input>"+
                       "</div>";
                }
                else
                {   
                    stndDate = newStndActTable[i].javaDate;
                    stndSubj = newStndActTable[i].tsk.Subject;  
                    //stndDateCompl = newStndActTable[i].tsk.Date_Activity_Completed__c; //default = today
                    stndDateCompl = '';
                    stndDescrip = newStndActTable[i].tsk.Description;
                    //stndMtgNotHeld = newStndActTable[i].tsk.Meeting_Not_Held__c;
                    stndMtgNotHeld = false; 
                    stndReasonCncl = newStndActTable[i].tsk.Reason_Canceled__c;                                    
                    stndClientSumm = newStndActTable[i].tsk.Client_Summary__c;
                    content += "<div class=\"StndDateDiv\">Date<br/>"+
                       "<input class=\"DateField\" type=\"date\" value="+stndDate+"></input>"+
                       "</div>";
                }   
                    stndReasonCncl = '';
                    stndClientSumm = '';                                                        
                    content += "<div class=\"StndSubject ui-field-contain\">"+
                           "<label for=\"StndSubjField" + i + "\">Subject</label>"+
                           "<textarea class=\"StndSubjField\" id=\"StndSubjField" + i + "\">"+stndSubj+"</textarea>"+
                           "</div>"+
                        "<div class=\"StndCommentsDiv ui-field-contain\">"+
                           "<label for=\"StndCommentsField" + i + "\">Comments</label>"+
                           "<textarea class=\"StndCommentsField\" id=\"StndCommentsField" + i + "\" rows=\"" + numberOfActivities + "\">"+stndDescrip+"</textarea>"+
                           "</div>"+
                           "<div class=\"StndDateComplDiv ui-field-contain\">"+
                           "<label for=\"StndDateComplField" + i + "\">Date Activity Completed</label>"+
                           "<input class=\"StndDateComplField\" id=\"StndDateComplField" + i + "\" type=\"date\" value="+stndDateCompl+"></input>"+
                           "</div>"+
                        "<div class=\"StndClientSummDiv ui-field-contain\">"+
                           "<label for=\"StndClientSummField" + i + "\">Client Summary</label>"+
                           "<textarea class=\"StndClientSummField\" id=\"StndClientSummField" + i + "\">"+stndClientSumm+"</textarea>"+
                           "</div>"+
                           "<div class=\"StndMtgNotHeldDiv ui-field-contain\">"+
                           "<fieldset data-role=\"controlgroup\">"+
                               "<input type=\"checkbox\" id=\"StndMtgNotHeldField" + i + "\" name=\"StndMtgNotHeldField\" class=\"StndMtgNotHeldField\"" +
                               "value=\"" + stndMtgNotHeld + "\" />" +
                               "<label for=\"StndMtgNotHeldField" + i + "\">Meeting Not Held</label>" +
                           "</fieldset>"+
                           "</div>"+
                           "<div class=\"StndReasonCnclDiv ui-field-contain\">"+
                           "<label for=\"StndReasonCnclField" + i + "\">Reason Cancelled</label>"+
                           "<textarea class=\"StndReasonCnclField\" id=\"StndReasonCnclField" + i + "\">"+stndReasonCncl+"</textarea>"+
                           "</div>"+
                           "<div class=\"StndContact ui-field-contain\">"+
                           "<label for=\"StndCtctField" + i + "\">Contact</label>"+
                           "<textarea class=\"StndCtctField\" id=\"StndCtctField" + i + "\"></textarea>"+
                           "</div>"+
                           "<button type=\"button\" onclick=\"gotoAcctList(\'LOG_CONTROLLED\')\">Controlled Ownership Accounts</button>"+
                           "<button type=\"button\" onclick=\"gotoAcctList(\'LOG_CLIENTS\')\">My Client Base</button>"+
                           "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>"+
                       "</div>";                                                                                                        
                } // for
                jqnc( content ).appendTo( "#allRecs" ).enhanceWithin();
                jqnc(".StndMtgNotHeldField, .StndReasonCnclField, .StndDateComplField, .StndClientSummField").on( 'change', errorCheck );
                jqnc(".navIcons").show();
                //This method will activate the publish button so the form can be submitted 
                jqnc.mobile.loading("hide");
            } // else
              } // if(event.status)
          }); // invokeAction
          } // processHRGActivities
        
        function gotoAcctList(type){ //Show Controlled Ownership Accounts for the user to choose to save to
                acctListType = type;
                HRGActivitiesMobilePageController.AdditionalAccounts(accountId,type,
                    function(accountList, event){
                        if (event.status) {
                            if (event.type === "exception") {
                                console.log('got exception on remote action');
                            }
                            else {
                                acctList = accountList;
                                jqnc.mobile.loading("show");
                                jqnc("#acctList").empty();
                                jqnc("#allRecs").hide();
                                jqnc(".navIcons").hide();
                                jqnc(".saveButton").show();
                                var content = "<div><h1>"+accountName+"</h1>" +
                                        "<div class=\"selectAll\">" +
                                        "<fieldset data-role=\"controlgroup\">" +
                                        "<input type=\"checkbox\" id=\"selectAll\"/>" +
                                        "<label for=\"selectAll\">Select All</label>"+
                                        "</fieldset></div>";
                                if(acctList){
                                    for (var i=0, j=acctList.length; i<j; i++) {
                                        var acctLabel = acctList[i].acctName;
                                        if(acctList[i].acctNumber){
                                            acctLabel += " - " + acctList[i].acctNumber;    
                                        }
                                        content += "<div class=\"account\">" +
                                            "<fieldset data-role=\"controlgroup\">" +
                                            "<input type=\"checkbox\" class=\"acctCheckBox\" id=\"select-" + i + "\"/>" +
                                            "<label for=\"select-" + i + "\">" + acctLabel + "</label>"+
                                            "</fieldset></div>";
                                    }
                                }
                                else{
                                    content += "<p>There are no additional accounts to show.</p>";
                                }
                                content +=  "<div>" +
                                    "<button type=\"button\" onclick=\"gotoStdActivities()\">Return to Activities</button>" +
                                    "<button type=\"button\" onclick=\"gotoLanding()\">Back To Menu</button>" +
                                    "</div>" +
                                    "</div>";                                                                   
                                jqnc( content ).appendTo( "#acctList" ).enhanceWithin();
                                jqnc("#selectAll").on( "change", selectAll );
                                jqnc("#acctList").show();
                                jqnc("#main").show();
                                jqnc.mobile.loading("hide");
                            }
                        }
                }); 
        } // gotoAcctList
        
        function selectAll(event){ //Check All of the Account CheckBoxes
            jqnc.mobile.loading("show");
            jqnc(".acctCheckBox").prop("checked", jqnc(event.target).is(":checked")).checkboxradio("refresh");
            jqnc.mobile.loading("hide");
        }
          
        function goBack(){ //Go back to the account after saving
            // Success - close the page and refresh the feed.
            // sforce.one.navigateToSObject(accountId); 
            sforce.one.back(true);
        } // goBack
        
        function gotoStdActivities(){ //From AccountList, navigate back to StdActivities without clearing the checked accounts
            jqnc.mobile.loading("show");
            jqnc("#acctList").hide();
            jqnc(".saveButton").hide();
            jqnc(".navIcons").show();
            jqnc("#allRecs").show();
            jqnc.mobile.loading("hide");
        } // gotoStdActivities
        
        function processStndActivities(){ //Process the activities and return to account
          if(!isError){
              jqnc("#main").hide();
              jqnc.mobile.loading( 'show', {
                  text: "Saving Changes. It may take a few minutes for the changes to appear.",
                  textVisible: true,
                  theme: "b",
              });
              var okay = true;
              var extraAccounts = false;
              jqnc(".account").each(function(idx) {
                  if(jqnc(this).find("input:checkbox").is(':checked')){
                      acctList[idx].selected = true;
                      extraAccounts = true;
                  }
              }); // each
              jqnc(".rec").each(function(idx) {
                  if ( newStndActTable[idx].isEvent) {   //newStndActTable[idx].evnt.ActivityDate = jqnc(this).find("input.DateField").val();
                    newStndActTable[idx].javaDate = jqnc(this).find("input.DateField").val();
                    newStndActTable[idx].selectedTime = jqnc(this).find("input.TimeField").val();
                    newStndActTable[idx].evnt.Subject = jqnc(this).find("textarea.StndSubjField").val();
                    //newStndActTable[idx].evnt.Date_Activity_Completed__c = jqnc(this).find("input.StndDateComplField").val();
                    newStndActTable[idx].javaDateCompl = jqnc(this).find("input.StndDateComplField").val();
                    newStndActTable[idx].evnt.Description = jqnc(this).find("textarea.StndCommentsField").val();
                    if (jqnc(this).find("textarea.StndCtctField").val() != ''){   
                        newStndActTable[idx].evnt.Description = newStndActTable[idx].evnt.Description + ' Contact=' + jqnc(this).find("textarea.StndCtctField").val();       
                    }
                    if (jqnc(this).find("input.StndMtgNotHeldField").is(':checked')){   
                        newStndActTable[idx].evnt.Meeting_Not_Held__c = true; 
                    }
                    else
                    {   
                        newStndActTable[idx].evnt.Meeting_Not_Held__c = false;    
                    }
                    console.log('evnt Meeting Not Held='+newStndActTable[idx].evnt.Meeting_Not_Held__c);
                    newStndActTable[idx].evnt.Reason_Canceled__c = jqnc(this).find("textarea.StndReasonCnclField").val();
                    newStndActTable[idx].evnt.Client_Summary__c = jqnc(this).find("textarea.StndClientSummField").val();                     
                  }
                  else {
                    newStndActTable[idx].tsk.Subject = jqnc(this).find("textarea.StndSubjField").val(); 
                    //newStndActTable[idx].tsk.Date_Activity_Completed__c = jqnc(this).find("input.StndDateComplField").val();
                    newStndActTable[idx].javaDate = jqnc(this).find("input.DateField").val();
                    newStndActTable[idx].javaDateCompl = jqnc(this).find("input.StndDateComplField").val();
                    newStndActTable[idx].tsk.Description = jqnc(this).find("textarea.StndCommentsField").val();
                    if (jqnc(this).find("textarea.StndCtctField").val() != ''){   
                        newStndActTable[idx].tsk.Description = newStndActTable[idx].tsk.Description + ' Contact=' + jqnc(this).find("textarea.StndCtctField").val();     
                    }
                    if (jqnc(this).find("input.StndMtgNotHeldField").is(':checked')){   
                        newStndActTable[idx].tsk.Meeting_Not_Held__c = true;  
                    }
                    else
                    {   
                        newStndActTable[idx].tsk.Meeting_Not_Held__c = false; 
                    }
                    console.log('tsk Meeting Not Held='+newStndActTable[idx].tsk.Meeting_Not_Held__c);
                    newStndActTable[idx].tsk.Reason_Canceled__c = jqnc(this).find("textarea.StndReasonCnclField").val();
                    newStndActTable[idx].tsk.Client_Summary__c = jqnc(this).find("textarea.StndClientSummField").val();
                  }
              }); // each
              console.log('at processStndActivities, newStndActTable='+newStndActTable+' okay='+okay);
              //acctList,
              setTimeout(goBack, 10000)
              HRGActivitiesMobilePageController.processStndActivities(newStndActTable, accountId, acctList, extraAccounts, acctListType,
                  function(result, event){;
                  if(event.status){
                     if (event.type === 'exception'){
                         jqnc.mobile.loading("hide");
                         console.log('back from processStndActivities, exception='+event.type);
                     }
                     else {
                         console.log('back from processStndActivities, no exceptions');
                         // Success - close the page and refresh the feed.
                         jqnc.mobile.loading("hide");
                         goBack();
                     }
                  } // if(event.status)
               }); // invokeAction
               console.log('finished processStndActivities');
         }//if(!isError)     
         else{
            jqnc(".messages").show();   
        }
         } // processStndActivities
      
        function closePopUp(event){ // Close the warning popup
                jqnc(".messages").hide();   
                jqnc(".recMessage").hide();
            }
            
        function navHandler( event ){ // Slide between records with swipes or navigation buttons
            event.stopPropagation();
            var curr = jqnc(event.target);
            var slideLeft = false;
            var slideRight = false;
            if(event.type == "swipeleft" || curr.hasClass("ui-btn-icon-right")){
            slideLeft = true;
            }
            else if(event.type == "swiperight" || curr.hasClass("ui-btn-icon-left")){
            slideRight = true;    
            }
            if(curr.hasClass("ui-btn-icon-left") || curr.hasClass("ui-btn-icon-right") || 
            (!curr.hasClass("rec") && !curr.is(':focus'))){
            curr = curr.parents("body").find(".rec:visible");
            }
                if(jqnc(".rec").length > 1 && !isError && curr.hasClass("rec")){
                    curr.hide();
                    curr.removeClass("slideLeft slideRight slideDown");
                    if(slideLeft ){
                        if(curr.index() != jqnc("div.rec:last").index()){
                curr.next(".rec").addClass("slideLeft").show();
                setTimeout(300);
                        }
                        else{
                jqnc("div.rec:first").addClass("slideLeft").show();
                setTimeout(300);
                        }
                    }
                    else if(slideRight){
                        if(curr.index() != jqnc("div.rec:first").index()){
                curr.prev(".rec").addClass("slideRight").show();
                setTimeout(300);
                        }
                        else{
                jqnc("div.rec:last").addClass("slideRight").show();
                setTimeout(300);
                        }
                    }
                }
           else if(isError && curr.hasClass("rec")){
            jqnc(".messages").show();   
            }
            }
    
            function build_hrgTypes(){
                HRGActivitiesMobilePageController.gethrgTypes( 
                    function(newhrgTypes, event){
                    console.log('got types back-'+newhrgTypes);
                    if (event.status) {
                        if (event.type === "exception") {
                            console.log('got exception on remote action gethrgTypes');
                        }
                        else {
                            hrgTypes = newhrgTypes;
                            console.log('hrgTypes='+hrgTypes);
                        }
                    } // if(event
                    } // function
                ); // invokeAction gethrgTypes
            }
            
            function build_hrgActivityTypes(){
                  HRGActivitiesMobilePageController.gethrgActivityTypes( 
                        function(newhrgActivityTypes, event){
                            console.log('got activity types back-'+newhrgActivityTypes);
                            if (event.status) {
                                if (event.type === "exception") {
                                    console.log('got exception on remote action gethrgActivityTypes');
                                }
                                else {
                                    hrgActivityTypes = newhrgActivityTypes;
                                }
                            } // if(event
                        } // function
                   ); // invokeAction gethrgActivityTypes
             } // build_hrgActivityTypes
             
             
        function build_hrgActivities(){ //Populate the Dropdown Lists
                  HRGActivitiesMobilePageController.gethrgActivities( 
                        function(newhrgActivities, event){
                            console.log('got activities back-'+newhrgActivities);
                            if (event.status) {
                                if (event.type === "exception") {
                                    console.log('got exception on remote action gethrgActivityTypes');
                                }
                                else {
                                    hrgActivities = newhrgActivities;
                                    ready = true;
                                    jqnc.mobile.loading("hide");
                                }
                            } // if(event
                        } // function
                   ); // invokeAction gethrgActivities
             } // build_hrgActivityTypes
             
            function updateActivityOpts( event ){ //Populate the Dropdown Lists
                console.log("Activity Type Changed");
                var curr = jqnc(event.target);
                var actField = jqnc(event.target).parents(".rec").find("select.ActivityField");
                var actTypeVal = jqnc(event.target).val();
                console.log(actTypeVal);
                var actOpts = "<option value=\"\">Select Activity</option>";
                for (var i=0, j=hrgActivities[actTypeVal].length; i<j; i++) {
                    actOpts += "<option value=\"" +hrgActivities[actTypeVal][i]+ "\">" + hrgActivities[actTypeVal][i] + "</option>";   
                }       
                actField.empty();
                actField.append(actOpts).enhanceWithin();
            actField.prop('selectedIndex',0);
            // Initialize the selectmenu
            actField.selectmenu();
    
            // jQM refresh
            actField.selectmenu("refresh", true);
             }; // updateActivityOpts
             
        function errorCheck(event){ //Check for fields that need to be completed based on other field values
                var curr = jqnc(event.target);
                var mtgMsg = "<h4 class=\"mtgMsg\">You must enter a Reason Canceled if you check Meeting Not Held.</h4>";
                var dateMsg = "<h4 class=\"dateMsg\">You must enter a Client Summary if Date Completed is set.</h4>";
                var picklistMsg = "<h4 class=\"picklistMsg\">You must select a value in all 3 picklists to proceed.</h4>";
                var healthReasonMsg = "<h4 class=\"healthReasonMsg\">You must add a reason for the change in client health.</h4>";
                if(curr.hasClass('StndMtgNotHeldField') || curr.hasClass('StndReasonCnclField')){
                    if((curr.hasClass('StndMtgNotHeldField') && 
                        curr.is(':checked') && 
                        !curr.parents(".rec").find(".StndReasonCnclField").val()) ||
                        (curr.hasClass('StndReasonCnclField') &&
                        !curr.val() &&
                        curr.parents(".rec").find(".StndMtgNotHeldField").is(':checked'))){
                        if(!mtgError){
                            isError=true;
                            mtgError=true;
                            curr.parents(".rec").find(".StndReasonCnclDiv").addClass("errorBox");
                            curr.parents(".rec").find(".StndMtgNotHeldDiv").addClass("errorBox");
                            jqnc(".messages").append(mtgMsg);
                            //jqnc(".messages").show();
                        }
                    }
                    else{
                        mtgError=false;
                        curr.parents(".rec").find(".StndReasonCnclDiv").removeClass("errorBox");
                        curr.parents(".rec").find(".StndMtgNotHeldDiv").removeClass("errorBox");
                        jqnc(".mtgMsg").remove();
                    }
                }
                else if(curr.hasClass('StndDateComplField') || curr.hasClass('StndClientSummField')){
                    if((curr.hasClass('StndDateComplField') && 
                        curr.val() && 
                        !curr.parents(".rec").find(".StndClientSummField").val()) ||
                        (curr.hasClass('StndClientSummField') &&
                        !curr.val() &&
                        curr.parents(".rec").find(".StndDateComplField").val())){
                        if(!dateError){
                            isError=true;
                            dateError=true;
                            curr.parents(".rec").find(".StndDateComplDiv").addClass("errorBox");
                            curr.parents(".rec").find(".StndClientSummDiv").addClass("errorBox");
                            jqnc(".messages").append(dateMsg);
                            //jqnc(".messages").show();
                        }
                    }
                    else{
                        dateError=false;
                        curr.parents(".rec").find(".StndDateComplDiv").removeClass("errorBox");
                        curr.parents(".rec").find(".StndClientSummDiv").removeClass("errorBox");
                        jqnc(".dateMsg").remove();
                    }
                }
                else if (curr.hasClass('TypeField') || curr.hasClass('ActivityTypeField') || curr.hasClass('ActivityField')) {
                    var typeF = curr.parents(".rec").find("select.TypeField").prop('selectedIndex');
                    var actTypeF = curr.parents(".rec").find("select.ActivityTypeField").prop('selectedIndex');
                    var actF = curr.parents(".rec").find("select.ActivityField").prop('selectedIndex');
                    if((typeF == 0 || actTypeF == 0  || actF == 0 ) && (typeF != 0 || actTypeF != 0  || actF != 0)) {                   
                            if(!picklistError){
                                isError=true;
                                picklistError=true;
                                jqnc(".messages").append(picklistMsg);
                                //jqnc(".messages").show();
                            }
                    }           
                    else{
                            picklistError=false;
                            jqnc(".picklistMsg").remove();
                    }
                }
                else if(curr.hasClass('newHealthField')||curr.hasClass('healthReasonField')){
                    if((curr.hasClass('newHealthField') 
                        && curr.val() 
                        && curr.val() != curr.parents("#allRecs").find(".currHealthField").text() 
                        && !curr.parents("#allRecs").find(".healthReasonField").val()) 
                       ||
                        (curr.hasClass('healthReasonField') 
                        && !curr.val() 
                        && curr.parents("#allRecs").find(".newHealthField").val() 
                        && curr.parents("#allRecs").find(".newHealthField").val() != curr.parents("#allRecs").find(".currHealthField").text())){
                        if(!picklistError){
                            isError=true;
                            picklistError=true;
                            curr.parents("#allRecs").find(".healthReasonDiv").addClass("errorBox");
                            jqnc(".messages").append(healthReasonMsg);
                            //jqnc(".messages").show();
                        }
                    }
                    else{
                        picklistError=false;
                        curr.parents("#allRecs").find(".healthReasonDiv").removeClass("errorBox");
                        jqnc(".healthReasonMsg").remove();
                    }
                }
                if(!dateError && !mtgError && !picklistError){
                    isError=false;
                    jqnc(".messages").empty;
                    jqnc(".messages").hide();
                }               
             }; //errorCheck
        
                
        function formatDate(unformatted){
            var formattedDate = "";
            if(unformatted){
                formattedDate = new Date(unformatted).toISOString().substring(5, 7);
                formattedDate += "/" + new Date(unformatted).toISOString().substring(8, 10);
                formattedDate += "/" + new Date(unformatted).toISOString().substring(0, 4);
            }
            return formattedDate;
        } // formatDate (mm/dd/yyyy)