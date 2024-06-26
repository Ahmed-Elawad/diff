/*
 *  This class will process messages received from email services.  The email is sent from a Paychex website
 *  and includes info about a Financial Advisor that wants to talk to someone about building a relationship.
 *  This class uses the class WebFALeadHelper to parse and process the incoming emails.
 *
 * History
 * --------
 * 04/24/2013  Cindy Freeman    created
 *
 */
 
global class WebFALeadEmailHandler implements Messaging.InboundEmailHandler {
 
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                       Messaging.InboundEnvelope env){
 
    // Create an InboundEmailResult object for returning the result of the  Apex Email Service
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
  
    String myPlainText= '';   
    // Add the email plain text into the local variable 
    myPlainText = email.plainTextBody;
    Integer idx = myPlainText.indexOf('The information contained');
    if (idx > 0)
    {    myPlainText = myPlainText.substring(0, idx - 1);    }
    myPlainText = myPlainText.trim();
System.debug('***CMF ** myPLainText='+myPlainText);
    
    List<WebFAleadHelper.FAlead> faList = new List<WebFAleadHelper.FAlead>();
    
    if (myPlainText.length() == 0 || myPlainText == null)
    {   System.debug('**CMF ** no text within email body!!');   
        Throw new FAemailException('Empty Email Body'); 
    }
    else
    {   WebFAleadHelper.FAlead fa = new WebFAleadHelper.FAlead();
        fa = WebFAleadHelper.parseXML(myPlainText);
        faList.add(fa);
    }

    // System.debug('**CMF ** handler faList.size='+faList.size()); 
    if (!faList.isEmpty())
    {   WebFALeadHelper.processFALead(faList);  }
    
    return result;
       
  } //handleInboundEmail
  
  // this exception is used to throw missing attachment messages
  public class FAemailException extends Exception {}
   
  
   
    
}