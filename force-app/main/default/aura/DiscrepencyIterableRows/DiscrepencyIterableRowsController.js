({
    saveComment : function(cmp, event, helper) {
        try{
            let docId = cmp.get('v.discRecId');
            let comment = cmp.find('prospectComment').get('v.value');
            let discRec = {};
            
            discRec.Id = cmp.get('v.discRecId');
            console.log('Comment Added '+cmp.find('prospectComment').get('v.value'));
            discRec.Prospect_Comments__c = cmp.find('prospectComment').get('v.value');
            
            let saveCmm = cmp.get('c.updateDisc');
            saveCmm.setParams({disc: discRec});
            
            saveCmm.setCallback(this, function(res) {
                let m, t, ttl;
                if (res.getState() !== 'SUCCESS') {
                    console.log(res.getError());
                    console.log(res.getReturnValue());
                    m = 'A server error occured while trying to save comment. Please notify admin.';
                    t = 'error';
                    ttl = 'Error';
                } else {
                    m = 'Comment saved';
                    t = 'Success';
                    ttl = 'Success!';          
                }
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    title: ttl,
                    message: m,
                    type: t
                });
                toastEvent.fire(); 

            })
            
            $A.enqueueAction(saveCmm);
        }catch(e) {
            console.log(e);
        }
    },
    saveRepComment : function(cmp, event, helper) {
        let saveCmm = cmp.get('c.updateDisc');
        
        let docId = cmp.get('v.discRecId');
        let comment = cmp.find('additionalComment').get('v.value');
        let discRec = {};
        
        discRec.Id = cmp.get('v.discRecId');
        discRec.additional_information__c = cmp.find('additionalComment').get('v.value');
        
        saveCmm.setParams({disc: discRec});
        
        saveCmm.setCallback(this, function(res) {
            let m, t, ttl;
            if (res.getState() !== 'SUCCESS') {
                console.log(res.getError());
                console.log(res.getReturnValue());
                m = 'A server error occured while trying to save comment. Please notify admin.';
                t = 'error';
                ttl = 'Error';
            } else {
                m = 'Comment saved';
                t = 'Success';
                ttl = 'Success!';          
            }
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                title: ttl,
                message: m,
                type: t
            });
            toastEvent.fire(); 
        })
        
        $A.enqueueAction(saveCmm);
    },
    
    //Added by Bharat to open discrepancy in new subtab
    openDiscRecTab: function(cmp, event, helper){
        var workspaceAPI = cmp.find("DiscrepancyWorkspace");
        workspaceAPI.openTab({
            url:'/lightning/r/PEO_Onboarding_Document_Discrepency__c/'+ cmp.get("v.discRecId") +'/view',
            focus:true
        }).then(function(response){
            workspaceAPI.getTabInfo({
                tabId:response
            }).then(function(tabInfo){
                console.log('Record ID for discrepency document tab is: '+tabInfo.recordId);
            });
        }).catch(function(error){
            console.log('Error occured while navigation: '+error);
        });
    },
    
    //Added by Bharat to open doc in new subtab
    openDocTab: function(cmp, event, helper){
        var workspaceAPI = cmp.find("DiscrepancyWorkspace");
        workspaceAPI.openTab({
            url:'/lightning/r/PEO_Onboarding_Document__c/'+ cmp.get("v.docId") +'/view',
            focus:true
        }).then(function(response){
            workspaceAPI.getTabInfo({
                tabId:response
            }).then(function(tabInfo){
                console.log('Record ID for PEO Document tab is: '+tabInfo.recordId);
            });
        }).catch(function(error){
            console.log('Error occured while navigation: '+error);
        });
    },
    
    
})