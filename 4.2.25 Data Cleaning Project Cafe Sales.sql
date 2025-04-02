# Lets tidy up this "dirty cafe sales" data for cleaning practice.

# First thing is to create a staging table to allow for any mistakes.

drop table if exists `staging_cafe_sales`;
CREATE TABLE `staging_cafe_sales` (
  `transaction_id` text,
  `item` text,
  `quantity` int DEFAULT NULL,
  `price_per_unit` double DEFAULT NULL,
  `total_spent` text,
  `payment_method` text,
  `location` text,
  `transaction_date` text
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

# Add all the data to our new table

insert into staging_cafe_sales 
(transaction_id, 
item, 
quantity, 
price_per_unit, 
total_spent, 
payment_method, 
location, 
transaction_date)
SELECT `raw_cafe_sales`.`Transaction ID`,
    `raw_cafe_sales`.`Item`,
    `raw_cafe_sales`.`Quantity`,
    `raw_cafe_sales`.`Price Per Unit`,
    `raw_cafe_sales`.`Total Spent`,
    `raw_cafe_sales`.`Payment Method`,
    `raw_cafe_sales`.`Location`,
    `raw_cafe_sales`.`Transaction Date`
FROM `cafe_sales`.`raw_cafe_sales`;

select *
from staging_cafe_sales;

# With the staging table created, lets standardize things.
# Firstly, lets ensure the date and price_per_unit column is the right type which means we should make sure that the formatting all works.

select distinct transaction_date
from staging_cafe_sales
order by 1 asc;

# Unknown and error for dates serves us no purpose and messes with formatting. Lets change all those unknown values to NULL

update staging_cafe_sales
set transaction_date = null
where transaction_date = 'ERROR';

update staging_cafe_sales
set transaction_date = null
where transaction_date = 'UNKNOWN';

update staging_cafe_sales
set transaction_date = null
where transaction_date = '';

# With those values cleared out and made null, lets update the column to datetime format.

alter table staging_cafe_sales
modify column transaction_date date;

select *
from staging_cafe_sales;

# Lets go ahead and standardize all the columns. We will reuse the update statments above for item, 

update staging_cafe_sales
set item = null
where item = 'ERROR';

update staging_cafe_sales
set item = null
where item = 'UNKNOWN';

update staging_cafe_sales
set item = null
where item = '';

update staging_cafe_sales
set payment_method = null
where payment_method = 'ERROR';

update staging_cafe_sales
set payment_method = null
where payment_method = 'UNKNOWN';

update staging_cafe_sales
set payment_method = null
where payment_method = '';

update staging_cafe_sales
set location = null
where location = 'ERROR';

update staging_cafe_sales
set location = null
where location = 'UNKNOWN';

update staging_cafe_sales
set location = null
where location = '';

select *
from staging_cafe_sales
order by 2 asc;

select distinct *
from staging_cafe_sales
where item is null
order by 4;

# Now lets see if we can clean up pricing data as much as possible. First lets go ahead and create a temp table with known values. 
# Note the temp table will not include Sandwich and Smoothie as both are $4
# Note the temp table will not include Cake and Juice as both are $3

CREATE TEMPORARY TABLE temp_table (
    item VARCHAR(50),
    price_per_unit DECIMAL(10, 2)
);

INSERT INTO temp_table (item, price_per_unit)
VALUES 
    ('Coffee', 2),
    ('Tea', 1.5),
    ('Salad', 5),
    ('Cookie', 1)
    ;
    
    
# Make sure the values match with price per unit and then we can update it to clear some missing data.alter

select s1.transaction_id, s1.item, s1.price_per_unit, t1.item, t1.price_per_unit
from staging_cafe_sales s1
join temp_table t1
	on s1.price_per_unit = t1.price_per_unit;
    
update staging_cafe_sales s1
join temp_table t1
	on s1.price_per_unit = t1.price_per_unit
set s1.item = t1.item;

# With items cleaned up, lets go ahead and ensure the column type for price is decimal

alter table staging_cafe_sales
modify column price_per_unit decimal (10,2);

select *
from staging_cafe_sales;

# Lets now sort out the total spent column. 

select distinct total_spent
from staging_cafe_sales;

update staging_cafe_sales
set total_spent = null
where total_spent = 'UNKNOWN';

update staging_cafe_sales
set total_spent = null
where total_spent = 'ERROR';

update staging_cafe_sales
set total_spent = null
where total_spent = '';

alter table staging_cafe_sales
modify column total_spent decimal (10,2);

select *
from staging_cafe_sales;

# With the data types sorted, lets go ahead and clear up any blanks where we can in the total spent column

select transaction_id, item, quantity, price_per_unit, total_spent, (quantity * price_per_unit) as true_total
from staging_cafe_sales;

with proper_price as
(
select transaction_id, item, quantity, price_per_unit, total_spent, (quantity * price_per_unit) as true_total
from staging_cafe_sales
)
select s1.transaction_id, s1.item, s1.quantity, s1.price_per_unit, s1.total_spent, p1.transaction_id, p1.true_total
from staging_cafe_sales s1
join proper_price p1
	on s1.transaction_id = p1.transaction_id
where s1.total_spent is null;

# We've determined the right totals, so lets go ahead and update them.

with proper_price as
(
select transaction_id, item, quantity, price_per_unit, total_spent, (quantity * price_per_unit) as true_total
from staging_cafe_sales
)
update staging_cafe_sales s1
join proper_price p1
	on s1.transaction_id = p1.transaction_id
set s1.total_spent = p1.true_total
where s1.total_spent is null;

select * 
from staging_cafe_sales;

# And this is as clean as this data can get. 
# Data retrieved from https://www.kaggle.com/datasets/ahmedmohamed2003/cafe-sales-dirty-data-for-cleaning-training
# Data cleaned by Malik Francis - Data Analyst 😁



