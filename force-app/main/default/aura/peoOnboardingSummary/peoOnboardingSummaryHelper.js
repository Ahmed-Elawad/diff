({
    /****************************
     * DATA RETRIEVAL SECTION
     ****************************/
    // get the PEO Onboarding Checklist
    // If the current prospect is a parent then set the peoChecklist
    // attribute to be the provided parentChecklist attribute and resolve
    // otherwise send the server call to get the checklist and append it to
    // the component
    // On success resolve true on failure reject with the error msg
    getChecklist: function(cmp, e) {
        return new Promise(function(resolve, reject) {
            if (cmp.get('v.isParent') || cmp.get('v.isClientAddOn')) {
                cmp.set('v.peoChecklist', cmp.get('v.parentChecklist'));
                resolve(true);
                return;
            }
            let getCklst = cmp.get('c.getPEOOnboardingChecklist');
            
            getCklst.setParams({
                accountId: cmp.get('v.recordId'),
                formName: 'PeoOnboardingSummaryhelper.js'
            });
            getCklst.setCallback(this, function(res) {
              //  console.log('Checklist returned');
                if (res.getState() !== 'SUCCESS') {
                    console.log(res.getError());
                    reject({t:'Error',
                            m: cmp.get('v.errMsg'),
                            ty: 'error', 
                            brk: true
                           });
                }
                
                cmp.set('v.peoChecklist', res.getReturnValue());
                //console.log('Resolving getChecklist')
                resolve(true);
            })
            $A.enqueueAction(getCklst);
        });  
    },
    // get the medical questionnare form
    // if medical underwriting is not requested resolve true
    // otherwise send the apex call to get the medical questionnaire
    // and set it to the medicalQuestionnaire attribute on the component
    // On success resolve true otherwise reject with the error message
    getMedical: function(cmp, e) {
        return new Promise(function(resolve, reject) {
            if (cmp.get('v.peoChecklist.Medical_Benefits_Underwriting_Requested__c') != 'Yes') {
              //  console.log('Resolving getMedical')
                resolve(true);
            } else {
                let getCklst = cmp.get('c.getMedicalQuestionnaireForm');            
                getCklst.setParams({
                    peoOnboardingChecklistId: cmp.get('v.peoChecklist.Id'),
                    formName: 'PeoOnboardingSummary.cmp'
                });
                getCklst.setCallback(this, function(res) {
                  //  console.log('Medical Checklsit returned');
                    if (res.getState() !== 'SUCCESS') {
                        console.log(res.getError());
                        reject({t:'Error',
                                m: cmp.get('v.errMsg'),
                                ty: 'error', 
                                brk: true
                               });
                    }
                    cmp.set('v.medicalQuestionnaire', res.getReturnValue());
                    
                  //  console.log('Resolving getMedical')
                    resolve(true);
                })
                $A.enqueueAction(getCklst);
            }
        });  
    },
    // get the industry specific questionnaire for the current prospect
    // Set the return on the component
    // Method has no return value
    /*getIndustry: function(component, e, helper) {
        let getIndsutryDetails = component.get('c.getIndustryStatus');
        getIndsutryDetails.setParams({
            PEOchecklist: component.get('v.parentChecklist').Id
        })
        getIndsutryDetails.setCallback(this, function(res) {
            //debugger;
            if (res.getState() !== 'SUCCESS') {
                console.log(res.getError());
                console.log('Could not retrieve Industry information');  
            }
            component.set('v.industrySpecificStatus', res.getReturnValue());
            console.log('Industry details:'+component.get('v.industrySpecificStatus'));
        })
        $A.enqueueAction(getIndsutryDetails);  
        
    },*/
    // based on the answers provided on the checklist of the current tab determine the list of
    // documents that are required for this prospect
    getDocs: function(cmp, e) {
        // get the documents
        // set them on the doc summary table
        return new Promise(function(resolve, reject) {
            let getDocAct = cmp.get('c.getAllPeoDocs'); // Server method sig
            let checklistIds = {}; // Used to store the checklist IDs for later reference
            // A map storing the doc names: routing name for the docs required for
            // this prospect. 
            let docNames = {
                'Payroll Register': 'Payroll Register',
                'Misc Files - Medical': 'Misc Files - Medical',
                "Misc Files - Workers' Comp": "Misc Files - Workers' Comp",
                "Additional Misc Documents":"Additional Misc Documents"
                //'Other': 'Other'
                //'HSF Census':'HSF Census' //SFDC-16848
            };
          //  console.log('Getting docs')
            //Added by Jidesh:Start - Update the list of docnames to include the document if it's required for this prospect
            if(cmp.get('v.censusRequired') === true)docNames['Census'] = 'Census';
            if(cmp.get('v.claimsReportRequired') === true)docNames['Claims Report'] = 'Claims Information';
            if(cmp.get('v.hlthInsRenwReqd') === true)docNames['Health Insurance Renewal'] = 'Health Insurance Renewal';
            if(cmp.get('v.hlthInsSummReqd') === true)docNames['Health Insurance Summary'] = 'Health Insurance Summary';
            if(cmp.get('v.hlthInvReqd') === true)docNames['Health Invoice'] = 'Health Invoice';
            if(cmp.get('v.lossRunsReqd') === true)docNames['Loss Runs'] = 'WC Loss Runs';
            if(cmp.get('v.suiReqd') === true)docNames['SUI Rate Forms'] = 'SUI Rate Forms';
            if(cmp.get('v.wcDecReqd') === true)docNames['WC Declarations Page/PEO Current Rate'] = 'WC Declarations Page';
            if(cmp.get('v.wcClsAndWgReqd') === true)docNames['WC Classes and Wages'] = 'WC Classes and Wages';
            if(cmp.get('v.wcRtNPrcReqd') === true){docNames['WC Rates and Pricing'] = 'WC Rates and Pricing';}
            if(cmp.get('v.payrollRegReqd') === true)docNames['Payroll Register'] = 'Payroll Register';
            if(cmp.get('v.medicalinvoicereq') === true)docNames['Medical Invoice'] = 'Medical Invoice';
            if(cmp.get('v.BenSummaryreq') === true)docNames['Benefit Summary'] = 'Benefit Summary';
            if(cmp.get('v.miscfilesmedreq') === true)docNames['Misc Files - Medical'] = 'Misc Files - Medical';
            if(cmp.get('v.miscfilesWCreq') === true)docNames['Misc Files - Workers\' Comp'] = 'Misc Files - Workers\' Comp';
            if(cmp.get('v.AddMiscFilesreq') === true)docNames['Additional Misc Documents'] = 'Additional Misc Documents';
            //End
            
            // set the paramaters of the apex action call. Doc names is the list of docs required
            // account ID is the account ID of the current tab, and checkListId is the checklist.
            // Method creates docs if they don't exist populating the checklist lookup
            getDocAct.setParams({checkListId: cmp.get('v.peoChecklist').Id,
                                 docNameSettingMap: docNames, 
                                 accountId: cmp.get('v.Account.Id'),
                                 formName: 'PeoOnboardingSummary.cmp'
                                });
          //  console.log('Set params for doc')
            // ASNYC callback
            getDocAct.setCallback(this, function(res) {
               // console.log('in callback of doc get')
                // brief err handling. Throw msg
                if (res.getState() !== 'SUCCESS') {
                    console.log(res.getError());
                    reject({
                        t: 'Error',
                        m: cmp.get('v.errMsg'),
                        ty: 'error',
                        brk: true
                    }); // REJECT call throws msg obj to errr handler. Err handler deals with msg & other stuff
                }
                
                let numberOfApprovedDocs = 0, // Num to track docs with status of Approved or submitted to CS
                    status = {}, // stores the status of the document. Later used by summary msg cmp
                    allDocInfoMap = {}, // reference obj storing doc data - key value pair is docName: Id
                    allIds = [];
                
                let CLDocumentList={};
                
                // iterate all of the documents in the return array, no return value.
                res.getReturnValue().forEach(function(doc) {
                    // set the document name as a joined string. 
                    // EX: if the document name is WC Declarations Page/PEO Current Rate set
                    // the docName var to WCDeclarationsPagePEOCurrentRate
                    let docName;
                    docName = doc.Name.split(' ').join('');
                    docName = docName.replace(/\W/g, '');
                    console.log('getDocs DocName:'+docName);
                    // increment the numOfApprovedDoc flag if the status is a approved like status
                    if (doc.Status__c == 'Approved' || doc.Status__c == 'Submitted to Clientspace' || doc.Status__c == 'Send to Clientspace Failed') numberOfApprovedDocs+= 1;
                    
                    // Set the documents name on the infoMap for later ref
                    // { WCDeclarationsPagePEOCurrentRate: xxxxxxxxx5654(Rec Id)} 
                    if (!allDocInfoMap[docName]) allDocInfoMap[docName] =doc.Id;
                    else allDocInfoMap[docName] = doc.Id;
                    
                    // dynamically sets the document ID onto the component
                    // attribute names are already prebuilt. This takes the formated docName
                    // appends 'Id' to the end and sets it as the currect doc rec ID value.
                    // EX: WCDeclarationsPagePEOCurrentRateId = xxxxxxxxx5654
                    cmp.set(`v.${docName}Id`, doc.Id);
                    allIds.push(doc.Id);
                    
                    // this section dynamically sets the status of the document on the status
                    // obj. IF the current is a portal user set the status using the Portal_Status__c
                    // otherwise set the status as needed if it's blank or whatever value is already 
                    // on the record
                    if (cmp.get('v.commUser')) {
                        status[docName] = doc.Portal_Status__c;                           
                    } else {
                        status[docName] = !doc.Status__c ? doc.PEO_Doc_Required__c : doc.Status__c;   
                        CLDocumentList[docName]=doc.PEO_Doc_Required__c;
                    }
                    
                })
                // set the mapped obj on the component: EX - { WCDeclarationsPagePEOCurrentRate: xxxxxxxxx5654(Rec Id)} 
                cmp.set('v.docNamesAndIds', allDocInfoMap);
                // get a percentage value rounded up of the number of approved docs / number of required docs
                cmp.set('v.statuss', status); // set the stuses on the cmp
                console.log('statuss:', status);
                 console.log('CLDocumentList:', CLDocumentList);
                cmp.set('v.CLDocumentList', CLDocumentList);
                cmp.set('v.documentList', res.getReturnValue()); // set the full array list on the cmp
                
                // handle adding the checklist IDs to retrieve needed discrepancies
                // if medical is needed add the medical questionnaire doc ID to the checklist
                // add the checklist ID to the list of checklist ids
                if (cmp.get('v.medBenUnderwritingRequested') && cmp.get('v.medicalQuestionnaire') != undefined) checklistIds['Medical'] = cmp.get('v.medicalQuestionnaire').Id;
                checklistIds['Checklist'] = cmp.get('v.peoChecklist').Id;
                // this may be useless. Verify if using v.docNamesAndIds or v.docMap
                cmp.set('v.docMap', allDocInfoMap);
                let docNames = Object.keys(allDocInfoMap);
            //    console.log('allDocNames'+docNames);
                resolve({docnames: docNames, docIds: allIds, allDocInfoMap: allDocInfoMap, checklsits: checklistIds});
            })
            $A.enqueueAction(getDocAct);
        })
    },
    /**
     * Params: cmp{component}, DocData{ docNames: Array[String], docIds: Array[Ids], allDocInfoMap: Object{String(docName): string(docId)}}
	 * Returns: Promise
	 * 		Resolves: true if the discrepencies are retrieved and set on the cmp
	 * 		Rejects: with error obj containing msg
	 */
    getDiscrepencies: function(cmp, docData) {
        // return the promise
        return new Promise(function(resolve, reject) {
            let getDiscrepencies = cmp.get('c.getDiscrepancies');    
            getDiscrepencies.setParams({
                docList: docData.docIds,
                checklistIds: docData.checklsits
            });
            
            getDiscrepencies.setCallback(this, function(res) {
                if (res.getState() !== 'SUCCESS') {
                 //   console.log(res.getError());
                    reject({
                        t: 'Error',
                        m: 'Failed to retrieve discrepancy information for documents',
                        ty: 'error',
                        brk: true
                    });
                }
                // traverse the list of returned discrepencies and return an object of key: array mappings
                // Key = document name, array is an array of the discrepencies for the document
                // creates a map of sorted disrepencies
                // handle document discrepancies the same as checklist discrep
                // { docName: [discrepency1, ...] }
                
                let data = res.getReturnValue();
                let chlstDisc;
                let medicalDiscs;
                let docDisc;
                
                let returnExistis = res.getReturnValue() !== undefined;
                if (returnExistis && res.getReturnValue().checklist !== null) 
                    	chlstDisc = res.getReturnValue().checklist;
           
                if (returnExistis && res.getReturnValue().docDiscrepancies) 
                    	docDisc = res.getReturnValue().docDiscrepancies;
                if (returnExistis && res.getReturnValue().Medical) 
                    	medicalDiscs = res.getReturnValue().Medical;
                
                console.log('doc Disc:'+ JSON.stringify(docDisc));                
                console.log('medical Disc:'+ JSON.stringify(medicalDiscs));
                console.log('chlst Disc:'+JSON.stringify(chlstDisc));
           
                let sortedDiscrepencies =  !docDisc ? null : docDisc.reduce(function(map, disc) {
                    let matchedName;
                    for (let i = 0; i < docData.docnames.length; i++) {
                        // docname = document name ex: census.
                        // clientDocId = doc id ex: a100q000001LdnxAAC
                        // used to match and verify that the discrepency is for the found document
                        // ex: Doc to match = census ID = a100q000001LdnxAAC
                        // found discrepency: PEO_Onboarding_Document__c lookup = a100q000001LdnxAAC: enters condition
                        let docName = docData.docnames[i];
                        let clientDocId;
                    //    console.table(docData.allDocInfoMap);
                        clientDocId = docData.allDocInfoMap[docName];
                    //    console.log('docName:'+docName+' clientDocID:'+clientDocId+ ' disc.PEO_Onboarding_Document__c:'+disc.PEO_Onboarding_Document__c);
                        // if the provided doc ID matches the doc ID on the discrepancy
                        // verify the discrepency status is closed to increment the approved docs
                        if ( clientDocId ===disc.PEO_Onboarding_Document__c){
                            matchedName = docName;
                            break;
                        }
                    } 
                    if (map[matchedName]) map[matchedName].push(disc);
                    else map[matchedName] = [disc];   
                    return map;
                }, {});
                
                // stores the checklist(form) discrepancies
                let sortedChecklistDiscs;
                if (chlstDisc !== undefined) {
                    sortedChecklistDiscs = chlstDisc.reduce(function(resMap, disc) {
                        // sort the discrepancies into their respective places
                        let discName = disc.Discrepancy_Type__c.split(' ').join('');
                       // console.log('ln 285 discName:'+discName);
                        if (discName[0] === '4') discName = 'd' + discName;
                        if (!resMap[discName]) resMap[discName] = [disc];
                        else resMap[discName].push(disc);
                        return resMap;
                    }, {});
                }
                console.table(chlstDisc);
                // traverse the sorted discrepencies
                // set the value of the matched attribute on the component to the list of discrepencies
                let TotalDiscrepencies = 0; //Added by Bharat to get total discrepencies count 
                if (medicalDiscs != undefined && cmp.get('v.medBenUnderwritingRequested')) {
                    cmp.set('v.MedicalQuestionnaireDiscrepencies', medicalDiscs);
                    TotalDiscrepencies = TotalDiscrepencies +  medicalDiscs.length;
                }
                
                var medStatus = cmp.get('v.parentChecklist.Peo_Medical_formStatus__c');
                cmp.set('v.MedicalQuestionnaireStatus',  medicalDiscs !== undefined && medicalDiscs.length ? ( cmp.get('v.commUser') ? 'Attention Needed' : 'Discrepancy') :medStatus);
                console.log('sortedDiscrepencies:',sortedDiscrepencies);
                for (let name in sortedDiscrepencies) {
                    console.log('Name:'+name);
                   
                    
                    cmp.set(`v.${name}Discrepencies`, sortedDiscrepencies[name]);
                    //Added by Bharat to get total discrepencies count
                  //  console.log('commUser:'+cmp.get('v.commUser'));
                    //console.log('WC Rnp descrs:'+cmp.get('v.WCRatesandPricingDiscrepencies'));
                    if(cmp.get('v.commUser') === true){
                        if(name != 'WCClassesandWages'){
                            TotalDiscrepencies = TotalDiscrepencies +  sortedDiscrepencies[name].length;
                        }
                    }
                    else{
                        TotalDiscrepencies = TotalDiscrepencies +  sortedDiscrepencies[name].length;
                    }
                    
                }
                const Account = cmp.get('v.Account');
                let isChild = !!cmp.get('v.Account.SalesParent__c');
                let isSingleId = !cmp.get('v.Account.isParent__c') && !cmp.get('v.Account.SalesParent__c');
                let isParent = cmp.get('v.Account.isParent__c');
                let isClientAddOn = !isParent && isChild && cmp.get('v.isClientAddOn');
                if (chlstDisc !== undefined && (isParent || isSingleId || isClientAddOn)) {
                    for (let name in sortedChecklistDiscs) {
                        console.log('ln 325 - Desc details:'+sortedChecklistDiscs[name]);
                        console.log('ln 326 Name:'+name);
                        
                        if(name == 'HealthInsuranceSummaryofBenefits/PlanDesigns'){
                             cmp.set(`v.${'BenefitSummary'}Discrepencies`, sortedChecklistDiscs[name]);                            
                            //cmp.set(`v.${'HealthInsuranceSummary'}Discrepencies`, sortedChecklistDiscs[name]);
                        }else if(name == 'HealthInvoice/PEOMedicalBillingReport'){
                            //cmp.set(`v.${'HealthInvoice'}Discrepencies`, sortedChecklistDiscs[name]);
                            cmp.set('v.MedicalInvoiceDiscrepencies', sortedChecklistDiscs[name]); 
                            
                        }else if(name == 'SUI'){
                            cmp.set('v.SUIRateFormsDiscrepencies', sortedChecklistDiscs[name]);
                        }else if(name == 'ClaimsInformation'){
                            cmp.set('v.ClaimsReportDiscrepencies', sortedChecklistDiscs[name]);
                        }else if(name == 'MiscFiles-Medical'){
                            cmp.set('v.MiscFilesMedicalDiscrepencies', sortedChecklistDiscs[name]);
                        }
                        //debugger;
                        cmp.set(`v.${name}Discrepencies`, sortedChecklistDiscs[name]);
                        console.log(name+'Discrepencies:' , cmp.get(`v.${name}Discrepencies`));
                        //Added by Bharat to get total discrepencies count
                        if (sortedChecklistDiscs[name].length){
                            cmp.set(`v.${name}Status`, cmp.get('v.commUser') ? 'Attention Needed' : 'Discrepancy');
                        }
                        TotalDiscrepencies = TotalDiscrepencies +  sortedChecklistDiscs[name].length;
                        console.log(`v.${name}Status`+':'+cmp.get('v.OtherStatus'));
                        // console.log(cmp.get(`v.${name}Status`));
                    }
                }
                //Added by Bharat to get total discrepencies count
                cmp.set("v.TotalDiscrepencies",TotalDiscrepencies);
                
                // this sets the form status attributes on the component
                // If any are left blank/undefined then there will be no status showing
                var form401Status = cmp.get('v.parentChecklist.Peo_401k_formStatus__c');
                var EPLIStatus = cmp.get('v.parentChecklist.Peo_EPLI_formStatus__c');
                var WCStatus = cmp.get('v.parentChecklist.Peo_WC_formStatus__c');
                var IndSpecificStatus = cmp.get('v.parentChecklist.Peo_IndSpecific_formStatus__c');
                var CovidStatus = cmp.get('v.parentChecklist.Peo_Covid_formStatus__c');
                if (!cmp.get('v.d401KQuestionnaireStatus')) cmp.set('v.d401KQuestionnaireStatus', form401Status);
                if (!cmp.get('v.PEOInformationSheetStatus')) cmp.set('v.PEOInformationSheetStatus', 'In Progress');
                if (!cmp.get('v.EPLIQuestionnaireStatus')) cmp.set('v.EPLIQuestionnaireStatus', EPLIStatus);
                if (!cmp.get('v.WorkersCompQuestionnaireStatus')) cmp.set('v.WorkersCompQuestionnaireStatus', WCStatus);               
                if (!cmp.get('v.CovidQuestionnaireStatus')) cmp.set('v.CovidQuestionnaireStatus', CovidStatus);
                if (!cmp.get('v.IndustrySpecificQuestionnaireStatus')) cmp.set('v.IndustrySpecificQuestionnaireStatus', IndSpecificStatus);
                // always resolves true on error or failure
                resolve(true);
            })
            
            $A.enqueueAction(getDiscrepencies)
        });             
    },
    /************************************
     * Form Render/Functionality SECTION
     ************************************/
    // This method kicks off the render process for the dynamic placement of the summary sections
    // Start by building a mapping of where each section goes then get all the attributes for each
    // individual section and add them to a storage object. Once each section is added to the mapping
    // iterate over the reference objects and pass each one into the appendSection which parses the
    // objects and builds the components
    initRender: function(cmp, e, helper) {
        let renderMap = {
            actionNeededItems: [],
            notSubmittedItems: [],
            completedItems: []
        };
        
        // callback used in later logic to determine where the section should be
        // appended to based on the status for the section
        let pushToRenderSection = function(obj) {
            // set the status of the object to attention needed if one isn't provided.
         
            var name = obj.name;
            console.log('obj:', obj);
            if ((obj.status == undefined || obj.status == '')&& cmp.get(`v.${name}Discrepencies`) != undefined && cmp.get(`v.${name}Discrepencies`).length >0) obj.status = 'Attention Needed';
            if (obj.status != undefined && obj.name == 'Other' && cmp.get('v.OtherDiscrepencies').length >0){
                if(cmp.get('v.commUser') == true){
                    obj.status = 'Discrepancy';
                }else{
                    obj.status = 'Attention Needed';
                } 
            }
            // if the status is any of the statuses that indicate 'Complete' this will be true
            let statusIsComplete = (obj.status == 'Submitted by Prospect' || obj.status == 'Complete' || obj.status == 'Submitted') ? true : false;
          console.log('obj status:'+obj.status);
            var descr = obj;
            var descrLength;
           // console.log(descr);
            if(descr.discrepencies){
              //  console.log('descr:'+descr.discrepencies.length);
                descrLength = descr.discrepencies.length;
            }
            //console.log('descrLength:'+descrLength);
            let locationToAppend;
            // if the object has discrepancies and it's still not completed or flagged as so by the analyst
            // set locationToAppend to be action needed
            //if (obj.discrepencies && obj.discrepencies.length && statusIsComplete == false) locationToAppend = 'actionNeededItems';
             // if the status is not complete and the location to append has not been set
            // assign the location to the not submitted items
            console.log('Obj Values');
            console.log(obj.discrepencies);
            console.log(statusIsComplete);
            console.log(descrLength);
            console.log(locationToAppend);
            
            if (obj.discrepencies && statusIsComplete == false && descrLength != 0) {
              //  console.log('inside if actionNeededItems');
                locationToAppend = 'actionNeededItems';
            }
            else if (!locationToAppend && statusIsComplete)
                locationToAppend = 'completedItems';
            else locationToAppend = 'notSubmittedItems';
            obj.pos = locationToAppend;
            
            renderMap[locationToAppend].push(obj);
           
        };
        
        /************************************************
        * FOLLOWING SET OF LOGIC BUILDS THE REF OBJECTS *
        * CONTAINING THE ATTRIBUTES FOR EACH SECTION 	*
        *************************************************/
        //Other Descrs
        if (cmp.get('v.OtherDiscrepencies.length')> 0 && !cmp.get('v.commUser')) {
            // build an obj containig the 
            let obj = helper.buildAttributeObjFromName(cmp, 'Other', false);
            pushToRenderSection(obj);
        }
        //Pricing
        if (cmp.get('v.PricingDiscrepencies.length')> 0) {
            // build an obj containig the 
            let obj = helper.buildAttributeObjFromName(cmp, 'Pricing', false);
            pushToRenderSection(obj);
        }
        //PEOInformationSheet
        if (cmp.get('v.PEOInformationSheetDiscrepencies.length')> 0) {
            // build an obj containig the 
            let obj = helper.buildAttributeObjFromName(cmp, 'PEO Information Sheet', false);
            pushToRenderSection(obj);
        }
        //ChecklistReject
        if (cmp.get('v.ChecklistRejectDiscrepencies.length')> 0) {
            // build an obj containig the 
            let obj = helper.buildAttributeObjFromName(cmp, 'Checklist Reject', false);
            pushToRenderSection(obj);
        }
        // @CENSUS
        if (cmp.get('v.censusRequired')) {
            // build an obj containig the 
           // console.log('Before creating the obj');
           // console.log(cmp.get(`v.statuss.Census`))
            let obj = helper.buildAttributeObjFromName(cmp, 'Census', true);
            pushToRenderSection(obj);
        }
        
        if (cmp.get('v.medicalinvoicereq')) {
            
            let medinvobj = helper.buildAttributeObjFromName(cmp, 'Medical Invoice', true);
            pushToRenderSection(medinvobj);
        }
        if (cmp.get('v.BenSummaryreq')) {
            
            let BenSumobj = helper.buildAttributeObjFromName(cmp, 'Benefit Summary', true);
            pushToRenderSection(BenSumobj);
        }
        
        if (cmp.get('v.hlthInsRenwReqd') ) //&& cmp.get('v.medPreQualWithNotAppr') == false
            {
            // build an obj containig the 
            let obj = {
                name: 'Health Insurance Renewal',
                checklistId: cmp.get('v.peoChecklist.Id'),
                Account: cmp.get('v.Account'),
                isDoc: true,
                isCommUser: cmp.get('v.commUser'),
                documentId: cmp.get('v.HealthInsuranceRenewalId'),
                docName: 'Health Insurance Renewal',
                status: cmp.get('v.statuss.HealthInsuranceRenewal'),
                DocReqStatus: cmp.get(`v.CLDocumentList.HealthInsuranceRenewal`),
                peoChecklist:cmp.get('v.peoChecklist'),
                parentChecklist:cmp.get('v.parentChecklist'),
                discrepencies: cmp.get('v.HealthInsuranceRenewalDiscrepencies')
            }
            pushToRenderSection(obj);
        }
        
        // @'Claims Report
        if (cmp.get('v.claimsReportRequired') //&& cmp.get('v.medPreQualWithNotAppr') == false
           ) {
            // build an obj containig the 
            let obj = {
                name: 'Claims Report',
                checklistId: cmp.get('v.peoChecklist.Id'),
                Account: cmp.get('v.Account'),
                isDoc: true,
                isCommUser: cmp.get('v.commUser'),
                documentId: cmp.get('v.ClaimsReportId'),
                docName: 'Claims Report',
                status: cmp.get('v.statuss.ClaimsReport'),
                 DocReqStatus: cmp.get(`v.CLDocumentList.ClaimsReport`),
                peoChecklist:cmp.get('v.peoChecklist'),
                parentChecklist:cmp.get('v.parentChecklist'),
                discrepencies: cmp.get('v.ClaimsReportDiscrepencies')
            }
            pushToRenderSection(obj);
        }
            //HSF SFDC-16848
            //if (cmp.get('v.parentChecklist.Medical_Benefits_Underwriting_Requested__c') == 'Yes') {
                
                //let objr = helper.buildAttributeObjFromName(cmp, 'HSF Census', true);	
                //pushToRenderSection(objr);
                
                // @MiscFilesMedical
            if(cmp.get('v.miscfilesmedreq')){
                 let obj = helper.buildAttributeObjFromName(cmp, 'Misc Files - Medical', true);
                pushToRenderSection(obj);
            }
               
           // }
            //sfdc-11580:start
            // @MiscFilesWC
            //console.log('Before creating the obj MiscFilesWC');
           // console.log(cmp.get(`v.statuss.MiscFilesWC`));
            if(cmp.get('v.miscfilesWCreq')){
            	let objWC = helper.buildAttributeObjFromName(cmp, "Misc Files - Workers' Comp", true);
            	pushToRenderSection(objWC);
            }
            
            // @AdditionalMiscDocuments
            //console.log('Before creating the obj AdditionalMiscDocuments');
           // console.log(cmp.get(`v.statuss.AdditionalMiscDocuments`));
            if(cmp.get('v.AddMiscFilesreq')){
            let objAMD = helper.buildAttributeObjFromName(cmp, "Additional Misc Documents", true);
            pushToRenderSection(objAMD);
            }
        
        
        /*// @MiscFilesMedical
        let objMiscMed = helper.buildAttributeObjFromName(cmp, 'Misc Files - Medical', true);
        pushToRenderSection(objMiscMed);*/
        
        // @Health Invoice
    /*    if (cmp.get('v.hlthInvReqd') && cmp.get('v.medPreQualWithNotAppr') == false) {
            // build an obj containig the 
            let obj = helper.buildAttributeObjFromName(cmp, 'Health Invoice', true);
            pushToRenderSection(obj);
        }*/
        
        // @Benefit Summaries
     /*   if (cmp.get('v.hlthInsSummReqd') && cmp.get('v.medPreQualWithNotAppr') == false) {
            // build an obj containig the 
            let obj = {
                name: 'Benefit Summaries',
            checklistId: cmp.get('v.peoChecklist.Id'),
                Account: cmp.get('v.Account'),
                isDoc: true,
                isCommUser: cmp.get('v.commUser'),
                documentId: cmp.get('v.HealthInsuranceSummaryId'),
                docName: 'Benefit Summaries',
                status: cmp.get('v.statuss.HealthInsuranceSummary'),
                peoChecklist:cmp.get('v.peoChecklist'),
                parentChecklist:cmp.get('v.parentChecklist'),
                discrepencies: cmp.get('v.HealthInsuranceSummaryDiscrepencies')
            }
            pushToRenderSection(obj);
        }
        */
        // @Health Insurance Renewal
        
        
        // @SUI Rate Forms
     /*   if (cmp.get('v.suiReqd') && cmp.get('v.medPreQualWithNotAppr') == false) {
            // build an obj containig the 
            let obj = {
                name: 'SUI Rate Forms',
                checklistId: cmp.get('v.peoChecklist.Id'),
                Account: cmp.get('v.Account'),
                isDoc: true,
                isCommUser: cmp.get('v.commUser'),
                documentId: cmp.get('v.SUIRateFormsId'),
                docName: 'SUI Rate Forms',
                status: cmp.get('v.statuss.SUIRateForms'),
                peoChecklist:cmp.get('v.peoChecklist'),
                parentChecklist:cmp.get('v.parentChecklist'),
                discrepencies: cmp.get('v.SUIRateFormsDiscrepencies')
            }
            pushToRenderSection(obj);
        } */
        
        // @Workersʼ Comp Declaration Page
      /*  console.log('wcDecReqd:'+cmp.get('v.wcDecReqd'));
        if (cmp.get('v.wcDecReqd')) {
            let wcDec = {
                name: 'Workersʼ Comp Declaration Page',
                checklistId: cmp.get('v.peoChecklist.Id'),
                Account: cmp.get('v.Account'),
                isDoc: true,
                isCommUser: cmp.get('v.commUser'),
                documentId: cmp.get('v.WCDeclarationsPagePEOCurrentRateId'),
                docName: 'Workersʼ Comp Declaration Page',
                status: cmp.get('v.statuss.WCDeclarationsPagePEOCurrentRate'),
                peoChecklist:cmp.get('v.peoChecklist'),
                parentChecklist:cmp.get('v.parentChecklist'),
                discrepencies: cmp.get('v.WCDeclarationsPagePEOCurrentRateDiscrepencies')
            }
            pushToRenderSection(wcDec);
        }
        */
        // @Workersʼ Comp Classes and Wages
        if (cmp.get('v.wcClsAndWgReqd')) // && !cmp.get('v.commUser') && cmp.get('v.medPreQualWithNotAppr') == false
            {
            // build an obj containig the 
            let obj = {
                name: 'Workersʼ Comp Classes and Wages',
                checklistId: cmp.get('v.peoChecklist.Id'),
                Account: cmp.get('v.Account'),
                isDoc: true,
                isCommUser: cmp.get('v.commUser'),
                documentId: cmp.get('v.WCClassesandWagesId'),
                docName: 'Workersʼ Comp Classes and Wages',
                status: cmp.get('v.statuss.WCClassesandWages'),
                DocReqStatus: cmp.get(`v.CLDocumentList.WCClassesandWages`),
                peoChecklist:cmp.get('v.peoChecklist'),
                parentChecklist:cmp.get('v.parentChecklist'),
                discrepencies: cmp.get('v.WCClassesandWagesDiscrepencies')
            }
            pushToRenderSection(obj);
        }
        
        // @Workersʼ Comp Rates and Pricing
         //console.log('wcRtNPrcReqd:'+cmp.get('v.wcRtNPrcReqd'));
        if (cmp.get('v.wcRtNPrcReqd') //&& cmp.get('v.medPreQualWithNotAppr') == false
           ) {
            let wcRtPrc = {
                name: 'Workersʼ Compensation Policy/Pricing',
                checklistId: cmp.get('v.peoChecklist.Id'),
                Account: cmp.get('v.Account'),
                isDoc: true,
                isCommUser: cmp.get('v.commUser'),
                documentId: cmp.get('v.WCRatesandPricingId'),
                docName: 'Workers’ Compensation Policy / Pricing',
                status: cmp.get('v.statuss.WCRatesandPricing'),
                DocReqStatus: cmp.get(`v.CLDocumentList.WCRatesandPricing`),
                peoChecklist:cmp.get('v.peoChecklist'),
                parentChecklist:cmp.get('v.parentChecklist'),
                discrepencies: cmp.get('v.WCRatesandPricingDiscrepencies')
            }
            pushToRenderSection(wcRtPrc);
        }
        
        // @Workersʼ Comp Loss Runs
        if ( //(!cmp.get('v.WCFastPassSelected') || cmp.get('v.WCFastPassSelected')=='No') &&
             cmp.get('v.lossRunsReqd') //&& cmp.get('v.medPreQualWithNotAppr') == false
           ) {
            // build an obj containig the 
           // console.log('build loss runs');
            let obj = {
                name: 'Workersʼ Comp Loss Runs',
                checklistId: cmp.get('v.peoChecklist.Id'),
                Account: cmp.get('v.Account'),
                isDoc: true,
                isCommUser: cmp.get('v.commUser'),
                documentId: cmp.get('v.LossRunsId'),
                docName: 'Workersʼ Comp Loss Runs',
                status: cmp.get('v.statuss.LossRuns'),
                DocReqStatus: cmp.get(`v.CLDocumentList.LossRuns`),
                peoChecklist:cmp.get('v.peoChecklist'),
                parentChecklist:cmp.get('v.parentChecklist'),
                discrepencies: cmp.get('v.LossRunsDiscrepencies')
            }
            pushToRenderSection(obj);
        }
        
        // @Payroll Report
        if(	cmp.get('v.payrollRegReqd') 	//cmp.get('v.medPreQualWithNotAppr') == false payrollReportReq
          ){
            let obj = {
                name: 'Payroll Register',
                checklistId: cmp.get('v.peoChecklist.Id'),
                Account: cmp.get('v.Account'),
                isDoc: true,
                isCommUser: cmp.get('v.commUser'),
                documentId: cmp.get('v.PayrollRegisterId'),
                docName: 'Payroll Register',
                status: cmp.get('v.statuss.PayrollRegister'),
                 DocReqStatus: cmp.get(`v.CLDocumentList.PayrollRegister`),
                peoChecklist:cmp.get('v.peoChecklist'),
                parentChecklist:cmp.get('v.parentChecklist'),
                discrepencies: cmp.get('v.PayrollReportDiscrepenciess')
            }
            console.log(obj);
            pushToRenderSection(obj);
        }
        
        if(cmp.get('v.hlthInsSummReqd')){
            let objWC = helper.buildAttributeObjFromName(cmp, "Health Insurance Summary", true);
            pushToRenderSection(objWC);
        }
        if(cmp.get('v.hlthInvReqd')){
            let objWC = helper.buildAttributeObjFromName(cmp, "Health Invoice", true);
            pushToRenderSection(objWC);
        }
        if(cmp.get('v.suiReqd')){
            let objWC = helper.buildAttributeObjFromName(cmp, "SUI Rate Forms", true);
            pushToRenderSection(objWC);
        }
        if(cmp.get('v.wcDecReqd')){
            let objWC = helper.buildAttributeObjFromName(cmp, "WC Declarations Page", true);
            pushToRenderSection(objWC);
        }
        
        
        // These sections are only inserted if the prospect is a client add on or the current tab
        // in view is the parent account tab
        let showQuestionnaireSectionspart1 = cmp.get('v.isClientAddOn') || cmp.get('v.Account.isParent__c');
        let showQuestionnaireSectionspart2 = cmp.get('v.Account.isParent__c') && cmp.get('v.Account.SalesParent__c') !== undefined;
        let showQuestionnaireSectionspart3 = (cmp.get('v.Account.isParent__c')== false) && cmp.get('v.Account.SalesParent__c') === undefined;
      //  console.log('showQuestionnaireSectionspart1:'+showQuestionnaireSectionspart1);
       // console.log('showQuestionnaireSectionspart2:'+showQuestionnaireSectionspart2);
       // console.log('showQuestionnaireSectionspart3:'+showQuestionnaireSectionspart3);
        //|| (!cmp.get('v.Account.isParent__c') && cmp.get('v.Account.SalesParent__c') === undefined)
        let showQuestionnaireSections = (cmp.get('v.isClientAddOn') || cmp.get('v.Account.isParent__c')) || (cmp.get('v.Account.isParent__c') && cmp.get('v.Account.SalesParent__c') !== undefined)||((cmp.get('v.Account.isParent__c')== false) && cmp.get('v.Account.SalesParent__c') === undefined) ;
        //console.log('SalesParent__c:'+cmp.get('v.Account.SalesParent__c'));
        //console.log('showQuestionnaireSections:'+showQuestionnaireSections);
        if (showQuestionnaireSections) {
            // @EPLI
           // if(cmp.get('v.EPLIQuestionnaireDiscrepencies') != undefined && cmp.get('v.EPLIQuestionnaireDiscrepencies').length>0){ }
            /*if(cmp.get('v.medPreQualWithNotAppr') == false){
                let epli = {
                    name: 'EPLI Questionnaire',
                    docName: 'EPLI Questionnaire',
                    checklistId: cmp.get('v.peoChecklist.Id'),
                    isDoc: false,
                    isCommUser: cmp.get('v.commUser'),
                    status: cmp.get('v.EPLIQuestionnaireStatus'),
                    peoChecklist:cmp.get('v.peoChecklist'),
                    parentChecklist:cmp.get('v.parentChecklist'),
                    discrepencies: cmp.get('v.EPLIQuestionnaireDiscrepencies')
                };
                pushToRenderSection(epli);
            }*/
            // Only shown if experience is Oasis
            // @401k Questionnaire
          /*  console.log('401k portalExperience:'+cmp.get('v.portalExperience'));
            console.log('medPreQualWithNotAppr:'+cmp.get('v.medPreQualWithNotAppr'));
            if(cmp.get('v.medPreQualWithNotAppr') == false){
                    let obj = {
                        name: '401K Questionnaire',
                        docName: '401K Questionnaire',
                        checklistId: cmp.get('v.peoChecklist.Id'),
                        isDoc: false,
                        isCommUser: cmp.get('v.commUser'),
                        status: cmp.get('v.d401KQuestionnaireStatus'),
                        peoChecklist:cmp.get('v.peoChecklist'),
                        parentChecklist:cmp.get('v.parentChecklist'),
                        discrepencies: cmp.get('v.d401KQuestionnaireDiscrepencies')
                    };
                    pushToRenderSection(obj);
            }*/
            // @Covid Questionnaire
            //console.log('covid reqd:'+cmp.get('v.covidSummaryNeeded'));
            //console.log('medPreQualWithNotAppr:'+cmp.get('v.medPreQualWithNotAppr'));
           /* if(cmp.get('v.medPreQualWithNotAppr') == false){
                if (cmp.get('v.covidSummaryNeeded')) {
                    let obj = {
                        name: 'COVID-19 Questionnaire',
                        docName: 'COVID-19 Questionnaire',
                        checklistId: cmp.get('v.peoChecklist.Id'),
                        isDoc: false,
                        isCommUser: cmp.get('v.commUser'),
                        status: cmp.get('v.CovidQuestionnaireStatus'),
                        peoChecklist:cmp.get('v.peoChecklist'),
                        parentChecklist:cmp.get('v.parentChecklist'),
                        discrepencies: cmp.get('v.CovidQuestionnaireDiscrepencies')
                    };
                    pushToRenderSection(obj);
                }
            }*/
            
            // @workers Comp
            if(cmp.get('v.medPreQualWithNotAppr') == false){
                let wrksrComp = {
                    name: 'Workersʼ Compensation Questionnaire',
                    docName: 'Workersʼ Compensation Questionnaire',
                    checklistId: cmp.get('v.peoChecklist.Id'),
                    isDoc: false,
                    isCommUser: cmp.get('v.commUser'),
                    status: cmp.get('v.WorkersCompQuestionnaireStatus'),
                    peoChecklist:cmp.get('v.peoChecklist'),
                    parentChecklist:cmp.get('v.parentChecklist'),
                    discrepencies: cmp.get('v.WorkersCompQuestionnaireDiscrepencies')
                };
                pushToRenderSection(wrksrComp);
            }
            // If not fast pass and Industry specific is required
            // @Industry Specific Questionnaire
            if(cmp.get('v.medPreQualWithNotAppr') == false){
                if (!(cmp.get('v.WCFastPassSelected') && !cmp.get('v.industrySpecificRequiredWithFastPass'))) {
                    let obj = {
                        name: 'Industry Specific Questionnaire',
                        docName: 'Industry Specific Questionnaire',
                        checklistId: cmp.get('v.peoChecklist.Id'),
                        isDoc: false,
                        isCommUser: cmp.get('v.commUser'),
                        status: cmp.get('v.IndustrySpecificQuestionnaireStatus'),
                        peoChecklist:cmp.get('v.peoChecklist'),
                        parentChecklist:cmp.get('v.parentChecklist'),
                        discrepencies: cmp.get('v.IndustrySpecificQuestionnaireDiscrepencies')
                    };
                    pushToRenderSection(obj);
                }
            }
            // If medical is requested
            // @medical QUestionnaire
            /*if (cmp.get('v.parentChecklist.Medical_Benefits_Underwriting_Requested__c') == 'Yes') {
                let obj = {
                    name: 'Medical Questionnaire',
                    docName: 'Medical Questionnaire',
                    checklistId: cmp.get('v.medicalQuestionnaire.Id'),
                    isDoc: false,
                    isCommUser: cmp.get('v.commUser'),
                    status: cmp.get('v.MedicalQuestionnaireStatus'),
                    peoChecklist:cmp.get('v.peoChecklist'),
                    parentChecklist:cmp.get('v.parentChecklist'),
                    discrepencies: cmp.get('v.MedicalQuestionnaireDiscrepencies')
                };
                pushToRenderSection(obj);
            }*/
        }
        
        // Iterate the created ref objects in renderMap
        // for each create a pos property which directly maps to where it
        // goes in the component then call the helper.appendSection method
        // passing in the ref obj that contains all the attributes
        let numOfReqDocs = 0,
            numberOfApprovedDocs = 0;
         console.log('835 Loopnig objList');
        console.log('renderMap:');
        console.log(renderMap);
        for (let pos in renderMap) {
            let objList = renderMap[pos];
           
            objList.forEach(function(attrLst){
                console.log(attrLst);
                attrLst.pos = 'v.' + pos; // pos is used in the callback of appendSection
                helper.appendSection(cmp, e, helper, attrLst);
                if(attrLst.isDoc){
                    if(attrLst.DocReqStatus=='Needed'){
                        if(attrLst.status == 'Approved'){
                            numberOfApprovedDocs+= 1;
                        } 
                        numOfReqDocs+=1;   
                    }
                }
                else
                {
                    if (attrLst.status == 'Complete') {
                        numberOfApprovedDocs+= 1;
                    }
                    numOfReqDocs+=1;                    
                }               
            })
        }
        cmp.set('v.approvedDocs',numberOfApprovedDocs); // set the number of approved docs on the cmp
        cmp.set('v.totalNumberOfRequiredDocs', numOfReqDocs); 
        let percent = Math.ceil((cmp.get('v.approvedDocs') / numOfReqDocs) *100);
        cmp.set('v.percent', percent); // set the percentage on the cmp
    },
    // for the passed in reference object
    // Build a callback to append the new component to the proper sections
    // assign the attributes for the component by parsing the passed in ref obj
    // then call the create component method to create the component
    // NOTE: Consider using the create components method. This would require some rewrite of the callback
    // used to append the component to the right section. Will maybe need to add another iteration of the result??
    appendSection: function(c, e, h, obj) {
        // get the positiong the component should be rendered and append
        // the new compoennt to that section
        let cb = function(newCmp, status, errMsg){
            // ADD ERROR HANDLING
            let x = c.get(obj.pos);
            x.push(newCmp);
            c.set(obj.pos, x);
        };
        
        // build the attribute list to be passed into the new cmp
        // ignore the Name key value pair on the ref obj we use docName for this
        let attributes = {};
        for (let attr in obj) {
            if (attr == name) continue;
            attributes[attr] = obj[attr];
        }
        let cmpName = 'c:CollapsableTableColumns';
        // create the component the CB will be called on failure or success
        $A.createComponent(cmpName, attributes, cb);    
    },
    /*****************************************************
     * Form attribute section (or something like that?)
     *****************************************************/
    setProfile: function(cmp, e) {
        return new Promise(function(resolve, reject){
            let profile = cmp.get('v.runningUserProfile');
            if (profile == 'Customer Community Login User Clone') {
                cmp.set('v.commUser',  true);
                cmp.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, visit the Need Help section on our homepage, so we can promptly address the issue.');
            }
            else {
                cmp.set('v.commUser',  false);
                cmp.set('v.errMsg', 'We’re sorry, your request can’t be completed right now. Please try again. For support, please submit a case through Sales Help.');
            }
            resolve(true);
        })        
    },
    setRequiredDocuments : function(cmp, checkList) {
        
        // no return value for this method. Consider adding a return value to be handled
        // in the next method call: getDocs. Pass in req docs map or above set attributes
        // denoting which docs are required
        //console.log('905 Census reqd:'+checkList.CensusRequired__c);
        let numOfReqDocs = 0;// the base num of required docs
        // this section updates the number of required docs. The number is used in the percentage
        // and progress bar on the component
        if(checkList.CensusRequired__c === true) cmp.set('v.censusRequired', true);
        if(checkList.Claims_Report_required__c === true) cmp.set('v.claimsReportRequired', true);
        if(checkList.Health_Insurance_Renewal_required__c === true) cmp.set('v.hlthInsRenwReqd', true);
        if(checkList.Health_Insurance_Summary_required__c === true) cmp.set('v.hlthInsSummReqd', true);
        if(checkList.Health_Invoice_required__c === true) cmp.set('v.hlthInvReqd', true);
        if(checkList.Loss_Runs_required__c === true) cmp.set('v.lossRunsReqd', true);
        if(checkList.Payroll_Register_Required__c === true) cmp.set('v.payrollRegReqd', true);
        if(checkList.SUI_Required__c === true) cmp.set('v.suiReqd', true);
        if(checkList.WC_Declarations_Required__c === true) cmp.set('v.wcDecReqd', true);
        if(checkList.WCClassesWages_Required__c  === true && cmp.get('v.commUser') === false) cmp.set('v.wcClsAndWgReqd', true);
        if(checkList.WC_RatesAndPricing_Required__c === true) cmp.set('v.wcRtNPrcReqd', true);
        if(checkList.Medical_Invoice_Required__c === true) cmp.set('v.medicalinvoicereq', true);
        if(checkList.Benefit_Summaries_Required__c === true) cmp.set('v.BenSummaryreq', true);
        if(checkList.Miscellaneous_Docs_Required__c === true) cmp.set('v.miscfilesmedreq', true);
		if(checkList.Miscellaneous_Docs_Required_WC__c === true) cmp.set('v.miscfilesWCreq', true);	
        if(checkList.Additional_Misc_Documents_Required__c === true) cmp.set('v.AddMiscFilesreq', true);

       // console.log('WCClassesWages_Required__c:'+checkList.WCClassesWages_Required__c);
        // no return value for this method. Consider adding a return value to be handled
        // in the next method call: getDocs. Pass in req docs map or above set attributes
        // denoting which docs are required
    },
    /*************
     * Helpers
     *************/
    buildAttributeObjFromName: function(cmp, sectionName, isDoc, checklist) {
        // dynamically get the attributes using the doc name
        // add the new obj to the mapping list
        // Handle if we're starting off the 401k
        if (sectionName && sectionName[0] == '4') sectionName = 'd' + sectionName;
        let joinedName = sectionName.replace(' ','');
        console.log('joinedName: '+joinedName); 	
        //if(joinedName =='HSFCensus Files')joinedName = "HSFCensusFiles"; //SFDC-16848
        if(joinedName =='MiscFiles - Medical')joinedName = "MiscFilesMedical";
        if(joinedName =="MiscFiles - Workers' Comp")joinedName = "MiscFilesWorkersComp";
        if(joinedName =="AdditionalMisc Documents")joinedName = "AdditionalMiscDocuments";
        //if(joinedName =="BenefitSummaries")	joinedName = "BenefitSummary";
        console.log(joinedName + ' Disc:' , cmp.get(`v.${joinedName}Discrepencies`) );
        let obj = {
            name: sectionName,
            checklistId: cmp.get('v.peoChecklist.Id'),
            isDoc: isDoc,
            isCommUser: cmp.get('v.commUser'),
            documentId: cmp.get(`v.${joinedName}Id`),
            docName: sectionName,
            status: cmp.get(`v.statuss.${joinedName}`),
            DocReqStatus: cmp.get(`v.CLDocumentList.${joinedName}`),
            peoChecklist:cmp.get('v.peoChecklist'),
            parentChecklist:cmp.get('v.parentChecklist'),
            discrepencies: cmp.get(`v.${joinedName}Discrepencies`),
        }
        //console.log('Building attribute list');
        //console.log(obj);
        //console.log(cmp.get(`v.statuss.${joinedName}`))
        if (isDoc) obj['Account'] = cmp.get('v.Account');
        if (!isDoc) obj['checklistId'] = cmp.get(`v.${checklist}.Id`);
        return obj;
    },
    
    checkMedPrequal: function(component, e, helper) {
        //show the following documents and document status upon the user selecting "Gradient Pre-Qualifer' in the Choose Medical Underwriting Path 
        //AND the 'Medical Pre-Qualifer' Status is NOT Approved or Declined 
        var statusList = ['Approved','Declined'];
       // var medUWStatus = component.get('v.parentChecklist').CS_CM_Medical_UW_Status__c != 'Approved' && component.get('v.parentChecklist').CS_CM_Medical_UW_Status__c  != 'Declined';
        var medUWpath = component.get('v.parentChecklist').Medical_Underwriting_Path__c == 'Gradient Pre-Qualifier';
        var Medical_Pre_Qualifier_Status__c = component.get('v.parentChecklist').Medical_Pre_Qualifier_Status__c;
       // console.log("Medical_Pre_Qualifier_Status__c:"+Medical_Pre_Qualifier_Status__c);
        //if(medUWpath == true && !statusList.includes(component.get('v.parentChecklist').CS_CM_Medical_UW_Status__c) )component.set('v.medPreQualWithNotAppr',true);
        if(medUWpath == true && !statusList.includes(component.get('v.parentChecklist').Medical_Pre_Qualifier_Status__c) )component.set('v.medPreQualWithNotAppr',true);
       // console.log("medPreQualWithNotAppr:"+component.get('v.medPreQualWithNotAppr'));
    },
})