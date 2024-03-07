--select continent, location
--from PortfolioProject..CovidDeaths
--WHERE continent IS not NULL OR continent != ''


--select *
--from PortfolioProject..CovidDeaths
--order by 3,4;

select location, date, total_cases, new_cases, total_deaths, population
from PortfolioProject..CovidDeaths
order by 1,2;

-- Looking at Total Cases vs Total Deaths at Serbia
-- We need to convert total_deaths and total_cases to float because they are Strings so we can't do matematical operations on them.
-- Shows likelihood of dying if you contract covid in your country

select location, date, total_cases, total_deaths,
case
	when total_cases = 0 then null
	else (convert(float, total_deaths) / nullif(convert(float, total_cases), 0)) * 100
	end as DeathsPercentage
from PortfolioProject..CovidDeaths
where location = 'Serbia'
order by 1,2;

-- Looking at Total Cases vs Population at Serbia
-- Shows what percentage of population got Covid 

select location, date, population, total_cases,
case 
	when total_cases = 0 then null
	else (convert(float, total_cases) / nullif(convert(float, population), 0)) * 100
	end as PercentageOfPopulationInfected
from PortfolioProject..CovidDeaths
where location = 'Serbia'
order by 1,2;



-- Looking at Countries with Highest Infection Rate compared to Population

select location, population, max(convert(float,total_cases)) as HighestInfectionCount,
case 
	when max(convert(float,total_cases)) = 0 then null
	else max((convert(float, total_cases) / nullif(convert(float, population), 0))) * 100
	end as PercentageOfPopulationInfected
from PortfolioProject..CovidDeaths
group by location, population
order by PercentageOfPopulationInfected desc;


-- Looking Countries with Highest Deaths Count per Population, percentage
select location, population, max(convert(float, total_deaths))as HighestDeaths,
case 
	when max(convert(float, total_deaths)) = 0 then null
	else max((convert(float, total_deaths) / nullif(convert(float, population), 0))) * 100
	end as PercentageOfDeaths
	from PortfolioProject..CovidDeaths
	group by location, population
	order by PercentageOfDeaths desc;
	

-- Looking for Highest Count of Deaths per Population
select location, max(cast(total_deaths as int)) as TotalDeathsCount
from PortfolioProject..CovidDeaths
WHERE continent != ''
group by location
order by TotalDeathsCount desc;


select location, max(cast(total_deaths as int)) as TotalDeathsCount
from PortfolioProject..CovidDeaths
WHERE continent = ''
group by location
order by TotalDeathsCount desc;


-- Showing continents with the highest death count per population

select continent, max(cast(total_deaths as int))as TotalDeathCount
from PortfolioProject..CovidDeaths
where continent != ''
group by continent
order by TotalDeathCount desc;

--GLOBAL NUMBERS

select sum(cast(new_cases as float)) as total_cases, sum(cast(new_deaths as float)) as total_deaths,
case 
	when sum(cast(new_cases as float)) = 0 then null
	else sum(CAST(new_deaths as float)) / nullif(sum(cast(new_cases as float)), 0) * 100
	end as DeathPercentage
from PortfolioProject..CovidDeaths
where continent = ''
--group by date
order by 1 desc;


--Marge two tabels covidDeaths and covidVaccinations

select *
from PortfolioProject..CovidDeaths dea
join PortfolioProject..CovidVaccinations vac
	on dea.location = vac.location 
	and dea.date = vac.date;


-- Looking at Total Population vs Vaccination and we didn't get percentage of rolling people vaccination we then make cte
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date, dea.location) as RollingPeopleVac
from PortfolioProject..CovidDeaths dea 
join PortfolioProject..CovidVaccinations vac
 on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent != ''
order by 2,3;

--USE CTE (Common Table Expression)
with cte (continent, location, date, population, new_vaccinations, RollingPeopleVac)
as
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date, dea.location) as RollingPeopleVac
from PortfolioProject..CovidDeaths dea 
join PortfolioProject..CovidVaccinations vac
 on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent != ''
)
select *,
case
	when population = 0 then null
	else RollingPeopleVac/cast(population as float) *100
	end as PercentageofPopulation
from cte


--Temp table 
drop table if exists #PercentagePopulationVaccinated
create table #PercentagePopulationVaccinated
(continent nvarchar(255),
location nvarchar(255),
date nvarchar(100),
population nvarchar(255),
new_vaccinations nvarchar(255),
RollingPeopleVac numeric
)
insert into #PercentagePopulationVaccinated
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date, dea.location) as RollingPeopleVac
from PortfolioProject..CovidDeaths dea 
join PortfolioProject..CovidVaccinations vac
 on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent != ''

select *,
case
	when population = 0 then null
	else RollingPeopleVac/cast(population as float) *100
	end as PercentageofPopulation
from #PercentagePopulationVaccinated;


--Create View 
create view PercentPopulationVaccinated1 as
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations,
sum(cast(vac.new_vaccinations as int)) over (partition by dea.location order by dea.date, 
dea.location) as RollingPeopleVac
from PortfolioProject..CovidDeaths dea 
join PortfolioProject..CovidVaccinations vac
 on dea.location = vac.location 
	and dea.date = vac.date
where dea.continent != ''


select*
from PercentPopulationVaccinated1