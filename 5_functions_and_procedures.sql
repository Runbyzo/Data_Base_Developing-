-- 1.1 ищем полную сумму заработанную менеджером по id
create or replace function
manager_gained_amount(chosen_manager_id int)
returns INT as $$
declare
	income int;
	is_manager_exist boolean;
begin
	select exists(select 1 from "order" where manager_id = chosen_manager_id) into is_manager_exist;

	if not is_manager_exist then raise exception 'this manager doesnt exist';
	end if;

	select sum(o.paid_amount)
	into income
	from "order" as o
	where o.manager_id = chosen_manager_id;

	return income;
end;
$$ language plpgsql;



select distinct 4 as "manager id" , manager_gained_amount(4) as "managers gaines from sales"
from "order" as o;


-- 1.2 вытаскиваю инфу о туре по его id
drop function tour_info(int);
create function tour_info(
	chosen_tour_id int,
	out t_name varchar,
	out t_category_id int,
	out t_price_adult int,
	out t_description text
) language plpgsql as $$
begin 
	select t.name, t.category_id, t.price_adult, t.description into t_name, t_category_id, t_price_adult, t_description
	from tour t where t.id = chosen_tour_id;

	if not found then raise exception 'not found anything with such id'; end if;
end;
$$;

select * from tour_info(15);

-- 1.3 ищу статистику менеджера по продажам туров со скользащей суммой
drop function get_managers_stat(int);
create function get_managers_stat(chosen_id int)
returns table (
	manager_id int,
	tour_id int,
	income NUMERIC(12, 2)
)
language plpgsql as $$ 
begin
	return query
	select o.manager_id, o.tour_id, sum(o.paid_amount) over (partition by o.manager_id order by o.tour_id)
	from "order" as o
	where o.manager_id = chosen_id;
end;
$$;

select * from get_managers_stat(4);

-- 2 процедура которая автоматически автоматически добавляет в комментарий заказа об неоплате если текста нет
drop procedure process_payment_check(int,boolean,text);
CREATE PROCEDURE process_payment_check(
    IN  p_client_id INT,
    OUT is_success  BOOLEAN,
    OUT message     TEXT
)
LANGUAGE plpgsql
AS $$
BEGIN
    BEGIN
        PERFORM 1
        FROM "order" o
        WHERE o.client_id = p_client_id
        FOR UPDATE;

        IF NOT FOUND THEN RAISE EXCEPTION 'order doesnt exist'; END IF;

        IF EXISTS (SELECT 1 FROM "order" o WHERE o.client_id = p_client_id AND COALESCE(o.paid_amount, 0) >= COALESCE(o.total_amount, 0)
        ) THEN RAISE EXCEPTION 'order is paid already'; END IF;

        UPDATE "order" o
        SET notes = concat_ws(', ', NULLIF(o.notes, ''), 'client did not pay'), total_amount = o.total_amount * 2
        WHERE o.client_id = p_client_id;

    EXCEPTION WHEN OTHERS THEN is_success := FALSE; message := SQLERRM;
    END;

    IF is_success IS FALSE THEN
        ROLLBACK;
    ELSE
        COMMIT;
        is_success := TRUE;
        message := 'success';
    END IF;
END;
$$;

select o.client_id, o.paid_amount , o.manager_id, o.notes from  "order" as o where o.client_id = 13 and o.manager_id = 13; 
CALL process_payment_check(13, NULL, NULL);


-- меняю текст в пустых нотациях с неоплатой
begin;
	update "order" 
	set notes = 'usual familly'
	where notes is null and id = 26;
	
	update "order" 
	set notes = notes || ', still waiting payment'
	where paid_amount = 0 and id = 26;
commit;

select o.paid_amount, o.notes 
from "order" o
where id = 26;


-- создал ошибку в предидущей транзакции чтобы откатить обратно
begin;
	update "order" 
	set notes = 'usual family trip'
	where notes is null and id = 26;
	
	update "order" 
	set notes = notes || ''
	where paid_amount = 0 and id = 26;
rollback;

-- dirty read
begin;
	update "order" 
	set notes = 'usual familly'
	where notes is null and id = 26;
	
	select pg_sleep(10);
rollback;

select o.notes 
from "order" o
where o.id = 26;

-- Non-Repeatable Read
begin;
	select total_amount from "order" where id = 50;
	select pg_sleep(10);
	select total_amount from "order" where id = 50;
commit;

update "order" set total_amount = 1200000 where id = 50;

-- phantom Read
begin;
	select count(*) from hotel;
	select pg_sleep(10);
	select count(*) from hotel;
commit;

begin;
	insert into hotel (id, name, city_id, stars, meal_plan_id, description)
	values (17, 'best hotel in the world', 9, 5, 5, 'really good hotel');
commit;