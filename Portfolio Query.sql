--Adjusting Data Types and Insertion of NULL Values

ALTER TABLE PortfolioProject.dbo.covid_deaths
ALTER COLUMN total_deaths INT;
UPDATE PortfolioProject.dbo.covid_deaths
SET continent = NULLIF(continent,'');
UPDATE PortfolioProject.dbo.covid_vaccinations
SET new_vaccinations = NULLIF(new_vaccinations,'');



-- Inspecting the Main Variables for Later Analysis

SELECT location,
       date, 
	   total_cases, 
	   new_cases, 
	   total_deaths, 
	   population
  FROM PortfolioProject.dbo.covid_deaths
 ORDER BY location, date
  */

-- Total Cases VS Total Deaths for Germany per Day
-- Likelihood of Death if you contract Covid in Germany

SELECT location, 
       date, 
	   total_cases, 
	   total_deaths, 
	   (total_deaths/total_cases)*100 AS death_percentage
  FROM PortfolioProject.dbo.covid_deaths
  WHERE location LIKE 'Germany'
  ORDER BY location, date

-- Total Cases VS Population
-- Percentage of Population that has been infected with Covid

SELECT location, 
       date, 
	   total_cases, 
	   population, (total_cases/population)*100 AS infection_percentage
  FROM PortfolioProject.dbo.covid_deaths
  ORDER BY location, date

-- Countries with Highest Infection Rate compared to Population

SELECT location, 
       population, 
	   MAX(total_cases) AS highest_infection_count,  
	   MAX((total_cases/population))*100 AS infection_percentage
  FROM PortfolioProject.dbo.covid_deaths
  GROUP BY location, population
  ORDER BY infection_percentage DESC

-- Countries with Highest Death Count per Population excl. Continents

SELECT location, 
       population, 
	   MAX(total_deaths) AS total_death_count
  FROM PortfolioProject.dbo.covid_deaths
  WHERE continent IS NOT NULL
  GROUP BY location, population
  ORDER BY total_death_count DESC

-- Breakdown per Continent with Highest Death Count
SELECT location, MAX(total_deaths) AS total_death_count
  FROM PortfolioProject.dbo.covid_deaths
  WHERE continent IS NULL AND population IS NOT NULL
  GROUP BY location, population
  ORDER BY total_death_count DESC
 

 -- Global Numbers per Day
SELECT date, 
       SUM(new_cases) AS case_total, 
	   SUM(CAST(new_deaths AS INT)) AS deaths_total, 
	   SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
  FROM PortfolioProject.dbo.covid_deaths
  WHERE continent IS NOT NULL
  GROUP BY date
  ORDER BY date

  --Global Numbers to Present Day
  SELECT SUM(new_cases) AS case_total, 
		 SUM(CAST(new_deaths AS INT)) AS deaths_total, 
		 SUM(CAST(new_deaths AS INT))/SUM(new_cases)*100 AS death_percentage
   FROM  PortfolioProject.dbo.covid_deaths
  WHERE  continent IS NOT NULL


-- Total Population VS Vaccinations
  SELECT dea.continent, 
         dea.location, 
		 dea.date, 
		 dea.population, 
		 vac.new_vaccinations, 
		 SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject.dbo.covid_deaths AS dea
    JOIN PortfolioProject.dbo.covid_vaccinations AS vac
	     ON dea.location = vac.location
	     AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL
   ORDER BY location, date

-- USE CTE

WITH popVSvac (continent, location, date, population, new_vaccinations, rolling_people_vaccinated )
AS
(
  SELECT dea.continent, 
         dea.location, 
		 dea.date, 
		 dea.population, 
		 vac.new_vaccinations, 
		 SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject.dbo.covid_deaths AS dea
    JOIN PortfolioProject.dbo.covid_vaccinations AS vac
	     ON dea.location = vac.location
	     AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL
)
SELECT *, (rolling_people_vaccinated/population)*100
FROM  popVSvac;


-- USE TEMP TABLE INSTEAD

DROP TABLE IF EXISTS #Percent_Pop_Vaccinated
CREATE TABLE #Percent_Pop_Vaccinated
(
continent					nvarchar(255),
location					nvarchar(255),
date						datetime,
population					numeric,
new_vaccinations			numeric
rolling_people_vaccinated	numeric
)

INSERT INTO #Percent_Pop_Vaccinated
  SELECT dea.continent, 
         dea.location, 
		 dea.date, 
		 dea.population, 
		 vac.new_vaccinations, 
		 SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject.dbo.covid_deaths AS dea
    JOIN PortfolioProject.dbo.covid_vaccinations AS vac
	     ON dea.location = vac.location
	     AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL

SELECT *, (rolling_people_vaccinated/population)*100
FROM  #Percent_Pop_Vaccinated


-- Creating View to store Data for later Visualization
CREATE VIEW Percent_Pop_Vaccinated AS
  SELECT dea.continent, 
         dea.location, 
		 dea.date, 
		 dea.population, 
		 vac.new_vaccinations, 
		 SUM(CONVERT(INT, vac.new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location,dea.date) AS rolling_people_vaccinated
    FROM PortfolioProject.dbo.covid_deaths AS dea
    JOIN PortfolioProject.dbo.covid_vaccinations AS vac
	     ON dea.location = vac.location
	     AND dea.date = vac.date
   WHERE dea.continent IS NOT NULL