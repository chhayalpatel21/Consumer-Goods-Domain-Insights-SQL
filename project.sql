use gdb023
-- 1> Provide the list of markets in which customer "Atliq Exclusive" operates its business in the APAC region.

      select  distinct market from dim_customer
	  where customer='atliq exclusive' and region='APAC'

-- 2> What is the percentage of unique product increase in 2021 vs. 2020? The final output contains these fields,
--   unique_products_2020
--   unique_products_2021
--   percentage_chg


with cte1 as 
( select distinct count(product_code) as a
from fact_gross_price
where fiscal_year=2020
),
cte2 as 
(select distinct count(product_code) as b
from fact_gross_price
where fiscal_year=2021
)
 
select a as unique_product_2020, b as unique_product_2021,round(((b-a)/a)*100,2) as percentage_change
from cte1,cte2


-- 3> Provide a report with all the unique product counts for each segment and
-- sort them in descending order of product counts. The final output contains 2 fields,
-- segment
-- product_count

select segment,count( distinct (product_code)) as product_count
from dim_product
group by 1
order by product_count desc

-- 4> Follow-up: Which segment had the most increase in unique products in 2021 vs 2020? The final output contains these fields,
--    segment
--    product_count_2020
--    product_count_2021
--    difference

with cte1 as
    (select p.segment as a,count(distinct(p.product_code)) as b 
	 from dim_product as p left join fact_gross_price as g using (product_code)
     where g.fiscal_year='2020'
     group by 1) ,
 cte2 as
    (select p.segment as c,count(distinct(p.product_code)) as d 
     from dim_product as p left join fact_gross_price as g using (product_code)
     where g.fiscal_year='2021'
     group by 1)

select cte1.a as segment,cte1.b as unique_product_2020,cte2.d as unique_product_2021,(cte2.d-cte1.b) as difference
from cte1,cte2
where cte1.a=cte2.c

-- 5> Get the products that have the highest and lowest manufacturing costs.
--   The final output should contain these fields,
--   product_code
--   product
--   manufacturing_cost

select p.product_code,p.product,m.manufacturing_cost as cost
from dim_product as p left join fact_manufacturing_cost as m
on p.product_code=m.product_code
where m.manufacturing_cost in ( select max(manufacturing_cost) from fact_manufacturing_cost
                                union
                                select min(manufacturing_cost) from fact_manufacturing_cost)
order by cost desc                              

-- 6> Generate a report which contains the top 5 customers who received an
--    average high pre_invoice_discount_pct for the fiscal year 2021 and in the
--    Indian market. The final output contains these fields,
--    customer_code
--    customer
--    average_discount_percentage

select c.customer_code,c.customer,round(avg(i.pre_invoice_discount_pct),4) as avg_discount_percentage
from dim_customer as c left join fact_pre_invoice_deductions as i
on c.customer_code=i.customer_code
where i.fiscal_year='2021' and c.market='india'
group by 1,2
order by   avg_discount_percentage desc
limit 5

-- 7>Get the complete report of the Gross sales amount for the customer “Atliq
-- Exclusive” for each month. This analysis helps to get an idea of low and
-- high-performing months and take strategic decisions.
-- The final report contains these columns:
-- Month
-- Year
-- Gross sales Amount

select concat(monthname(s.date),' (',year(s.date),')') as 'Month' ,s.fiscal_year as 'year',round(sum(s.sold_quantity*g.gross_price),2) as 'gross sales amount'
from dim_customer as c join fact_sales_monthly as s using(customer_code)
						join fact_gross_price as g using(product_code)
 where c.customer = 'atliq exclusive'
 group by month,year
 order by year

-- 8> In which quarter of 2020, got the maximum total_sold_quantity? The final
-- output contains these fields sorted by the total_sold_quantity,
-- Quarter
-- total_sold_quantity

SELECT 
CASE
    WHEN date BETWEEN '2019-09-01' AND '2019-11-01' then 1  
    WHEN date BETWEEN '2019-12-01' AND '2020-02-01' then 2
    WHEN date BETWEEN '2020-03-01' AND '2020-05-01' then 3
    WHEN date BETWEEN '2020-06-01' AND '2020-08-01' then 4
    END AS Quarters,
    SUM(sold_quantity) AS total_sold_quantity
FROM fact_sales_monthly
WHERE fiscal_year = 2020
GROUP BY Quarters
ORDER BY total_sold_quantity DESC

-- 9>Which channel helped to bring more gross sales in the fiscal year 2021
-- and the percentage of contribution? The final output contains these fields,
-- channel
-- gross_sales_mln
-- percentage

with tbl1 as
	(select c.channel as channel,sum(g.gross_price*s.sold_quantity) as total_gross
    from dim_customer as c join fact_sales_monthly as s using(customer_code)
						join fact_gross_price as g using(product_code)
	where g.fiscal_year=2021
    group by c.channel)
    
select channel,round(total_gross/1000000,2) as total_gross_mln,round(total_gross/(sum(total_gross) OVER())*100,2) as percentage
from tbl1
                        
-- 10> Get the Top 3 products in each division that have a hightotal_sold_quantity in the fiscal_year 2021? The final output contains these
 -- fields,
-- division
-- product_code
-- product
-- total_sold_quantity
-- rank_order

with tbl1 as 
	(select p.division,p.product_code,p.product,sum(s.sold_quantity) as 'total_sold_quantity'
     from dim_product as p left join fact_sales_monthly as s using(product_code)
     where s.fiscal_year=2021
     group by p.division,p.product_code,p.product),
    tbl2 as 
	(select division, product_code, product, Total_sold_quantity,rank() over(partition by division order by total_sold_quantity desc) as 'rank_order'
    from tbl1)
select tbl1.division,tbl1.product_code,tbl1.product,tbl1.total_sold_quantity,tbl2.rank_order
from tbl1 join tbl2 using(product_code)
where tbl2.rank_order in(1,2,3)
     
	 