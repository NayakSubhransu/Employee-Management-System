-- Total unique employees
SELECT COUNT(DISTINCT EmpID) AS total_employees
FROM Employee;

-- Employee details with department and job role
SELECT e.EmpID,
       e.FirstName,
       e.LastName,
       jd.JobDept,
       jd.Name AS JobRole
FROM Employee e
JOIN JobDepartment jd ON e.JobID = jd.JobID
ORDER BY e.LastName, e.FirstName;


-- Employee count per department
SELECT jd.JobDept,
       COUNT(e.EmpID) AS employee_count
FROM JobDepartment jd
LEFT JOIN Employee e ON e.JobID = jd.JobID
GROUP BY jd.JobDept
ORDER BY employee_count DESC;

-- Number of different job roles per department
SELECT jd.JobDept,
       COUNT(DISTINCT jd.Name) AS total_job_roles
FROM JobDepartment jd
GROUP BY jd.JobDept;


-- Average salary per department
SELECT jd.JobDept,
       AVG(CAST(sb.Annual AS REAL)) AS avg_annual_salary
FROM JobDepartment jd
JOIN Salary_Bonus sb ON jd.JobID = sb.JobID
GROUP BY jd.JobDept
ORDER BY avg_annual_salary DESC;

-- Top 5 highest-paid employees
SELECT e.EmpID,
       e.FirstName,
       e.LastName,
       MAX(CAST(sb.Annual AS REAL)) AS annual_salary
FROM Employee e
JOIN Payroll p ON e.EmpID = p.EmpID
JOIN Salary_Bonus sb ON p.SalaryID = sb.SalaryID
GROUP BY e.EmpID, e.FirstName, e.LastName
ORDER BY annual_salary DESC
LIMIT 5;

-- Which job role offers the highest salary?
SELECT jd.Name AS job_role,
       MAX(CAST(sb.Annual AS REAL)) AS highest_salary
FROM JobDepartment jd
JOIN Salary_Bonus sb ON jd.JobID = sb.JobID
GROUP BY jd.Name
ORDER BY highest_salary DESC
LIMIT 1;


-- Employees with highest number of qualifications
SELECT e.EmpID,
       e.FirstName,
       e.LastName,
       COUNT(q.QualID) AS num_qualifications
FROM Employee e
JOIN Qualification q ON e.EmpID = q.EmpID
GROUP BY e.EmpID, e.FirstName, e.LastName
ORDER BY num_qualifications DESC
LIMIT 5;


-- Average leave count per department
WITH emp_leave_counts AS (
  SELECT EmpID, COUNT(*) AS leave_count
  FROM Leaves
  GROUP BY EmpID
)
SELECT jd.JobDept,
       AVG(elc.leave_count) AS avg_leave_days_per_employee
FROM emp_leave_counts elc
JOIN Employee e ON elc.EmpID = e.EmpID
JOIN JobDepartment jd ON e.JobID = jd.JobID
GROUP BY jd.JobDept
ORDER BY avg_leave_days_per_employee DESC;

-- Employees with most leaves
SELECT e.EmpID,
       e.FirstName,
       e.LastName,
       COUNT(l.LeaveID) AS total_leaves
FROM Employee e
JOIN Leaves l ON e.EmpID = l.EmpID
GROUP BY e.EmpID, e.FirstName, e.LastName
ORDER BY total_leaves DESC
LIMIT 5;


-- Gender distribution across departments
SELECT jd.JobDept,
       e.Gender,
       COUNT(e.EmpID) AS employee_count,
       ROUND(COUNT(e.EmpID) * 100.0 / dept_totals.total_in_dept, 2) AS percentage_within_dept
FROM Employee e
JOIN JobDepartment jd ON e.JobID = jd.JobID
JOIN (
    SELECT jd2.JobDept, COUNT(e2.EmpID) AS total_in_dept
    FROM Employee e2
    JOIN JobDepartment jd2 ON e2.JobID = jd2.JobID
    GROUP BY jd2.JobDept
) dept_totals ON jd.JobDept = dept_totals.JobDept
GROUP BY jd.JobDept, e.Gender, dept_totals.total_in_dept
ORDER BY jd.JobDept, e.Gender;


-- Age distribution analysis
SELECT 
    CASE 
        WHEN e.Age < 25 THEN 'Under 25'
        WHEN e.Age BETWEEN 25 AND 34 THEN '25-34'
        WHEN e.Age BETWEEN 35 AND 44 THEN '35-44'
        WHEN e.Age BETWEEN 45 AND 54 THEN '45-54'
        WHEN e.Age >= 55 THEN '55 and above'
    END AS age_group,
    COUNT(e.EmpID) AS employee_count,
    AVG(CAST(sb.Annual AS REAL)) AS avg_salary
FROM Employee e
JOIN JobDepartment jd ON e.JobID = jd.JobID
JOIN Salary_Bonus sb ON jd.JobID = sb.JobID
GROUP BY age_group
ORDER BY MIN(e.Age);

-- Compensation quartiles analysis (using manual quartile calculation)
WITH salary_data AS (
    SELECT 
        CAST(sb.Annual AS REAL) AS annual_salary,
        ROW_NUMBER() OVER (ORDER BY CAST(sb.Annual AS REAL)) AS row_num,
        COUNT(*) OVER () AS total_count
    FROM Salary_Bonus sb
),
salary_quartiles AS (
    SELECT annual_salary,
           CASE 
               WHEN row_num <= total_count * 0.25 THEN 1
               WHEN row_num <= total_count * 0.50 THEN 2
               WHEN row_num <= total_count * 0.75 THEN 3
               ELSE 4
           END AS quartile
    FROM salary_data
)
SELECT quartile,
       MIN(annual_salary) AS min_salary,
       MAX(annual_salary) AS max_salary,
       AVG(annual_salary) AS avg_salary,
       COUNT(*) AS employee_count
FROM salary_quartiles
GROUP BY quartile
ORDER BY quartile;



-- Salary vs Bonus ratio analysis by department
SELECT jd.JobDept,
       AVG(CAST(sb.Annual AS REAL)) AS avg_annual_salary,
       AVG(CAST(sb.Bonus AS REAL)) AS avg_bonus,
       ROUND(AVG(CAST(sb.Bonus AS REAL)) * 100.0 / AVG(CAST(sb.Annual AS REAL)), 2) AS bonus_to_salary_ratio_percent
FROM JobDepartment jd
JOIN Salary_Bonus sb ON jd.JobID = sb.JobID
GROUP BY jd.JobDept
ORDER BY bonus_to_salary_ratio_percent DESC;


-- Department workload analysis (employees vs leave patterns)
SELECT jd.JobDept,
       COUNT(DISTINCT e.EmpID) AS total_employees,
       COUNT(l.LeaveID) AS total_leaves_taken,
       ROUND(COUNT(l.LeaveID) * 1.0 / COUNT(DISTINCT e.EmpID), 2) AS avg_leaves_per_employee,
       -- Workload pressure indicator
       CASE 
           WHEN COUNT(l.LeaveID) * 1.0 / COUNT(DISTINCT e.EmpID) > 10 THEN 'High Leave Usage'
           WHEN COUNT(l.LeaveID) * 1.0 / COUNT(DISTINCT e.EmpID) > 5 THEN 'Moderate Leave Usage'
           ELSE 'Low Leave Usage'
       END AS leave_usage_category
FROM Employee e
JOIN JobDepartment jd ON e.JobID = jd.JobID
LEFT JOIN Leaves l ON e.EmpID = l.EmpID
GROUP BY jd.JobDept
ORDER BY avg_leaves_per_employee DESC;



-- Department cost analysis and budget efficiency
SELECT jd.JobDept,
       COUNT(DISTINCT e.EmpID) AS employee_count,
       SUM(CAST(sb.Annual AS REAL)) AS total_annual_salary,
       SUM(CAST(sb.Bonus AS REAL)) AS total_bonus,
       SUM(CAST(p.TotalAmount AS REAL)) AS total_payroll_processed,
       ROUND(SUM(CAST(sb.Annual AS REAL)) / COUNT(DISTINCT e.EmpID), 2) AS cost_per_employee,
       ROUND(SUM(CAST(sb.Bonus AS REAL)) * 100.0 / SUM(CAST(sb.Annual AS REAL)), 2) AS bonus_percentage_of_salary
FROM Employee e
JOIN JobDepartment jd ON e.JobID = jd.JobID
JOIN Salary_Bonus sb ON jd.JobID = sb.JobID
LEFT JOIN Payroll p ON e.EmpID = p.EmpID
GROUP BY jd.JobDept
ORDER BY cost_per_employee DESC;
