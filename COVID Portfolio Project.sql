-- The query below provides the snapshot of CovidDeaths table in my "PortfolioProject" database
SELECT * 
FROM PortfolioProject..CovidDeaths
ORDER BY location, date

-- The query below selects the data that I will be using for analysis.
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM PortfolioProject..CovidDeaths
ORDER BY location, date

-- Looking at total cases Vs Total deaths
-- What percentage of the people that got Covid died from it?
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Percent_death
FROM PortfolioProject..CovidDeaths
ORDER BY location, date

-- Because "Africa" is showing as part of our location and we only want to check for countries and not continents, we will exclude 'africa' in our location
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Percent_death
FROM PortfolioProject..CovidDeaths
WHERE location <> 'Africa'
ORDER BY location, date

-- Analyzing the percentage of the people that got Covid died from it in the United States
SELECT location, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Percent_death
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY location, date

-- What percentage of the population got Covid
-- What percentage of the population US population has died from Covid
SELECT location, date, total_cases, total_deaths, population, (total_cases/population)*100 as covidcase_percent_pop, (total_deaths/population) *100 as Death_percent_pop
FROM PortfolioProject..CovidDeaths
WHERE location like '%states%'
ORDER BY location, date

-- Looking at country with highest percentage covid infection compared to its population
SELECT location, population, MAX(total_cases) highest_infection_count, MAX((total_cases/population))*100 as highest_percentage_pop_infected, MAX((total_deaths/population))*100 as highest_perc_death_pop
FROM PortfolioProject..CovidDeaths
WHERE location <> 'Africa' 
GROUP BY location, population
ORDER BY highest_percentage_pop_infected DESC

-- Looking at country with highest percentage death compared to its population
SELECT location, population, MAX(total_cases) highest_infection_count, MAX((total_cases/population))*100 as highest_percentage_pop_infected, MAX((total_deaths/population))*100 as highest_perc_death_pop
FROM PortfolioProject..CovidDeaths
WHERE location <> 'Africa' 
GROUP BY location, population
ORDER BY highest_perc_death_pop DESC

-- Countries with its highest death count per population
SELECT location, MAX(CAST(total_deaths AS int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY location
ORDER BY total_death_count DESC

-- Continent with its highest death count per population
SELECT continent, MAX(CAST(total_deaths AS int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent
ORDER BY total_death_count DESC

-- Looking at total cases Vs Total deaths at the continent level
-- What percentage of the people that got Covid died from it?
SELECT continent, date, total_cases, total_deaths, (total_deaths/total_cases)*100 as Percent_death
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
ORDER BY Percent_death 

-- Global Numbers
-- Let's check the total number of covid cases, total number of covid deaths and percentage of covid death relating to covid cases in the world
-- Lets check these metrics on a day to day basis
SELECT date, SUM(new_cases) as total_case, SUM(CAST(new_deaths as int)) AS total_death, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 as perc_new_death
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY date
order by date, total_case 

--Let's see the world's Covid total cases, total death, and the percentage of the world's population that died from covid.
SELECT SUM(new_cases) as total_case, SUM(CAST(new_deaths as int)) AS total_death, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
order by total_case 


--Let's consider world's population vs Vaccinations
--We will be joining covid death table and covid vaccination table
--Let's use a window's function (Partition) to calculate a rolling vaccination count
SELECT cd.location, cd.continent, cd.date, cd.population, CONVERT(BIGINT, cv.new_vaccinations) as new_vaccinations, SUM(CONVERT(BIGINT, new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations as cv
ON cd.location=cv.location 
AND cd.date=cv.date
WHERE cd.continent is not null
ORDER BY cd.location, cd.date

-- Using CTE (Common Table Expression) to find percentage of people in each country that is vaccinated
-- Let's the newly created column from the CTE to check madagascar's population that is vaccinated
WITH PopVac (location, continent, date, population, new_vaccinations, rolling_vaccinations)
AS
(
SELECT cd.location, cd.continent, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(BIGINT, new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations as cv
ON cd.location=cv.location 
AND cd.date=cv.date
WHERE cd.continent is not null
)
SELECT *, (rolling_vaccinations/population)*100 as perc_pop_vac
FROM PopVac
WHERE location LIKE '%madagas%' 

--Using TEMP Table to find percentage of people in each country that is vaccinated
DROP TABLE IF exists #PercentagePopVaccinated
CREATE TABLE #PercentagePopVaccinated
(
location NVARCHAR(255), continent NVARCHAR(255), date DATETIME, population NUMERIC, new_vaccinations NUMERIC, rolling_vaccination NUMERIC)
INSERT INTO #PercentagePopVaccinated
SELECT cd.location, cd.continent, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(BIGINT, new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations as cv
ON cd.location=cv.location 
AND cd.date=cv.date
WHERE cd.continent is not null

SELECT *, (rolling_vaccination/population)*100 as perc_pop_vac
FROM #PercentagePopVaccinated
WHERE location LIKE '%madag%'


--Let's create Views to store data for later visualizations

CREATE View PopulationVaccinated AS
SELECT cd.location, cd.continent, cd.date, cd.population, cv.new_vaccinations, SUM(CONVERT(BIGINT, new_vaccinations)) OVER (PARTITION BY cd.location ORDER BY cd.location, cd.date) AS rolling_vaccinations
FROM PortfolioProject..CovidDeaths AS cd
JOIN PortfolioProject..CovidVaccinations as cv
ON cd.location=cv.location 
AND cd.date=cv.date
WHERE cd.continent is not null


SELECT *, (rolling_vaccinations/population)*100 as perc_pop_vac
FROM PopulationVaccinated

CREATE View ContinentDeathCount AS
SELECT continent, MAX(CAST(total_deaths AS int)) as total_death_count
FROM PortfolioProject..CovidDeaths
WHERE continent is not null
GROUP BY continent

SELECT * 
FROM ContinentDeathCount

CREATE View WorldDeathVersusCase AS
SELECT SUM(new_cases) as total_case, SUM(CAST(new_deaths as int)) AS total_death, (SUM(CAST(new_deaths AS int))/SUM(new_cases))*100 as death_percentage
FROM PortfolioProject..CovidDeaths
WHERE continent is not null

SELECT *
FROM 
WorldDeathVersusCase
