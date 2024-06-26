({
    init : function (component) {
        /*var flow = component.find("supportFlow");
        flow.startFlow("PEO_Getting_Started_Case_Submission");*/
        var year = $A.localizationService.formatDate(new Date(), "YYYY");
        component.set('v.year', year);
    },
    
    navGetStarted : function(component, event, helper) {
        var urlEvent = $A.get("e.force:navigateToURL");
        urlEvent.setParams({
            "url": '/evaluation-questionnaire'
        });
        urlEvent.fire();
    },
    
    navToGettingStartedPortal: function(component, event, helper) {
        component.set("v.openVideo", true);
        component.set("v.displayURL", "https://px.wistia.com/medias/9vluvb0mmy?autoplay=1");
	},
    
    closeModal: function(component, event, helper) {
        component.set("v.openVideo", false);
    },
    
	navToCompInfo : function(component, event, helper) {
        component.set("v.openVideo", true);
        component.set("v.displayURL", "https://px.wistia.com/medias/hfvbj3elno?autoplay=1");
	},
    
    navToMedInfo : function(component, event, helper) {
        component.set("v.openVideo", true);
        component.set("v.displayURL", "https://px.wistia.com/medias/lk38a59t03?autoplay=1");
        
	},
    removeStickyNote: function(component, event, helper) {
        component.set("v.showStickyNote", false);
    },
    navToWorkersCompInfo : function(component, event, helper) {
        component.set("v.openVideo", true);
        component.set("v.displayURL", "https://px.wistia.com/medias/dy76d13b1s?autoplay=1");
	},
    
    navToAdditionalInfo : function(component, event, helper) {
        component.set("v.openVideo", true);
        component.set("v.displayURL", "https://px.wistia.com/medias/9nzpf8yz3g?autoplay=1");
	},
    
    infoAndDocChecklist : function(component, event, helper) {
        window.open("https://www.paychex.com/sites/default/files/2022-09/edge-checklist.pdf", '_blank');
    },
    
    contactSupport : function(component, event, helper) {
        /*var flow = component.find("supportFlow");
        flow.startFlow("PEO_Getting_Started_Case_Submission");
        component.set('v.disableContactSupport', true);*/
        window.open("https://paychex.my.site.com/GettingStarted/s/help-center", '_self');
    },
})