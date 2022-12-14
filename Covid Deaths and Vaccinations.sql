--Check to see that data imported correctly

SELECT *
FROM [PortfolioProject].[dbo].[Covid deaths]
ORDER BY 3,4

/* SELECT *
FROM [PortfolioProject].[dbo].[Covid vaccinations]
ORDER BY 3,4 */

-- Total Cases vs Total Deaths
SELECT location, date, total_cases, total_deaths, ((1.0*total_deaths)/total_cases)*100 as DeathPercentage -- 1.0* needed to convert operand to float so as to not perform integer division
FROM [PortfolioProject].[dbo].[Covid deaths]
WHERE continent is not null
ORDER BY 1,2

-- Total Cases vs Population
SELECT location, date, total_cases, population, ((1.0*total_cases)/population)*100 as InfectedPercentage 
FROM [PortfolioProject].[dbo].[Covid deaths]
WHERE continent is not null
ORDER BY 1,2

-- Countries with Highest Infection Count vs Population
SELECT location, max(total_cases) as HighestInfectionCount, population, max((1.0*total_cases)/population)*100 as HighestInfectionPercentage 
FROM [PortfolioProject].[dbo].[Covid deaths]
WHERE continent is not null
GROUP BY location, population
ORDER BY HighestInfectionPercentage DESC

-- Countries with Highest Death Count vs Population
SELECT location, max(total_deaths) as HighestDeathCount, population, max((1.0*total_deaths)/population)*100 as HighestDeathPercentage 
FROM [PortfolioProject].[dbo].[Covid deaths]
WHERE continent is not null
GROUP BY location, population
ORDER BY HighestDeathPercentage DESC

-- Continents with Highest Death Count vs Population
SELECT location, max(total_deaths) as TotalDeathCount, max(population) as Population, max((1.0*total_deaths)/population)*100 as HighestDeathPercentage
FROM [PortfolioProject].[dbo].[Covid deaths]
WHERE continent is null
GROUP BY location
ORDER BY HighestDeathPercentage DESC


-- Global New Cases vs New Deaths by day
SELECT date, sum(new_cases) as NewCases , sum(new_deaths) as NewDeaths, sum(new_deaths)*1.0/sum(new_cases)*100 as DeathPercentage
FROM [PortfolioProject].[dbo].[Covid deaths]
WHERE continent is not null
GROUP BY date
ORDER BY 1,2

-- Total Population vs Vaccinations (Merge Death data to Vaccination data)
    -- By creating CTE
WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingTotalVaccinations)
AS(
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) as RollingTotalVaccinations
FROM [PortfolioProject].[dbo].[Covid deaths] as dea
JOIN [PortfolioProject].[dbo].[Covid vaccinations] as vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is not null
)

SELECT *, ((1.0*RollingTotalVaccinations)/Population)*100 as PopulationPercentVaccinated
FROM PopvsVac
ORDER BY 2,3

    -- By creating Temp Table
DROP Table if exists #PercentPopulationVaccinated 
CREATE TABLE #PercentPopulationVaccinated
(
    Continent nvarchar(255),
    Location NVARCHAR(255),
    Date datetime,
    Population numeric,
    New_vaccinations numeric,
    RollingTotalVaccinations NUMERIC

)

INSERT INTO #PercentPopulationVaccinated
SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) as RollingTotalVaccinations
FROM [PortfolioProject].[dbo].[Covid deaths] as dea
JOIN [PortfolioProject].[dbo].[Covid vaccinations] as vac
    ON dea.location = vac.location
    AND dea.date = vac.date
WHERE dea.continent is not null

SELECT *, ((1.0*RollingTotalVaccinations)/Population)*100 as PopPercentVaccinated
FROM #PercentPopulationVaccinated
ORDER BY 2,3

--Create View to store data for later visualizations
CREATE VIEW PopulationPercentVaccinated as
    WITH PopvsVac(Continent, Location, Date, Population, New_Vaccinations, RollingTotalVaccinations)
    AS(
    SELECT dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations, sum(new_vaccinations) OVER (PARTITION BY dea.location ORDER BY dea.location , dea.date) as RollingTotalVaccinations
    FROM [PortfolioProject].[dbo].[Covid deaths] as dea
    JOIN [PortfolioProject].[dbo].[Covid vaccinations] as vac
        ON dea.location = vac.location
        AND dea.date = vac.date
    WHERE dea.continent is not null
    )

    SELECT *, ((1.0*RollingTotalVaccinations)/Population)*100 as PopulationPercentVaccinated
    FROM PopvsVac
GO

CREATE VIEW DeathPercentage as
    SELECT location, date, total_cases, total_deaths, ((1.0*total_deaths)/total_cases)*100 as DeathPercentage
    FROM [PortfolioProject].[dbo].[Covid deaths]
    WHERE continent is not null
GO

CREATE VIEW InfectedPercentage as
    SELECT location, date, total_cases, population, ((1.0*total_cases)/population)*100 as InfectedPercentage 
    FROM [PortfolioProject].[dbo].[Covid deaths]
    WHERE continent is not null
GO

CREATE VIEW HighestInfectionPercentage as
    SELECT location, max(total_cases) as HighestInfectionCount, population, max((1.0*total_cases)/population)*100 as HighestInfectionPercentage 
    FROM [PortfolioProject].[dbo].[Covid deaths]
    WHERE continent is not null
    GROUP BY location, population
GO

CREATE VIEW CountryHighestDeathPercentage as
    SELECT location, max(total_deaths) as HighestDeathCount, population, max((1.0*total_deaths)/population)*100 as HighestDeathPercentage 
    FROM [PortfolioProject].[dbo].[Covid deaths]
    WHERE continent is not null
    GROUP BY location, population
GO

CREATE VIEW ContinentHighestDeathPercentage as
    SELECT location, max(total_deaths) as TotalDeathCount, max(population) as Population, max((1.0*total_deaths)/population)*100 as HighestDeathPercentage
    FROM [PortfolioProject].[dbo].[Covid deaths]
    WHERE continent is null
    GROUP BY location
GO

DROP VIEW IF EXISTS [dbo].RollingTotalVaccinations