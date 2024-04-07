select * from dbo.CovidVaccinations
order by 3,4

select * from dbo.CovidDeath
order by 3,4

-- Select Data that we are going to be using

Select Location, date, total_cases, new_cases, total_deaths, population
From dbo.CovidDeath
Where continent is not null 
order by 1,2


-- Lokking at Total Cases vs Total Deaths
-- Shows likelihood of dying if you contract covid in your country

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From dbo.CovidDeath
Where location like '%states%'
and continent is not null 
order by 1,2

Select Location, date, total_cases,total_deaths, (total_deaths/total_cases)*100 as DeathPercentage
From dbo.CovidDeath
Where location like '%kingdom%'
and continent is not null 
order by 1,2


-- Total Cases vs Population
-- Shows what percentage of population infected with Covid

Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From dbo.CovidDeath
--Where location like '%states%'
order by 1,2


Select Location, date, Population, total_cases,  (total_cases/population)*100 as PercentPopulationInfected
From dbo.CovidDeath
--Where location like '%kingdom%'
order by 1,2

-- Countries with Highest Infection Rate compared to Population

Select Location, Population, MAX(total_cases) as HighestInfection,  Max((total_cases/population))*100 as PopulationInfectedPercent
From dbo.CovidDeath
--Where location like '%kingdom%'
Group by Location, Population
order by PopulationInfectedPercent desc


-- Countries with Highest Death Count per Population

Select Location, MAX(cast(Total_deaths as int)) as TotalDeathNumber
From dbo.CovidDeath
--Where location like '%states%'
Where continent is not null 
Group by Location
order by TotalDeathNumber desc


Select Location, MAX(cast(Total_deaths as int)/population)*100 as PercentDeathperpopulation
From dbo.CovidDeath
--Where location like '%states%'
Where continent is not null 
Group by Location
order by PercentDeathperpopulation desc

Select Location, MAX(cast(Total_deaths as int)/population)*100 as PercentDeathperpopulation
From dbo.CovidDeath
Where location like '%state%'
--Where continent is not null 
Group by Location
order by PercentDeathperpopulation desc

Select Location, MAX(cast(Total_deaths as int)/population)*100 as PercentDeathperpopulation
From dbo.CovidDeath
Where location like '%kingdom%'
--Where continent is not null 
Group by Location
order by PercentDeathperpopulation desc
-- BREAKING THINGS DOWN BY CONTINENT

-- Showing contintents with the highest death count per population

Select continent, MAX(cast(Total_deaths as int)) as TotalDeathCount
From dbo.CovidDeath
--Where location like '%states%'
Where continent is not null 
Group by continent
order by TotalDeathCount desc



-- GLOBAL NUMBERS Case and Death

Select SUM(new_cases) as total_cases,  SUM(cast(new_deaths as float)) as total_deaths, SUM(cast(new_deaths as float))/SUM(cast(New_Cases as float))*100 as DeathPercentage
From dbo.CovidDeath
--Where location like '%states%'
where continent is not null 
--Group By date
order by 1,2



-- Total Population vs Vaccinations
-- Shows Percentage of Population that has recieved at least one Covid Vaccine

Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeath dea
Join dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
order by 2,3


-- Using CTE to perform Calculation on Partition By in previous query

With PopvsVac (Continent, Location, Date, Population, New_Vaccinations, RollingPeopleVaccinated)
as
(
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeath dea
Join dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 
--order by 2,3
)
Select *, (RollingPeopleVaccinated/Population)*100 as VacsinatdperPopulationpercentage
From PopvsVac



-- Using Temp Table to perform Calculation on Partition By in previous query

DROP Table if exists #PercentPopulationVaccinated
Create Table #PercentPopulationVaccinated
(
Continent nvarchar(255),
Location nvarchar(255),
Date datetime,
Population numeric,
New_vaccinations numeric,
RollingPeopleVaccinated numeric
)

Insert into #PercentPopulationVaccinated
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeath dea
Join dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
--where dea.continent is not null 
--order by 2,3

Select *, (RollingPeopleVaccinated/Population)*100 as percentVaccinatedperpopulation
From #PercentPopulationVaccinated




-- Creating View to store data for later visualizations

Create View PercentpopulationVaccinated as
Select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations
, SUM(CONVERT(int,vac.new_vaccinations)) OVER (Partition by dea.Location Order by dea.location, dea.Date) as RollingPeopleVaccinated
--, (RollingPeopleVaccinated/population)*100
From dbo.CovidDeath dea
Join dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
where dea.continent is not null 

