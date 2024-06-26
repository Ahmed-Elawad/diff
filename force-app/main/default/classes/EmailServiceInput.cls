/**
 * This is part of several classes that work together to process email attachments and insert records into Salesforce.
 * This is the input stub that handles the incoming email.
 * Created Justin Stouffer 8/19/2015
   02/24/2020 Dan Carmen        Increment API version

 */
global class EmailServiceInput implements Messaging.InboundEmailHandler {

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        EmailServiceProcessor.processEmailWithAttachment(email);
        return result;
    }
}