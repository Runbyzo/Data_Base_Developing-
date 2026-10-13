- проверяю работу селект со звездочкой
select * from doc_package;

- пробую селект с кличкой для поля с условием в виде таkекстового фильтра
select person_name as "имя владельцов пакета документов" from doc_package where person_name like '%3%';

- умножаю ценники у первых 10 покупок
select
	id,
	order_id,
	100 * amount as "new price"
from payment
where id between 1 and 10;

- выборка неповторяемых элементов
select distinct meal_plan from hotel;

- выборка отелей c разнами типами условий
select id, name, city, stars, meal_plan from hotel where city not in ('Город 4', 'Город 5', 'Город 20');

select id, name, city, stars, meal_plan from hotel where city in ('Город 4', 'Город 5');

select id, name, city, stars, meal_plan from hotel where city = 'Город 4' or city = 'Город 5';

select id, name, city, stars, meal_plan from hotel where city = 'Город 4';

select id, name, city, stars, meal_plan from hotel where city = 'Город 5';

select id, name, city, stars, meal_plan from hotel where city = 'Город 4' and name = 'Отель 23' or name = 'Отель 43';

select id, name, city, stars, meal_plan from hotel where city = 'Город 5' and name = 'Отель 24' or name = 'Отель 43';


--------------------------------------------------------------------------------
- добавил две строки в табличку с отзывами чтобы протестировать проверку на нулл
insert into client_review (id, order_id, rating, review_text, created_at) values 
(101,
1,
NULL,
'7 ночей в каком-то непонятном Отеле номер один в городе номер два с планом питония UAI НИКОМУ НЕ РЕКОМЕНДУЮ',
'2024-04-28 10:00:00');


insert into client_review (id, order_id, rating, review_text, created_at) values 
(102,
2,
5,
'мама попросила написать отзыв чтобы мы получили скидку на следующий заказ. Рекомендую',
NULL);
---------------------------------------------------------------------------------

- ищем булщит с неизвестным значением в поле
select * from client_review cr where rating is null or review_text is null or cr.created_at is null 

- три запроса с групировками и выставлением порядка
select id, total_amount  from "order" o  where id between 1 and 20 group by id, total_amount

select id, total_amount  from "order" o  where id between 1 and 20 group by id, total_amount having o.total_amount > 60000

select id,total_amount  
from "order" o  
where id between 1 and 20 
group by id, total_amount 
having o.total_amount > 60000 
order by total_amount desc

- использую апдейт и делит чтобы манипулировать данными в таблице с отелями и отзывами 
update hotel set name = 'SANTA GRAND' where id = 100

delete from client_review where rating is null or created_at is null