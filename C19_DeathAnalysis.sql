--Basic query to confirm all data is present

SELECT *
FROM PortfolioProjectSQL.DBO.CovidDeaths
ORDER BY 1,2

SELECT * 
FROM PortfolioProjectSQL.DBO.CovidVaccinations
ORDER BY 1,2


--Looking at the total cases vs total death ratio worldwide

SELECT date, Location, total_cases, total_deaths, (total_deaths/total_cases)*100
FROM PortfolioProjectSQL..CovidDeaths
ORDER by 1,2

--Looking at the total cases vs total death ratio for New Zealand
--Provides likelihood of dying from contracting Covid in New Zealand 

SELECT date, Location, total_cases, total_deaths, (total_deaths/total_cases)*100 as 'Death Percentage'
FROM PortfolioProjectSQL..CovidDeaths
WHERE Location = '%zealand%'
ORDER by 1,2


--Looking at the Total cases vs the Population in New Zealand 

SELECT date, Location, total_cases, Population, (total_cases/Population)*100 as 'Death Percentage per Pop'
FROM PortfolioProjectSQL..CovidDeaths
WHERE Location like '%zealand%'
ORDER by 1,2


-- Highlighting the rise of the stringency index (NZ Government's strictness of reponse) 
-- when total cases and deaths began to increase

SELECT total_deaths, location, stringency_index, date, total_cases
FROM PortfolioProjectSQL.DBO.CovidDeaths
WHERE Location like '%zealand%'
ORDER by date


--Looking at Highest infection rate to population ratio

SELECT Location, Population, MAX(total_cases) as 'Highest Infection Count', MAX((total_cases/Population))*100 as 'Highest Infection per Pop by Country'
FROM PortfolioProjectSQL..CovidDeaths
GROUP by Location, Population
ORDER by [Highest Infection per Pop by Country] DESC


-- Looking at Countries with Highest Death count per Population 

SELECT Location, MAX(cast(total_deaths as int)) as 'Total Death Count'
FROM PortfolioProjectSQL..CovidDeaths
GROUP by Location
ORDER by [Total Death Count] DESC

-- Looking at the death rate by country from Covid, from patients with
-- prexisting cardiovascular conditions.

SELECT cdea.location, cdea.date, cdea.total_deaths, cvacs.cardiovasc_death_rate,
(cdea.total_deaths / cvacs.cardiovasc_death_rate) * 100 as CardiovascularCovidDeathRate
FROM CovidDeaths cdea
JOIN CovidVaccinations cvacs
ON cdea.location = cvacs.location
--WHERE cdea.location like '%zealand%'
ORDER by 1,2


-- Showing the death total of Covid by continent

SELECT continent, MAX(cast(total_deaths as int)) as 'Total Death Count by Continent'
FROM PortfolioProjectSQL..CovidDeaths
WHERE continent is not null
GROUP by continent
ORDER by [Total Death Count by Continent] DESC


-- Total Death Percentage by Country

SELECT location, SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProjectSQL..CovidDeaths
WHERE continent is not null 
GROUP by location
ORDER by 1,2 desc

--Total Death Percentage by World Pop

SELECT SUM(new_cases) as total_cases, SUM(cast(new_deaths as int)) as total_deaths, SUM(cast(new_deaths as int))/SUM(New_Cases)*100 as DeathPercentage
FROM PortfolioProjectSQL..CovidDeaths
WHERE continent is not null 
ORDER by 1,2 desc

-- Vaccinations (World)
--Shows the amount of people that received at least one dose + a rolling count per day

SELECT cdea.continent, cdea.location, cdea.date, cdea.population, cvacs.new_vaccinations
, SUM(CONVERT(int,cvacs.new_vaccinations)) OVER (Partition by cdea.location 
	ORDER by cdea.location, cdea.date) as 'Amount of People Vaccinated (Rolling)'
FROM PortfolioProjectSQL..CovidDeaths cdea
JOIN PortfolioProjectSQL..CovidVaccinations cvacs
	ON cdea.location = cvacs.location
	AND cdea.date = cvacs.date
WHERE cdea.continent is not null
ORDER by 2,3


--Using CTE to calculate the percentage of people vaccinated overtime

WITH PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
AS
(
SELECT cdea.continent, cdea.location, cdea.date, cdea.population, cvacs.new_vaccinations
, SUM(CONVERT(int,cvacs.new_vaccinations)) OVER (Partition by cdea.Location Order by cdea.location, cdea.Date) as RollingPeopleVaccinated
FROM PortfolioProjectSQL..CovidDeaths cdea
JOIN PortfolioProjectSQL..CovidVaccinations cvacs
	ON cdea.location = cvacs.location
	AND cdea.date = cvacs.date
WHERE cdea.continent is not null 

)
SELECT *, (RollingPeopleVaccinated/Population)*100 AS 'Percentage of Pop Vaccinated'
FROM PopvsVac

-- Create temp table to perform calculation of former query

CREATE TABLE #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

INSERT into #PercentPopulationVaccinated
SELECT cdea.continent, cdea.location, cdea.date, cdea.population, cvacs.new_vaccinations
, SUM(CONVERT(int,cvacs.new_vaccinations)) OVER (Partition by cdea.Location Order by cdea.location, cdea.Date) as RollingPeopleVaccinated
FROM PortfolioProjectSQL..CovidDeaths cdea
JOIN PortfolioProjectSQL..CovidVaccinations cvacs
	On cdea.location = cvacs.location
	AND cdea.date = cvacs.date


SELECT *, (RollingPeopleVaccinated/Population)*100
FROM #PercentPopulationVaccinated

--Creating a view to visualise data later in tableau

CREATE VIEW PercentPopulationVaccinated as
SELECT cdea.continent, cdea.location, cdea.date, cdea.population, cvacs.new_vaccinations
, SUM(CONVERT(int,cvacs.new_vaccinations)) OVER (Partition by cdea.Location Order by cdea.location, cdea.Date) as RollingPeopleVaccinated
FROM PortfolioProjectSQL..CovidDeaths cdea
JOIN PortfolioProjectSQL..CovidVaccinations cvacs
	On cdea.location = cvacs.location
	and cdea.date = cvacs.date
WHERE cdea.continent is not null 


