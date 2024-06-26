/*
 *  This class pulls in the inbound email message for a SurePayroll lead, 
 *  cleans it, and sends it to the WebSPLeadHelper class for processing.  
 *
 * History
 * --------
 * 6/26/2014   Carrie Marciano created 
 * 01/31/2018 Jacob Hinds    adding !isRunningTest when processing lead to prevent test from failing
 */
 
global class WebSPLeadEmailHandler implements Messaging.InboundEmailHandler {
 
  global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email, 
                                                       Messaging.InboundEnvelope env){
 
    // Create an InboundEmailResult object for returning the result of the  Apex Email Service
    Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
    
    String myPlainText = email.plainTextBody;
    system.debug('*** CLM *** myPlainText: '+ myPlainText);
    Integer idx = myPlainText.indexOf('The information contained');
    if(idx > 0){
        myPlainText = myPlainText.substring(0, idx - 1);
    }    
    else{
        myPlainText = '';
    }
    
    List<WebSPleadHelper.spLead> splList = new List<WebSPleadHelper.spLead>();
    
    if (myPlainText.length() == 0 || myPlainText == null)
    {   
        Throw new SPEmailException('Empty Email Body'); 
    }
    else
    {   
        try{
        xmlHelper splHelper = new xmlHelper('WebSPLeadHelper.splead',myPlainText);
        WebSPleadHelper.spLead spl = new WebSPleadHelper.spLead();
        spl = (WebSPLeadHelper.spLead)splHelper.xmlObject;
        splList.add(spl);
        }
        catch(Exception ex){
            Throw new SPEmailException('Unable to Parse XML');   
        }
    }
 
    if (!splList.isEmpty())
    {   
        Try{
            WebSPLeadHelper.processSPLead(splList);
        }
        catch(Exception ex){
            if(!Test.isRunningTest()){
                Throw new SPEmailException('Unable to Process Lead: '+splList[0]); 
            }
        } 
    }
    
    return result;
       
  } //handleInboundEmail
  
  // this exception is used to throw missing attachment messages
  public class SPEmailException extends Exception {}      
}

/* XML Should look like:

<node>
<surePayrollLeadID></surePayrollLeadID>
<company>JGS Testing Consultants</company>
<firstname>Justin</firstname>
<lastname>TestLead23</lastname>
<phone>585-123-4568</phone>
<mobile>585-123-4568</mobile>
<email>flurz@testing.com</email>
<NumOfEmployees></NumOfEmployees>
<product>HNBF</product>
<contactFirstName>Carrie</contactFirstName>
<contactLastName>Marciano</contactLastName>
<contactPhone>716-123-4567</contactPhone>
<contactEmail>jstouffer@paychex.com</contactEmail>
<street>10 Main St</street>
<city>CityCentre</city>
<state>NY</state>
<zip>14543</zip>
</node>

 
*/