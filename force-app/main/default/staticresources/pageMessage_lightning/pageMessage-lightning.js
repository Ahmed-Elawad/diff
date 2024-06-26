    $(document).ready(function(){
       overridePageMessages();    
    });

    function overridePageMessages(){    
        var textureEffect = '';
        //Uncomment below line for texture effect on page messages
        //textureEffect = 'slds-theme--alert-texture';

        $('.warningM3').addClass('slds-notify slds-notify--toast slds-theme--warning customMessage '+textureEffect);          
        $('.confirmM3').addClass('slds-notify slds-notify--alert slds-theme--success  customMessage '+textureEffect);    
        $('.errorM3').addClass('slds-notify slds-notify--alert slds-theme--error customMessage '+textureEffect);                  
        $('.infoM3').addClass('slds-notify slds-notify--toast customMessage '+textureEffect);    

        $('.errorM3').removeClass('errorM3'); 
        $('.confirmM3').removeClass('confirmM3'); 
        $('.infoM3').removeClass('infoM3');   
        $('.warningM3').removeClass('warningM3');  
    }