
SELECT *
FROM CovidProject..CovidDeaths
ORDER BY 3, 4




SELECT *
FROM CovidProject..CovidVaccinations
ORDER BY 3, 4




-- Select the Data that we are going to be using
SELECT location, date, total_cases, new_cases, total_deaths, population
FROM CovidProject..CovidDeaths
ORDER BY 1, 2 --Location ve Date'e göre sýralatýyorum.




-- Looking at Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths,
CASE
	WHEN total_cases = 0 THEN 0
	ELSE (total_deaths/total_cases)*100
END AS death_percentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2




-- Shows the likelihood of dying if you get covid in United States (at the last row)
SELECT location, date, total_cases, total_deaths,
CASE
	WHEN total_cases = 0 THEN 0
	ELSE (total_deaths/total_cases)*100
END AS death_percentage
FROM CovidProject..CovidDeaths
WHERE location like '%states%' 
ORDER BY 1, 2




-- Looking at Total Cases vs Population
-- Shows what percentage of population got covid
SELECT location, date, population, total_cases, (total_cases/population)*100 as percent_population_infected
FROM CovidProject..CovidDeaths
WHERE location = 'Turkey' and total_cases <> 0
ORDER BY 1, 2




-- Looking at Countries with Highest Infection rate compared to Population
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS percent_population_infected
FROM CovidProject..CovidDeaths
GROUP BY location, population
ORDER BY percent_population_infected DESC




-- Looking at Countries Dead Count
SELECT continent, location, MAX(total_deaths) AS total_dead_count
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location
ORDER BY total_dead_count DESC




-- Looking at Countries with Highest Dead rate compared to Population
SELECT continent, location, population, MAX(total_deaths) AS total_dead_count, MAX((total_deaths/population)*100) AS percent_population_dead
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population
ORDER BY percent_population_dead DESC




-- Let's break things down by continent
SELECT continent, MAX(total_deaths) AS total_dead_count
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent
ORDER BY total_dead_count DESC

---- Burada datada continent'i null olan ve location'unda continent isimleri ya da sýnýflandýrma isimleri yazýlý olan veriler var
---- Kýtalardaki toplam ölümlerin gerçek deðerini görmek için bu queryi kullan.
--SELECT location, MAX(total_deaths) AS total_dead_count
--FROM CovidProject..CovidDeaths
--WHERE continent IS NULL 
--GROUP BY location
--ORDER BY total_dead_count DESC




-- GLOBAL NUMBERS // ATW is short for Around The World // Data is weekly
SELECT date, SUM(new_cases) AS new_cases_ATW, SUM(new_deaths) AS new_deaths_ATW, 
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE (SUM(new_deaths)/SUM(new_cases))*100
END AS death_ratio_for_the_week
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date
ORDER BY 1, 2

---- I was confused for why there was %150 death on the first week of 2020. Germany's data...
--SELECT *
--FROM CovidProject..CovidDeaths
--WHERE date = '2020-01-05 00:00:00.000' and continent IS NOT NULL and (new_cases <> 0 OR new_deaths <> 0)
--ORDER BY 3, 4
--Global total aþaðýdaki de
SELECT SUM(new_cases) AS total_cases_ATW, SUM(new_deaths) AS total_deaths_ATW, 
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE (SUM(new_deaths)/SUM(new_cases))*100
END AS total_death_ratio
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
ORDER BY 1, 2




-- Switching to the other table
-- Looking at the total population vs vaccination
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
ORDER BY 2, 3




-- vac.total_vaccinations kullanarak o güne kadar yapýlan toplam aþý sayýsýný görebiliriz.
-- bunun yerine bu deðeri yeni bir sütunda kendimiz hesaplatacaðýz.
-- Using CTE to get VACCED_rate, since you cannot use a column you created in the same select statement (VACCED_total)
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, VACCED_total)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VACCED_total
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (VACCED_total/population)*100 AS VACCED_rate
FROM PopvsVac




-- TEMP TABLE
DROP TABLE IF EXISTS #PercentPopulationVaccinated
CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)
-- VACCED_total = RollingPeopleVaccinated
INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VACCED_total
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
--WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3

SELECT *, (RollingPeopleVaccinated/Population)*100 AS TotalVaccinationRate
FROM #PercentPopulationVaccinated




-- CREATING VIEW TO STORE DATA FOR LATER VISUALIZATIONS

CREATE VIEW PercentPopulationVaccinated AS
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VACCED_total
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
--ORDER BY 2, 3


SELECT *
FROM PercentPopulationVaccinated


--CREATING SOME VIEWS FOR VISUALIZATION

CREATE VIEW DeathsOverCasesPercentage AS
SELECT location, date, total_cases, total_deaths,
CASE
	WHEN total_cases = 0 THEN 0
	ELSE (total_deaths/total_cases)*100
END AS death_percentage
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL

CREATE VIEW TurkeyPercentageInfected AS
SELECT location, date, population, total_cases, (total_cases/population)*100 as percent_population_infected
FROM CovidProject..CovidDeaths
WHERE location = 'Turkey' and total_cases <> 0

CREATE VIEW HighestPercentInfected AS
SELECT location, population, MAX(total_cases) AS highest_infection_count, MAX((total_cases/population)*100) AS percent_population_infected
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY location, population

CREATE VIEW HighestPercentDeath AS
SELECT continent, location, population, MAX(total_deaths) AS total_dead_count, MAX((total_deaths/population)*100) AS percent_population_dead
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY continent, location, population

CREATE VIEW TotalDeathOverContinents AS
SELECT location, MAX(total_deaths) AS total_dead_count
FROM CovidProject..CovidDeaths
WHERE continent IS NULL AND location NOT IN('World', 'High-income countries', 'Upper-middle-income countries', 'European Union (27)', 
'Lower-middle-income countries', 'Low-income countries')
GROUP BY location

CREATE VIEW GlobalDeathsOverCasesPercentage AS
SELECT date, SUM(new_cases) AS new_cases_ATW, SUM(new_deaths) AS new_deaths_ATW, 
CASE
	WHEN SUM(new_cases) = 0 THEN 0
	ELSE (SUM(new_deaths)/SUM(new_cases))*100
END AS death_ratio_for_the_week
FROM CovidProject..CovidDeaths
WHERE continent IS NOT NULL
GROUP BY date

CREATE VIEW VaccinationRate AS
WITH PopvsVac (Continent, Location, Date, Population, New_vaccinations, VACCED_total)
AS
(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
SUM(CONVERT(bigint, new_vaccinations)) OVER (PARTITION BY dea.location ORDER BY dea.location, dea.date) AS VACCED_total
FROM CovidProject..CovidDeaths dea
JOIN CovidProject..CovidVaccinations vac
	ON dea.location = vac.location AND dea.date = vac.date
WHERE dea.continent IS NOT NULL
)
SELECT *, (VACCED_total/population)*100 AS VACCED_rate
FROM PopvsVac

------------------------------------------------------------------

