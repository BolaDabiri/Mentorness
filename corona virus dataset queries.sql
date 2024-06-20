-- view everything in the table

SELECT
	*
FROM 
	corona_virus_dataset;


-- duplicate table to protect against data loss

DROP TABLE IF EXISTS corona_virus_dataset_copy;
CREATE TABLE corona_virus_dataset_copy AS
	SELECT
		*
	FROM
		corona_virus_dataset;

        
-- changing 'Date' column type from str to date

UPDATE
	corona_virus_dataset
SET Date = str_to_date(Date, '%d-%m-%Y');

ALTER TABLE
	corona_virus_dataset
MODIFY Date DATE;


-- Q1. Write a code to check NULL values

SELECT
	*
FROM
	corona_virus_dataset
WHERE Province IS NULL
OR `Country/Region` IS NULL
OR Latitude IS NULL
OR Longitude IS NULL
OR Date IS NULL
OR Confirmed IS NULL
OR Deaths IS NULL
OR Recovered IS NULL;

-- (No null values)


-- Q2. If NULL values are present, update them with zeros for all columns. 

UPDATE
	corona_virus_dataset
SET
	`COLUMN` = 0
WHERE `COLUMN` IS NULL;

/* No Null values were found, but 'Column' in the above query
   can be replaced with the name of a column containing null values! */


-- Q3. check total number of rows

SELECT
	COUNT(*) AS count_of_rows
FROM
	corona_virus_dataset;

-- (78386 rows)


-- Q4. Check what is start_date and end_date

SELECT
	MIN(Date) AS start_date,
    MAX(Date) AS end_date
FROM
	corona_virus_dataset;
    
-- (start_date: 22-01-2020; end_date: 13-06-2021)


-- Q5. Number of month present in dataset

SELECT
	COUNT(DISTINCT month(Date)) AS num_of_months
FROM
	corona_virus_dataset;
    
-- (12 months)


-- Q6. Find monthly average for confirmed, deaths, recovered

SELECT
	monthname(Date) AS Month,
    AVG(Confirmed) AS avg_confirmed,
    AVG(Deaths) AS avg_deaths,
    AVG(Recovered) AS avg_recovered
FROM
	corona_virus_dataset
GROUP BY Month;

-- (This gives the average daily cases across countries per month)


-- Q7. Find most frequent value for confirmed, deaths, recovered each month 

WITH Counted_confirmed AS (
SELECT
	monthname(Date) AS Month,
    month(Date) AS Month_num,
    Confirmed,
    COUNT(Confirmed) AS freq_confirmed,
    ROW_NUMBER() OVER (PARTITION BY monthname(Date) ORDER BY COUNT(Confirmed) DESC) AS freq_ranking
FROM
	corona_virus_dataset
GROUP BY
	Month,
    Month_num,
    Confirmed
ORDER BY Month_num
),
Counted_deaths AS (
SELECT
	monthname(Date) AS Month,
    month(Date) AS Month_num,
    Deaths,
    COUNT(Deaths) AS freq_deaths,
    ROW_NUMBER() OVER (PARTITION BY monthname(Date) ORDER BY COUNT(Deaths) DESC) AS freq_ranking
FROM
	corona_virus_dataset
GROUP BY
	Month,
    Month_num,
    Deaths
ORDER BY Month_num, freq_ranking
),
Counted_recovered AS (
SELECT
	monthname(Date) AS Month,
    month(Date) AS Month_num,
    Recovered,
    COUNT(Recovered) AS freq_recovered,
    ROW_NUMBER() OVER (PARTITION BY monthname(Date) ORDER BY COUNT(Recovered) DESC) AS freq_ranking
FROM
	corona_virus_dataset
GROUP BY
	Month,
    Month_num,
    Recovered
ORDER BY Month_num, freq_ranking
)
SELECT
	sc.Month,
    sc.Confirmed AS most_freq_confirmed,
    sd.Deaths AS most_freq_deaths,
    sr.Recovered AS most_freq_recovered
FROM
	(SELECT
		Month,
        Confirmed
	FROM
		Counted_confirmed
	WHERE freq_ranking = 1
    ) AS sc
JOIN
	(SELECT
		Month,
        Deaths
	FROM
		Counted_deaths
	WHERE freq_ranking = 1
    ) AS sd
ON sc.Month = sd.Month
JOIN
	(SELECT
		Month,
        Recovered
	FROM
		Counted_recovered
	WHERE freq_ranking = 1) AS sr
ON sc.Month = sr.Month
;

-- (The most frequently occuring tally of confirmed cases, deaths and recovered was 0 across all months)
 

-- Q8. Find minimum values for confirmed, deaths, recovered per year

SELECT
	year(Date) AS Year,
    MIN(Confirmed) AS min_confirmed,
    MIN(Deaths) AS min_deaths,
    MIN(Recovered) AS min_recovered
FROM
	corona_virus_dataset
GROUP BY Year;

-- (O was the minimum value for all stats in both years)


-- Q9. Find maximum values of confirmed, deaths, recovered per year

SELECT
	year(Date) AS Year,
    MAX(Confirmed) AS max_confirmed,
    MAX(Deaths) AS max_deaths,
    MAX(Recovered) AS max_recovered
FROM
	corona_virus_dataset
GROUP BY Year;

/* (There were some really high recorded cases:
	823225 confirmed cases in Turkey on 10-12-2020;
	1123456 recovered in Turkey on 12-12-2020 - This was good news!) */


-- Q10. The total number of case of confirmed, deaths, recovered each month

SELECT
	monthname(Date) AS Month,
    SUM(Confirmed) AS total_confirmed,
    SUM(Deaths) AS total_deaths,
    SUM(Recovered) AS total_recovered
FROM
	corona_virus_dataset
GROUP BY Month;


-- Q11. Check how corona virus spread out with respect to confirmed case
--      (Eg.: total confirmed cases, their average, variance & STDEV )

SELECT
	SUM(Confirmed) AS total_confirmed,
    AVG(Confirmed) AS avg_confirmed,
    VARIANCE(Confirmed) AS var_confirmed,
    STDDEV(Confirmed) AS std_confirmed
FROM
	corona_virus_dataset;
    

-- Q12. Check how corona virus spread out with respect to death case per month
--      (Eg.: total confirmed cases, their average, variance & STDEV 

SELECT
	monthname(Date) AS Month,
	SUM(Deaths) AS total_deaths,
    AVG(Deaths) AS avg_deaths,
    VARIANCE(Deaths) AS var_deaths,
    STDDEV(Deaths) AS std_deaths
FROM
	corona_virus_dataset
GROUP BY Month;


-- Q13. Check how corona virus spread out with respect to recovered case
--      (Eg.: total confirmed cases, their average, variance & STDEV )

SELECT
	SUM(Recovered) AS total_recovered,
    AVG(Recovered) AS avg_recovered,
    VARIANCE(Recovered) AS var_recovered,
    STDDEV(Recovered) AS std_recovered
FROM
	corona_virus_dataset;


-- Q14. Find Country having highest number of the Confirmed case

WITH Confirmed_per_country AS (
SELECT
	`Country/Region` AS Country,
	SUM(Confirmed) AS total_confirmed,
	DENSE_RANK() OVER (ORDER BY SUM(Confirmed) DESC) AS ranking
FROM
	corona_virus_dataset
GROUP BY Country
)
SELECT
	Country,
    total_confirmed
FROM
	Confirmed_per_country
WHERE ranking = 1;

-- (The US had the most confirmed cases)


-- Q15. Find Country having lowest number of the death case

WITH Deaths_per_country AS (
SELECT
	`Country/Region` AS Country,
	SUM(Deaths) AS total_deaths,
	DENSE_RANK() OVER (ORDER BY SUM(Deaths) ASC) AS ranking
FROM
	corona_virus_dataset
GROUP BY Country
)
SELECT
	Country,
    total_deaths
FROM
	Deaths_per_country
WHERE ranking = 1;

-- (4 Countries recored 0 deaths: Dominica, Kiribati, Marshall Islands and Samoa)


-- Q16. Find top 5 countries having highest recovered case

WITH Recovered_per_country AS (
SELECT
	`Country/Region` AS Country,
	SUM(Recovered) AS total_recovered,
	DENSE_RANK() OVER (ORDER BY SUM(Recovered) DESC) AS ranking
FROM
	corona_virus_dataset
GROUP BY Country
)
SELECT
	Country,
    total_recovered,
    ranking
FROM
	Recovered_per_country
WHERE ranking BETWEEN 1 AND 5;

-- (In Order, from the most: India, Brazil, US, Turkey, Russia)
