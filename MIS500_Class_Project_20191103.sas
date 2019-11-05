/****************************************************/
/****************************************************/
/*  MIS500 - Week 8 Critical Thinking Excercise     */
/* Author - Jeff Davis                              */
/* Data Sources - 									*/
/*		PBMI Contact List and                	    */
/*		Mail Contact History for 2019        	    */
/*  	Attendance of Webinars and Conferences 		*/
/*													*/
/* Purpose of Project                               */                                                  */
/*                                                  */
/* P1 - Clean and establish categorical variables   */
/*		for the purpose of evaluating which         */
/*		portions of the population have the         */
/*      most interest in Conferences, webinars,     */
/*      or education.                               */
/*                                                  */
/* P2 - Evaluate a series of hypotheses concerning  */
/*		Job Titles, PBMI Membership status, and     */
/*		previous PBMI event attendance and the      */
/*		relationship to opening email marketing		*/
/*		emails for the three PBMI revenue streams:	*/
/*		Conferences, webinars, and education.		*/
/****************************************************/
/****************************************************/

libname MIS500 '/folders/myfolders/MIS500/MIS500_Project';

/****************************************************/
/*	Step 1 - Import PBMI Contact List				*/
/****************************************************/

FILENAME REFFILE '/folders/myfolders/sasuser.v94/PBMI_Contact_LIst_For_Project_20191028.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.PBMI_CONTACT_LIST;
	GETNAMES=YES;
	SHEET="PBMI_Contact_List";
RUN;

/*
 NOTE: The import data set has 18841 observations and 24 variables.
 NOTE: WORK.PBMI_CONTACT_LIST data set was successfully created.
*/

Data WORK.pbmi_contact_list_UPDATED;
	Set WORK.pbmi_contact_list;

New_Domain_Name = substr(email, Index(email, "@")+1, Length(email));
Run;
/*
 NOTE: There were 18841 observations read from the data set WORK.PBMI_CONTACT_LIST.
 NOTE: The data set WORK.PBMI_CONTACT_LIST_UPDATED has 18841 observations and 25 variables.
*/

/****************************************************/
/*	Step 2 - Import Corporate Membership 			*/
/****************************************************/

FILENAME REFFILE '/folders/myfolders/sasuser.v94/Corporate_member_dues_schedule2019ld_Revision.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.PBMI_CORPORTE_MEMBERS;
	GETNAMES=YES;
	SHEET="Member_Listing_by_domain";
RUN;

/*
 NOTE: The import data set has 78 observations and 2 variables.
 NOTE: WORK.PBMI_CORPORTE_MEMBERS data set was successfully created.
*/

/****************************************************/
/*	Step 2A - Sort Corporate Members email nodupkey */
/****************************************************/
Proc Sort nodupkey Data=work.pbmi_corporte_members (Keep = New_Domain_Name) out=work.DISTINCT_EMAIL;
	By New_Domain_Name;
Run;
/*
 NOTE: There were 78 observations read from the data set WORK.PBMI_CORPORTE_MEMBERS.
 NOTE: 0 observations with duplicate key values were deleted.
 NOTE: The data set WORK.DISTINCT_EMAIL has 78 observations and 1 variables.
*/

/****************************************************/
/*	Step 2B - Sort Corporate Members email nodupkey */
/****************************************************/
Proc Sort nodupkey Data=work.pbmi_corporte_members  
	out=work.DISTINCT_Company_Name (rename=Company_Name=CompanyName);
	By Company_Name;
Run;
Proc Print data=work.distinct_company_name;run;
/*
 NOTE: There were 78 observations read from the data set WORK.PBMI_CORPORTE_MEMBERS.
 NOTE: 12 observations with duplicate key values were deleted.
 NOTE: The data set WORK.DISTINCT_COMPANY_NAME has 66 observations and 1 variables.
*/
Proc Sort Data=work.pbmi_contact_list_updated; By New_Domain_Name;run;
/*
 NOTE: There were 18841 observations read from the data set WORK.PBMI_CONTACT_LIST_UPDATED.
 NOTE: The data set WORK.PBMI_CONTACT_LIST_UPDATED has 18841 observations and 25 variables.
*/

/*****************************************************/
/*	Step 3 - Add Corporate Member Indicator by email */
/*****************************************************/

/*****************************************************/
/*	Step 3A - Add Corporate Member by Domain		 */
/*****************************************************/
data WORK.pbmi_contact_list_CORP1;
   merge WORK.pbmi_contact_list_UPDATED (IN=A) work.DISTINCT_EMAIL (IN=B);
   by New_Domain_Name;
   
If A and Not B then CORP1 = 0; Else CORP1 = 1;
If email = ' ' then delete;
if email = 'dgawle@follett.com' and FirstName = ' ' then delete;

run;
/*
 NOTE: There were 18841 observations read from the data set WORK.PBMI_CONTACT_LIST_UPDATED.
 NOTE: There were 78 observations read from the data set WORK.DISTINCT_EMAIL.
 NOTE: The data set WORK.PBMI_CONTACT_LIST_CORP1 has 18840 observations and 26 variables.
 NOTE: DATA statement used (Total process time):
*/
/*
Find Duplicates
Proc FREQ Data=work.pbmi_contact_list_corp1 ; Tables CORP1;Run;
Proc Print Data=WORK.pbmi_contact_list_CORP1 (OBS=20) ;run;
Proc Sort Data=work.pbmi_contact_list_corp1; by email;run;
Data Test;
	Set work.pbmi_contact_list_corp1;
	By email;
IF first.email and not last.email then output;
If last.email and not first.email then output;
Run;
Proc Print Data=work.test;run;
*/

/*****************************************************/
/*	Step 3A - Add Corporate Member by Domain		 */
/*****************************************************/

Proc Sort Data=WORK.pbmi_contact_list_CORP1; By CompanyName;run;

data WORK.pbmi_contact_list_CORP2;
   merge WORK.pbmi_contact_list_CORP1 (IN=A) work.DISTINCT_Company_Name (IN=B);
   by CompanyName;
   
If A and Not B then CORP2 = 0; Else CORP2 = 1;

If CORP1 = 1 or Corp2 = 1 then CORPORATE_PBMI_MEMBER = 1; Else CORPORATE_PBMI_MEMBER =0;
run;
/*
 NOTE: There were 18840 observations read from the data set WORK.PBMI_CONTACT_LIST_CORP1.
 NOTE: There were 66 observations read from the data set WORK.DISTINCT_COMPANY_NAME.
 NOTE: The data set WORK.PBMI_CONTACT_LIST_CORP2 has 18840 observations and 28 variables.
*/

/* Permanent Dataset for Corporate */

Data MIS500.pbmi_contact_list_corp (Drop= CORP1 CORP2);
	Set work.pbmi_contact_list_corp2;
	If From_Marketing_Mailing_List =  . then delete; 
run;
Proc Print Data=MIS500.pbmi_contact_list_corp (OBS=10);run;

Title 'PBMI Complete Contact List With Mailing List Indicator';
Proc FREQ Data=MIS500.pbmi_contact_list_corp ; 
	Tables From_Marketing_Mailing_List CORPORATE_PBMI_MEMBER;
Run;

Proc Print Data=MIS500.pbmi_contact_list_corp; 
	where  From_Marketing_Mailing_List =  .;run;
	

/****************************************************/
/*	Step 3B - Import Individual Membership 			*/
/****************************************************/

FILENAME REFFILE '/folders/myfolders/sasuser.v94/Individual_Members_20191028.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.PBMI_Individual_MEMBERS;
	GETNAMES=YES;
	SHEET="Sheet1";
RUN;

/*
 NOTE: The import data set has 161 observations and 4 variables.
 NOTE: WORK.PBMI_INDIVIDUAL_MEMBERS data set was successfully created.
*/	

Proc Sort Data=work.PBMI_Individual_MEMBERS nodupkey; By Email;Run;	
Proc Sort Data=MIS500.pbmi_contact_list_corp NodupKey out=Test; By Email;Run;


data MIS500.PBMI_Contact_list_Memb;
   merge MIS500.pbmi_contact_list_corp (IN=A) work.PBMI_Individual_MEMBERS (IN=B);
   by Email;
   
If A and Not B then Individual_PBMI_Member = 0; Else Individual_PBMI_Member = 1;

If CORPORATE_PBMI_MEMBER = 1 or Individual_PBMI_Member = 1 then PBMI_MEMBER = 1; Else PBMI_MEMBER = 0;

If A then output;
run;
/*
 NOTE: There were 18840 observations read from the data set MIS500.PBMI_CONTACT_LIST_CORP.
 NOTE: There were 161 observations read from the data set WORK.PBMI_INDIVIDUAL_MEMBERS.
 NOTE: The data set MIS500.PBMI_CONTACT_LIST_MEMB has 18926 observations and 31 variables.
*/
Proc Freq Data=mis500.PBMI_Contact_list_Memb; Tables PBMI_Member Corporate_PBMI_Member Individual_PBMI_Member; Run;

/*****************************************************/
/*	Step 4 - Add MArketing Mailing Details			 */
/*****************************************************/


FILENAME REFFILE '/folders/myfolders/sasuser.v94/201901_Mailings_By_Type_and_Date_20191011.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.January_2019_Mailings;
	GETNAMES=YES;
	SHEET="Sheet1";
RUN;
/*
 NOTE: The import data set has 64092 observations and 31 variables.
 NOTE: WORK.JANUARY_2019_MAILINGS data set was successfully created.
*/
Proc Freq Data=January_2019_Mailings; Tables Email_Type;run;
Proc Print Data=January_2019_Mailings (OBS=20);run;
FILENAME REFFILE '/folders/myfolders/sasuser.v94/201902_Mailings_By_Type_and_Date_20191011.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.February_2019_Mailings;
	GETNAMES=YES;
	SHEET="Mailings";
RUN;
/*
 NOTE: The import data set has 50218 observations and 31 variables.
 NOTE: WORK.FEBRUARY_2019_MAILINGS data set was successfully created.
*/

FILENAME REFFILE '/folders/myfolders/sasuser.v94/201903_Mailings_By_Type_and_Date_20191011.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.March_2019_Mailings;
	GETNAMES=YES;
	SHEET="Mailings";
RUN;
/*
 NOTE: The import data set has 62821 observations and 31 variables.
 NOTE: WORK.MARCH_2019_MAILINGS data set was successfully created.
*/

FILENAME REFFILE '/folders/myfolders/sasuser.v94/201904_Mailings_By_Type_and_Date_20191011.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.April_2019_Mailings;
	GETNAMES=YES;
	SHEET="Mailings";
RUN;
/*
 NOTE: The import data set has 62812 observations and 31 variables.
 NOTE: WORK.APRIL_2019_MAILINGS data set was successfully created.
*/

FILENAME REFFILE '/folders/myfolders/sasuser.v94/201905_06_Mailings_By_Type_and_Date_20191011.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.May_June_2019_Mailings;
	GETNAMES=YES;
	SHEET="Mailings";
RUN;
/*
 NOTE: The import data set has 62800 observations and 31 variables.
 NOTE: WORK.MAY_JUNE_2019_MAILINGS data set was successfully created.
*/

FILENAME REFFILE '/folders/myfolders/sasuser.v94/201907_08_Mailings_By_Type_and_Date_20191011.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.July_August_2019_Mailings;
	GETNAMES=YES;
	SHEET="Mailings";
RUN;
/*
 NOTE: The import data set has 62783 observations and 31 variables.
 NOTE: WORK.JULY_AUGUST_2019_MAILINGS data set was successfully created.
*/


FILENAME REFFILE '/folders/myfolders/sasuser.v94/201907_09_Mailings_By_Type_and_Date_20191011.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.September_2019_Mailings;
	GETNAMES=YES;
	SHEET="Mailings";
RUN;
/*
 NOTE: The import data set has 62770 observations and 31 variables.
 NOTE: WORK.SEPTEMBER_2019_MAILINGS data set was successfully created.
*/

Proc Print Data=work.september_2019_mailings (Obs=10);run;
Data MIS500.PBMI_Mailings (Keep = Email_Type Email_Date Email_Name 
	subscriberid email fname lname fullname Date_Opened opens clicks 
	unsubscribes bounces neither link status diagnostic_code recip 
	prefix suffix business address1 address2 city state zip phone 
	fax code member);
	Set WORK.January_2019_Mailings
		WORK.February_2019_Mailings
		WORK.March_2019_Mailings
		WORK.April_2019_Mailings
		WORK.May_June_2019_Mailings
		WORK.July_August_2019_Mailings
		September_2019_mailings ;
	If Email_Type = ' ' then delete;
run;
 
/*
 NOTE: There were 64092 observations read from the data set WORK.JANUARY_2019_MAILINGS.
 NOTE: There were 50218 observations read from the data set WORK.FEBRUARY_2019_MAILINGS.
 NOTE: There were 62821 observations read from the data set WORK.MARCH_2019_MAILINGS.
 NOTE: There were 62812 observations read from the data set WORK.APRIL_2019_MAILINGS.
 NOTE: There were 62800 observations read from the data set WORK.MAY_JUNE_2019_MAILINGS.
 NOTE: There were 62783 observations read from the data set WORK.JULY_AUGUST_2019_MAILINGS.
 NOTE: There were 62770 observations read from the data set WORK.SEPTEMBER_2019_MAILINGS.
 NOTE: The data set MIS500.PBMI_MAILINGS has 346747 observations and 30 variables.
 NOTE: DATA statement used (Total process time):
*/

Proc Print Data=MIS500.pbmi_contact_list_memb (Obs=30);run;

Proc Freq Data=MIS500.pbmi_contact_list_memb; Tables Last_Mailing_Open_Date;run;


/*****************************************************/
/*	Step 5 - Import Conference Attendees			 */
/*****************************************************/


FILENAME REFFILE '/folders/myfolders/sasuser.v94/Conference_Attendees_20191028.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.Conference_Attendance_2017_2019;
	GETNAMES=YES;
	SHEET="Sheet1";
RUN;
/*
 NOTE: The import data set has 1034 observations and 9 variables.
 NOTE: WORK.CONFERENCE_ATTENDANCE_2017_2019 data set was successfully created.
*/
Proc Print Data=work.conference_attendance_2017_2019 (OBS=10);run;

Proc Sort Data=work.conference_attendance_2017_2019; By Email;run;

Data Conference_By_Year (Keep=email Conferences_Attended
		Conference_Count_2017 Conference_Count_2018 Conference_Count_2019
		Conference_Attendee_2017 Conference_Attendee_2018 Conference_Attendee_2019);
	Set work.conference_attendance_2017_2019;
	By Email;

If First.email then do;
	Conference_Count_2017 = 0;
	Conference_Count_2018 = 0;
	Conference_Count_2019 = 0;
	Conference_Attendee_2017 = 0;
	Conference_Attendee_2018 = 0;
	Conference_Attendee_2019 = 0;	
	Conferences_Attended = 0;
End;
If Event_Year = 2017 then Conference_Count_2017 = Conference_Count_2017 + 1; 
If Event_Year = 2018 then Conference_Count_2018 = Conference_Count_2018 + 1; 
If Event_Year = 2019 then Conference_Count_2019 = Conference_Count_2019 + 1; 


If last.email then do;
	If Conference_Count_2017 = 0 Then Conference_Attendee_2017 = 0; Else Conference_Attendee_2017 = 1;
	If Conference_Count_2018 = 0 Then Conference_Attendee_2018 = 0; Else Conference_Attendee_2018 = 1;
	if Conference_Count_2019 = 0 Then Conference_Attendee_2019 = 0; Else Conference_Attendee_2019 = 1;
	Conferences_Attended = Conference_Attendee_2017 + Conference_Attendee_2018 + Conference_Attendee_2019;
	output;
End;
Retain 	Conferences_Attended Conference_Count_2017 Conference_Count_2018 Conference_Count_2019	
		Conference_Attendee_2017 Conference_Attendee_2018 Conference_Attendee_2019	;
run;
/*
 NOTE: There were 1034 observations read from the data set WORK.CONFERENCE_ATTENDANCE_2017_2019.
 NOTE: The data set WORK.CONFERENCE_BY_YEAR has 801 observations and 8 variables.
*/

Proc Print Data=work.conference_by_year (OBS=500);run;

Proc Sort Data=mis500.pbmi_contact_list_memb; By email; run;


Data mis500.pbmi_contact_list_Conference;
	Merge mis500.pbmi_contact_list_memb (In=A) work.conference_by_year (IN=B);
	By Email;
	
If Conference_Count_2017 = . then Conference_Count_2017 = 0;
If Conference_Count_2018 = . then Conference_Count_2018 = 0;
If Conference_Count_2019 = . then Conference_Count_2019 = 0;
If Conference_Attendee_2017 = . then Conference_Attendee_2017 = 0;
If Conference_Attendee_2018 = . then Conference_Attendee_2018 = 0;
If Conference_Attendee_2019 = . then Conference_Attendee_2019 = 0;	
If Conferences_Attended = . then Conferences_Attended = 0;	

If A then output;

run;
/*
 NOTE: There were 18840 observations read from the data set MIS500.PBMI_CONTACT_LIST_MEMB.
 NOTE: There were 801 observations read from the data set WORK.CONFERENCE_BY_YEAR.
 NOTE: The data set MIS500.PBMI_CONTACT_LIST_CONFERENCE has 18840 observations and 38 variables.
*/



/*****************************************************/
/*	Step 6 - Import Webinar Attendees				 */
/*****************************************************/


FILENAME REFFILE '/folders/myfolders/sasuser.v94/Webinar_Attendance_Registration_20191028.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.Webinar_Attendance_2018_2019;
	GETNAMES=YES;
	SHEET="Sheet1";
RUN;
/*
 NOTE: The import data set has 6087 observations and 39 variables.
 NOTE: WORK.WEBINAR_ATTENDANCE_2018_2019 data set was successfully created.
*/

Proc Print Data=work.Webinar_Attendance_2018_2019 (OBS=10);run;

Proc Sort Data=work.Webinar_Attendance_2018_2019; By Email;run;

Data Webinar_By_Year (Keep=email Webinars_Attended Webinar_Count_2018 Webinar_Count_2019);
	Set work.Webinar_Attendance_2018_2019;
	By Email;

If First.email then do;
	Webinar_Count_2018 = 0;
	Webinar_Count_2019 = 0;
	Webinars_Attended = 0;
End;
If Year(Webminar_Date) = 2018 then Webinar_Count_2018 = Webinar_Count_2018 + 1; 
If Year(Webminar_Date) = 2019 then Webinar_Count_2019 = Webinar_Count_2019 + 1; 


If last.email then do;
	If Webinar_Count_2018 = 0 Then Webinar_Attendee_2018 = 0; Else Webinar_Attendee_2018 = 1;
	if Webinar_Count_2019 = 0 Then Webinar_Attendee_2019 = 0; Else Webinar_Attendee_2019 = 1;
	Webinars_Attended = Webinar_Attendee_2018 + Webinar_Attendee_2019;
	output;
End;
Retain 	Webinars_Attended Webinar_Count_2018 Webinar_Count_2019	;

run;
/*
 NOTE: There were 6087 observations read from the data set WORK.WEBINAR_ATTENDANCE_2018_2019.
 NOTE: The data set WORK.WEBINAR_BY_YEAR has 3081 observations and 4 variables.
*/

Proc Print Data=work.WEBINAR_BY_YEAR (OBS=500);run;

Proc Sort Data=mis500.pbmi_contact_list_Conference; By email; run;


Data mis500.pbmi_contact_list_Webinar;
	Merge mis500.pbmi_contact_list_Conference (In=A) work.WEBINAR_BY_YEAR (IN=B);
	By Email;
	
If WEBINAR_Count_2018 = . then WEBINAR_Count_2018 = 0;
If WEBINAR_Count_2019 = . then WEBINAR_Count_2019 = 0;
If WEBINARS_Attended = . then WEBINARS_Attended = 0;	

If A then output;

run;
/*
 NOTE: There were 18840 observations read from the data set MIS500.PBMI_CONTACT_LIST_CONFERENCE.
 NOTE: There were 3081 observations read from the data set WORK.WEBINAR_BY_YEAR.
 NOTE: The data set MIS500.PBMI_CONTACT_LIST_WEBINAR has 18840 observations and 41 variables.
*/

Proc Freq Data=MIS500.PBMI_CONTACT_LIST_WEBINAR; Tables Webinars_Attended;run;


/*****************************************************/
/*	Step 7 - Add Open Indicators From Mailings		 */
/*****************************************************/

Proc Print Data=MIS500.PBMI_Mailings (Obs=10);run;

Proc Freq Data=MIS500.PBMI_Mailings; Tables Email_Type;run;

Proc Sort Data=MIS500.PBMI_Mailings nodupkey out=Distinct_Openings (Keep = Email Email_Date Email_Type opens);
	by Email Email_Date Email_Type opens ;
	Where Opens = 1;
run;
/*
 NOTE: There were 78119 observations read from the data set MIS500.PBMI_MAILINGS.
       WHERE Opens=1;
 NOTE: 46422 observations with duplicate key values were deleted.
 NOTE: The data set WORK.DISTINCT_OPENINGS has 31697 observations and 4 variables.
*/


Data Open_Counts (Keep = Email Conference_Open_Count Education_Open_Count Webinar_Open_Count All_Open);
	Set MIS500.PBMI_Mailings;
	by Email;

If First.email then do;
	Conference_Open_Count = 0;
	Webinar_Open_Count = 0;
	Education_Open_Count = 0;
	All_Open = 0;
End;
If Email_Type = 'Conference' and opens = 1 then Conference_Open_Count = Conference_Open_Count + 1; 
If Email_Type = 'Education' and opens = 1 then Education_Open_Count = Education_Open_Count + 1; 
If Email_Type = 'Webinar' and opens = 1 then Webinar_Open_Count = Webinar_Open_Count + 1; 
If opens = 1 then All_Open = All_Open + 1; 


If last.email then output;

Retain 	Conference_Open_Count Education_Open_Count Webinar_Open_Count All_Open;


run;
/*
 NOTE: There were 346747 observations read from the data set MIS500.PBMI_MAILINGS.
 NOTE: The data set WORK.OPEN_COUNTS has 10325 observations and 5 variables.
*/


Data mis500.pbmi_contact_list_With_Open;
	Merge mis500.pbmi_contact_list_Webinar (In=A) work.OPEN_COUNTS (IN=B);
	By Email;
	
If Conference_Open_Count = . then Conference_Open_Count = 0;
If Education_Open_Count = . then Education_Open_Count = 0;
If All_Open = . then All_Open = 0;	

If A then output;

run;
/*
 NOTE: There were 18840 observations read from the data set MIS500.PBMI_CONTACT_LIST_WEBINAR.
 NOTE: There were 10325 observations read from the data set WORK.OPEN_COUNTS.
 NOTE: The data set MIS500.PBMI_CONTACT_LIST_WITH_OPEN has 18840 observations and 45 variables.
*/


/*****************************************************/
/*	Step 8 - Add Removal Indicators From Mailings	 */
/*****************************************************/

Proc Print Data=MIS500.PBMI_Mailings (Obs=10);run;

Proc Freq Data=MIS500.PBMI_Mailings; Tables unsubscribes bounces;run;

Proc Sort Data=MIS500.PBMI_Mailings nodupkey out=Distinct_Bounces (Keep = Email);
	by Email  ;
	Where bounces = 1;
run;
/*
 NOTE: There were 960 observations read from the data set MIS500.PBMI_MAILINGS.
       WHERE bounces=1;
 NOTE: 451 observations with duplicate key values were deleted.
 NOTE: The data set WORK.DISTINCT_BOUNCES has 509 observations and 1 variables.
*/

Proc Sort Data=MIS500.PBMI_Mailings nodupkey out=Distinct_unsubscribes (Keep = Email);
	by Email  ;
	Where unsubscribes = 1;
run;
/*
 NOTE: There were 260 observations read from the data set MIS500.PBMI_MAILINGS.
       WHERE unsubscribes=1;
 NOTE: 26 observations with duplicate key values were deleted.
 NOTE: The data set WORK.DISTINCT_UNSUBSCRIBES has 234 observations and 1 variables.
*/


Data mis500.pbmi_contact_list_With_Unsub;
	Merge mis500.pbmi_contact_list_With_Open (In=A) 
		work.Distinct_unsubscribes (IN=B)
		work.Distinct_bounces (IN=C);
	By Email;
	
If A and B then  email_Unsubscribes = 1; Else Email_Unsubscribes = 0;
If A and C then  email_Bounces = 1; Else email_Bounces = 0;

If A then output;

run;
/*
 NOTE: There were 18840 observations read from the data set MIS500.PBMI_CONTACT_LIST_WITH_OPEN.
 NOTE: There were 234 observations read from the data set WORK.DISTINCT_UNSUBSCRIBES.
 NOTE: There were 509 observations read from the data set WORK.DISTINCT_BOUNCES.
 NOTE: The data set MIS500.PBMI_CONTACT_LIST_WITH_UNSUB has 18840 observations and 47 variables.
*/

Proc Freq Data=mis500.pbmi_contact_list_With_Unsub; Tables email_unsubscribes email_bounces;run;

Proc Freq Data=work.open_counts; Tables Conference_Open_Count Education_Open_Count Webinar_Open_Count All_Open; run;

/*****************************************************/
/*	Step 9 - Add Job Titles							 */
/*****************************************************/


FILENAME REFFILE '/folders/myfolders/sasuser.v94/Job_Titles_By_Email_20191103.xlsx';


PROC IMPORT DATAFILE=REFFILE
	DBMS=XLSX
	OUT=WORK.Job_Titles;
	GETNAMES=YES;
	SHEET="Sheet1";
RUN;
/*
 NOTE: The import data set has 3563 observations and 2 variables.
 NOTE: WORK.JOB_TITLES data set was successfully created.
*/

Proc Print Data=work.Job_Titles (OBS=10);run;
Proc Freq Data=work.Job_Titles ;Tables New_Job_Title;run;

Proc Sort Data=work.Job_Titles; By Email;run;

Data mis500.pbmi_contact_list_With_Title;
	Merge mis500.pbmi_contact_list_With_Unsub (In=A) 
		work.Job_Titles (IN=B);
	By Email;

If New_Job_Title IN ('Vice President', 'Senior Director', 'OWNER / Partner / Founder / Principal',
	'Director', 'Chief or President', 'Account Executive') Then DIRECTOR_ABOVE = 1; Else DIRECTOR_ABOVE = 0;
	

If A then output;

run;
/*
 NOTE: There were 18840 observations read from the data set MIS500.PBMI_CONTACT_LIST_WITH_UNSUB.
 NOTE: There were 3563 observations read from the data set WORK.JOB_TITLES.
 NOTE: The data set MIS500.PBMI_CONTACT_LIST_WITH_TITLE has 18840 observations and 49 variables.
*/
Proc Freq Data=MIS500.PBMI_CONTACT_LIST_WITH_TITLE ;Tables Last_Mailing_Open_Date;run;



/*****************************************************/
/*	Step 10 - REmove Non-Marketing Bounce and opt out */
/*****************************************************/

Data Excluded;
	Set MIS500.PBMI_CONTACT_LIST_WITH_TITLE;
IF Include = 'Bounced' or Unsubscribed_Mailing_List = 1 or Email_Bounced = 1 or 
	email_Unsubscribes = 1 or email_Bounces = 1 or From_Marketing_Mailing_List = 0 then output;
run;

/*
 NOTE: There were 18840 observations read from the data set MIS500.PBMI_CONTACT_LIST_WITH_TITLE.
 NOTE: The data set WORK.EXCLUDED has 11570 observations and 49 variables.
 */
Data MIS500.PBMI_CONTACT_LIST_Include (Keep= Email From_Marketing_Mailing_List New_Domain_Name 
		CORPORATE_PBMI_MEMBER Organization Individual_PBMI_Member PBMI_MEMBER 
		Conference_Count_2017 Conference_Count_2018 Conference_Count_2019 
		Conference_Attendee_2017 Conference_Attendee_2018 Conference_Attendee_2019 Conferences_Attended	
		Webinar_Count_2018 Webinar_Count_2019 Webinars_Attended 
		Conference_Open_Count Webinar_Open_Count Education_Open_Count All_Open 
		New_Job_Title DIRECTOR_ABOVE);
	Set MIS500.PBMI_CONTACT_LIST_WITH_TITLE;
IF Include = 'Bounced' or Unsubscribed_Mailing_List = 1 or Email_Bounced = 1 or 
	email_Unsubscribes = 1 or email_Bounces = 1 or From_Marketing_Mailing_List = 0 then delete;
	
run;
/*
 NOTE: There were 18840 observations read from the data set MIS500.PBMI_CONTACT_LIST_WITH_TITLE.
 NOTE: The data set MIS500.PBMI_CONTACT_LIST_INCLUDE has 7270 observations and 23 variables.
 */
Title 'PBMI Job Title Rollup';
Proc Freq Data=MIS500.PBMI_CONTACT_LIST_INCLUDE ;Tables New_Job_Title;run;

Proc Freq Data=MIS500.PBMI_CONTACT_LIST_INCLUDE ;Tables DIRECTOR_ABOVE;run;



Proc Print Data=MIS500.PBMI_CONTACT_LIST_WITH_TITLE (Obs=200);run;


/*****************************************************/
/*	Step 11 - Model for Director and Above T Test	 */
/*****************************************************/
Title 'Director and Above - Open Conference Email Evaluation';
Proc Ttest Data=MIS500.PBMI_CONTACT_LIST_INCLUDE;
	Class Director_Above ;
	Var Conference_Open_Count ;
run;






