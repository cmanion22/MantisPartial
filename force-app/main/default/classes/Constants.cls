public class Constants 
{     
    //API URLs
    // public static final string apiURL = 'http://5bd29df9.ngrok.io/api/esb/LogData';
    public static final string baseApiURL = 'https://staging.energymarketexchange.com'; 
    public static final string apiURL = baseApiUrl + '/salesforce/esb?api_token=7e015b4b-d36b-4c41-bc98-0fc9b9ba64b3'; 

    //Job Retry settings
    public static final String jobPrefix = 'SendJsonToESB@';  
    public static final List<Integer> retryScheduleInMinutes = new List<Integer>{ 1, 5, 10 };
    public static boolean jobRetryEnabled = false;    
    public static final String[] toAddresses = new String[] {   'neh.gupta@cygrp.com', 
                                                                'rahul.arora@cygrp.com',
                                                                'carolyn.campbell@cygrp.com',
                                                                'hinson.j@emexllc.com',
                                                                'page.c@emexllc.com'};
    public static boolean syncDataEnabled = false;
}