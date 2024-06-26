public with sharing class EventAttendeeSearchAuraService {
    private static UserDAInterface userDataAccessor = new UserDA();
    public static UserDAInterface UserDADI {
        get {
            return userDataAccessor;
        }
        set {
            userDataAccessor = value;
        }
    }

    private static EventDAInterface eventDataAccessor = new EventDA();
    public static EventDAInterface EventDADI {
        get {
            return eventDataAccessor;
        }
        set {
            eventDataAccessor = value;
        }
    }

    @AuraEnabled
    public static List<User> getAllActiveUsers(String searchParam) {
        try {
            if (searchParam != null) {
                return UserDADI.getAllActiveUsersByNameSearch(searchParam);
            } else {
                return UserDADI.getAllActiveUsers();
            }
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new AuraHandledException('An error occurred while retrieving users, please refresh and try again');
        }
    }

    @AuraEnabled
    public static void inviteAttendees(Id evtId, List<User> attendeeUsers) {
        try {
            String currentUserName = UserInfo.getName();
            String currentUserEmail = UserInfo.getUserEmail();
            Event originalEvent = EventDADI.getEventByEventId(evtId);
            List<Event> clonedEvents = new List<Event>();
            System.debug('attendee users ' + attendeeUsers);
            List<Messaging.SingleEmailMessage> outgoingEmails = new List<Messaging.SingleEmailMessage>();

            EmailTemplate template = [SELECT Id, Body, HtmlValue, Markup FROM EmailTemplate WHERE Name = 'Add Attendee Notification'];
            System.debug('email template id: ' + template.Id);

            for (User attendee : attendeeUsers) {
                Event clonedEvent = originalEvent.clone(false, false, false, false);
                clonedEvent.OwnerId = attendee.Id;
                clonedEvent.ReminderDateTime = clonedEvent.StartDateTime.addMinutes(-30);
                clonedEvent.Type = originalEvent.Type;
                clonedEvents.add(clonedEvent);

                if (attendee.SenderEmail != null) {
                    outgoingEmails.add(getNewAttendeeEmail(clonedEvent, currentUserName, originalEvent, attendee, template, currentUserEmail));
                }
            }
            insert clonedEvents;

            Messaging.sendEmail(outgoingEmails);


        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw new AuraHandledException('An error occurred while adding invitees.  Please refresh and try again');
        }
    }

    private static Messaging.SingleEmailMessage getNewAttendeeEmail(Event clonedEvent, String currentUserName, Event originalEvent, User attendee, EmailTemplate template, String currentUserEmail) {
        Map<String, String> replacementMap = new Map<String, String>();
        replacementMap.put('eventDate', String.valueOfGmt(clonedEvent.ActivityDate));
        replacementMap.put('eventSubject', clonedEvent.Subject);
        replacementMap.put('requestor', currentUserName);
        replacementMap.put('eventLink', Url.getSalesforceBaseUrl().toExternalForm() + '/lightning/r/Event/' + originalEvent.Id);

        // send email to added attendees
        Messaging.SingleEmailMessage newAttendeeEmail = new Messaging.SingleEmailMessage();

        newAttendeeEmail.setTemplateId(template.Id);

        List<String> sendTo = new List<String>();
        sendTo.add(attendee.SenderEmail);
//        sendTo.add('mheim@acumensolutions.com');
        newAttendeeEmail.setToAddresses(sendTo);

        newAttendeeEmail.setReplyTo(currentUserEmail);
        newAttendeeEmail.setSenderDisplayName(currentUserName);

        newAttendeeEmail.setSubject('Testing Add Attendee');
        String body = getEmailBody(template.HtmlValue, replacementMap);

        newAttendeeEmail.setHtmlBody(body);

        return newAttendeeEmail;
    }
    private static String getEmailBody(String emailBody, Map<String, String> replacementMap) {
        MergeFieldBinder emailBinder = new MergeFieldBinder(emailBody);
        String returnBody = emailBinder.replaceMergeFields(replacementMap);
        return returnBody;
    }
}