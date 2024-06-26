/*
 *  This class pulls in the inbound email message for an Icon Web Registration, 
 *  cleans it, and sends it to the WebIconRegistrationEmailHelper class for processing.  
 *
 * History
 * --------
 * 06/18/2015   Carrie Marciano   created 
   12/28/2022   Dan Carmen        Change to use SF Duplicate Management

 */
 
global class WebIconRegistrationEmailHandler implements Messaging.InboundEmailHandler {
 
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                       Messaging.InboundEnvelope env){
 
    // Create an InboundEmailResult object for returning the result of the  Apex Email Service
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
    
    
    String myPlainText = email.plainTextBody;
    system.debug('*** CLM *** myPlainText: '+ myPlainText);
    Integer startIdx = myPlainText.indexOf('<node>');
    Integer endIdx = myPlainText.indexOf('</node>');
    system.debug('*** CLM *** startIdx: '+ startIdx + ' endIdx: '+ endIdx);
    if(endIdx > 0){
        myPlainText = myPlainText.substring(startIdx, endIdx+7);
    }    
    else{
        myPlainText = '';
    }
    
    List<WebIconRegistrationEmailHelper.iWebReg> iwrList = new List<WebIconRegistrationEmailHelper.iWebReg>();
    
    if (myPlainText.length() == 0 || myPlainText == null)
    {   
        Throw new IconRegistrationEmailException('Empty Email Body'); 
    }
    else
    {   
        try{
        xmlHelper iwrHelper = new xmlHelper('WebIconRegistrationEmailHelper.iWebReg',myPlainText);
        WebIconRegistrationEmailHelper.iWebReg iwr = new WebIconRegistrationEmailHelper.iWebReg();
        iwr = (WebIconRegistrationEmailHelper.iWebReg)iwrHelper.xmlObject;
        iwr.myPlainText = myPlainText;
        iwrList.add(iwr);
        }
        catch(Exception ex){
            Throw new IconRegistrationEmailException('Unable to Parse XML'+ex.getMessage()+' myPlainText='+myPlainText);     
        }
    }
 
    if (!iwrList.isEmpty())
    {   
        Try{
            WebIconRegistrationEmailHelper.processIWebReg(iwrList);
        }
        catch(Exception ex){
            System.debug('handleInboundEmail ex='+ex.getMessage()+'; '+ex.getStackTraceString());
            Throw new IconRegistrationEmailException('Unable to Process Web Registration='+ex.getMessage()); 
        } 
    }
    
    return result;
       
  } //handleInboundEmail
  
  // this exception is used to throw missing attachment messages
  public class IconRegistrationEmailException extends Exception {}      
}

/* XML Should look like:

<node>
<CompanyName></CompanyName>
<IconType></IconType>
<street> </street>
<city> </city>
<state> </state>
<zip></zip>
<country></country>
<NumOfEmployees></NumOfEmployees>
<firstname> </firstname>
<lastname> </lastname>
<phone></phone>
<fax></fax>
<email> </email>
<ContactRole></ContactRole>
<ProductName></ProductName>
<ClockSerialNumber></ClockSerialNumber>
<SoftwareVersion></SoftwareVersion>
<NumOfClocks></NumOfClocks>
<AdditionalSerialNum></AdditionalSerialNum>
<Reseller></Reseller>
</node>
 
*/