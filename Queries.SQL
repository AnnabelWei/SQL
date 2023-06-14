Q1_#1 (Result1)

select f.title film_title,  c.name category_name,count(r.rental_id) rental_count 
from category c
inner join film_category fc
on c.category_id=fc.category_id
inner join film f
on fc.film_id=f.film_id
inner join inventory i
on i.film_id=f.film_id
inner join rental r
on r.inventory_id=i.inventory_id
where c.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family' ,'Music')
group by f.title, c.name
order by c.name

Q1_#2 (Result2)

WITH avg_rental_duration AS (
  SELECT AVG(rental_duration) AS avg_duration
  FROM film
),
family_movies AS (
  SELECT film.film_id, film.title, film.rental_duration, category.name
  FROM film
  JOIN film_category ON film.film_id = film_category.film_id
  JOIN category ON film_category.category_id = category.category_id
  WHERE category.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
)
SELECT family_movies.title, family_movies.name ,family_movies.rental_duration,
  NTILE(4) OVER (ORDER BY family_movies.rental_duration / avg_rental_duration.avg_duration) AS standard_quartile
FROM family_movies, avg_rental_duration;


Q1_#3 (Result3)
WITH avg_rental_duration AS (
  SELECT AVG(rental_duration) AS avg_duration
  FROM film
),
family_movies AS (
  SELECT film.film_id, film.title, film.rental_duration, category.name
  FROM film
  JOIN film_category ON film.film_id = film_category.film_id
  JOIN category ON film_category.category_id = category.category_id
  WHERE category.name IN ('Animation', 'Children', 'Classics', 'Comedy', 'Family', 'Music')
)
SELECT name,standard_quartile,count(*)  FROM
(SELECT family_movies.title, family_movies.name ,family_movies.rental_duration,
  NTILE(4) OVER (ORDER BY family_movies.rental_duration / avg_rental_duration.avg_duration) AS standard_quartile
FROM family_movies, avg_rental_duration) as quartiles
group by name,standard_quartile
order by name, standard_quartile

Q2_#1 (Result4)


SELECT EXTRACT(YEAR FROM rental.rental_date) AS year,
       EXTRACT(MONTH FROM rental.rental_date) AS month,
  store.store_id AS store_id,
  COUNT(*) AS rental_count
FROM
  rental
  JOIN payment ON rental.rental_id = payment.rental_id
  JOIN staff ON payment.staff_id = staff.staff_id
  JOIN store ON staff.staff_id = store.manager_staff_id
WHERE
  rental.return_date IS NOT NULL
GROUP BY
year,month,store.store_id
ORDER BY
  rental_count DESC;

Q2_#2 (Result5)
SELECT 
	DATE_TRUNC('month', p.payment_date) AS pay_month, 
	CONCAT(c.first_name, ' ', c.last_name) AS fullname,       
       COUNT(*) AS pay_countpermonth,
       SUM(p.amount) AS pay_amount
FROM customer c
JOIN payment p ON c.customer_id = p.customer_id
WHERE DATE_TRUNC('year', p.payment_date) = '2007-01-01'
  AND c.customer_id IN (
    SELECT customer_id
    FROM payment
    GROUP BY customer_id
    ORDER BY SUM(amount) DESC
    LIMIT 10
  )
GROUP BY fullname, pay_month
ORDER BY fullname, pay_month

Q2_#3 (Result6)
WITH top_customers AS (
  SELECT customer_id, SUM(amount) AS pay_amount
  FROM payment
  WHERE DATE_TRUNC('year', payment_date) = '2007-01-01'
  GROUP BY customer_id
  ORDER BY pay_amount DESC
  LIMIT 10
),
monthly_payments AS (
  SELECT
    CONCAT(c.first_name, ' ', c.last_name) AS fullname,
    DATE_TRUNC('month', p.payment_date) AS month,
    SUM(p.amount) AS total_amount,
    ROW_NUMBER() OVER (
      PARTITION BY c.customer_id
      ORDER BY DATE_TRUNC('month', p.payment_date)
    ) AS payment_num
  FROM customer c
  JOIN payment p ON c.customer_id = p.customer_id
  WHERE DATE_TRUNC('year', p.payment_date) = '2007-01-01'
    AND c.customer_id IN (
      SELECT customer_id FROM top_customers
    )
  GROUP BY fullname, month, c.customer_id
),
payment_diff AS (
  SELECT
    fullname,
    month,
    total_amount - LAG(total_amount) OVER (
      PARTITION BY fullname
      ORDER BY month
    ) AS payment_difference
  FROM monthly_payments
)
SELECT
  fullname,
  month as pay_month,
  payment_difference
FROM payment_diff
WHERE payment_difference IS NOT NULL
ORDER BY payment_difference DESC
LIMIT 1;