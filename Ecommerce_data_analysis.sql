/** RDBMS Used for this Analysis : MySQL

    Analysis of Ecommerce order data by Olist and finding possible insights from the data.

  Actual data for this database has been taken from kaggle at (https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
  titled E-Commerce Public Dataset by Olist


  This database contains data of order details of 2016, 2017, 2018 in 9 tables.
  note: This database does not include data for (november, december for 2018) and (January - August, November for 2016)

  1. Customers - Information about the customer
  2. Geolocation - location information about the cities
  3. Order_items - Information about the order items
  4. Order_payment - Information about the customer's order payment
  5. Order_reviews - customers review about the orders
  6. Orders - Information about the order
  7. Product_category_name_translation - Translation of product category data from brazilian to english
  8. Products - Information about the products
  9. seller - Information about the seller

  Questions that are to be answered with the analysis:
  1. Which product category has most positive customer reviews in 2016, 2017, 2018 and how many orders placed on those product category?
  2. Top 10 city has most sellers?
  3. Which is customers favourite mode of payment_type and why?
  4. Top 5 cities where customers orders the most?
  5. What is the average difference between purchase date and estimated delivery date for each product category. Find Top 5 product product category
     and compare whether the avg order to estimated delivery date is improved or not.
  6. What are some of the trends in total orders per month per year. Is it Increasing / Decreasing?
  7. Which product category sold the most per month in 2016, 2017, 2018.

 */


use Olist_ecommerce;

show tables;


--   1. Which product category has most positive customer reviews in 2016, 2017, 2018 and how many orders placed on those product category?


select year(order_purchase_timestamp)                              as year,
       monthname(order_purchase_timestamp)                         as month,
       product_category_name_english,
       count(order_id)                                             as order_count,
       count(case when review_score in (4, 5) then 'Positive' end) as positive_review_count,
       count(case when review_score = 3 then 'Average' end)        as average_review_count,
       count(case when review_score in (1, 2) then 'Negative' end) as negative_review_count
from (select fd.*, orr.review_score
      from full_prod_order_data fd
               join order_reviews orr on fd.order_id = orr.order_id) as fl_rev
where product_category_name_english is not null
group by year, month, product_category_name_english
order by year, positive_review_count desc;

/*
    OUTCOME: 2016(october) - furniture_decor - 70 (Positive_review - 41)
             2017(november) - bed_bath_table - 975 (Positive_review - 599)
             2018(June) - health_beauty - 880 (Positive_review - 745)

*/


-- ---------------------------------------------------------------------------------------------------------------------------------------------------

-- 2. Top 10 city has most sellers?

select seller_city, count(seller_id) as seller_count
from seller
group by seller_city
order by seller_count desc
limit 10;

/*
    OUTCOME: We could see that sao paulo city has most number of sellers with 695 sellers.
             There is a great difference between 1st and 2nd city with most number of sellers.
             sao paulo - 695
             curitiba - 127

*/



-- ---------------------------------------------------------------------------------------------------------------------------------------------------


--   3. Which is customers favourite mode of payment_type and why?


select payment_type, count(order_id) as order_count
from order_payment
group by payment_type
order by order_count desc;

/*
    OUTCOME : We could see from the result below that credit card is customers favourite mode of payment. The reason might be
             customers prefers to buy the products with installments.

             credit_card - 76795
             boleto      - 19784
             voucher     - 5775
             debit_card  - 1529
             not_defined - 3

*/




-- ---------------------------------------------------------------------------------------------------------------------------------------------------


-- 4. Top 5 cities where customers orders the most?

select customer_city, count(*) as order_count
from orders o
         join customer c on o.customer_id = c.customer_id
group by customer_city
order by order_count desc
limit 5;

/*
    QUERY RESULT: Customer_city    Order_count
                  sao paulo        15540
                  rio de janeiro   6882
                  belo horizonte   2773
                  brasilia         2131
                  curitiba         1521

        OUTCOME: We could see that sao paulo city has significantly most number of orders as well as seller.
                 We could provide promotions in other cities to increase the customer base for our company.

*/


-- ---------------------------------------------------------------------------------------------------------------------------------------------------


--   5. What is the average difference between purchase date and estimated delivery date for each product category. Find Top 5 product product category
--      and compare whether the avg order to estimated delivery date is improved or not.

select year(order_purchase_timestamp)      as year,
       monthname(order_purchase_timestamp) as months,
       product_category_name_english,
       round(avg(timestampdiff(day, order_purchase_timestamp, order_estimated_delivery_date)),
             1)                            as avg_order_to_est_delivery_date
from full_prod_order_data
where product_category_name_english is not null
group by year, months, product_category_name_english
order by year, avg_order_to_est_delivery_date desc;


-- Comparing Top 5 higher avg order to estimate delivery date product category in 2016, 2017 and 2018


select product_category_name_english,
       sum(case when year = 2016 then avg_order_to_est_delivery_date_yearly end) as avg_order_to_est_delivery_date_yearly_2016,
       sum(case when year = 2017 then avg_order_to_est_delivery_date_yearly end) as avg_order_to_est_delivery_date_yearly_2017,
       sum(case when year = 2018 then avg_order_to_est_delivery_date_yearly end) as avg_order_to_est_delivery_date_yearly_2018
from (select year(order_purchase_timestamp)                                            as year,
             product_category_name_english,
             round(avg(timestampdiff(day, order_purchase_timestamp, order_estimated_delivery_date)),
                   1)                                                                  as avg_order_to_est_delivery_date_yearly,
             row_number()
                     over (partition by year(order_purchase_timestamp) order by year(order_purchase_timestamp), round(
                             avg(timestampdiff(day, order_purchase_timestamp, order_estimated_delivery_date)),
                             1) desc rows between unbounded preceding and current row) as row_num
      from full_prod_order_data
      where product_category_name_english is not null
      group by year, product_category_name_english
      order by year, avg_order_to_est_delivery_date_yearly desc) as dat
group by product_category_name_english
order by avg_order_to_est_delivery_date_yearly_2016 desc
limit 5;


/*
        OUTCOME : Average order to estimate delivery date for 2016 seems to be higher - this is not a accurate value as the dataset doesn't have value full
                  data for 2016. comparing 2017 and 2018 we could see that the average order to estimated delivery date is decreased over all the product
                  categories.

*/


-- ---------------------------------------------------------------------------------------------------------------------------------------------------


--   6. What are some of the trends in total orders per month per year. Is it Increasing / Decreasing?

-- Since the database only contains 3 months data for 2016 - Hence we have only used data of 2017, 2018 for this analysis.

select year(order_purchase_timestamp) as year, count(*) as order_count
from orders
where year(order_purchase_timestamp) in (2017, 2018)
group by year
order by year;


/*
    OUTCOME: On 2017, the total orders were 45,101 however on 2018 the total orders were 54,011(november, december
            data not included as it was not available), Even then we could see that the orders in 2018 were higher than 2017.
            With the data that we have we could say that this company is making profits than previous year.
*/


-- Total orders per month per year

select year,
       months,
       order_count,
       order_count - lag(order_count) over (partition by year order by year) as monthly_diff, -- total order difference between current month and previous month
       (case
            when (order_count - lag(order_count) over (partition by year order by year)) > 0 then 'Increasing'
            when (order_count - lag(order_count) over (partition by year order by year)) < 0 then 'Decreasing'
            when (order_count - lag(order_count) over (partition by year order by year)) = 0
                then 'Equals Last Month' end)                                as monthly_order_diff_outcome,
       running_total_yearly
from (select year(order_purchase_timestamp)                                                  as year,
             monthname(order_purchase_timestamp)                                             as months,
             count(order_id)                                                                 as order_count,
             sum(count(order_id))
                 over (partition by year(order_purchase_timestamp) order by year(order_purchase_timestamp), -- partitioning the data to yearly to calculate running total for the years
                     (case
                          when months = 'January' then 1
                          when months = 'February' then 2
                          when months = 'March' then 3
                          when months = 'April' then 4
                          when months = 'May' then 5
                          when months = 'June' then 6
                          when months = 'July' then 7
                          when months = 'August' then 8
                          when months = 'September' then 9
                          when months = 'October' then 10
                          when months = 'November' then 11
                          when months = 'December'
                              then 12 end) rows between unbounded preceding and current row) as running_total_yearly
      from orders
      where year(order_purchase_timestamp) in (2017, 2018) -- select only year 2017, 2018 for the analysis
      group by year, months
      order by year,
               (case
                    when months = 'January' then 1
                    when months = 'February' then 2
                    when months = 'March' then 3
                    when months = 'April' then 4
                    when months = 'May' then 5
                    when months = 'June' then 6
                    when months = 'July' then 7
                    when months = 'August' then 8
                    when months = 'September' then 9
                    when months = 'October' then 10
                    when months = 'November' then 11
                    when months = 'December' then 12 end)) -- To order the data as per month sequence
         as ord_data;

/*
      OUTCOME: When comparing the total orders per month between 2017 and 2018, we could see that for most of the months the total
              orders were higher in 2018. And November has higher order count in 2017, the reason could be due to holiday season around
              november

*/



-- ---------------------------------------------------------------------------------------------------------------------------------------------------



--   7. Which product category sold the most per month in 2016, 2017, 2018.

--  prod_details View created for joining products table with product category name translation table

create view prod_details as
(
select p.*, pct.product_category_name_english
from products p
         left outer join product_category_name_translation pct
                         on p.product_category_name = pct.product_category_name);

-- creating view for full order + Product tables

create view full_prod_order_data as
(
select pd.*,
       oi.order_item_id,
       oi.seller_id,
       oi.shipping_limit_date,
       oi.price,
       oi.freight_value,
       o.order_id,
       o.customer_id,
       o.order_status,
       o.order_purchase_timestamp,
       o.order_approved_at,
       o.order_delivered_carrier_date,
       o.order_delivered_customer_date,
       o.order_estimated_delivery_date
from prod_details pd
         inner join order_items oi on pd.product_id = oi.product_id
         join orders o on oi.order_id = o.order_id);


select year, month, product_category_name_english, order_count as top3_order_count
from (select year(order_purchase_timestamp)                                                                                                                                         as year,
             monthname(order_purchase_timestamp)                                                                                                                                    as month,
             product_category_name_english,
             count(order_id)                                                                                                                                                        as order_count,
             row_number()
                     over (partition by year(order_purchase_timestamp), (case
                                                                             when month = 'January' then 1
                                                                             when month = 'February' then 2
                                                                             when month = 'March' then 3
                                                                             when month = 'April' then 4
                                                                             when month = 'May' then 5
                                                                             when month = 'June' then 6
                                                                             when month = 'July' then 7
                                                                             when month = 'August' then 8
                                                                             when month = 'September' then 9
                                                                             when month = 'October' then 10
                                                                             when month = 'November' then 11
                                                                             when month = 'December'
                                                                                 then 12 end) order by year(order_purchase_timestamp), (case
                                                                                                                                            when month = 'January'
                                                                                                                                                then 1
                                                                                                                                            when month = 'February'
                                                                                                                                                then 2
                                                                                                                                            when month = 'March'
                                                                                                                                                then 3
                                                                                                                                            when month = 'April'
                                                                                                                                                then 4
                                                                                                                                            when month = 'May'
                                                                                                                                                then 5
                                                                                                                                            when month = 'June'
                                                                                                                                                then 6
                                                                                                                                            when month = 'July'
                                                                                                                                                then 7
                                                                                                                                            when month = 'August'
                                                                                                                                                then 8
                                                                                                                                            when month = 'September'
                                                                                                                                                then 9
                                                                                                                                            when month = 'October'
                                                                                                                                                then 10
                                                                                                                                            when month = 'November'
                                                                                                                                                then 11
                                                                                                                                            when month = 'December'
                                                                                                                                                then 12 end), count(order_id) desc) as order_count_per_category
      from full_prod_order_data as fd
      group by year, month, product_category_name_english
      order by year,
               (case
                    when month = 'January' then 1
                    when month = 'February' then 2
                    when month = 'March' then 3
                    when month = 'April' then 4
                    when month = 'May' then 5
                    when month = 'June' then 6
                    when month = 'July' then 7
                    when month = 'August' then 8
                    when month = 'September' then 9
                    when month = 'October' then 10
                    when month = 'November' then 11
                    when month = 'December' then 12 end), order_count desc) as fil_data
where order_count_per_category <= 3;



-- ---------------------------------------------------------------------------------------------------------------------------------------------------
