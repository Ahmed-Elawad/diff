public with sharing class EventDA implements EventDAInterface {
    public Event getEventByEventId(Id eventId) {
        try {
            Event returnEvent = new Event();

            returnEvent = [
                    SELECT Id,
                            ClientGuid,
                            ActivityDate,
                            Description,
                            DurationInMinutes,
                            EndDateTime,
                            RecordTypeId,
                            EventSubtype,
                            IsException,
                            Location,
                            WhoId,
                            IsPrivate,
                            IsVisibleInSelfService,
                            WhatId,
                            IsReminderSet,
                            ShowAs,
                            StartDateTime,
                            Subject,
                            ActivityDateTime,
                            Type,
                            ReminderDateTime
                    FROM Event
                    WHERE Id = :eventId
            ];

            return returnEvent;
        } catch (Exception ex) {
            System.debug(ex.getMessage());
            throw ex;
        }
    }

}