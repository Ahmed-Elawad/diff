({
    SendWithDocuSign : function(component, event, helper) {
        
        var config = component.get("v.AppConfig");
        //window.open(config.createEnvelopeAction);
        window.open("/apex/SendToDocusign?url="+ encodeURIComponent(config.createEnvelopeAction));
    
    },
    Init : function(component, event, helper) {
        //var query = "select Id, In_Person_Signature__c from Opportunity where Id = '{!Opportunity.Id}' limit 1"; 
        
        //var result = sforce.connection.query(query); 
        //var records = result.getArray("records"); 
        
        //var myObj = records[0]; 
        
        //myObj.In_Person_Signature__c = false; 
        
        //var results = sforce.connection.update([myObj]); 
        //********* Option Declarations (Do not modify )*********// 
        var RC = '';var RSL='';var RSRO='';var RROS='';var CCRM='';var CCTM='';var CCNM='';var CRCL='';var CRL='';var OCO='';var DST='';var LA='';var CEM='';var CES='';var STB='';var SSB='';var SES='';var SEM='';var SRS='';var SCS ='';var RES=''; 
        //*************************************************// 
        
        // Modify individual options here: 
        
        // Related Content (default no related content) 
        RC = ''; //Ex: GetRelContentIDs("{!Opportunity.Id}"); 
        
        // Recipient Signer Limit (default no limit) 
        RSL = ''; //Ex: '3' 
        
        // Recipient Starting Routing Order (default 1) 
        RSRO = ''; // Ex: '1' 
        
        // Recipient Routing Order Sequential (default not sequential) 
        RROS= ''; //Ex: '1' 
        
        // Custom Contact Role Map (default config role) 
        CCRM = ''; //Ex: 'Decision Maker~Signer1;Economic Buyer~CarbonCopy' 
        
        // Custom Contact Type Map (default Signer) 
        CCTM = ''; //Ex: 'Decision Maker~Signer;Economic Buyer~CC' 
        
        // Custom Contact Note Map (default no note) 
        CCNM = ''; //Ex: 'Decision Maker~Note for DM;Economic Buyer~Note For EB;DEFAULT_NOTE~Default Note' 
        
        // Custom Related Contact List (default object contact) 
        CRCL = ''; 
        //Ex:'LoadDefaultContacts~1,MyContacts__r,Email~Email__c;FirstName~First_Name__c;LastName~Last_Name__c;Role~Role__c' 
        
        // Custom Recipient List 
        CRL = ''; 
        
        //Ex:'Email~;FirstName~;LastName~;Role~SignInPersonName~;RoutingOrder~;AccessCode~;RecipientNote~;SignNow~, LoadDefaultContacts~1;Role~Signer 1;RoutingOrder~3' 
        
        // One Click Option (default edit envelope screen) 
        OCO = ''; //Ex: Tag 
        
        // DocuSign Template ID (default no template) 
        DST = ''; //Ex: '67870A79-A0B5-4596-8AC1-CC7CC1EA01EB' 
        
        // Load Attachments (default on) 
        LA = '0'; //Ex: '0' 
        
        // Custom Email Message (default in config) 
        var sOwner = component.get("v.opportunity.Owner.Name"); 
        var sOppName = component.get("v.opportunity.Name"); 
        //var sSigner = "{!JSENCODE(dsfs__DocuSign_Envelope_Recipient__c.dsfs__DocuSign_Signature_Name__c)}"; 
        //CEM=''; 
        CEM = 'As discussed, please review and execute the documentation by clicking on the link above.\\n\\nShould you have any questions, do not hesitate to reach out.\\n\\nThank you and have a great day!\\n\\nSincerely,\\n'+sOwner; 
        
        // Custom Email Subject (default in config) 
        var sAcc = component.get("v.opportunity.Account.Name");  
        CES = 'Paychex Documents - '+sAcc; 
        //Ex: 'Re: Opportunity Name: {!Opportunity.Name}' 
        
        // Show Tag Button (default in config) 
        STB = ''; //Ex: '1' 
        
        // Show Send Button (default in config) 
        SSB = ''; //Ex: '1' 
        
        // Show Email Subject (default in config) 
        SES = ''; //Ex: '1' 
        
        // Show Email Message (default in config) 
        SEM = ''; //Ex: '1' 
        
        // Show Reminder/Expire (default in config) 
        SRS = ''; //Ex: '1' 
        
        // Show Chatter (default in config) 
        SCS = ''; //Ex: '1' 
        
        // Reminder and Expiration Settings 
        RES = ''; //Ex: '0,1,2,0,120,3' 
        
        var appConfig = {
            buttonLabel:"Send with DocuSign",
            createEnvelopeAction:"/apex/dsfs__DocuSign_CreateEnvelope?DSEID=0&SourceID=" + component.get("v.recordId") + "&RC="+RC+"&RSL="+RSL+"&RSRO="+RSRO+"&RROS="+RROS+"&CCRM="+CCRM+"&CCTM="+CCTM+"&CRCL="+CRCL+"&CRL="+CRL+"&OCO="+OCO+"&DST="+DST+"&CCNM="+CCNM+"&LA="+LA+"&CEM="+CEM+"&CES="+CES+"&SRS="+SRS+"&STB="+STB+"&SSB="+SSB+"&SES="+SES+"&SEM="+SEM+"&SRS="+SRS+"&SCS="+SCS+"&RES="+RES,
            isDebugLogEnabled: false
        };
        component.set("v.AppConfig", appConfig);
	}
})