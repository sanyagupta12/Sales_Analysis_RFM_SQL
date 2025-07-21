use sales;
select * from data_1;
alter table data_1
add column orderdates datetime;
update data_1
set orderdates= str_to_date( orderdate, '%c/%e/%Y %k:%i');
alter table data_1
rename to sales_data_sample;
-- Inspecting data-------
select * from sales.sales_data_sample;
-- cheking unique values --------
select distinct status from sales.sales_data_sample;
select distinct YEAR_ID from sales.sales_data_sample;
select distinct productline from sales.sales_data_sample;
select distinct COUNTRY from sales.sales_data_sample;
select distinct DEALSIZE from sales.sales_data_sample;
select distinct territory from sales.sales_data_sample;


-- ANALYSIS -----
-- Grouping sales by product line -----
select PRODUCTLINE, sum(sales) Revenue
from sales.sales_data_sample
group by PRODUCTLINE
order by 2 desc;
-- Year ID
select YEAR_ID, sum(sales) Revenue
from sales.sales_data_sample
group by YEAR_ID
order by 2 desc;
-- Deal Size
select DEALSIZE, sum(sales) Revenue
from sales.sales_data_sample
group by DEALSIZE
order by 2 desc;

-- Best month for sales in a specific year? How much was earned in the specific month ------
select month_id, sum(sales) Revenue, count(ordernumber) Frequency
from sales.sales_data_sample
where year_id=2004 -- change according to need
group by month_id
order by 2 desc;

-- November seems to be the month, what product do they sell in november, Classic I believe
select  month_id,productline,sum(sales) Revenue, count(ordernumber)
from sales.sales_data_sample
where year_id=2004 and month_id=11
group by month_id,productline
order by 3 desc;
-- Who is our best customer (this could be best answered with RFM)
CREATE VIEW rfm
as
with rfm as 

(
	select 
		customername,
		sum(sales) MonetaryValue,
		avg(sales) AvgMonetaryValue,
		count(ORDERNUMBER) Frequency,
		max(Orderdates) last_order_date,
		( select max(orderdates) from sales.sales_data_sample) max_order_date,
		abs(datediff (  max(orderdates), (select max(orderdates) from sales.sales_data_sample))) Recency
from sales.sales_data_sample
group by customername
),
rfm_calc as
(
	select r.*,
		NTILE(4) OVER (order by Recency desc) rfm_recency,
		NTILE(4) OVER (order by frequency) rfm_frequency,
		NTILE(4) OVER (order by Avgmonetaryvalue) rfm_monetary
	from rfm r
)

select *, 
rfm_recency+rfm_frequency+rfm_monetary as rfm_cell, -- combine as number
concat(cast(rfm_recency as char), cast(rfm_frequency as char) ,cast(rfm_monetary as char )) rfm_string -- combine as string
from rfm_calc c;
select * from rfm;
SELECT CUSTOMERNAME , rfm_recency, rfm_frequency, rfm_monetary,
	CASE 
		WHEN rfm_string IN (111, 112 , 121, 122, 123, 132, 211, 212, 114, 141) THEN 'lost_customers'  -- lost customers
		WHEN rfm_string IN (133, 134, 143, 244, 334, 343, 344, 144) THEN 'slipping away, cannot lose' -- (Big spenders who haven’t purchased lately) slipping away
		WHEN rfm_string IN (311, 411, 331) THEN 'new customers'
		WHEN rfm_string IN (222, 223, 233, 322) THEN 'potential churners'
		WHEN rfm_string IN (323, 333,321, 422, 332, 432) THEN 'active' -- (Customers who buy often & recently, but at low price points)
		WHEN rfm_string IN (433, 434, 443, 444) THEN 'loyal'
	END AS "rfm_segment"
FROM rfm;



