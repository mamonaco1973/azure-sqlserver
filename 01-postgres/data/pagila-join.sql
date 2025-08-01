SELECT
    f.title AS film_title,
    a.first_name || ' ' || a.last_name AS actor_name
FROM
    film f
JOIN film_actor fa ON f.film_id = fa.film_id
JOIN actor a ON fa.actor_id = a.actor_id
ORDER BY f.title, actor_name
LIMIT 20;
