
-- 1.1 triger 
-- тригер на проверку id и активности тура при создании заказа
-- таблица: order; событие: insert; время срабатывания: defore; логика: for each row
-- 1. проверяю id всех туров, 2. проверяю что тур активен, 3. делаю вставку, если нигде не сработало исключение
CREATE OR REPLACE FUNCTION check_order_tour_active()
RETURNS trigger AS $$
DECLARE
    v_is_active boolean;
BEGIN
    SELECT t.is_active
    INTO v_is_active
    FROM tour AS t
    WHERE t.id = NEW.tour_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Tour with id % does not exist', NEW.tour_id;
    END IF;

    IF v_is_active IS DISTINCT FROM TRUE THEN
        RAISE EXCEPTION 'Tour with id % is not active', NEW.tour_id;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER check_order_tour_active_before_insert
BEFORE INSERT ON "order"
FOR EACH ROW
EXECUTE FUNCTION check_order_tour_active();

insert into "order" (id, client_id, tour_id, manager_id, status_id, created_at, total_amount, paid_amount, notes)
values (52, 2, 16, 14, 1, now(), 3200, 0, null);

insert into "order" (id, client_id, tour_id, manager_id, status_id, created_at, total_amount, paid_amount, notes)
values (52, 2, 15, 14, 1, now(), 3200, 0, null);

insert into "order" (id, client_id, tour_id, manager_id, status_id, created_at, total_amount, paid_amount, notes)
values (52, 2, 14, 14, 1, now(), 3200, 0, null);

-- 1.2 triger
-- тригер который меняет цену тура при изменении количества звезд отеля(-1 звезда = -10% от цены тура)
-- таблица: tour; событие: insert/update; время срабатывания: after; логика: for each row
-- 1. проверяет количество звезд отеля, 2. считаем коэфицент 3.при вставке или обновлении отеля уменьшаем его цену в зависимости от звезд отеля
CREATE OR REPLACE FUNCTION update_tour_price_by_hotel()
RETURNS TRIGGER AS $$
DECLARE
    v_hotel_stars INTEGER;
    v_discount_coeff NUMERIC;
BEGIN

    SELECT stars INTO v_hotel_stars
    FROM hotel
    WHERE id = NEW.hotel_id;

    IF v_hotel_stars IS NULL THEN
        RETURN NEW;
    END IF;

    v_discount_coeff := GREATEST(0.1, 1.0 - (5 - v_hotel_stars) * 0.1);


    IF NEW.price_adult IS NOT NULL THEN
        NEW.price_adult := NEW.price_adult * v_discount_coeff;
    END IF;

    IF NEW.price_child IS NOT NULL THEN
        NEW.price_child := NEW.price_child * v_discount_coeff;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql;


DROP TRIGGER IF EXISTS trg_tour_price_after ON tour;
DROP TRIGGER IF EXISTS trg_tour_price_before ON tour;

CREATE TRIGGER trg_tour_price_before
BEFORE INSERT OR UPDATE ON tour
FOR EACH ROW
EXECUTE FUNCTION update_tour_price_by_hotel();

CREATE TRIGGER trg_tour_price_after
AFTER INSERT OR UPDATE ON tour
FOR EACH ROW
EXECUTE FUNCTION update_tour_price_by_hotel();

update tour set price_adult = 2000, price_child = 1000 where id = 2 and hotel_id = 2;

-- 1.3 triger
-- тригер который перед удалением отеля в таблице туров меняет hotel_id на id отеля который имеет тот же city_id что и предидущий отель
-- 1. Ищем другой отель в том же городе 
CREATE OR REPLACE function reassign_tour_hotel_before_delete()
RETURNS TRIGGER AS $$
DECLARE
    v_replacement_hotel_id INTEGER;
BEGIN

    SELECT id INTO v_replacement_hotel_id
    FROM hotel
    WHERE city_id = OLD.city_id 
      AND id <> OLD.id
    ORDER BY id 
    LIMIT 1;

    UPDATE tour
    SET hotel_id = v_replacement_hotel_id
    WHERE hotel_id = OLD.id;

    RETURN OLD; -- Разрешаем удаление отеля
END;
$$ LANGUAGE plpgsql;

drop trigger if exists trg_hotel_tour_before on hotel;

create trigger trg_hotel_tour_before
before update or delete on hotel
for each row
execute function reassign_tour_hotel_before_delete();

insert into hotel (id, name, city_id, stars, meal_plan_id, description)
values (17, 'best hotel in the world', 9, 5, 5, 'really good hotel');

delete from tour where id = 16; 

insert into 
tour (id, name, operator_id, country_id, category_id, hotel_id, start_date, end_date, nights, price_adult, price_child, description, is_active)
values (16, 'super cool tour', 1, 9, 5, 17, '2026-11-20', '2026-11-25', 5, 1900, 950, 'this tour is kinda cool', false);

delete from hotel where id = 17;

-- 2.1 cursor
-- курсор проходится построчно по турам и выводит id, и цены
do $$ 
declare 
	curs cursor for select id, price_adult, price_child from tour;
	i record;
begin
	open curs;
	loop 
		fetch curs into i;
		exit when not found;
		raise notice 'id: %; price for adult: %; price for a child: %', i.id, i.price_adult, i.price_child;
	end loop;
	close curs;
end; $$ language plpgsql;


-- 2.2 cursor 
-- делает то же что и прошлый курсор но в виде таблицы и неявно в функции
create or replace function get_some_tour_data()
returns table(tour_id_out int, price_for_adult_out int, price_for_a_child int)
as $$
declare
	tours_row tour%rowtype;
begin
	for tours_row in
		select * from tour order by id
	loop
		tour_id_out := tours_row.id;
		price_for_adult_out := tours_row.price_adult;
		price_for_a_child := tours_row.price_child;

		return next;
	end loop;
	
	return;
end; $$ language plpgsql;

select * from get_some_tour_data();
