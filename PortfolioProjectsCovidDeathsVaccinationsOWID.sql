--SELECT *
FROM CovidDeaths
WHERE continent is not NULL
ORDER BY 3,4

--SELECT *
FROM CovidVaccinations
ORDER BY 3,4

--Select the variables we need

SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidDeaths
ORDER BY 1, 2

--Looking at total cases vs total deaths
--this shows the likelihood of dying from covid over a period of time in different countries
--I narrowed it down to Nigeria using the WHERE statement (I am from Nigeria)

SELECT location, date, total_cases, total_deaths, (total_deaths / total_cases) * 100 AS death_rate
FROM CovidDeaths
WHERE location = 'Nigeria'
ORDER BY 1, 2

--Looking at total cases vs population
--showing the infection rate in Nigeria

SELECT location, date, population, total_cases, (total_cases / population) * 100 AS infection_rate
FROM CovidDeaths
WHERE location = 'Nigeria'
ORDER BY 1, 2


--Looking at countries with highest infection rate compared to population

SELECT location, population, MAX(total_cases) AS HighestInfectionCount, MAX((total_cases / population)) * 100 AS infection_rate
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location, population
ORDER BY infection_rate DESC

-- Showing Countries with highest death count per population

SELECT location, MAX(CAST(total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY location
ORDER BY TotalDeathCount DESC




-- LET'S BREAK THINGS DOWN BY CONTINENT

-- Showing continent with highest death count per population

SELECT location, MAX(CAST (total_deaths AS INT)) AS TotalDeathCount
FROM CovidDeaths
WHERE continent is NULL
GROUP BY location
ORDER BY TotalDeathCount DESC

--GLOBAL NUMBERS

-- Highest death rate globally per infection.

SELECT date, SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as INT)) AS total_deaths
, (SUM(CAST(new_deaths as INT)) / SUM(new_cases)) * 100 AS death_rate
FROM CovidDeaths
WHERE continent is not NULL
GROUP BY date
ORDER BY 1, 2

--Global death rate

SELECT SUM(new_cases) AS total_cases, SUM(CAST(new_deaths as INT)) AS total_deaths, (SUM(CAST(new_deaths as INT)) / SUM(new_cases)) * 100 AS death_rate
FROM CovidDeaths
WHERE continent is not NULL
--GROUP BY date
ORDER BY 1, 2


-- WE WILL DO A JOIN OF THE TWO TABLES (CovidDeaths AND CovidVaccinations) ON DATE AND LOCATION
--(In order to be able to work with data in the CovidVaccinations table)

SELECT *
FROM CovidDeaths Dea
JOIN CovidVaccinations Vacc
	ON Dea.location = Vacc.location
	AND Dea.date = Vacc.date


-- Looking at the Total Population vs Vaccinations.

SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vacc.new_vaccinations
	, SUM(CONVERT(FLOAT, Vacc.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)
		AS rolling_vaccinated_count, (rolling_vaccinated_count/population)*100
FROM CovidDeaths Dea
JOIN CovidVaccinations Vacc
	ON Dea.location = Vacc.location
	AND Dea.date = Vacc.date
	WHERE Dea.continent is not NULL
	--ORDER BY 2, 3

--The above wouldn't work because 'rolling_vaccinated_count' is a calculated field which doesn't exist in any of the tables hence, 
--cannot be used for further calculation.  
--USE CTE (Common Table Expression)

WITH PopvsVacc AS
(
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vacc.new_vaccinations
	, SUM(CONVERT(FLOAT, Vacc.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)
		AS rolling_vaccinated_count--, (rolling_vaccinated_count/population)*100 
FROM CovidDeaths Dea
JOIN CovidVaccinations Vacc
	ON Dea.location = Vacc.location
	AND Dea.date = Vacc.date
	WHERE Dea.continent is not NULL
	--ORDER BY 2, 3
)

SELECT *, (rolling_vaccinated_count/population)*100 AS VaccinationRate
FROM PopvsVacc


-- Or use a Temp Table 
-- TEMP TABLE

DROP TABLE IF exists #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date datetime,
population numeric,
new_vaccination numeric,
rolling_vaccinated_count numeric,
)

INSERT INTO #PercentPopulationVaccinated
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vacc.new_vaccinations
	, SUM(CONVERT(FLOAT, Vacc.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)
		AS rolling_vaccinated_count--, (rolling_vaccinated_count/population)*100 
FROM CovidDeaths Dea
JOIN CovidVaccinations Vacc
	ON Dea.location = Vacc.location
	AND Dea.date = Vacc.date
	WHERE Dea.continent is not NULL
	--ORDER BY 2, 3

SELECT *, (rolling_vaccinated_count/population)*100 AS VaccinationRate
FROM #PercentPopulationVaccinated



-- Creating View to Store Data for Future Visualizations

CREATE VIEW PercentPopulationVaccinated AS
SELECT Dea.continent, Dea.location, Dea.date, Dea.population, Vacc.new_vaccinations
	, SUM(CONVERT(FLOAT, Vacc.new_vaccinations)) OVER (PARTITION BY Dea.location ORDER BY Dea.location, Dea.date)
		AS rolling_vaccinated_count--, (rolling_vaccinated_count/population)*100 
FROM CovidDeaths Dea
JOIN CovidVaccinations Vacc
	ON Dea.location = Vacc.location
	AND Dea.date = Vacc.date
	WHERE Dea.continent is not NULL
	--ORDER BY 2, 3



