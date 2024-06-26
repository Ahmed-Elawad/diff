({
    GenerateMSA : function(component, event, helper) {
        console.log('In Here 2');
        var config = component.get("v.AppConfig");
        //window.open(config.createEnvelopeAction);
        window.open("/apex/APXTConga4__Conga_Composer"+ config.createEnvelopeAction);
    
    },
    Init : function(component, event, helper) {
        console.log('In Here');
        var recId = component.get("v.recordId");
        var quoteId = component.get("v.opportunity.Primary_Oracle_QuoteId__c");
        var tempId = component.get("v.opportunity.CongaTemplateIds__c");
        var oppAccount = component.get("v.opportunity.Account.Name"); 
        var oppVersion = component.get("v.opportunity.Version__c");
        var oppNextVersion = component.get("v.opportunity.Next_Version__c");
        var today = $A.localizationService.formatDate(new Date(), "YYYY-MM-DD");
        
        var appConfig = {
            buttonLabel:"Generate MSA",
            createEnvelopeAction:"?serverUrl={!API.Partner_Server_URL_370}&id=" + recId + "&QueryId=[OracleQuote]a5E0g000004Evu8?pv0="+recId+",[OracleMultiID]a5E0g000004EvuD?pv0="+quoteId+",[ROP]a5E0g000002oj7a?pv0="+recId+"&TemplateId="+tempId+"&DefaultPDF=1&TNC=Service Agreement&OFN="+oppAccount+"+-+Service+Agreement+created+on+"+today+"+Version+"+oppVersion+"&SC0=1&SC1=SalesforceFile&AttachmentParentID="+recId+"&UF0=1&MFTS0=Version__c&MFTSValue0="+oppNextVersion+"&DS7=1",
            isDebugLogEnabled: false
        };
        component.set("v.AppConfig", appConfig);
	}
})