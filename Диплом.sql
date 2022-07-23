create database supermarket_sales

create schema dim

CREATE TABLE dim.time
AS
	select (h||''||m)::int as id, h as "hours", m as "minute", "time", SUBSTRING(time::varchar, 1, 5) as time2
from (SELECT extract(hour from w) h, extract(minute from w) m, w::time as "time"
FROM generate_series('2019-01-01 10:00'::timestamp, '2019-01-01 21:00', '1 minute') w)r

ALTER TABLE dim.time ADD PRIMARY KEY (id)

select *
from dim.time

CREATE TABLE dim.date
AS
WITH dates AS (
    SELECT dd::date AS dt
    FROM generate_series
 ('01/01/2019'::timestamp
 , '31/03/2019'::timestamp
 , '1 day'::interval) dd
)
SELECT
 to_char(dt, 'DDMMYYYY')::int AS id,
 dt AS date,
 to_char(dt, 'DD/MM/YYYY') AS ansi_date,
 date_part('isodow', dt)::int AS day,
 date_part('week', dt)::int AS week_number,
 date_part('month', dt)::int AS month,
 date_part('isoyear', dt)::int AS year,
    (date_part('isodow', dt)::smallint BETWEEN 1 AND 5)::int AS week_day,
 (to_char(dt, 'DDMMYYYY')::int IN (
        01012019,
        04012019,
        06012019,
        02022019,
        02032019,
        04032019,
        20032019,
        21032019,
        27032019))::int AS holiday
FROM dates
ORDER BY dt

ALTER TABLE dim.date ADD PRIMARY KEY (id)

select *
from dim.date

create table dim.branch (
	branch_id serial primary key,
	branch varchar(50) not null,
	city varchar(50)
);

select *
from dim.branch

create table dim.customer (
	customer_id serial primary key,
	customer_type varchar(50) not null,
	gender varchar(20) not null
);

select *
from dim.customer

create table dim.product_line (
	id serial primary key,
	product_line varchar(100) not null
);

select *
from dim.product_line

create schema fact

create table fact."sales" (
	invoice_ID varchar(20) primary key,
	branch_id integer references dim.branch(branch_id),
	customer_id integer references dim.customer(customer_id),
	product_line_id integer references dim.product_line(id),
	unit_price decimal(10, 2),
	quantity integer not null,
	"Tax_5%" decimal(14, 4) not null,
	total decimal(14, 4) not null,
	id_date integer references dim.date(id),
	id_time integer references dim.time(id),
	payment varchar(20) CHECK (Payment = 'Cash' or Payment = 'Credit card' or Payment = 'Ewallet') not null,
	cogs decimal(10, 2) not null,
	gross_margin_percentage decimal(20, 10) not null,
	gross_income decimal(14, 4) not null,
	rating decimal(10, 1)
);

select *
from fact."sales"

create table dim.branch_rejected (
	rejected text,
	branch_id serial primary key,
	branch varchar(50),
	city varchar(50)
);

create table dim.customer_rejected (
	rejected text,
	customer_id serial primary key,
	customer_type varchar(50),
	gender varchar(20)
);

create table dim.product_line_rejected (
	rejected text,
	id serial primary key,
	product_line varchar(100)
);

create table fact.sales_rejected (
	rejected text,
	invoice_ID serial primary key,
	branch_id integer,
	customer_id integer,
	product_line_id integer,
	unit_price decimal(10, 2),
	quantity integer,
	"Tax_5%" decimal(14, 4),
	total decimal(14, 4),
	id_date integer,
	id_time integer,
	payment varchar(20),
	cogs decimal(10, 2),
	gross_margin_percentage decimal(20, 10),
	gross_income decimal(14, 4),
	rating decimal(10, 1)
);

 create table supermarket_sales (
	invoice_ID varchar(20) primary key,
	branch varchar(50),
	city varchar(50),
	customer_type varchar(50),
	gender varchar(20),
	product_line varchar(100),
	unit_price decimal(10, 2),
	quantity integer,
	"Tax_5%" decimal(14, 4),
	total decimal(14, 4),
	"date" date,
	"time" varchar(10),
	payment varchar(20) CHECK (Payment = 'Cash' or Payment = 'Credit card' or Payment = 'Ewallet') not null,
	cogs decimal(10, 2),
	gross_margin_percentage decimal(20, 10),
	gross_income decimal(14, 4),
	rating decimal(10, 1)
);


select invoice_ID, branch_id, c.customer_id, p.id as product_line_id, unit_price, quantity, "Tax_5%", total, d.id as id_date, t.id as id_time,
payment, cogs, gross_margin_percentage, gross_income, rating
from supermarket_sales s
left join dim.branch b on b.branch = s.branch
left join dim.customer c on c.customer_type = s.customer_type and c.gender = s.gender
left join dim.product_line p on p.product_line = s.product_line
left join dim.date d on d.date = s.date
left join dim.time t on t.time2 = s.time