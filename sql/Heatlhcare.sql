create database healthcare_db;
use healthcare_db;
set sql_safe_updates= 0;
CREATE TABLE facilities (
    FacilityID INT PRIMARY KEY,
    FacilityName VARCHAR(100),
    City VARCHAR(50),
    State VARCHAR(50),
    Capacity INT
);

CREATE TABLE Patients (
    PatientID INT PRIMARY KEY,
    Name VARCHAR(100),
    Gender VARCHAR(20),
    DOB DATE,
    BloodGroup VARCHAR(5),
    InsuranceType VARCHAR(30),
    Address VARCHAR(300),
    Phone VARCHAR(20),
	City VARCHAR(50),
    State VARCHAR(50)
);

ALTER TABLE visits
add column status varchar (30);
ALTER TABLE visits
ADD AppointmentDate DATETIME;

UPDATE visits
SET AppointmentDate = DATE_SUB(VisitDate, INTERVAL FLOOR(RAND() * 10) + 1 DAY);

UPDATE visits
SET Status = CASE 
                WHEN RAND() < 0.6 THEN 'Completed'   -- 60% chance
                WHEN RAND() < 0.8 THEN 'No-Show'    -- 20% chance
                ELSE 'Cancelled'                    -- 20% chance
             END;

UPDATE visits
SET ProcedureCost = NULL,
    InsurancePaid = NULL
WHERE Status = 'Cancelled';


SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE Facilities;
SET FOREIGN_KEY_CHECKS = 1;

CREATE TABLE Providers (
    ProviderID INT PRIMARY KEY,
    ProviderName VARCHAR(100),
    Specialty VARCHAR(100),
    City VARCHAR(50),
    State VARCHAR(51)
);



CREATE TABLE VISITS(	
VisitID	INT PRIMARY KEY,
PatientID	INT ,
ProviderID	INT ,
FacilityID	INT ,
VisitDate	DATE ,
Diagnosis	VARCHAR (52),
ProcedureCost	DECIMAL (10,2),
InsurancePaid	DECIMAL (10,3),
FOREIGN KEY (PatientID) REFERENCES Patients (PatientID),
FOREIGN KEY (ProviderID) REFERENCES Providers (ProviderID),
FOREIGN KEY (FacilityID) REFERENCES  Facilities (FacilityID)
);

LOAD DATA INFILE 'C:\\ProgramData\\MySQL\\MySQL Server 8.0\\Uploads\\visits.csv'
INTO TABLE visits
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

select count(*) as total
from visits;

SELECT * FROM facilities;
select * from patients;
select * from providers;
select * from visits;

 use healthcare_db;
-- TYPE 1 Basic Data Exploration
-- 1. Count total records in the patients table.
 select count(*)
 from patients;
-- 2. Count total unique patient IDs.
 select count(distinct patientid ) as uniquePatient
from patients ;
-- 3. Find the oldest visit date and the latest visit date.
 select min(visitdate) as oldestVisit
 , max(visitdate) as latestVisit
 from visits ;
 
-- 4. List all unique departments.
 select distinct Specialty 
 from providers;
-- 5. List names and cities of all female patients.
 select name , Gender, city 
 from patients
 where Gender =  'Female';
-- 6. List names and DOB of patients aged 60+.
 select name , dob, timestampdiff(year, dob , curdate()) as age
 from patients 
 having age>60;

-- 7. Count patients whose phone number is NULL or blank.
 select count(distinct patientid) as CountPatient
 from patients
 where Phone is null ;

-- 8. Count total patients city-wise.
 select city , count(patientid) as total_Patient
 from patients
 group by city 
 order by total_Patient desc ;
-- DATA Cleaning Checks
-- -- 9. Find duplicate patient records based on first_name, last_name, and dob.
 select name , dob ,count(*)
 from 
 patients 
 group by  name,dob
having count(*) >1;
 -- 10. Filter records where phone number contains only digits.
 select *from patients
 where phone regexp '^[0-9] +$';
-- 12. List visits where visit_date is earlier than appointment_date.
 select patientid , visitdate , AppointmentDate
 from visits
 group by patientid , visitdate , AppointmentDate
 having datediff(AppointmentDate,visitdate);
 
 select patientid , date_format(visitdate, '%y-%m') as visit
 , date_format(AppointmentDate,'%y-%m') as apDate
 from visits
where visitdate < AppointmentDate
 ;
 
-- 13. Count visits with NULL department.
 select count(v.visitid ) as vsisitCount
 from visits v
 join providers p on p.providerid = v.providerid 
 where p.Specialty is null ;

 
 
-- 14. Find patients with invalid email format (NOT LIKE '%@%').'%@%').

 select * from 
 patients 
 where Address regexp '%@%';

-- KPIs & Metrics
-- 15. Calculate the total revenue.
 select sum(procedurecost) as totalRevenue
 from visits;
-- 16. Calculate the average revenue per patient.
 select sum(procedurecost) / count(distinct patientid) as AvgRevenuePerPatient
 from visits
 ;
-- 17. Calculate the average revenue per visit.
 select avg(procedurecost) avgRevenuePerVisit
 from visits ;
-- 18. Calculate the percentage of repeat patients.
 select (count(distinct case when visitCount >1 then patientid end)*100 /
 count(distinct patientid)) as repeatPatientsCount
 from(
 select patientid , count(*) as visitCount
 from visits
 group by patientid)t ;
-- 19. Find the most visited department.
 select specialty ,count(visitid) as visitCount
 from visits v
 join providers p on p.providerid = v.providerid
 group by specialty
 order by visitCount desc 
 limit 1;
-- 20. List the top 5 patients by revenue.
 
 select patientid , sum(procedurecost) as total_revenue
 from visits
 group by patientid 
 order by total_revenue desc
 limit 5;

-- 21. Show the monthly visits trend (month & visit count).
select date_format(visitdate, '%y-%M') as "MONTH" , COUNT(visitid) as total_count
from visits 
GROUP BY DATE_FORMAT(visitdate, '%y-%M')  
ORDER BY MIN(visitdate);

select monthname(visitdate) as month , count(visitid) as total_count
from visits
group by month(visitdate) , monthname(visitdate)
order by month(visitdate) ;
-- 22. Calculate the yearly revenue growth percentage.
select year(visitdate)as year, sum(procedurecost) as revenue,
round((sum(procedurecost) - lag(sum(procedurecost)) over(order by year(visitdate)))*100.0
/ lag(sum(procedurecost)) over(order by year(visitdate)),2)as rowthParcentage
from visits 
group by year(visitdate)
order by year(visitdate);






-- 23. Show the gender-wise revenue contribution.
select p.gender , sum(v.procedurecost) as totalRevenue
from patients p 
join visits v on v.patientid = p.patientid
group by gender 
order by totalRevenue desc ;
-- 24. Show the age group-wise patient count (0-18, 19-35, 36-60, 60+).
select case 
	when timestampdiff(year,dob ,curdate()) <=18 then '0-18'
	when timestampdiff(year,dob ,curdate()) between 19 and 35 then '19-35'
    when timestampdiff(year,dob ,curdate()) between 36 and 60 then '36-60'
else '60+'
end as AgeGroup , count(distinct patientid) as PatientCount
from patients 
group by AgeGroup
order by PatientCount desc;


 -- Advanced Analysis

-- 25. Show department-wise revenue and average bill.
 select p.Specialty , sum(v.procedurecost) as Revenue
 ,round(avg(v.procedurecost),2) as avgBill
 from visits v
 join providers p on p.providerid = v.Providerid 
 group by p.Specialty 
 order by revenue desc;
-- 26. Show doctor-wise total patients treated.
 select p.ProviderName,count(distinct patientid) as totalPatients
 from providers p 
 join visits v on p.providerid = v.providerid 
 where v.status = 'No-Show'
 group by ProviderName
 order by totalPatients desc;
 
 select * from visits;
-- 27. Find the most common diagnosis/treatment.
 select diagnosis, Count(patientid) as totalPatients
 from visits 
 group by diagnosis
 order by totalPatients desc 
 limit 1;
-- 28. Find the highest revenue generating doctor.
 select providername, sum(procedurecost) as revenue
 from providers p
 join visits v on p.providerid = v.providerid 
 group by providername 
 order by revenue desc 
 limit 1 offset 1;
 
 select providername , revenue 
 from (
 select ProviderName, sum(ProcedureCost) as revenue,
 rank() over(order by sum(ProcedureCost) desc) as rnk
 from providers p
  join visits v on p.providerid = v.providerid 
 group by ProviderName )t
 where rnk = 2;
 
-- 29. Show city-wise revenue.
 select city , sum(procedurecost) as revenue
 from patients p 
 join visits v on p.patientid = v.patientid 
 group by city 
 order by revenue desc ;
-- 30. Find the most visited day of the week.
select dayname(visitdate) as weekdays, count(visitid) as totalVisit
from visits 
group by weekdays
order by totalVisit desc 
limit 1;
 
-- 31. Calculate the no-show rate (appointments scheduled but no visit).
select "No-Show" as status,(count(case when status = 'Completed' then 1 end)
 *100.0 / count(*)) as noVisit
from visits 
where AppointmentDate is not null 
;



-- 32. Calculate the average days gap between patient visits.
select round(avg(dayGap)) as avgGap
from (
select patientid , datediff(visitdate , lag(visitdate) 
over(partition by patientid order by  visitdate)) as dayGap 
from visits 
) t where dayGap is not null ;


 
-- 33. List patients who visited in the last 30 days.
 select patientid ,visitdate
 from visits 
 where visitdate between '2024-12-01' and '2024-12-31'
 group by patientid, visitdate 
 order by date(visitdate) ;

-- 34. List patients with more than 5 visits in a year.
 select patientid , count(*) as totalVisits
 from visits
 group by patientid 
 having count(*) > 5
 order by totalVisits desc;
-- Q Business Insights
-- -- 35. Identify loss-making departments (average bill < 1000).
 select p.Specialty , round(avg(v.procedurecost)) as avgBill
 from visits v
 join providers p on p.providerid = v.providerid 
 group by p.specialty 
having  avg(v.procedurecost) < 10000
order by avgBill desc ;

-- 36. Detect seasonal trends in visits.
 select monthname(visitdate) as months, count(patientid) as totalVisits
 from visits 
 where visitdate between '2023-01-01' and '2024-12-31'
 group by month(visitdate) , monthname(visitdate)
 order by month(visitdate);
 
-- 37. List patients who haven’t visited in the last 1 year.
select p.* , max(v.visitdate) as "date"
from patients p 
join visits  v on p.patientid = v.patientid 
group by patientid 
having max(visitdate) < curdate() -  interval 1 day;


 
 -- 38. Calculate the revenue contribution of the top 10% patients.
WITH PatientRevenue AS (
    SELECT patientid, SUM(ProcedureCost) AS totalRevenue
    FROM visits
    GROUP BY patientid
),
RankedPatients AS (
    SELECT 
        patientid,
        totalRevenue,
        ROW_NUMBER() OVER (ORDER BY totalRevenue DESC) AS rn,
        COUNT(*) OVER () AS total_patients
    FROM PatientRevenue
),
TopPatients AS (
    SELECT patientid
    FROM RankedPatients
    WHERE rn <= CEIL(total_patients * 0.10)
)
SELECT SUM(v.ProcedureCost) AS top10PercentRevenue
FROM visits v
WHERE v.PatientID IN (SELECT patientid FROM TopPatients);






-- 39. Find the most profitable age group.
select case when timestampdiff(year,dob,curdate()) <=18 then '0-18'
			when timestampdiff(year,dob,curdate()) between 19 and 35 then '19-35'
            when timestampdiff(year,dob,curdate()) between 36 and 60 then '36-60'
else '60+'
end as ageGroup, sum(v.procedurecost) as revenue
from patients p
join visits v on p.patientid = v.patientid 
group by ageGroup 
order by revenue desc 
limit 1 ;

-- 40. Analyze the correlation between visit reason and revenue.
select diagnosis , sum(procedurecost) as revenue 
from visits 
group by diagnosis 
order by revenue desc;




