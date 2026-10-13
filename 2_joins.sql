-- inner join
-- поиск общей инфы о лекарстве
select si.quantity, si.unit_price, med.name, med.price 
from sale_items as si
inner join medicines as med
on si.medicine_id = med.id;

-- right join
-- поиск страны которое ничего не производит
select med.name, med.price, man.name, man.country 
from medicines med
right join manufacturers man  
on  man.manufacturer_id = med.manufacturer_id  
where med.price is null


-- left join
-- поиск лекарств с информацией о стране производителе
select med.name, med.price, man.name, man.country 
from medicines med
left join manufacturers man  
on  man.manufacturer_id = med.manufacturer_id  

-- full join
-- сбор иныормации о продажах и покупателях c выявлением несовпадений
select s.*, c.first_name, c.last_name 
from sales as s 
full join customers c
on s.customer_id = c.customer_id; 

-- cross join
-- информация всех возможных парах лекарство - проданый элемент
select m.name, si.quantity, si.unit_price
from medicines as m
cross join sale_items as si;

-- self join
-- поиск начальника
select em.first_name || ' ' || em.last_name AS employee,
em2.first_name || ' ' || em2.last_name AS big_boss
FROM employee_med em
LEFT JOIN employee_med as em2
ON em.manager_id = em2.emp_id
where em.manager_id is null;

-- big query
-- сколько, какие, от кого и откуда лекарств было куплено
select si.quantity, med.name as "medicine name", man.name as "manufacturer", man.country
from sale_items si 
inner join medicines as med on si.medicine_id = med.id 
inner join manufacturers as man on med.manufacturer_id = man.manufacturer_id 



-- UNION
-- обьединение имен лекарств и имен производителей
select name from medicines 
union 
select name from manufacturers;

-- INTERSECT
-- поиск покупателей которые хоть раз покупали хоть что-то
select first_name from customers 
intersect
select c.first_name from customers as c
join sales as s on c.customer_id = s.customer_id;

-- EXCEPT
-- найти страны которые ничего не производят
select name from manufacturers 
except 
select m.name from manufacturers as m
join medicines as med on med.manufacturer_id = m.manufacturer_id

