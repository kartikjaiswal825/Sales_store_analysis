create database sales;

create table sales_stagging like sales_store;

insert into sales_stagging
select * from sales_store;

select * from sales_stagging;

-- --step 1 remove duplicate

-- 1 duplicate find

select transaction_id , count(*) from sales_stagging
group by transaction_id
having count(transaction_id) >1;

-- 2 now check with full details

with CTE as (
select * , 
row_number() over(
partition by transaction_id 
order by transaction_id) as row_num
from sales_stagging
)
select * from CTE
where row_num>1;
 
-- 3  over check

with CTE as (
select * , 
row_number() over(
partition by transaction_id 
order by transaction_id) as row_num
from sales_stagging
)
select * from CTE
where transaction_id in ('TXN240646','TXN342128','TXN855235','TXN981773');

-- 4 delete duplicate

-- // gives unique id
ALTER TABLE sales_stagging
 ADD COLUMN id INT NOT NULL
 AUTO_INCREMENT PRIMARY KEY;

with CTE as (
select * , 
row_number() over(
partition by transaction_id 
order by transaction_id) as row_num
from sales_stagging
)
delete from sales_stagging
where id not in (
select *  from (
select min(id)
from sales_stagging
group by transaction_id
) as sub
);

-- correction of header(spelling)

describe sales_stagging;

Alter table sales_stagging
change column quantiy quantity varchar(50);

alter table sales_stagging
change column prce price varchar(50);

select * from sales_stagging;

-- step 3
-- 1 identify null or blanck

select * from sales_stagging
where customer_id is null or trim(customer_id) = '';

select * from sales_stagging
where transaction_id is null or trim(transaction_id) = '';
-- 2 count null and blankks

select count(*) as missing from sales_stagging
where customer_id is null or trim(customer_id) = '';

select count(*) as missing from sales_stagging
where customer_age is null or trim(customer_age) = '';


select count(*) as missing from sales_stagging
where transaction_id is null or trim(transaction_id) = '';

select * from sales_stagging
where transaction_id is null or
customer_id is null or 
customer_name is null or
customer_age is null or
gender is null ;

delete from sales_stagging
where transaction_id is null or
customer_id is null or 
customer_name is null or
customer_age is null or
gender is null ;

-- 3 update values

delete from sales_stagging
where transaction_id is null or customer_id is null;

select * from sales_stagging;

select * from sales_stagging 
where customer_name = 'Ehsaan Ram';

update  sales_stagging
set customer_id = 'CUST9494'
where transaction_id = 'TXN977900';

select * from sales_stagging
where customer_id is null or customer_id = '';

select * from sales_stagging
where customer_name is null or customer_name = '';

select * from sales_stagging 
where customer_name = 'Damini Raju';

update sales_stagging
set customer_id = 'CUST1401'
where transaction_id = 'TXN985663';

select * from sales_stagging
where customer_id= 'CUST1003';

-- DAte- text to date
select purchase_date,
str_to_date(purchase_date,'%d/%m/%Y')
from sales_stagging;

update sales_stagging
set purchase_date = str_to_date(purchase_date,'%d/%m/%Y');

ALTER TABLE sales_stagging
MODIFY COLUMN purchase_date DATE;

-- for time

UPDATE sales_stagging
SET time_of_purchase = STR_TO_DATE(time_of_purchase, '%H:%i:%s');

ALTER TABLE sales_stagging
MODIFY COLUMN time_of_purchase TIME;

-- 5 inconsistent data

select distinct gender from sales_stagging;

update sales_stagging
set gender = 'Female'
where gender = 'F';

update sales_stagging
set gender = 'Male'
where gender = 'Male';

select distinct payment_mode from sales_stagging;

update sales_stagging
set payment_mode = 'Credit Card'
where payment_mode = 'CC';



-- Date-cleaning End

-- ## Business Insights

-- ques-1) what are the top 5 most selling products by quantity?
   
   select * from sales_stagging;

select product_name , Sum(quantity) as top5 
from sales_stagging
where status = 'delivered'
group by product_name
order by top5 desc
limit 5;

		  -- Business Problem: We don't know which products are most in demand
          --  Business Impact: Helps prioritize stock and boost sales through targeted promotions.

-- ques-2) which product most frequently canclled

select product_name , count(*) as most_Cancelled
from sales_stagging
where status = 'cancelled'
group by product_name
order by most_cancelled desc
limit 5;
    
   --  Business Problem: Frequent cancellations affect revenue and customer trust.
   -- Business Impact: Identify poor-performing products to improve quality or remove from catalog.
   
-- ques-3) what time of the day has the highest number of purchase?

select * from sales_stagging;

SELECT 
  CASE
    WHEN HOUR(time_of_purchase) BETWEEN 0 AND 5 THEN 'NIGHT'
    WHEN HOUR(time_of_purchase) BETWEEN 6 AND 11 THEN 'MORNING'
    WHEN HOUR(time_of_purchase) BETWEEN 12 AND 17 THEN 'AFTERNOON'
    WHEN HOUR(time_of_purchase) BETWEEN 18 AND 23 THEN 'EVENING'
  END AS time_slot,
  COUNT(*) AS total_orders
FROM sales_stagging
GROUP BY time_slot
ORDER BY total_orders DESC;

           --  Business Problem Solved: Find peak sales times.
           -- Business Impact: Optimize staffing, promotions, and server loads.

   --  ques-4) who are the top 5 highest spending customers
   
   select customer_name ,
   CONCAT('$',format(sum(price*quantity),0)) as highest_spend
   from sales_stagging
   group by customer_name
   order by highest_spend desc
   limit 5;
      
     --  Business Problem Solved: Identify VIP customers.
     --  Business Impact: Personalized offers, loyalty rewards, and retention.
     
 --   ques-5) which product generate the highest revenue
  
  select product_name , 
  concat('$',format(sum(price*quantity),0)) as highest_revenue 
  from sales_stagging
  group by product_name
  order by highest_revenue desc
  limit 5;
  
 --  Business Problem Solved: Identify top-performing product categories.

-- Business Impact: Refine product strategy, supply chain, and promotions.
-- llowing the business to invest more in high-margin or high-demand categories.
  
--   ques-6) what is the return / cancelation rate per product category?

-- cancellation
select product_category,
  CONCAT(FORMAT(
           COUNT(CASE WHEN status = 'cancelled' THEN 1 END) * 100/ COUNT(*),3), ' %') AS cancelled_product
from sales_stagging
group by product_category
order by cancelled_product desc;

-- return
select product_category, 
   concat(format(count(case when status = 'returned' then 1 end)* 100/ count(*),3), ' %') as returned_product
   from sales_stagging
   group by product_category
   order by returned_product desc;
   
-- Business Problem Solved: Monitor dissatisfaction trends per category.
-- Business Impact: Reduce returns, improve product descriptions/expectations.
-- Helps identify and fix product or logistics issues.
   
--    gues-7) what is most prefered payment mode?
  
  select payment_mode , count(payment_mode)
  as prefered from sales_stagging
  group by payment_mode
  order by prefered desc;
    
    -- Business Problem Solved: Know which payment options customers prefer.
    -- Business Impact: Streamline payment processing, prioritize popular modes.

--  ques-8) how does age group affect purchasing behaviour?
select * from sales_stagging;

select 
     case 
       when customer_age between 18 and 30 then '18-30'
       when customer_age between 31 and 40 then '31-40'
       when customer_age between 41 and 50 then '41-50'
       else '51+'
       end as ages,
       concat('$' ,format(sum(price*quantity),0)) as total_purchase
       from sales_stagging
       group by ages
       order by total_purchase desc;
       
       
           -- Business Problem Solved: Understand customer demographics.
		   -- Business Impact: Targeted marketing and product recommendations by age group.

--    ques-9) what is the monthly sales trend?

      select date_format(purchase_date, '%Y-%m') as Month_year,
             concat('$',format(sum(quantity*price),0)) as total_sales,
             sum(quantity) as Total_quantity
             from sales_stagging
             group by Month_year
             order by month_year;
                
                -- Business Problem: Sales fluctuations go unnoticed.
				-- Business Impact: Plan inventory and marketing according to seasonal trends.
      
     --  ques-10) are certain genders buying more specific product categories? 
	  
      select * from sales_stagging;
      
      select product_category,
       count(case when gender = 'Male' then 1 END) as Male,
       count(case when gender = 'Female' then 1 end) as Female
       from sales_stagging
       group by product_category
		order by product_category;
        
        -- Business Problem Solved: Gender-based product preferences.
        -- Business Impact: Personalized ads, gender-focused campaigns.
  
