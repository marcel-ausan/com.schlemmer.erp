-------------------------------------------------------------------------------------------------------------------------
------------General SQL-------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------

-----------------------------------------
-------WITH Clause--------------------------
-----------------------------------------
WITH 
	emp_count AS (SELECT COUNT(*) num, deptno
                FROM emp
                GROUP BY deptno),
	avg_sal AS (SELECT AVG(sal) avgsal, deptno
            FROM emp
            GROUP BY deptno)
SELECT dname department, loc location, num "number of employees", avgsal "average salary"
FROM dept, emp_count, avg_sal
WHERE dept.deptno = emp_count.deptno
	AND dept.deptno = avg_sal.deptno;
	
	
-----------------------------------------------------------
---finding a function in metadata dict
-----------------------------------------------------------
select * from all_source
 where 1=1 
 --type = 'PACKAGE'
   and text like '%Get_Contract %'
   and owner != 'SYS'
   and name like '%PART%';