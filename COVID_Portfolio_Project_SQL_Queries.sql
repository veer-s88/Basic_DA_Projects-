/*
Covid 19 Data Exploration 
Skills used: Joins, CTE's, Temp Tables, Windows Functions, Aggregate Functions, Creating Views, Converting Data Types
*/

-- Check that we managed to import the csv data correctly
SELECT * 
FROM covid_proj.covid_vaccinations;


SELECT *
FROM covid_proj.covid_vaccinations;


-- View some of the data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM covid_proj.covid_deaths
ORDER BY location, date;


-- Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM covid_proj.covid_deaths
ORDER BY location, date;


-- Looking at Total Cases vs Total Deaths in UK
-- Shows the likelihood of dying if you contract Covid in UK
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases) * 100 AS DeathPercentage
FROM covid_proj.covid_deaths
WHERE location LIKE '%Kingdom%'
ORDER BY date DESC;


-- Looking at Total Cases vs Population
-- Shows what percentage of population are infected Covid
SELECT location, date, total_cases, population, (total_cases/population) * 100 AS CasePercentage
FROM covid_proj.covid_deaths
WHERE location LIKE '%Kingdom%'
ORDER BY date;


-- Showing Countries with Highest Infection Rate
SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases/population) * 100) AS CasePercentage
FROM covid_proj.covid_deaths
GROUP BY location, population
HAVING MAX((total_cases/population) * 100) IS NOT NULL
ORDER BY CasePercentage DESC;


-- Looking at Countries with the Highest Death Toll
SELECT location, population, MAX(CAST(total_deaths AS INT)) AS DeathCount
FROM covid_proj.covid_deaths
WHERE continent IS NOT NULL
GROUP BY location, population
HAVING MAX(total_deaths) IS NOT NULL
ORDER BY DeathCount DESC;


-- Breaking the Death Count Down by Continent
SELECT location, population, MAX(total_deaths) AS DeathCount
FROM covid_proj.covid_deaths
WHERE Continent IS NULL
GROUP BY location, population
ORDER BY DeathCount DESC;


-- Global Numbers for new cases and new deaths per date
SELECT date, SUM(new_cases) AS nc, SUM(new_deaths) AS nd, (SUM(New_deaths) / SUM(New_cases)*100) AS death_percentage
FROM covid_proj.covid_deaths
WHERE continent IS NOT NULL
GROUP BY date
HAVING SUM(new_deaths) IS NOT NULL
ORDER BY death_percentage DESC;


-- Looking at Total Population vs Vaccincations
-- Shows rolling number of vaccines given out
SELECT d.continent,d.location,d.date,d.population, v.new_vaccinations, 
SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_tot_vac 
FROM covid_proj.covid_deaths AS d
JOIN covid_proj.covid_vaccinations AS v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL
ORDER BY location, date;


-- Looking at Total Population vs Vaccincations, population % vaccinated
-- Use CTE
WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, rolling_tot_vac) AS
	(
	SELECT d.continent,d.location,d.date,d.population, v.new_vaccinations, 
	SUM(v.new_vaccinations) OVER (PARTITION BY d.location ORDER BY d.location, d.date) AS rolling_tot_vac
	FROM covid_proj.covid_deaths AS d
	JOIN covid_proj.covid_vaccinations AS v
	ON d.location = v.location AND d.date = v.date
	WHERE d.continent IS NOT NULL)

-- Find total numbwer of vaccines given per population
SELECT *, (rolling_tot_vac/population)*100 AS Perc_Vaccinated FROM PopvsVac
WHERE location = 'United Kingdom' AND rolling_tot_vac IS NOT NULL
ORDER BY perc_vaccinated DESC;
-- It is important to note that some percentages may be higher than 100 because in many countries many people have gotten 2 doses


-- To find a better value for perc_vaccinated, we should use the people vaccinated column
-- Using CTE
WITH vaccinations AS( 
SELECT d.continent, d.location, d.date, d.population, v.people_vaccinated
FROM covid_proj.covid_deaths AS d
JOIN covid_proj.covid_vaccinations AS v
ON d.location = v.location AND d.date = v.date
WHERE d.continent IS NOT NULL)

SELECT *, (people_vaccinated/population)*100 AS perc_vac
FROM vaccinations
WHERE location = 'United Kingdom' AND people_vaccinated IS NOT NULL
ORDER BY perc_vac DESC;


-- Creating View to store data for later visualisations
CREATE VIEW covid_proj.Percent_population_vaccinated AS(
	SELECT d.continent, d.location, d.date, d.population, v.people_vaccinated
	FROM covid_proj.covid_deaths AS d
	JOIN covid_proj.covid_vaccinations AS v
	ON d.location = v.location AND d.date = v.date
	WHERE d.continent IS NOT NULL);
