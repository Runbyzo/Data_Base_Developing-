
--------------------first part-----------------------------
-- изменение количесва ночей на короткое название
select name, nights,
case
	when nights > 5 then 'long tour'
	when nights < 5 then 'short tour'
	when nights = 5 then 'tour for 5 days'
	else 'unknown'
end as how_long_tour
from tour t
order by nights desc;

-- переименование цен
select name, price_adult,
count(
case
	when price_adult > 1750 then 'cheap'
	else null
end)as cheap_tours,
count(
case
	when price_adult < 1750 then 'pricy'
	else null
end) as expensive_tours
from tour
group by name, price_adult;
-----------------------------------------------------------

--------------------second part-----------------------------
-- поиск цен для детей которые выше средней цены
select name, price_adult, price_child from tour where price_child > (select avg(price_child) from tour) order by price_child ;

-- поиск сотрудника с большим стажем работы в компании
select e.person_name, e.hire_date  from employee e where e.id in (select id from employee where hire_date >= (current_date - interval '4 y'));

-- поиск всех активных тур операторов с турами
select name from tour_operator where exists (select 1 from tour where tour_operator.id = tour.operator_id and tour.is_active is true);

-- поиск активных тур операторов
select distinct tour_operator.name
from tour_operator
join tour
on  tour_operator.id = tour.operator_id;
-----------------------------------------------------------

--------------------third part-----------------------------
-- поиск активных тур операторов
with active_tours as (select t.operator_id from tour t)
select distinct name from tour_operator join active_tours on id = active_tours.operator_id ;

-- вся информация тура в одном столбце
WITH RECURSIVE tour_chain AS (
    -- Anchor Member (Шаг 1): Выборка базовых туров
    SELECT 
        t.id AS tour_id,
        t.name AS tour_name,
        t.hotel_id,
        CAST(NULL AS INTEGER) AS city_id,
        CAST(NULL AS INTEGER) AS meal_plan_id,
        1 AS step,
        t.name::TEXT AS full_path
    FROM tour t
    WHERE t.is_active = TRUE

    UNION ALL

    -- Recursive Member (Шаг 2 и 3): Переход к связанным сущностям
    SELECT 
        tc.tour_id,
        tc.tour_name,
        tc.hotel_id,
        CASE 
            WHEN tc.step = 1 THEN h.city_id 
            ELSE tc.city_id 
        END AS city_id,
        CASE 	
            WHEN tc.step = 1 THEN h.meal_plan_id 
            ELSE tc.meal_plan_id 
        END AS meal_plan_id,
        tc.step + 1 AS step,
        CASE 
            WHEN tc.step = 1 THEN tc.full_path || ' -> Отель: ' || h.name
            WHEN tc.step = 2 THEN tc.full_path || ' -> Город: ' || c.name || ' | Питание: ' || mp.name
        END AS full_path
    FROM tour_chain tc
    -- Переход от Тура к Отелю
    LEFT JOIN hotel h ON tc.step = 1 AND tc.hotel_id = h.id
    -- Переход от Отеля к Городу и Плану питания
    LEFT JOIN city c ON tc.step = 2 AND tc.city_id = c.id
    LEFT JOIN meal_plan mp ON tc.step = 2 AND tc.meal_plan_id = mp.id
    WHERE tc.step < 3
)
SELECT 
    tour_id,
    tour_name,
    full_path
FROM tour_chain
WHERE step = 3;
-----------------------------------------------------------

--------------------fourth part-----------------------------
-- поиск логинов по длине
select e.person_name, e.login, length(e.login) from employee e where length(e.login)  between 5 and 7;

-- увеличение текста для того чтобы начальник увидел
select UPPER(e.person_name), UPPER(e.email) from employee e;

-- сотрудники работающие до 2020
select e.person_name, e.hire_date from employee e where extract(year from e.hire_date ) < 2020;

-- сотрудники работающие меньше 5 лет
select e.person_name, e.hire_date, age(e.hire_date) from employee e where age(e.hire_date) > '5 years';

-- небольшое увеличение цены для детей
select t.name, t.price_adult, round(t.price_child * 1.23, 3)  from tour t
-----------------------------------------------------------

--------------------fifth part-----------------------------
-----------------------------------------------------------
-- 1. Создание таблицы логов пользователей
CREATE TABLE IF NOT EXISTS user_logs (
    log_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    user_id INT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP NOT NULL,
    data JSONB NOT NULL
);

-- 2. Добавление индекса (GIN) для ускорения поиска по JSONB
CREATE INDEX IF NOT EXISTS idx_user_logs_data ON user_logs USING gin (data);

-- 3. Наполнение таблицы тестовыми данными (10 строк)
INSERT INTO user_logs (user_id, created_at, data) VALUES
(101, NOW() - INTERVAL '5 hours', '{
    "event": "login",
    "browser": "Chrome",
    "os": "Windows",
    "actions_count": 5,
    "success": true,
    "ip": "192.168.1.10"
}'),

(102, NOW() - INTERVAL '4 hours 30 minutes', '{
    "event": "page_view",
    "browser": "Firefox",
    "os": "macOS",
    "page": "/dashboard",
    "duration_sec": 12
}'),

(101, NOW() - INTERVAL '4 hours', '{
    "event": "file_upload",
    "browser": "Chrome",
    "os": "Windows",
    "file_name": "report.pdf",
    "file_size_kb": 2048,
    "success": true
}'),

(103, NOW() - INTERVAL '3 hours 15 minutes', '{
    "event": "login",
    "browser": "Safari",
    "os": "iOS",
    "actions_count": 1,
    "success": false,
    "error_code": "INVALID_PASSWORD"
}'),

(104, NOW() - INTERVAL '3 hours', '{
    "event": "password_reset",
    "browser": "Edge",
    "os": "Windows",
    "method": "email",
    "success": true
}'),

(102, NOW() - INTERVAL '2 hours', '{
    "event": "purchase",
    "browser": "Firefox",
    "os": "macOS",
    "cart_items": 3,
    "total_amount": 149.99,
    "currency": "USD",
    "success": true
}'),

(105, NOW() - INTERVAL '1 hour 45 minutes', '{
    "event": "login",
    "browser": "Chrome",
    "os": "Android",
    "actions_count": 8,
    "success": true,
    "ip": "10.0.0.42"
}'),

(101, NOW() - INTERVAL '1 hour', '{
    "event": "logout",
    "browser": "Chrome",
    "os": "Windows",
    "session_duration_min": 240
}'),

(103, NOW() - INTERVAL '30 minutes', '{
    "event": "login",
    "browser": "Safari",
    "os": "iOS",
    "actions_count": 2,
    "success": true
}'),

(106, NOW() - INTERVAL '10 minutes', '{
    "event": "api_call",
    "browser": "Postman",
    "os": "Linux",
    "endpoint": "/api/v1/users",
    "status_code": 200,
    "latency_ms": 45
}');
-----------------------------------------------------------
-- поиск джисон логов с ос виндоус
select log_id , data from user_logs where data ->> 'os' = 'Windows';

-- добавление ко всем логам дополнительного поля
update user_logs ul set data = data || '{"source": "web"}'::jsonb;
SELECT data FROM user_logs;

-- изменение одного из полей жисона
update user_logs ul set data = jsonb_set(data, '{success}', 'true'::jsonb) where log_id = 5;
update user_logs ul set data = jsonb_set(data, '{success}', 'false'::jsonb) where log_id = 5;
SELECT data FROM user_logs where log_id = 5; 

-----------------------------------------------------------