SELECT
    f.title,
    STRING_AGG(a.first_name || ' ' || a.last_name, ', ') AS actor_names
FROM
    film f
JOIN film_actor fa ON f.film_id = fa.film_id
JOIN actor a ON fa.actor_id = a.actor_id
GROUP BY f.title
ORDER BY f.title
LIMIT 10;

