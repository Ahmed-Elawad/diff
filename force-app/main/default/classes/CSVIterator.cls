/**
* This is part of several classes that work together to process email attachments and insert records into Salesforce.
* This is an iterator class that parses out chunks of data from the CSV to be processed in the batch process.
* Created Justin Stouffer 8/19/2015
* 11/02/2016 Justin Stouffer Updated CSVIterator to handle line splitting more efficiently.
*/
global with sharing class CSVIterator implements Iterator<String>, Iterable<String>
{
    private String m_CSVData;
    private String m_introValue;
    private integer m_introValueLength;
    public CSVIterator(String fileData, String introValue)
    {
        m_introValue = introValue;
        m_CSVData = fileData;
        m_introValueLength = m_introValue.length();
    }
    global Boolean hasNext()
    {
        return m_CSVData.length() > 1 ? true : false;
    }
    global String next()
    {
        integer m_introValuePos = m_CSVData.indexOf(m_introValue);
        while(math.mod(m_CSVData.subString(0, m_introValuePos).countMatches('"'),2)!=0){
            m_introValuePos = m_CSVData.indexOf(m_introValue, m_introValuePos + m_introValuelength);           
        }
        String row = m_CSVData.subString(0, m_introValuePos);
        m_CSVData = m_CSVData.subString(m_introValuePos + m_introValue.length());     
        //String row = m_CSVData.subString(0, m_CSVData.indexOf(m_introValue));
        //m_CSVData = m_CSVData.subString(m_CSVData.indexOf(m_introValue) + m_introValuelength,m_CSVData.length());
        return row;
    }
    global Iterator<String> Iterator()
    {
        return this;   
    }
}