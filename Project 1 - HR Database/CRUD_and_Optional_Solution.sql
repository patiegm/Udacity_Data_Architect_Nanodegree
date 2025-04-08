

/*******************************************************************
CRUD
********************************************************************/	
--Question 1: Return a list of employees with Job Titles and Department Names
	
SELECT e.emp_id, j.job_title, d.dept_nm
	FROM employee AS e
	JOIN employment_history AS eh
	ON eh.emp_id = e.emp_id
	JOIN job AS j
	ON eh.job_id = j.job_id
	JOIN department AS d
	ON eh.dept_id = d.dept_id;

	
--Question 2: Insert Web Programmer as a new job title
INSERT INTO job(job_title) VALUES ('Web Programmer');

--Verifying data inserted
SELECT  *
FROM	job;

--Question 3: Correct the job title from web programmer to web developer
UPDATE job 
SET job_title='Web Developer' 
WHERE job_title='Web Programmer';

--Verifying data modified
SELECT  *
FROM	job;

--Question 4: Delete the job title Web Developer from the database
DELETE FROM job WHERE job_title='Web Developer';

--Verifying data deleted
SELECT  *
FROM	job;


/*Question 5: How many employees are in each department?*/
SELECT d.dept_nm, COUNT(e.emp_id)
FROM department AS d
JOIN employment_history AS eh
	ON d.dept_id = eh.dept_id
JOIN employee AS e
	ON e.emp_id = eh.emp_id
WHERE end_dt IS NULL
GROUP BY d.dept_nm;


/*Question 6: Write a query that returns current and past jobs
(include employee name, job title, department, manager name, start and end date for position) 
for employee Toni Lembeck.
*/

SELECT DISTINCT e.emp_nm, j.job_title, d.dept_nm, m.emp_nm as manager_name, eh.start_dt, eh.end_dt
FROM EMPLOYMENT_HISTORY eh
INNER JOIN EMPLOYEE e
	ON eh.emp_id = e.emp_id
INNER JOIN JOB j
	ON	eh.job_id = j.job_id	
INNER JOIN DEPARTMENT d
	ON eh.dept_id = d.dept_id
INNER JOIN EMPLOYEE m
	ON eh.manager_id = m.emp_id
WHERE   e.emp_nm = 'Toni Lembeck'
ORDER BY start_dt ASC;

--Question 7: Describe how you would apply table security to restrict access to employee salaries using an SQL Server
/*
We can utilise separate ROLES and object GRANTS so that there is a ROLE with 'elevated access' that has GRANTS on all tables, 
and a separate role for employees that has access revoked to a seperate SALARY table.

Existing users should be given the appropriate ROLE to their job role.
When a user is onboarded, they should be given the appropriate role by the ADMIN
*/


/*******************************************************************
Optional Step 1
********************************************************************/

CREATE OR REPLACE VIEW excel_extract AS 
SELECT 
	e.emp_id,
	e.emp_nm,
	e.email,
	e.hire_dt,
	j.job_title,
	s.salary,
	d.dept_nm as department,
	m.emp_nm as manager,
	eh.start_dt,
	eh.end_dt,
	l.loc_nm as location,
	a.address,
	a.city,
	a.state,
	ed.edu_level as education_level
FROM employee e
INNER JOIN employment_history eh
	ON e.emp_id = eh.emp_id
INNER JOIN salary s
	ON eh.sal_id = s.sal_id
INNER JOIN location l
	ON eh.loc_id = l.loc_id
INNER JOIN address a
	ON	l.address_id = a.address_id
INNER JOIN employee m
	ON eh.manager_id = m.emp_id
INNER JOIN job j
	ON eh.job_id = j.job_id
INNER JOIN department d
	ON eh.dept_id = d.dept_id
INNER JOIN education ed
	ON e.edu_id = ed.edu_id;

--Verifying data can be viewed
SELECT	*
FROM	excel_extract;

/*******************************************************************
Optional Step 2
********************************************************************/

CREATE OR REPLACE FUNCTION f_RETURN_EMPLOYEE_HIST(in v_name varchar, ref refcursor) RETURNS refcursor AS $$
    BEGIN
	    OPEN ref FOR 
			SELECT DISTINCT e.emp_nm, j.job_title, d.dept_nm, m.emp_nm as manager_name, eh.start_dt, eh.end_dt
			FROM EMPLOYMENT_HISTORY eh
			INNER JOIN EMPLOYEE e
				ON eh.emp_id = e.emp_id
			INNER JOIN JOB j
				ON	eh.job_id = j.job_id	
			INNER JOIN DEPARTMENT d
				ON eh.dept_id = d.dept_id
			INNER JOIN EMPLOYEE m
				ON eh.manager_id = m.emp_id
			WHERE   e.emp_nm = (v_name);
		RETURN ref;
    END;
    $$ LANGUAGE plpgsql;

--Verifying data can be retreived
BEGIN;
	select * from f_RETURN_EMPLOYEE_HIST('Toni Lembeck', 'ref');
   FETCH ALL IN "ref";
COMMIT;


/*******************************************************************
Optional Step 3
********************************************************************/
CREATE USER NoMgr;

GRANT SELECT ON EMPLOYMENT_HISTORY, JOB, LOCATION, DEPARTMENT, ADDRESS, EMPLOYEE, EDUCATION
TO NoMgr;

REVOKE ALL ON salary from NoMgr;