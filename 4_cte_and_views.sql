-- топ отелей по количеству звезд
with hotel_ranking as (
	select 
		h."name",
		h.stars, 
		h.meal_plan_id,
		mp.name as "meal_name",
		dense_rank() over (partition by h.meal_plan_id order by h.stars desc) as stars_rank
	from hotel h 
	join meal_plan mp on h.meal_plan_id = mp.id
)
select name, meal_name, stars, meal_plan_id, stars_rank
from hotel_ranking 
where stars_rank <= 4
order by stars_rank, meal_name;

-- продажи туров по месяцам
with tour_sales as (
select 
	t.name as tour_name, 
	o.notes as tour_notes, 
	date_trunc('month', o.created_at)::date as months,
	sum(o.paid_amount) as sum_amount
from "order" o
join "tour" t on o.tour_id = t.id
group by tour_name, tour_notes, months
)
select tour_name, tour_notes, months,
	sum(sum_amount) over (partition by tour_name order by months) as growing_result
from tour_sales
order by months, growing_result;

-- продажи туров по месяцам со столбцом предидущего сумирования для линейного сравнения
with tour_sales as (
select 
	o.notes as order_notes, 
	date_trunc('month', o.created_at)::date as months,
	sum(o.paid_amount) as sum_amount
from "order" o
group by o.notes, months
)
select order_notes, months, sum_amount,
lag(sum_amount, 1, 0) over (order by months) as previous_amounts 
from tour_sales
order by months, order_notes;

-- продажи туров по месяцам где у каждого месяца своя табличка
select 
	t.name,
	sum(case when extract('month' from o.created_at) = 6 then o.total_amount else 0 end) as "Juni",
	sum(case when extract('month' from o.created_at) = 7 then o.total_amount else 0 end) as "Juli",
	sum(case when extract('month' from o.created_at) = 8 then o.total_amount else 0 end) as "August",
	sum(case when extract('month' from o.created_at) = 9 then o.total_amount else 0 end) as "September",
	sum(case when extract('month' from o.created_at) = 10 then o.total_amount else 0 end) as "October"
from "order" o
join tour t on o.tour_id = t.id
group by t.name
order by t.name;

-- лист заказов в стамбул
create or replace view "istambul_cruise_list" as
select id, client_id, tour_id, manager_id, status_id, created_at, total_amount, paid_amount, notes
from "order" o
where o.tour_id = 10;

select * from istambul_cruise_list;

---------------------------------------------
-- добавил данные в основную таблицу через представление
insert into istambul_cruise_list (id, client_id, tour_id, manager_id, status_id, created_at, total_amount, paid_amount, notes)
values (51, 2, 10, 3, 1, now(), 3300, 3000, 'cabin with balcony');

select * from "order" where tour_id = 10 and paid_amount = 3000;

-- удалил
delete from istambul_cruise_list where id = 51;

select * from "order" where tour_id = 10 and paid_amount = 3000;

---------------------------------------------
-- неизменяемая статистика туров по продажам и количеству клиентов
create or replace view tour_summary as 
select 
	t.name,
	sum(o.paid_amount) as total_gain,
	count(distinct o.client_id) as total_client
from "order" as o
join tour t on o.tour_id = t.id
group by t.name;

select * from tour_summary;

---------------------------------------------
-- запрос из под таблицы со статистикой
select * from tour_summary where total_gain >= 10000;

---------------------------------------------
-- материализованная таблица всех лучших туров
create materialized view best_hotels as 
select
	name,
	city_id,
	stars,
	description
from hotel
where stars = 5;

select * from best_hotels;

-- обновил данные в основной таблице а затем и в материализованной таблице
delete from hotel where id = 16;
insert into hotel (id, name, city_id, stars, meal_plan_id, description)
values (16, 'super puper coll hotel osaka', 9, 5, 5, 'this hotel is pure paradise');

select * from best_hotels;

refresh materialized view best_hotels;

select * from best_hotels;
