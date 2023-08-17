use covid_db;

select * from CovidDeaths
where continent is not null
order by location, date;

select location, date, total_cases, new_cases, total_deaths, population
from CovidDeaths
order by 1,2;

-- change data type of two column to allow rate calculation
alter table CovidDeaths
alter column total_cases FLOAT Null;

alter table CovidDeaths
alter column total_deaths FLOAT Null;


-- looking at total cases vs. total deaths
select location, date, total_cases, total_deaths, 
(case when total_deaths is null then null else (total_deaths/total_cases)*100 end) AS deathpercentage
from CovidDeaths
where location = 'Netherlands'
order by 1,2;

select location, date, total_cases, total_deaths, 
(case when total_deaths is null then null else (total_deaths/total_cases)*100 end) AS deathpercentage
from CovidDeaths
where location = 'Netherlands'
order by 5 desc; -- The Netherlands attained almost a 13% death rate during in May 2020 


/*
select location, date, sum(total_cases), sum(total_deaths), (sum(total_deaths)/sum(total_cases))*100 AS Tot_deathpercentage
from CovidDeaths
group by location
order by 5 desc; */

-- Looking at total cases vs population
select location, date, total_cases, population,total_deaths, 
(case when total_deaths is null then null else (total_cases/population)*100 end) AS percentage_pop_infected
from CovidDeaths
where location = 'Netherlands'
order by 6 desc;  -- max infection rate of 8% in The Netherlands

-- which countries have the highest infection rate
select location,  population, max(total_cases) as highest_infection_count, max((total_cases/population))*100 AS percentage_pop_infected
--(case when total_deaths is null then null else max((total_cases/population))*100 end) AS percentage_pop_infected
from CovidDeaths
group by location, population
order by 4 desc; -- Andorra reached the highest infection rate of 17%


-- Show countries with the highest death rate per population
select location, MAX(cast(total_deaths as int)) as Totaldeathcount, max((total_deaths/total_cases))*100 AS max_death_percent_infected
from CovidDeaths
where continent is not null
group by location
order by 2 desc;

-- Deaths per continent
select location, MAX(cast(total_deaths as int)) as Totaldeathcount, max((total_deaths/total_cases))*100 AS max_death_percent_infected
from CovidDeaths
where continent is null
group by location
order by 2 desc;


-- Global numbers
select sum(new_cases) as tot_cases, sum(new_deaths) as tot_deaths, (sum(cast(new_deaths as float))/sum(cast(new_cases as float)))*100 AS death_rate_newcases
from CovidDeaths
where continent is not null
-- group by date
order by 1,2 -- World wide death percentage is about 2%

-- Join Death and Vaccination tables
-- Look at total population vs vaccinations
with PopvsVac(continent,location, date, population, new_vaccinations, rolling_vacc_total)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations , 
sum(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as rolling_vacc_total -- Rolling count of vaccinations per location
from CovidDeaths dea
Join CovidVaccinations vac on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
-- order by 2,3;
)
select *, (convert(float,rolling_vacc_total)/(convert(float, population))*100) as rolling_vacc_rate
from PopvsVAc -- Gives a rolling vaccination rate per location


-- creating view to store data for visualizations
create view percent_pop_vacc as 
with PopvsVac(continent,location, date, population, new_vaccinations, rolling_vacc_total)
as 
(
select dea.continent, dea.location, dea.date, dea.population, vac.new_vaccinations , 
sum(vac.new_vaccinations) OVER (Partition by dea.location order by dea.location, dea.date) as rolling_vacc_total -- Rolling count of vaccinations per location
from CovidDeaths dea
Join CovidVaccinations vac on dea.location = vac.location 
and dea.date = vac.date
where dea.continent is not null
-- order by 2,3;
)
select *, (convert(float,rolling_vacc_total)/(convert(float, population))*100) as rolling_vacc_rate
from PopvsVAc -- Gives a rolling vaccination rate per location
