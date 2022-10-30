----probability of a person dying if he contracts covid-19 in Nigeria
select location,
	date,
	total_cases,
	total_deaths,
	(total_deaths/total_cases)*100 as DeathPercentage
	from Portfolio_Project..CovidDeaths
	where continent = 'Africa' and 
	date between '2020-01-01' and '2021-12-31'
	and location like '%nigeria%'
group by location,date,total_cases,total_deaths 

--percentage of population that contracted covid in Nigeria
select location,
	date,
	population,
	total_cases,
	ROUND((total_cases/population)*100,2) as PopulationPercentage
	from Portfolio_Project..CovidDeaths
	where continent = 'Africa' and 
	date between '2020-04-01' and '2021-12-01'
	and location like '%nigeria%'
group by location,date,total_cases,population

--country with highest infection rate compared to population
select DISTINCT (location)as dislocation,
	population,
	total_cases,
	MAX(total_cases) highestcases,
	Max(total_cases/population)*100 as  IPP
	from Portfolio_Project..CovidDeaths
	where date between '2020-04-01' and '2021-09-30'
	GROUP BY location,Population,total_cases
	order by IPP DESC
 
 --Country with the highest infection rate with respect to their population
Select
	Location,
	population,
	max(total_cases) as HighestInfectionCount,
	Max((total_cases/population)*100) as IPP
	FROM Portfolio_Project..CovidDeaths
	where location not in ('world','High income','Europe', 'Asia', 'European Union','Upper middle income', 'North America','Lower middle income')
	and continent is not null
	GROUP BY location,Population
	order by IPP desc
 --Country with the highest death rate with respect to their population
select 
	Location,
	population,
	max(cast(total_deaths as int)) as highestdeathcount,
	Max((total_deaths/population)*100) as DPP
	FROM Portfolio_Project..CovidDeaths
	where continent is not null
	GROUP BY Location,population
	order by highestdeathcount desc

select distinct (location) as all_
from Portfolio_Project..CovidDeaths
where continent is not null

--query by continent
select 
	continent,
	max(cast(total_deaths as int)) as highestdeathcount,
	Max((total_deaths/population)*100) as DPP
	FROM Portfolio_Project..CovidDeaths
	where continent is not null
	GROUP BY continent

select 
	--location,
	distinct (continent),
	max(cast(total_deaths as int)) as highestdeathcount,
	Max((total_deaths/population)*100) as DPP
	FROM Portfolio_Project..CovidDeaths
	where continent is not null
	GROUP BY continent
	order by highestdeathcount 
	
--Global New_cases to new_death Per day Query
SELECT
	date,
	(new_casesperday/new_deathperday)*100 as GCP
	FROM(
select
	date,
	sum(new_cases) over(partition by date order by date) as new_casesperday,
	sum(cast(new_deaths as int)) over(partition by date order by date) as new_deathperday
	--(new_casesperday/new_deathperday)*100 as GDP
FROM Portfolio_Project..CovidDeaths
WHERE new_cases is not null and new_deaths is not null
and new_cases > 0 and new_deaths > 0
) GLOBAL

--Global new_death to New_cases Per day Query
SELECT
	--date,
	(new_deathperday/new_casesperday)*100 as GDP
	FROM(
select
	--date,
	sum(new_cases) over(partition by date order by date) as new_casesperday,
	sum(cast(new_deaths as int)) over(partition by date order by date) as new_deathperday
	--(new_casesperday/new_deathperday)*100 as GDP
FROM Portfolio_Project..CovidDeaths
WHERE CONTINENT IS NOT NULL
--WHERE new_cases is not null and new_deaths is not null
--and new_cases > 0 and new_deaths > 0
) GLOBAL

--GCP AND GDP
SELECT
	date,
	(new_deathperday/new_casesperday)*100 as GDP,
	(new_casesperday/new_deathperday)*100 as GCP
FROM(
select
	date,
	sum(new_cases) over(partition by date order by date) as new_casesperday,
	sum(cast(new_deaths as int)) over(partition by date order by date) as new_deathperday
	--(new_casesperday/new_deathperday)*100 as GDP
FROM Portfolio_Project..CovidDeaths
WHERE new_cases is not null and new_deaths is not null
and new_cases > 0 and new_deaths > 0
) GLOBAL
Select 
	sum(new_cases) as new_casesperday,
	sum(cast(new_deaths as int)) as new_deathperday,
	sum(new_cases)/sum(cast(new_deaths as int))*100 as GDP
FROM Portfolio_Project..CovidDeaths
where continent is not null
order by 1,2

--Query total population vs Vaccinations

WITH PopvsVac (continent,location,date,population,new_vaccinations,RollingPopulationVaccinated)
as (
select dea.continent,dea.location, dea.date,dea.population, vac.new_vaccinations,
sum(cast(new_vaccinations as bigint)) over(partition by dea.location order by dea.date) as RollingPopulationVaccinated
--(RollingPopulationVaccinated/population)*100
from Portfolio_Project..CovidDeaths dea
 join Portfolio_Project..CovidVaccinations vac
 on dea.location = vac.location
 and dea.date = vac.date
 where dea.continent is not null
)
select *,(RollingPopulationVaccinated/population)*100
from PopvsVac
group by continent,location,population,date,new_vaccinations,RollingPopulationVaccinated

--Temp Table
Drop table if exists #PopvsVac  
Create table #PopvsVac
(continent varchar(55),
location varchar(55),
date datetime,
population numeric,
new_vaccinations numeric,
RollingPopulationVaccinated numeric)

Insert into #PopvsVac
select dea.continent,
       dea.location,
       dea.date,
       dea.population,
       vac.new_vaccinations,
       sum(cast(new_vaccinations as bigint)) over (partition by dea.location order by dea.date) as RollingPopulationVaccinated
--(RollingPopulationVaccinated/population)*100
from Portfolio_Project..CovidDeaths dea
    join Portfolio_Project..CovidVaccinations vac
        on dea.location = vac.location
           and dea.date = vac.date
where dea.continent is not null

select *,
	  (RollingPopulationVaccinated/population)*100
from
#PopvsVac


--select  sum(cast(new_vaccinations as bigint))
--from CovidVaccinations


Create view Globalcasesperday_vs_Globalcasedeathperday as
SELECT
	date,
	(new_deathperday/new_casesperday)*100 as GDP,
	(new_casesperday/new_deathperday)*100 as GCP
FROM(
select
	date,
	sum(new_cases) over(partition by date order by date) as new_casesperday,
	sum(cast(new_deaths as int)) over(partition by date order by date) as new_deathperday
	--(new_casesperday/new_deathperday)*100 as GDP
FROM Portfolio_Project..CovidDeaths
WHERE new_cases is not null and new_deaths is not null
and new_cases > 0 and new_deaths > 0
) GLOBAL
--Select 
--	sum(new_cases) as new_casesperday,
--	sum(cast(new_deaths as int)) as new_deathperday,
--	sum(new_cases)/sum(cast(new_deaths as int))*100 as GDP
--FROM Portfolio_Project..CovidDeaths
--where continent is not null
--order by 1,2