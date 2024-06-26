({
    validateForm : function(component, helper) {
        component.set("v.loadSpinner", true);
        var fieldName = null;
        var multi = component.find("multi").get("v.value");
        var paperwork = component.find("paperwork").get("v.value");
        var returning = component.find("returning").get("v.value");
        var dataExtraction = component.find("dataExtraction").get("v.value");
        var fedIdValue = component.find("fedId").get("v.value");
        //var ssn = component.find("enteredssn").get("v.value");
        var fedIsSSN = component.get("v.fedIdIsSSN");
        var hasSignedQuote = component.get("v.hasSignedQuote");
        var quoteName = component.get("v.quoteUploadName");
        var certificateName = component.get("v.certUploadName");
        var quoteId = component.get("v.quoteId");
        var certificateId = component.get("v.certificateId");
        var signedQuoteFound = hasSignedQuote || ((quoteId != null && quoteId != '') && (certificateId != null && certificateId != '')) ? true : false;
        var duplicateAttachments = !hasSignedQuote && quoteId != null && (quoteId == certificateId) ? true : false;
        var ssn;// = component.find("enteredssn").get("v.value");
        var disableButton = multi !='No' 
        || paperwork !='No' 
        || returning !='No'
        || !signedQuoteFound
        || duplicateAttachments
        || fedIdValue ==null
        || fedIdValue ==''
        || dataExtraction =='Please select' ? true : false;
        component.set("v.matchingAttachments",duplicateAttachments);
        if(multi=='Yes'){
            fieldName = fieldName == null ? "Is this part of a Multi ID (Affiliated ID’s) ":fieldName+", and Is this part of a Multi ID (Affiliated ID’s) ";
            component.set("v.isMulti",true);
        }
        if(paperwork=='Yes'){
            fieldName = fieldName == null ? "Does this client require Non-English (Spanish, etc) set up paperwork? ":fieldName+", and Does this client require Non-English (Spanish, etc) set up paperwork? ";
            component.set("v.needsNonEngPpwrk",true);
        }
        if(returning=='Yes'){
            fieldName = fieldName == null ? "Is this a returning Lost Client? ":fieldName+", and Is this a returning Lost Client?  ";
            component.set("v.isReturning",true);
        }
        /*if(dataExtraction=='Yes'){
            fieldName += "Is a Data Extraction needed? ";
        }*/
        if(fieldName!=null){
            component.set("v.knockoutFields",fieldName);
        }else{
            component.set("v.knockoutFields",null);
        }
        if(dataExtraction=='Yes'){
            component.set("v.showDataExtractMessage", true);
        }else{
            component.set("v.showDataExtractMessage", false);
        }
        if(disableButton){
            
            component.set("v.buttonDisabled", true);
            component.set("v.updateOppty",true);
        }
        else{
            component.set("v.buttonDisabled", false);
            component.set("v.updateOppty",false);
        }
        ssn = fedIsSSN ? component.get("v.enteredssn"): null;
        var action = component.get('c.updateCSO');
        action.setParams(
            {
                "cso":component.get("v.csoTrackingRec"),
                "ssn":ssn,
                "isssn":fedIsSSN,
                "multiId":multi,
                "paperwork":paperwork,
                "client":returning,
                "extraction":dataExtraction
            })
        action.setCallback(this, function(response){  
            component.set("v.loadSpinner", false);
            console.log('response->'+response);
            var name = response.getState();
            if (name === "SUCCESS") {
               var res = response.getReturnValue();
               if (res.statusCode != 200) {
                    var showToast = $A.get("e.force:showToast");
                    showToast.setParams({ 
                        'mode' : 'sticky',
                        'title' : 'Confirmation', 
                        'type' : 'error',
                        'message' : 'An unexpected error has occurred.\n Details: '+res.message
                    });
                   showToast.fire();
 
               }
            }
        });
        $A.enqueueAction(action);
    },
    uploadHelper: function(component, event, helper) {
        component.set("v.showLoadingSpinner", true);
        var MAX_FILE_SIZE= 4500000;
        var fileInput = component.find("fileId").get("v.files");
        var file = fileInput[0]; 
        component.set("v.file", file);
        if (file.size > MAX_FILE_SIZE) {
            component.set("v.showLoadingSpinner", false);
            component.set("v.fileName", 'Alert : File size cannot exceed ' + MAX_FILE_SIZE + ' bytes.\n' + ' Selected file size: ' + file.size);
            return;
        }
        
        var objFileReader = new FileReader();
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            
            component.set("v.dataStart", dataStart);
            component.set("v.base64", base64);
            component.set("v.fileContents", fileContents.substring(dataStart));
            fileContents = fileContents.substring(dataStart);
        });
        
        objFileReader.readAsDataURL(file);
    },
    uploadCertHelper: function(component, event, helper) {
        component.set("v.showLoadingSpinner", true);
        var MAX_FILE_SIZE= 4500000;
        var fileInput = component.find("certId").get("v.files");
        var file = fileInput[0]; 
        component.set("v.certfile", file);
        if (file.size > MAX_FILE_SIZE) {
            component.set("v.showLoadingSpinner", false);
            component.set("v.fileName", 'Alert : File size cannot exceed ' + MAX_FILE_SIZE + ' bytes.\n' + ' Selected file size: ' + file.size);
            return;
        }
        
        var objFileReader = new FileReader();
        objFileReader.onload = $A.getCallback(function() {
            var fileContents = objFileReader.result;
            var base64 = 'base64,';
            var dataStart = fileContents.indexOf(base64) + base64.length;
            
            component.set("v.certdataStart", dataStart);
            component.set("v.base64", base64);
            component.set("v.certfileContents", fileContents.substring(dataStart));
            fileContents = fileContents.substring(dataStart);
        });
        
        objFileReader.readAsDataURL(file);
    },
    uploadProcess: function(component, event, helper) {
        component.set("v.loadSpinner", true);
        var startPosition = 0;
        var CHUNK_SIZE = 750000;
        var file = component.get("v.file");
        var quoteName= component.get("v.quoteName");
        var certName = component.get("v.certificateName");
        var fileContents = component.get("v.fileContents");
        var endPosition = Math.min(fileContents.length, startPosition + CHUNK_SIZE);
        var getchunk = fileContents.substring(startPosition, endPosition);
        var certfile = component.get("v.certfile");
        var certfileContents = component.get("v.certfileContents");
        var endPosition = Math.min(certfileContents.length, startPosition + CHUNK_SIZE);
        var getCertchunk = certfileContents.substring(startPosition, endPosition);
        var action = component.get("c.saveQuoteAttachment");
        var action2 = component.get("c.saveQuoteAttachment");
        var recid = component.get("v.opportunityObj.Id");
        if(file.name == certfile.name){
            var showToast = $A.get("e.force:showToast");
            showToast.setParams({ 
                'title' : 'Duplicate file upload', 
                'type' : 'error',
                'message' : 'The uploaded Quote and Certificate files cannot have the same name, please update attachments'
            });
            showToast.fire();
            component.set("v.loadSpinner", false);
            component.set("v.quoteName", null);
            component.set("v.certificateName", null);
        }else{
                    action.setParams({
            recordId: recid,
            cso:component.get("v.csoTrackingRec"),
            attachType:'Quote',
            fileName: file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type,
        });
        action.setCallback(this, function(response) {
            var attachId = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                //this.validateForm(component, helper);
                //alert("The signed quote has successfully been uploaded"); 
                component.set("v.quoteId", attachId);
                component.set("v.quoteUploadName", component.get("v.quoteName"));
            }
        });
        $A.enqueueAction(action);
        action2.setParams({
            recordId: recid,
            cso:component.get("v.csoTrackingRec"),
            attachType:'Certificate',
            fileName: certfile.name,
            base64Data: encodeURIComponent(getCertchunk),
            contentType: certfile.type,
        });
        action2.setCallback(this, function(response) {
            var attachId = response.getReturnValue();
            var state = response.getState();
            if (state === "SUCCESS") {
                alert("The files have successfully been uploaded"); 
                component.set("v.certificateId", attachId);
                component.set("v.certUploadName", component.get("v.certificateName"));
                //Validate the rest of the form
                var multi = component.find("multi").get("v.value");
                var paperwork = component.find("paperwork").get("v.value");
                var returning = component.find("returning").get("v.value");
                var dataExtraction = component.find("dataExtraction").get("v.value");
                var fedIdValue = component.find("fedId").get("v.value");
                var disableButton = multi !='No' 
                || paperwork !='No' 
                || returning !='No'
                || fedIdValue ==null
                || fedIdValue ==''
                || dataExtraction =='Please select' ? true : false;
                component.set("v.buttonDisabled", disableButton);
                component.set("v.loadSpinner", false);
            }
        });
        $A.enqueueAction(action2);
        }
        
    },
    uploadCertProcess: function(component, event, helper) {
        
        var startPosition = 0;
        var CHUNK_SIZE = 750000;
        var MAX_FILE_SIZE= 4500000;
        var file = component.get("v.file");
        var fileContents = component.get("v.fileContents");
        var endPosition = Math.min(fileContents.length, startPosition + CHUNK_SIZE);
        var getchunk = fileContents.substring(startPosition, endPosition);
        var action = component.get("c.saveQuoteAttachment");
        var recid = component.get("v.opportunityObj.Id");
        
        action.setParams({
            recordId: recid,
            cso:component.get("v.csoTrackingRec"),
            attachType:'Quote',
            fileName: file.name,
            base64Data: encodeURIComponent(getchunk),
            contentType: file.type,
        });
        
        $A.enqueueAction(action);
    },
})