/** Accept an email from telereach, create opp and update account
 *
 * History
 * -------
 * 03/21/2019 Jake Hinds    Accept email from telereach, use email to convert lead, create opp and meeting
 * 07/08/2019 Jake Hinds    Changes for intermittent account ownership issues
 * 11/22/2019 Jake Hinds    Changes to error email for test coverage, more changes for ownership issues
 * 07/06/2020  Jacob Hinds         Added without sharing per PMD
 */
global without sharing class TelereachEmailHandler implements Messaging.InboundEmailHandler {

    // this exception is used to throw any errors in this class
    public class TelereachEmailException extends Exception {}

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail email,
        Messaging.InboundEnvelope env) {
        // Create an InboundEmailResult object for returning the result of the Apex Email Service
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();

        string bodyText;
        if (string.isEmpty(email.plainTextBody)) {
            bodyText = htmlToText(email.htmlBody);
        } else {
            bodyText = email.plainTextBody;
        }
        if (String.isNotBlank(bodyText)) {
            system.debug('TelereachEmailHandler inEmailBody');
            Matcher namePattern = Pattern.compile('(?m)(?i)^\\s*Company Name: (.*)').matcher(bodyText);
            Matcher idPattern = Pattern.compile('(?m)(?i)^\\s*SalesForce ID: (.*)').matcher(bodyText);
            Matcher contactNamePattern = Pattern.compile('(?m)(?i)^\\s*Contact Name: (.*)').matcher(bodyText);
            Matcher contactTitlePattern = Pattern.compile('(?m)(?i)^\\s*Contact Title: (.*)').matcher(bodyText);
            Matcher streetAddressPattern = Pattern.compile('(?m)(?i)^\\s*Address: (.*)').matcher(bodyText);
            Matcher mainPhonePattern = Pattern.compile('(?m)(?i)^\\s*Main Phone Number: (.*)').matcher(bodyText);
            Matcher directPhonePattern = Pattern.compile('(?m)(?i)^\\s*Direct Phone Number: (.*)').matcher(bodyText);
            Matcher mobilePhonePattern = Pattern.compile('(?m)(?i)^\\s*Mobile Phone Number: (.*)').matcher(bodyText);
            Matcher emailPattern = Pattern.compile('(?m)(?i)^\\s*Email: (.*)').matcher(bodyText);
            Matcher meetingDatePattern = Pattern.compile('(?m)(?i)^\\s*Meeting Date: (.*)').matcher(bodyText);
            Matcher meetingTimePattern = Pattern.compile('(?m)(?i)^\\s*Meeting Time: (.*)').matcher(bodyText);
            Matcher empCountPattern = Pattern.compile('(?m)(?i)^\\s*Total Number of Employees: (.*)').matcher(bodyText);
            Matcher payrollProviderPattern = Pattern.compile('(?m)(?i)^\\s*Payroll Provider: (.*)').matcher(bodyText);
            Matcher soundFilePattern = Pattern.compile('(?m)(?i)^\\s*Link to Sound File: (.*)').matcher(bodyText);

            String companyName;
            String recordID;
            String contactName;
            String contactTitle;
            String streetName;
            String cityAddress;
            String stateAddress;
            String zipAddress;
            //since there's no identifying tag for the second line of the address, 
            //we have to deduce it from the space between the first address line and the phone tag after it
            Integer streetAddressEnd;
            Integer mainPhoneEnd;
            String mainPhone;
            String directPhone;
            String mobilePhone;
            String emailAddress;
            DateTime meetingDate;
            Integer employees;
            String payrollProvider;
            String soundFileURL;

            SalesOrg__c sos = SalesOrg__c.getInstance('PEO');
            User runningUser = UserHelper.getRunningUser();

            Lead ld;
            Referral__c referral;
            Opportunity opp;
            Contact ctct;
            Account acct;

            //Record ID is the most important, if we can't match this to a lead or contact there's nothing to create from the email
            if (idPattern.find()) {
                recordId = idPattern.group(1).trim();
                system.debug('TelereachEmailHandler SalesForce ID: ' + recordId);
                if (recordId != null) {
                    Id contactId;
                    if (recordId.startsWith(Lead.sObjectType.getDescribe().getKeyPrefix())) {
                        ld = [SELECT Id,OwnerId,List_Type__c, List_Source__c, IsConverted, ConvertedAccountId, ConvertedContactId FROM Lead WHERE Id =: recordId];
                        if (ld.IsConverted) {
                            contactId = ld.ConvertedContactId;
                        } else {
                            //is this the right way to do this?
                            Database.LeadConvert lc = new Database.LeadConvert();
                            lc.setLeadId(ld.id);
                            lc.setOwnerId(ld.OwnerId);
                            LeadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted = true LIMIT 1];
                            lc.setConvertedStatus(convertStatus.MasterLabel);
                            lc.setDoNotCreateOpportunity(true);
                            Database.LeadConvertResult lcr = Database.convertLead(lc);
                            contactId = lcr.getContactId();
                        }
                    } else if (recordId.startsWith(Contact.sObjectType.getDescribe().getKeyPrefix())) {
                        contactId = recordId;
                    }
                    if (contactId != null) {
                        ctct = [SELECT Id, AccountId, Account.Id, Account.Name, Account.OwnerId, Account.Owner.ManagerId, Account.Owner.DSA_FSS__c, Account.ShippingStreet, Account.ShippingCity, Account.ShippingState,
                            Account.ShippingPostalCode, Account.Phone, Account.Current_Prior_Method__c, Account.List_Source__c,Account.List_Type__c,Account.RecordTypeId,
                            Name, FirstName, LastName, Title, Phone, MobilePhone, Email, Sales_Contact__c
                            FROM Contact WHERE Id =: contactId];
                    }
                    if (ctct != null) {
                        acct = ctct.Account;
                    }
                } //if recordId !=null
            } //if idPattern.find

            if (ctct != null) {
                //update contact
                Boolean updateContact = false;
                if (contactNamePattern.find()) {
                    contactName = contactNamePattern.group(1).trim();
                    if (contactName != ctct.Name) {
                        ctct.FirstName = contactName.substringBefore(' ');
                        ctct.LastName = contactName.substringAfter(' ');
                        updateContact = true;
                    }
                    system.debug('TelereachEmailHandler Contact Name: ' + contactName);
                }
                if (contactTitlePattern.find()) {
                    contactTitle = contactTitlePattern.group(1).trim();
                    if (contactTitle != ctct.Title) {
                        ctct.Title = contactTitle;
                        updateContact = true;
                    }
                    system.debug('TelereachEmailHandler Contact Title: ' + contactTitle);
                }
                if (directPhonePattern.find()) {
                    directPhone = directPhonePattern.group(1).trim();
                    if (ctct.Phone != directPhone) {
                        ctct.Phone = directPhone;
                        updateContact = true;
                    }
                    system.debug('TelereachEmailHandler Direct Phone: ' + directPhone);
                }
                if (mainPhonePattern.find()) {
                    mainPhone = mainPhonePattern.group(1).trim();
                    system.debug('TelereachEmailHandler Main Phone: ' + mainPhone);
                    mainPhoneEnd = bodyText.indexOf(mainPhonePattern.group(0));
                    system.debug('TelereachEmailHandler mainPhoneEnd' + mainPhoneEnd);
                    if (directPhone == null && ctct.Phone != mainPhone) {
                        ctct.Phone = mainPhone;
                        updateContact = true;
                    }
                }
                if (mobilePhonePattern.find()) {
                    mobilePhone = mobilePhonePattern.group(1).trim();
                    system.debug('TelereachEmailHandler Mobile Phone: ' + mobilePhone);
                    if (ctct.MobilePhone != mobilePhone) {
                        ctct.MobilePhone = mobilePhone;
                        updateContact = true;
                    }
                }
                if (emailPattern.find()) {
                    //printing out as clientservices@telereach.com<mailto:clientservices@telereach.com>, split at < to ignore everything in the tag
                    emailAddress = emailPattern.group(1).split('<')[0].trim();
                    system.debug('TelereachEmailHandler Email: ' + emailAddress);
                    if (ctct.Email != emailAddress) {
                        ctct.Email = emailAddress;
                        updateContact = true;
                    }
                }
                if (!ctct.Sales_Contact__c) {
                    ctct.Sales_Contact__c = true;
                    updateContact = true;
                }
                if (updateContact) {
                    try {
                        DmlHelper.performDML2(new List < Contact > {
                            ctct
                        }, DmlHelper.DML_UPDATE, 'TelereachEmailHandler', 'handleInboundEmail', 'Update Contact', true);
                    } catch (exception e) // catch DupeBlocker exception, should never get here
                    {
                        Messaging.Singleemailmessage contactErrorMail = forwardEmail('TelereachEmailHandler TelereachEmailHandler unable to update contact', e.getMessage());
                        throw new TelereachEmailException(e.getMessage());
                    }
                }

                //update account
                
                if (namePattern.find()) {
                    companyName = namePattern.group(1).trim();
                    if (companyName != acct.Name) {
                        acct.Name = companyName;
                    }
                    system.debug('TelereachEmailHandler Company Name: ' + companyName);
                }
                if (streetAddressPattern.find()) {
                    String wholeAddress = streetAddressPattern.group(1).trim();
                    //streetName = streetAddressPattern.group(1).trim();
                    if(String.isNotBlank(wholeAddress)){
                        streetName = wholeAddress.substringBefore(',').trim();
                        String cityAddressTemp = wholeAddress.substringBetween(',');
                        if(String.isNotBlank(cityAddressTemp)){
                            cityAddress = cityAddressTemp.trim();
                        } 
                        String tempStateZip = wholeAddress.substringAfterLast(',');
                        if(String.isNotBlank(tempStateZip)){
                            tempStateZip = tempStateZip.trim();
                            stateAddress = tempStateZip.substringBefore(' ');
                            zipAddress = tempStateZip.substringAfter(' ');
                        }
                        
                        system.debug('TelereachEmailHandler Street Name: ' + streetName);
                    }
                    if (String.isNotBlank(streetName)) {
                        //streetAddressEnd = Integer.valueOf(bodyText.indexOf(streetAddressPattern.group(1)) + streetAddressPattern.group(1).length());
                        system.debug('TelereachEmailHandler streetName:' + streetName + ' cityAddress:' + cityAddress + ' stateAddress:' + stateAddress + ' zipAddress:' + zipAddress);
                        if (streetName != acct.ShippingStreet) {
                            acct.ShippingStreet = streetName;
                        }
                        if (String.IsNotBlank(cityAddress) && cityAddress != acct.ShippingCity) {
                            acct.ShippingCity = cityAddress;
                        }
                        if (String.IsNotBlank(stateAddress) && stateAddress != acct.ShippingState) {
                            acct.ShippingState = stateAddress;
                        }
                        if (String.IsNotBlank(stateAddress) && zipAddress != acct.ShippingPostalCode) {
                            acct.ShippingPostalCode = zipAddress;
                        }
                    }
                }
                
                //for some reason the RT doesn't always get set properly.
                Id acctRTId = RecordTypeHelper.getRecordType(PeoHelper.RT_PROSPECT, 'Account').getRecordTypeId();
                Boolean checkAccountOwner = false;
                if(acct.RecordTypeId!=acctRTId){
                    acct.RecordTypeId = acctRTId;
                    if(String.isNotBlank(acct.ShippingPostalCode)){
                        Map<String,List<Zip_Assignment__c>> zipMap = ZipQueries.getZipAsgnMap(new set<String>{acct.ShippingPostalCode},false,new set<String>{'PEO'},null);
                        if(zipMap!=null && !zipMap.isEmpty()){
                            Id ownerId = zipMap.get(acct.ShippingPostalCode)[0].User__c;
                            User ownerUser = [SELECT Id,DSA_FSS__c,ManagerId FROM User WHERE Id=:ownerId LIMIT 1];
                            acct.Owner = ownerUser;
                            acct.OwnerId = ownerUser.Id;
                        }
                        else{
                            acct.Use_Zip_Assignment_Rules__c = true;
                            checkAccountOwner = true;
                        }
                    }
                    else{
                        acct.Use_Zip_Assignment_Rules__c = true;
                        checkAccountOwner = true;
                    }                    
                    acct.PEOLeasing__c = true;
                }

                if (mainPhone != null && acct.Phone != mainPhone) {
                    acct.Phone = mainPhone;
                }
                if (payrollProviderPattern.find()) {
                    payrollProvider = payrollProviderPattern.group(1).trim();
                    system.debug('TelereachEmailHandler Payroll Provider: ' + payrollProvider);
                    if (payrollProvider != acct.Current_Prior_Method__c) {
                        acct.Current_Prior_Method__c = payrollProvider;
                    }
                }
                try {
                    DmlHelper.performDML2(new List <Account> {acct}, DmlHelper.DML_UPDATE, 'TelereachEmailHandler', 'handleInboundEmail', 'Update Account', true);
                } catch (exception e) // catch DupeBlocker exception, should never get here
                {
                    Messaging.Singleemailmessage accountErrorMail = forwardEmail('TelereachEmailHandler unable to update account', e.getMessage());
                    throw new TelereachEmailException(e.getMessage());
                }

                Id oppRTId = RecordTypeHelper.getRecordType(sos.OpptyRecordTypeName__c, 'Opportunity').getRecordTypeId();
                opp = new Opportunity();
                opp.RecordTypeId = oppRTId;
                system.debug('TelereachEmailHandler opp rt' + opp.RecordTypeId);
                opp.Name = acct.Name + ' - PEO';
                //if we need to requery owner per use_zip_assignments
                if(checkAccountOwner){
                    Account acctUpdated = [SELECT OwnerId FROM Account WHERE Id=:acct.Id LIMIT 1];
                    opp.OwnerId = acctUpdated.OwnerId;
                }
                else{
                    opp.OwnerId = acct.OwnerId;
                }
                opp.AccountId = acct.Id;
                opp.StageName = sos.ReferralOppFirstStage__c;
                opp.CloseDate = date.today();
                opp.OpportunityType__c = 'PEO';
                opp.Payroll_Platform__c = 'Prism PEO';
                opp.OpportunityType__c = 'PEO';
                opp.NSS_Source__c = 'Telereach';
                opp.LeadSource = 'Purchased List';
                if (ld != null) {
                    opp.List_Type__c = ld.List_Type__c;
                    opp.List_Source__c = ld.List_Source__c;
                }
                else if(acct!=null){
                    opp.List_Type__c = acct.List_Type__c;
                    opp.List_Source__c = acct.List_Source__c;
                }
                if (empCountPattern.find()) {
                    opp.Employees_Paid_Per_Payroll__c = Integer.valueOf(empCountPattern.group(1).trim());
                    system.debug('TelereachEmailHandler Employee Count: ' + opp.Employees_Paid_Per_Payroll__c);
                }
                if (soundFilePattern.find()) {
                    opp.Recording_Link__c = soundFilePattern.group(1).substringBefore('<').trim();
                    system.debug('TelereachEmailHandler Sound File: ' + soundFileURL);
                }
                try {
                    DmlHelper.performDML2(new List <Opportunity>{opp}, DmlHelper.DML_INSERT, 'TelereachEmailHandler', 'handleInboundEmail', 'Insert Opportunity', true);
                } catch (exception e) // catch DupeBlocker exception, should never get here
                {
                    Messaging.Singleemailmessage oppErrorMail = forwardEmail('TelereachEmailHandler bad insert of new opp', e.getMessage());
                    throw new TelereachEmailException(e.getMessage());
                }
                OpportunityContactRole oppContactRole = new OpportunityContactRole();
                oppContactRole.contactId = ctct.Id;
                oppContactRole.isPrimary = true;
                oppContactRole.OpportunityId = opp.Id;
                try {
                    DmlHelper.performDML2(new List<OpportunityContactRole>{oppContactRole}, DmlHelper.DML_INSERT, 'TelereachEmailHandler', 'handleInboundEmail', 'Insert Opp Contact Role', true);
                } catch (exception e) // catch DupeBlocker exception, should never get here
                {
                    Messaging.Singleemailmessage oppCtCtRoleErrorMail = forwardEmail('TelereachEmailHandler bad insert of new opp contact role', e.getMessage());
                    throw new TelereachEmailException(e.getMessage());
                }

                Referral_Partner__c refPart = [SELECT Id, Name FROM Referral_Partner__c WHERE Name = 'PEO' AND NSS_Source__c = 'Telereach' LIMIT 1];

                referral = new Referral__c();
                referral.Selling_Opportunity__c = opp.Id;
                system.debug('TelereachEmailHandler referral selling Opp' + referral.Selling_Opportunity__c);
                referral.Status__c = 'Approved';
                referral.SourceLead__c = (ld != null ? ld.Id : null);
                referral.SourceContact__c = ctct.Id;
                referral.Account__c = acct.Id;
                referral.Referral_Partner__c = (refPart != null ? refPart.Id : null);
                referral.Name = opp.Name + (refPart != null ? '-' + refPart.Name : '');
                referral.Referring_User__c = runningUser.Id;
                referral.User__c = acct.OwnerId;
                referral.DSA__c = acct.Owner.DSA_FSS__c;
                referral.DSM__c = acct.Owner.ManagerId;
                referral.Email__c = runningUser.Email;
                referral.DateLeadSubmitted__c = date.today();
                referral.NotifyOwner__c = true;
                ChatterMessageSend.ONLY_CHAT_AS_LEAD_LOADER = false;
                ChatterMessageSend.notifyOwnerIdSet.add(referral.User__c);
                ChatterMessageSend.notifyOwnerIdSet.add(referral.DSA__c);
                ChatterMessageSend.notifyOwnerIdSet.add(referral.DSM__c);
                try {
                    DmlHelper.performDML2(new List<Referral__c> {referral}, DmlHelper.DML_INSERT, 'TelereachEmailHandler', 'handleInboundEmail', 'Insert Referral', true);
                } catch (exception e) // catch DupeBlocker exception, should never get here
                {
                    Messaging.Singleemailmessage referralErrorMail = forwardEmail('TelereachEmailHandler bad insert of new referral', e.getMessage());
                    throw new TelereachEmailException(e.getMessage());
                }
                system.debug('TelereachEmailHandler referral ID' + referral.Id);

                //create event
                Id evtRTId = RecordTypeHelper.getRecordType(sos.EventRecordTypeName__c, 'Event').getRecordTypeId();
                Event evt;
                if (evtRTId != null) {
                    evt = new Event();
                    evt.RecordTypeId = evtRTId;
                    evt.OwnerId = opp.OwnerId;
                    evt.WhoId = ctct.Id;
                    evt.WhatId = opp.Id;
                    evt.Lead_Source_WAR_Call_Type__c = opp.LeadSource;
                    evt.Type = 'Presentation - Initial';
                    evt.Subject = opp.Name + ' ' + ctct.Name + ' ' + ctct.Phone;
                    evt.IsReminderSet = true;
                    evt.Location = acct.ShippingStreet + '\n' + acct.ShippingCity + ', ' + acct.ShippingState + ' ' + acct.ShippingPostalCode;
                    evt.Description = 'Company Name: ' + acct.Name + '\n';
                    evt.Description += 'Contact Name: ' + ctct.Name + '\n';
                    evt.Description += 'Contact Title: ' + (ctct.Title != null ? ctct.Title : '') + '\n';
                    evt.Description += 'Address: ' + evt.Location + '\n';
                    evt.Description += 'Main Phone Number: ' + (mainPhone != null ? mainPhone : '') + '\n';
                    evt.Description += 'Direct Phone Number: ' + (directPhone != null ? directPhone : '') + '\n';
                    evt.Description += 'Mobile Phone Number: ' + (mobilePhone != null ? mobilePhone : '') + '\n';
                    evt.Description += 'Email: ' + (ctct.Email != null ? ctct.Email : '') + '\n';

                    if (meetingDatePattern.find() && meetingTimePattern.find()) {
                        String meetingDateStr = meetingDatePattern.group(1).trim();
                        String meetingTimeStr = meetingTimePattern.group(1).substringBefore('Time').trim();
                        system.debug('Meeting Date: ' + meetingDateStr);
                        system.debug('Meeting Time: ' + meetingTimeStr);
                        String zipTrimmed = zipAddress.left(5);
                        // 06/19/2019
                        //telereach couldn't give an answer on the format of their DT so this will have to do
                        try {
                            Zip_Code_Information__c zci = [SELECT TimeZoneName__c FROM Zip_Code_Information__c WHERE Name =: zipTrimmed LIMIT 1];
                            Integer month = Integer.valueOf(meetingDateStr.left(2).trim());
                            Integer day = Integer.valueOf(meetingDateStr.substringBetween('/').trim());
                            Integer year = Integer.valueOf(meetingDateStr.right(4).trim());
                            Integer hour = Integer.valueOf(meetingTimeStr.substringBefore(':').trim());
                            Integer minute = Integer.valueOf(meetingTimeStr.substringAfter(':').left(2).trim());
                            if(meetingTimeStr.right(2).trim()=='PM'){
                                hour = hour + 12;
                            }
                            system.debug('month:' + month + ' day:' + day + ' year:' + year + ' hour:' + hour + ' minute:' + minute);
                            Integer clientTZOffsetMilliseconds = Timezone.getTimeZone(zci.TimeZoneName__c).getOffset(date.newInstance(year,month,day));
                            Integer paychexTZOffsetMilliseconds = Timezone.getTimeZone('America/New_York').getOffset(date.newInstance(year,month,day));
                            Integer tzDifference = paychexTZOffsetMilliseconds-clientTZOffsetMilliseconds;
                            DateTime dtPreTimeZone = DateTime.newInstance(year, month, day, hour, minute, 0);
                            Integer hoursToAdd = tzDifference/3600000;
                            system.debug('tzDifference:' + tzDifference+ 'hoursToAdd:' + hoursToAdd+ 'dtPreTimeZone'+dtPreTimeZone);
                            DateTime dtPostTimeZone = dtPreTimeZone.addHours(hoursToAdd);
                            evt.StartDateTime = dtPostTimeZone;
                            evt.DurationInMinutes = 60;
                        } catch (Exception e) {
                            evt.Description += 'Could not determine event time.  Please set this meeting start to: ' + meetingDateStr + ' ' + meetingTimeStr + '.';
                            evt.StartDateTime = DateTime.now();
                            evt.DurationInMinutes = 60;
                        }
                    }
                    try {
                        DmlHelper.performDML2(new List<Event>{evt}, DmlHelper.DML_INSERT, 'TelereachEmailHandler', 'handleInboundEmail', 'Insert Event', true);
                    } catch (exception e) // catch DupeBlocker exception, should never get here
                    {
                        Messaging.Singleemailmessage eventErrorMail = forwardEmail('TelereachEmailHandler bad insert of new event', e.getMessage());
                        throw new TelereachEmailException(e.getMessage());
                    }

                }
            } //if ctct!=null
        } else {
            Throw new TelereachEmailException('Empty Email Body');
        } // if (String.isBlank(myPlainText
        return result;
    } //handleInboundEmail   
    //If this email is sent in as html, strip away all of the tags so we're only left with text related to the email message
    public static string htmlToText(string html) { //replace all <BR> tags with \n to support new lines
        string result = html.replaceAll('<br/>', '\n');
        result = result.replaceAll('<br />', '\n');
        //all HTML/XML tags
        string htmlPattern = '<.*?>';
        Matcher match = Pattern.compile(htmlPattern).matcher(result);
        //remove the tags and return string
        return match.replaceAll('');
    }
    /* method to send incoming email to person listed in custom setting
     */
    public Messaging.Singleemailmessage forwardEmail(String p_subj, String p_body) {
        Messaging.Singleemailmessage mail;
        PaychexSettings__c payxSetting = PaychexSettings__c.getInstance('TelereachForwardErrorEmail');
        if (payxSetting != null && !payxSetting.IsActive__c) {
            payxSetting = null;
        }

        if (payxSetting != null && payxSetting.Attribute1__c != null) {
            mail = new Messaging.Singleemailmessage();
            List <String> addrList = new List <String> ();
            addrList = payxSetting.Attribute1__c.split(';');
            mail.setToAddresses(addrList);
            //mail.setToAddresses (new String[]{payxSetting.Attribute1__c});
            mail.setSubject(p_subj);
            mail.setPlainTextBody(p_body);
            if(!Test.isRunningTest()){
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
            }
            
        } // if
        return mail;
    } // forwardEmail 
}

/*
EXAMPLE:

March 8, 2019

This email is to inform you of an appointment with:
Company Name: TeleReach Corporate
SalesForce ID: TEST SF ID GOES HERE
Contact Name: Client Services
Contact Title: Top Chief
Address: 123 Main St
New City, TX 77055
Main Phone Number: (123) 456 7890
Direct Phone Number: (860) 358 9129
Mobile Phone Number: 
Email: clientservices@telereach.com
Meeting Date: 01/01/2021
Meeting Time: 6: 00 AM Time Zone: Eastern
Original PEO Listed: 
Total Number of Employees: 0
Number of Employees on Benefits: TEST 2
Current PEO if Different: Sheet Metal Machine Model(s) Inserted
PEO Renewal Date: 01/01/1996
Payroll Provider: TEST 3
If the company no longer has a PEO list Medical Provider, Renewal Date, and Payroll Processor in comments below:
Additional Information and Comments: Test Comments Go Here
Script Title:  DO NOT EDIT THIS RECORD!
Market: Market Goes Here
Link to Sound File: 

Regards,


*/