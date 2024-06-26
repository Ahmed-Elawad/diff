/*
 *  This class takes in the inbound email message from Marketo ESR response web form, 
 *  cleans it, and sends it to the WebESREmailHelper class for processing.  
 *
 * History
 * --------
 * 05/07/2015   Cindy Freeman created 
   12/29/2022   Dan Carmen    Commented out code, doesn't seem to be used. 
 */


global class WebESREmailHandler  implements Messaging.InboundEmailHandler {
 
	  global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
	                                                       Messaging.InboundEnvelope env){
	 
	    // Create an InboundEmailResult object for returning the result of the  Apex Email Service
	    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
	    /*
	    String myPlainText = email.plainTextBody;
	    system.debug('**CMF ** ESR Marketo myPlainText: '+ myPlainText);
	    
	    ESRtracking_settings__c esrSettings = WebESREmailHelper.getESRSettings('ESR settings');
	    if (esrSettings == null)
	    {	WebESREmailHelper.logError('ESRSettings missing or not Active or invalid', myPlainText);
	    	Throw new WebESREmailHandlerException('ESRSettings missing or not Active or invalid, myPlainText='+myPlainText);	    	
	    }
	    if (esrSettings.Log_All_Emails__c)
	    {	WebESREmailHelper.logError('incoming Web-Marketo ESR emails', myPlainText);	}	   	
	   		    
	    List<WebESREmailHelper.ESRemail> esrList = new List<WebESREmailHelper.ESRemail>();
	    
	    if (myPlainText.length() == 0 || myPlainText == null)
	    {   Throw new WebESREmailHandlerException('Empty Email Body');    }
	    else
	    {   Integer endIdx = myPlainText.indexOf('</note>');
	    	String goodPlainText = myPlainText.substring(0,endIdx+7);
	    	WebESREmailHelper.ESRemail esr = new WebESREmailHelper.ESRemail();
	    	try
	        {	xmlHelper esrHelper = new xmlHelper('WebESREmailHelper.ESRemail',goodPlainText);	        	
	        	esr = (WebESREmailHelper.ESRemail)esrHelper.xmlObject;	        	
	        }
	        catch(Exception ex)
	        {   Throw new WebESREmailHandlerException('Unable to Parse XML '+ex.getMessage()+' goodPlainText='+goodPlainText);	}
	        esr.myPlainText = goodPlainText;
	        if (esr.branchclientid != null)
        	{	esr.acctnbr = esr.branchclientid.replaceAll(' ','');
        		esr.acctnbr = esr.acctnbr.replaceAll('%20','');
        		esr.acctnbr = esr.acctnbr.removeStart('00');
        		esr.acctnbr = esr.acctnbr.removeStart('0');
        	}
        	esrList.add(esr);
        	
	    } // else
	 
	    if (!esrList.isEmpty())
	    {   try
	        {   WebESREmailHelper.processESRemail(esrList);	}
	        catch(Exception ex)
	        {	Throw new WebESREmailHandlerException('Unable to Process esrList exception='+ex.getMessage());	} 
	    }
	    */
	    return result;
	       
	  } //handleInboundEmail
	  
	  // this exception is used to throw missing attachment messages
	  public class WebESREmailHandlerException extends Exception {}      
}

/* XML Should look like:

<node>
<firstname>Justin</firstname>
<lastname>TestLead23</lastname>
<phone>585-123-4568</phone>
<email>flurz@testing.com</email>
<branchclientid>400-1234</branchclientid>
<bisid>123456</bisid>
<reasonsfordecliningesrservices1>I Do Not Plan to Take Action on ESR</reasonsfordecliningesrservices1>
<reasonsfordecliningesrservices2>I Think ESR Will Be Eliminated</reasonsfordecliningesrservices2>
</node>

 
*/