
/*******************************************************************
Tear Down script for preparing a fresh working area
********************************************************************/

DROP TABLE IF EXISTS STAGING_HR_RAW;

DROP TABLE IF EXISTS EMPLOYMENT_HISTORY;

DROP TABLE IF EXISTS JOB;

DROP TABLE IF EXISTS LOCATION;

DROP TABLE IF EXISTS DEPARTMENT;

DROP TABLE IF EXISTS SALARY;

DROP TABLE IF EXISTS ADDRESS;

DROP TABLE IF EXISTS EMPLOYEE;

DROP TABLE IF EXISTS EDUCATION;

DROP VIEW IF EXISTS excel_extract;

DROP PROCEDURE IF EXISTS f_RETURN_EMPLOYEE_HIST;
/*******************************************************************
Staging Set up and insert script to set up to ingest source data from file
********************************************************************/

-- create stage table to store raw HR Excel data
CREATE TABLE IF NOT EXISTS STAGING_HR_RAW (
emp_id varchar(10),	
emp_nm varchar(200),	
email varchar(200),	
hire_dt date,	
job_title varchar(50),	
salary Money,	
department varchar(50),	
manager varchar(200),	
start_dt date,	
end_dt date,	
location varchar(50),	
address varchar(500),
city varchar(25),	
state varchar(50),	
education_level varchar(50));	


-- data ingestion from raw data 
COPY STAGING_HR_RAW FROM 'D:/Developments/Data Architect Nano Degree/Project 1 - HR Database/Raw Data/hr-dataset(HR Data).csv'
delimiter ',' csv header;

--Checking Raw table forquality and  completeness
--Total number of rows should be 205. There should be no null values at all apart from end_dt
SELECT  COUNT(*) TOTAL_COUNT,
SUM(CASE WHEN EMP_ID IS NULL THEN 1 ELSE 0 END) EMP_ID, 
SUM(CASE WHEN EMP_NM IS NULL THEN 1 ELSE 0 END) EMP_NM, 
SUM(CASE WHEN EMAIL IS NULL THEN 1 ELSE 0 END) EMAIL, 
SUM(CASE WHEN HIRE_DT IS NULL THEN 1 ELSE 0 END) HIRE_DT, 
SUM(CASE WHEN JOB_TITLE IS NULL THEN 1 ELSE 0 END) JOB_TITLE, 
SUM(CASE WHEN SALARY IS NULL THEN 1 ELSE 0 END) SALARY, 
SUM(CASE WHEN DEPARTMENT IS NULL THEN 1 ELSE 0 END) DEPARTMENT, 
SUM(CASE WHEN MANAGER IS NULL THEN 1 ELSE 0 END) MANAGER, 
SUM(CASE WHEN START_DT IS NULL THEN 1 ELSE 0 END) START_DT, 
SUM(CASE WHEN END_DT IS NULL THEN 1 ELSE 0 END) END_DT, 
SUM(CASE WHEN LOCATION IS NULL THEN 1 ELSE 0 END) LOCATION, 
SUM(CASE WHEN ADDRESS IS NULL THEN 1 ELSE 0 END) ADDRESS, 
SUM(CASE WHEN CITY IS NULL THEN 1 ELSE 0 END) CITY, 
SUM(CASE WHEN STATE IS NULL THEN 1 ELSE 0 END) STATE, 
SUM(CASE WHEN EDUCATION_LEVEL IS NULL THEN 1 ELSE 0 END) EDUCATION_LEVEL
FROM	STAGING_HR_RAW;

/*******************************************************************
--CREATE SCRIPT CONTAINING ALL TABLES REQUIRED INCLUDING KEYS
********************************************************************/

--CREATE EDUCATION TABLE
CREATE TABLE IF NOT EXISTS EDUCATION (
edu_id SERIAL PRIMARY KEY,
edu_level varchar(50)
);

--CREATE EMPLOYEE TABLE
CREATE TABLE IF NOT EXISTS EMPLOYEE (
emp_id varchar(10) primary key,
emp_nm varchar(200),
email varchar (200),
edu_id integer references EDUCATION(edu_id),
hire_Dt date
);

--CREATE JOB TABLE
CREATE TABLE IF NOT EXISTS JOB (
job_id SERIAL PRIMARY KEY,
job_title varchar(50)
);

--CREATE ADDRESS TABLE
CREATE TABLE IF NOT EXISTS ADDRESS (
address_id SERIAL primary key,
address varchar (500),
city varchar (100),
state varchar(50)
);

--CREATE LOCATION TABLE
CREATE TABLE IF NOT EXISTS LOCATION (
loc_id SERIAL primary key,
loc_nm varchar(50),
address_id integer references ADDRESS(address_id)
);

--CREATE DEPARTMENT TABLE
CREATE TABLE IF NOT EXISTS DEPARTMENT (
dept_id SERIAL primary key,
dept_nm varchar(50)
);

--CREATE SALARY TABLE
--A separated table for salary allows us to secure it easier since it contains sensitive information
CREATE TABLE IF NOT EXISTS SALARY (
sal_id SERIAL primary key,
salary money
);

--CREATE EMPLOYMENT HISTORY TABLE
CREATE TABLE IF NOT EXISTS EMPLOYMENT_HISTORY (
job_id integer references JOB(job_id),
emp_id varchar(10) references EMPLOYEE(emp_id),
manager_id varchar(10) references EMPLOYEE(emp_id),
loc_id integer references LOCATION(loc_id),
dept_id integer references DEPARTMENT(dept_id),
sal_id integer references SALARY(sal_id),
start_dt date,
end_dt date
);

--Add a composite primary key to employee_history
ALTER TABLE EMPLOYMENT_HISTORY ADD PRIMARY KEY (job_id, emp_id);



/*******************************************************************
Insertion script to set up initial data for each table using the Staging table as source
********************************************************************/

/*
Setting up Education
*/
INSERT INTO EDUCATION(edu_level)
SELECT DISTINCT EDUCATION_LEVEL
FROM STAGING_HR_RAW;

--Verifying data inserted
SELECT *
FROM	EDUCATION;

/*
Setting up EMPLOYEE
*/
INSERT 	INTO EMPLOYEE(emp_id, emp_nm, email, hire_dt, edu_id)
SELECT 	DISTINCT S.emp_id, S.emp_nm, S.email, S.hire_dt, e.edu_id
FROM 	STAGING_HR_RAW S
INNER 	JOIN EDUCATION e on s.education_level = e.edu_level;

--Verifying data inserted
SELECT *
FROM	EMPLOYEE;

/*
Setting up JOB
*/
INSERT 	INTO JOB (job_title)
SELECT 	DISTINCT job_title
FROM 	STAGING_HR_RAW S;

--Verifying data inserted
SELECT *
FROM	JOB;

/*
Setting up SALARY
*/
INSERT 	INTO SALARY (salary)
SELECT 	DISTINCT salary
FROM	STAGING_HR_RAW S;

--Verifying data inserted
SELECT *
FROM	SALARY;

/*
Setting up DEPARTMENT
*/
INSERT 	INTO DEPARTMENT (dept_nm)
SELECT 	DISTINCT department
FROM	STAGING_HR_RAW S;

--Verifying data inserted
SELECT *
FROM	DEPARTMENT;

/*
Setting up ADDRESS
*/
INSERT INTO ADDRESS (address, city, state)
SELECT DISTINCT address, city, state
FROM	STAGING_HR_RAW S;

--Verifying data inserted
SELECT *
FROM	ADDRESS;

/*
Setting up ADDRESS
*/
INSERT INTO LOCATION (loc_nm, address_id)
SELECT DISTINCT s.location, a.address_id
FROM	STAGING_HR_RAW S
INNER JOIN address a ON s.address = a.address;

--Verifying data inserted
SELECT *
FROM	LOCATION;

/*
Setting up Employment_history
*/
INSERT INTO EMPLOYMENT_HISTORY (
job_id,
emp_id,
manager_id,
loc_id,
dept_id,
sal_id,
start_dt,
end_dt
)
SELECT DISTINCT j.job_id, s.emp_id, e.emp_id as manager_id, l.loc_id, d.dept_id, sal.sal_id, s.start_dt, s.end_dt
FROM	STAGING_HR_RAW S
INNER JOIN job j ON s.job_title = j.job_title
LEFT OUTER JOIN employee e ON s.manager = e.emp_nm
INNER JOIN location l ON s.location = l.loc_nm
INNER JOIN department d ON s.department = d.dept_nm
INNER JOIN salary sal ON s.salary = sal.salary;

--Verifying data inserted
SELECT *
FROM	EMPLOYMENT_HISTORY;

