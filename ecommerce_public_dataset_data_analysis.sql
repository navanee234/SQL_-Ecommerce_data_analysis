/** RDBMS Used for this Analysis : MySQL

    Analysis of Brazilian ecommerce order data by Olist and finding insights from the data.

  Actual data has been taken from kaggle at (https://www.kaggle.com/datasets/olistbr/brazilian-ecommerce)
  titled E-Commerce Public Dataset by Olist


  This database contains data of order details of 2016, 2017, 2018 in 9 tables.
  note: This database does not include data for (november, december for 2018) and (January - August, November for 2016)

  Tables:
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


USE Olist_ecommerce; 

SHOW tables;


--   1. Which product category has most positive customer reviews in 2016, 2017, 2018 and how many orders placed on those product category?


SELECT 
    YEAR(order_purchase_timestamp) AS year,
    MONTHNAME(order_purchase_timestamp) AS month,
    product_category_name_english,
    COUNT(order_id) AS order_count,
    COUNT(CASE
        WHEN review_score IN (4 , 5) THEN 'Positive' END) AS positive_review_count,
    COUNT(CASE
        WHEN review_score = 3 THEN 'Average' END) AS average_review_count,
    COUNT(CASE
        WHEN review_score IN (1 , 2) THEN 'Negative' END) AS negative_review_count
FROM
    (SELECT 
        fd.*, orr.review_score
    FROM
        full_prod_order_data fd
    JOIN order_reviews orr ON fd.order_id = orr.order_id) AS fl_rev
WHERE
    product_category_name_english IS NOT NULL
GROUP BY year , month , product_category_name_english
ORDER BY year , positive_review_count DESC;


/*
    OUTCOME: 2016(october) - furniture_decor - 70 (Positive_review - 41)
             2017(november) - bed_bath_table - 975 (Positive_review - 599)
             2018(June) - health_beauty - 880 (Positive_review - 745)

*/


-- ---------------------------------------------------------------------------------------------------------------------------------------------------


-- 2. Top 10 city which has most sellers?

SELECT 
    seller_city, 
    COUNT(seller_id) AS seller_count
FROM
    seller
GROUP BY seller_city
ORDER BY seller_count DESC
LIMIT 10;

/*
    OUTCOME: We could see that sao paulo city has most number of sellers with 695 sellers.
             There is a great difference between 1st and 2nd city with most number of sellers.
             sao paulo - 695
             curitiba - 127

*/



-- ---------------------------------------------------------------------------------------------------------------------------------------------------


--   3. Which is customers favourite mode of payment_type and why?


SELECT 
    payment_type, 
    COUNT(order_id) AS order_count
FROM
    order_payment
GROUP BY payment_type
ORDER BY order_count DESC;

/*
    OUTCOME : We could see from the result below shows that credit card is customers favourite mode of payment. The reason might be
             customers prefers to buy the products with installments.

             credit_card - 76795
             boleto      - 19784
             voucher     - 5775
             debit_card  - 1529
             not_defined - 3

*/




-- ---------------------------------------------------------------------------------------------------------------------------------------------------


-- 4. Top 5 cities where customers orders the most?


SELECT 
    customer_city, 
    COUNT(*) AS order_count
FROM
    orders o
        JOIN
    customer c ON o.customer_id = c.customer_id
GROUP BY customer_city
ORDER BY order_count DESC
LIMIT 5;

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

SELECT 
    YEAR(order_purchase_timestamp) AS year,
    MONTHNAME(order_purchase_timestamp) AS months,
    product_category_name_english,
    ROUND(AVG(TIMESTAMPDIFF(DAY,
                order_purchase_timestamp,
                order_estimated_delivery_date)),1) AS avg_order_to_est_delivery_date
FROM
    full_prod_order_data
WHERE
    product_category_name_english IS NOT NULL
GROUP BY year , months , product_category_name_english
ORDER BY year , avg_order_to_est_delivery_date DESC;


-- Comparing Top 5 higher avg order to estimate delivery date product category in 2016, 2017 and 2018


SELECT 
    product_category_name_english,
    SUM(CASE WHEN year = 2016 then avg_order_to_est_delivery_date_yearly end) AS avg_order_to_est_delivery_date_yearly_2016,
    SUM(CASE WHEN year = 2017 then avg_order_to_est_delivery_date_yearly end) AS avg_order_to_est_delivery_date_yearly_2017,
    SUM(CASE WHEN year = 2018 then avg_order_to_est_delivery_date_yearly end) AS avg_order_to_est_delivery_date_yearly_2018
FROM 
    (SELECT 
        year(order_purchase_timestamp) AS year,
        product_category_name_english,
        ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_estimated_delivery_date)),1) AS avg_order_to_est_delivery_date_yearly,
             ROW_NUMBER() OVER (PARTITION BY YEAR(order_purchase_timestamp) ORDER BY YEAR(order_purchase_timestamp),
                          ROUND(AVG(TIMESTAMPDIFF(DAY, order_purchase_timestamp, order_estimated_delivery_date)),1) DESC 
                          ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS row_num
      FROM 
          full_prod_order_data
      WHERE product_category_name_english is not null
      GROUP BY year, product_category_name_english
      ORDER BY year, avg_order_to_est_delivery_date_yearly DESC) AS dat
GROUP BY product_category_name_english
ORDER BY avg_order_to_est_delivery_date_yearly_2016 DESC
LIMIT 5;


/*
        OUTCOME : Average order to estimate delivery date for 2016 seems to be higher - this is not a accurate value as the dataset doesn't have value full
                  data for 2016. comparing 2017 and 2018 we could see that the average order to estimated delivery date is decreased over all the product
                  categories.

*/


-- ---------------------------------------------------------------------------------------------------------------------------------------------------


--   6. What are some of the trends in total orders per month per year. Is it Increasing / Decreasing?

-- Since the database only contains 3 months data for 2016 - Hence we have only used data of 2017, 2018 for this analysis.


SELECT 
    YEAR(order_purchase_timestamp) AS year,
    COUNT(*) AS order_count
FROM
    orders
WHERE
    YEAR(order_purchase_timestamp) IN (2017 , 2018)
GROUP BY year
ORDER BY year;


/*
    OUTCOME: On 2017, the total orders were 45,101 however on 2018 the total orders were 54,011(november, december
            data not included as it was not available), Even then we could see that the orders in 2018 were higher than 2017.
            With the data that we have we could say that this company is making profits than previous year.
*/



-- Total orders per month per year


SELECT 
	   year,
       months,
       order_count,
       order_count - LAG(order_count) OVER (PARTITION BY year ORDER BY year) AS monthly_diff, -- total order difference between current month and previous month
       (CASE
            WHEN (order_count - LAG(order_count) OVER (PARTITION BY year ORDER BY year)) > 0 THEN 'Increasing'
            WHEN (order_count - LAG(order_count) OVER (PARTITION BY year ORDER BY year)) < 0 THEN 'Decreasing'
            WHEN (order_count - LAG(order_count) OVER (PARTITION BY year ORDER BY year)) = 0 THEN 'Equals Last Month' 
            END) AS monthly_order_diff_outcome,running_total_yearly
FROM 
   (SELECT
		YEAR(order_purchase_timestamp) AS year,
		MONTHNAME(order_purchase_timestamp) AS months,
		COUNT(order_id) as order_count,
		SUM(COUNT(order_id))
                 OVER (PARTITION BY year(order_purchase_timestamp) ORDER BY year(order_purchase_timestamp), -- partitioning the data to yearly to calculate running total for the years
                     (CASE                              
                          WHEN months = 'January' THEN 1 -- For ordering the data in monthly order
                          WHEN months = 'February' THEN 2
                          WHEN months = 'March' THEN 3
                          WHEN months = 'April' THEN 4
                          WHEN months = 'May' THEN 5
                          WHEN months = 'June' THEN 6
                          WHEN months = 'July' THEN 7
                          WHEN months = 'August' THEN 8
                          WHEN months = 'September' THEN 9
                          WHEN months = 'October' THEN 10
                          WHEN months = 'November' THEN 11
                          WHEN months = 'December'
                              THEN 12 END) ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS running_total_yearly
      FROM
		 orders
      WHERE YEAR(order_purchase_timestamp) IN (2017, 2018) -- select only year 2017, 2018 for the analysis
	  GROUP BY year, months
      ORDER BY year,
               (CASE
                    WHEN months = 'January' THEN 1
                    WHEN months = 'February' THEN 2
                    WHEN months = 'March' THEN 3
                    WHEN months = 'April' THEN 4
                    WHEN months = 'May' THEN 5
                    WHEN months = 'June' THEN 6
                    WHEN months = 'July' THEN 7
                    WHEN months = 'August' THEN 8
                    WHEN months = 'September' THEN 9
                    WHEN months = 'October' THEN 10
                    WHEN months = 'November' THEN 11
                    WHEN months = 'December' THEN 12 
                    END)) -- To order the data as per month sequence
         AS ord_data;
         
         
/*
      OUTCOME: When comparing the total orders per month between 2017 and 2018, we could see that for most of the months the total
              orders were higher in 2018. And November has higher order count in 2017, the reason could be due to holiday season around
              november

*/



-- ---------------------------------------------------------------------------------------------------------------------------------------------------



--   7. Which product category sold the most per month in 2016, 2017, 2018.

--  prod_details View created for joining products table with product category name translation table


CREATE VIEW prod_details AS
(
SELECT 
    p.*, 
    pct.product_category_name_english
FROM 
    products p
         LEFT OUTER JOIN product_category_name_translation pct
                         on p.product_category_name = pct.product_category_name);



-- creating view for full order + Product tables

CREATE VIEW full_prod_order_data AS
(
SELECT 
       pd.*,
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
FROM 
    prod_details pd
    INNER JOIN order_items oi on pd.product_id = oi.product_id
         JOIN orders o on oi.order_id = o.order_id);



SELECT  -- Outer Query to filter the data from the inner query
    year, 
    month, 
    product_category_name_english, 
    order_count AS top3_order_count
FROM 
    (SELECT  -- Inner Query
        YEAR(order_purchase_timestamp) AS year,
             monthname(order_purchase_timestamp) AS month,
             product_category_name_english,
             count(order_id) AS order_count,
             ROW_NUMBER()
                     OVER (PARTITION BY YEAR(order_purchase_timestamp), 
                     (CASE
                         WHEN month = 'January' THEN 1 -- This case statement is to group the data as per month according to the partion
                         WHEN month = 'February' THEN 2
                         WHEN month = 'March' THEN 3
                         WHEN month = 'April' THEN 4
                         WHEN month = 'May' THEN 5
                         WHEN month = 'June' THEN 6
                         WHEN month = 'July' THEN 7
                         WHEN month = 'August' THEN 8
                         WHEN month = 'September' THEN 9
                         WHEN month = 'October' THEN 10
                         WHEN month = 'November' THEN 11
                         WHEN month = 'December'THEN 12
                         END) ORDER BY YEAR(order_purchase_timestamp), (case WHEN month = 'January' THEN 1 -- This case statement is to order the grouped data as per the month order
                                                                             WHEN month = 'February' THEN 2
                                                                             WHEN month = 'March' THEN 3
                                                                             WHEN month = 'April' THEN 4
                                                                             WHEN month = 'May' THEN 5
                                                                             WHEN month = 'June' THEN 6
                                                                             WHEN month = 'July' THEN 7
                                                                             WHEN month = 'August' THEN 8
                                                                             WHEN month = 'September' THEN 9
                                                                             WHEN month = 'October' THEN 10
                                                                             WHEN month = 'November' THEN 11
                                                                             WHEN month = 'December'THEN 12
                                                                             END), COUNT(order_id) DESC) AS order_count_per_category
      FROM
          full_prod_order_data AS fd
      GROUP BY year, month, product_category_name_english
      ORDER BY year,
               (case WHEN month = 'January' THEN 1 -- This case statement is to order the grouped data as per the month order
                     WHEN month = 'February' THEN 2
                     WHEN month = 'March' THEN 3
                     WHEN month = 'April' THEN 4
                     WHEN month = 'May' THEN 5
                     WHEN month = 'June' THEN 6
                     WHEN month = 'July' THEN 7
                     WHEN month = 'August' THEN 8
                     WHEN month = 'September' THEN 9
                     WHEN month = 'October' THEN 10
                     WHEN month = 'November' THEN 11
                     WHEN month = 'December'THEN 12
                     END), order_count DESC) AS fil_data
WHERE order_count_per_category <= 3;



-- ---------------------------------------------------------------------------------------------------------------------------------------------------
