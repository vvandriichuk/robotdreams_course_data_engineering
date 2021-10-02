SELECT * FROM pagila.public.category;

-- Задание 1: вывести количество фильмов в каждой категории, отсортировать по убыванию.
SELECT COUNT(film_id) AS count, category_id
FROM pagila.public.film_category
GROUP BY category_id
ORDER BY count desc;

-- Задание 2: вывести 10 актеров, чьи фильмы большего всего арендовали, отсортировать по убыванию.
SELECT COUNT(rental_id) AS count_rent, actor_id, actor.first_name || ' ' || actor.last_name AS actor_name
FROM pagila.public.rental
INNER JOIN pagila.public.inventory USING (inventory_id)
INNER JOIN pagila.public.film_actor USING (film_id)
INNER JOIN pagila.public.actor USING (actor_id)
GROUP BY actor_id, actor_name
ORDER BY count_rent DESC;

-- Задание 3: вывести категорию фильмов, на которую потратили больше всего денег.
SELECT SUM(amount) AS sum_amount, name AS category_name
FROM pagila.public.payment
INNER JOIN pagila.public.rental USING (rental_id)
INNER JOIN pagila.public.inventory USING (inventory_id)
INNER JOIN pagila.public.film USING (film_id)
INNER JOIN pagila.public.film_category USING (film_id)
INNER JOIN pagila.public.category USING (category_id)
GROUP BY category_name
ORDER BY sum_amount DESC;

-- Задание 4: вывести названия фильмов, которых нет в inventory. Написать запрос без использования оператора IN.
SELECT title
FROM pagila.public.inventory
RIGHT JOIN film USING (film_id)
WHERE inventory_id IS NULL;

-- Задание 5: вывести топ 3 актеров, которые больше всего появлялись в фильмах в категории “Children”.
-- Если у нескольких актеров одинаковое кол-во фильмов, вывести всех.
SELECT *
FROM (
         SELECT *, DENSE_RANK() OVER (ORDER BY count DESC) as rank
         FROM (
                  SELECT COUNT(category_id) AS count, actor_id, actor.first_name || ' ' || actor.last_name AS actor_name
                  FROM pagila.public.film_category
                           INNER JOIN pagila.public.film_actor USING (film_id)
                           INNER JOIN pagila.public.category USING (category_id)
                           INNER JOIN pagila.public.actor USING (actor_id)
                  WHERE name = 'Children'
                  GROUP BY actor_id, actor_name
                  ORDER BY count DESC) AS c
     ) AS s
WHERE rank <= 3;

-- Задание 6: вывести города с количеством активных и неактивных клиентов (активный — customer.active = 1).
-- Отсортировать по количеству неактивных клиентов по убыванию
WITH active AS (
    SELECT COUNT(active) AS count_active, city_id
    FROM pagila.public.customer
    INNER JOIN pagila.public.address USING (address_id)
    INNER JOIN pagila.public.city USING (city_id)
    WHERE active = 1
    GROUP BY city_id
), non_active AS (
    SELECT COUNT(active) AS count_nonactive, city_id
    FROM pagila.public.customer
    INNER JOIN pagila.public.address USING (address_id)
    INNER JOIN pagila.public.city USING (city_id)
    WHERE active = 0
    GROUP BY city_id
)

SELECT *
FROM active
FULL OUTER JOIN non_active USING (city_id)
ORDER BY count_nonactive DESC;

-- Задание 7: вывести категорию фильмов, у которой самое большое кол-во часов суммарной аренды в городах
-- (customer.address_id в этом city), и которые начинаются на букву “a”. То же самое сделать для городов в которых
-- есть символ “-”. Написать все в одном запросе.
SELECT SUM(rental_duration) AS sum_rental_duration, name AS cat_name
FROM pagila.public.rental
INNER JOIN pagila.public.inventory USING (inventory_id)
INNER JOIN pagila.public.customer USING (customer_id)
INNER JOIN pagila.public.address USING (address_id)
INNER JOIN pagila.public.film_category AS cat USING (film_id)
INNER JOIN pagila.public.film USING (film_id)
INNER JOIN pagila.public.category USING (category_id)
INNER JOIN pagila.public.city USING (city_id)
WHERE city LIKE ANY (array['A%', '%-%'])
GROUP BY cat_name
ORDER BY sum_rental_duration DESC;
