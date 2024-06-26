/* 
 * A batch job for updating accounts, contacts and leads.
 *
 * History
 * -------
 * 11/24/2009 Dan Carmen   Created
 * 07/12/2010 Dan Carmen   Added checks for reaching limits.
 * 09/01/2010 Dan Carmen   Added HNB owner fields
   07/11/2011 Dan Carmen   Modify process to update all ownership fields at once.
   08/04/2011 Dan Carmen   Changed update to Database.update call
   02/22/2012 Dan Carmen   Added extra rows when checking for Account DML limits.
   10/26/2018 Dan Carmen   Increment API to version 44

 */
global class NSSZipBatch  {



} // class NSSZipBatch