Select *
From PorfoilioProject.dbo.CovidDeaths
Order by 3,4

Select *
From PorfoilioProject.dbo.CovidVaccinations
Order by 3,4

Select location,date,total_cases,new_cases,total_deaths,population
From PorfoilioProject.dbo.CovidDeaths
Order by 1,2

/*looking at Total Case vs Total Death
show the likihood of dying if you infected Covid19 in VN*/
Select location,date,total_cases,total_deaths, (cast(total_deaths as numeric)/cast(total_cases as numeric))*100 as DeathPercentage
From PorfoilioProject.dbo.CovidDeaths
Order by 1,2

Select location,date,total_cases,total_deaths, (cast(total_deaths as numeric)/cast(total_cases as numeric))*100 as DeathPercentage
From PorfoilioProject.dbo.CovidDeaths
Where location like '%iet%'
Order by 1,2

/*Total case vs Population
the Percentage of population got covid*/
Select location,date,total_cases,population, (cast(total_cases as numeric)/cast(population as numeric))*100 as InfectedPercent
From PorfoilioProject.dbo.CovidDeaths
Where location like '%iet%'
Order by 1,2

/*Country with highest Infection rate compare to Population*/
Select location,population,Max(cast(total_cases as numeric)) as HighestInfectionCount, 
	Max((cast(total_cases as numeric)/cast(population as numeric))*100) as InfectionRate
From PorfoilioProject.dbo.CovidDeaths
Group by Location,population
Order by 4 DESC

/*Country with highest death count per population*/
Select location, Max(cast(total_deaths as numeric)) as TotalDeathCount
From PorfoilioProject.dbo.CovidDeaths
Where continent is not null /*get rid of the continent total values*/
Group by Location
Order by 2 DESC

/*check the max total death of the continent*/
Select location, Max(cast(total_deaths as numeric)) as TotalDeathCount
From PorfoilioProject.dbo.CovidDeaths
Where continent is null
Group by location
Order by 2 DESC

/*Global number*/
Select date, total_cases, total_deaths, (cast(total_deaths as numeric)/cast(total_cases as numeric))*100 as DeathPercentage
From PorfoilioProject.dbo.CovidDeaths
Where location like 'world'
Order by 4 desc

/*current deathrate*/
Select max(cast(total_cases as numeric)) as TotalCases, max(cast(total_deaths as numeric)) as TotalDeaths, 
	(max(cast(total_deaths as numeric))/max(cast(total_cases as numeric)))*100 as DeathPercentage
From PorfoilioProject.dbo.CovidDeaths
Where location like 'world'
Order by 1,2

/*Total Population vs Vaccinations*/

/*total Vaccination by day*/
Select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as numeric)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVac
From PorfoilioProject.dbo.CovidDeaths dea
Join PorfoilioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
Order by 2,3

/*Use CTE*/
With PopvsVac (Continent, Location, Date, Population,new_vaccinations, TotalVac)
	as (
Select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations,
	SUM(cast(vac.new_vaccinations as numeric)) 
	OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVac
From PorfoilioProject.dbo.CovidDeaths dea
Join PorfoilioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null
)
Select*,(TotalVac/Population)*100 as VacPercentage
From PopvsVac

/*Temp table*/
Drop table if exists #PercentPopulationVaccincated
Create Table #PercentPopulationVaccincated (
	Continent nvarchar(255),
	Location nvarchar(255),
	Date datetime,
	Population numeric,
	NewVac numeric,
	TotalVac numeric)
Insert into #PercentPopulationVaccincated
Select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations as NewVac,
	SUM(cast(vac.new_vaccinations as numeric)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVac
From PorfoilioProject.dbo.CovidDeaths dea
Join PorfoilioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date


/*Create View to store data for later visualization*/
Drop view if exists PercentPopulationVaccincated
Create View PercentPopulationVaccincated as
Select dea.continent,dea.location,dea.date,dea.population, vac.new_vaccinations as NewVac,
	SUM(cast(vac.new_vaccinations as numeric)) OVER (Partition by dea.location Order by dea.location, dea.date) as TotalVac
From PorfoilioProject.dbo.CovidDeaths dea
Join PorfoilioProject.dbo.CovidVaccinations vac
	On dea.location = vac.location
	and dea.date = vac.date
Where dea.continent is not null