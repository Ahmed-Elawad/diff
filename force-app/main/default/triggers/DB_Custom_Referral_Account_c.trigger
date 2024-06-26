/*
 09/11/2023 Dan Carmen          Comment out code

*/
trigger DB_Custom_Referral_Account_c on Referral_Account__c ( before delete, after insert, after update, after undelete )
{
    /*
    try
    {
        if ( Test.isRunningTest() && CRMfusionDBR101.DB_Globals.generateCustomTriggerException )
        {
            throw new CRMfusionDBR101.DB_Globals.TestException( 'Test exception.');
        }
        else if ( trigger.isAfter && ( trigger.isInsert || trigger.isUpdate || trigger.isUndelete ) )
        {
            CRMfusionDBR101.DB_TriggerHandler.processAfterInsertUpdateUndelete( trigger.New, trigger.Old, trigger.isInsert,
                trigger.isUpdate, trigger.isUndelete );
        }
        else if ( trigger.isBefore && trigger.isDelete )
        {
            CRMfusionDBR101.DB_TriggerHandler.processBeforeDelete( trigger.Old );
        }
    }
    catch ( Exception ex )
    {
        CRMfusionDBR101.DB_TriggerHandler.handleTriggerException( ex, 'DB_Custom_Referral_Account_c' );
    }
    */
}