/**
* ----------------------------------------------------------------------------
* Class to generate JSON and use as request body for Huckleberry.
* -----------------------------------------------------------------------------
* History
* 01-11-2024   Vinay   Initial Version.
* ----------------------------------------------------------------------------
*/
public without sharing class HuckleberryJSONController {
    public class Agency {
		public String user_name;
	}

	public Sfdc_request_header sfdc_request_header;
	public List<String> lines_of_business;
	public String company_name;
	public String fein;
	public String first_name;
	public String last_name;
	public String email;
	public String start_date;
	public String phone;
	public Billing_location billing_location;
	public Integer full_time_employees;

	public class Sfdc_request_header {
		public String request_id;
		public String request_date;
		public Agency agency;
	}

	public class Billing_location {
		public String zip;
		public String city;
		public String line1;
		public String line2;
		public String state;
		public String formatted_address;
	}
}