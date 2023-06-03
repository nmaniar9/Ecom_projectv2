# Ecom_projectv2
Update to the original file

files in project
	
	(tables)
	product.csv
	orders.csv
	ordereditems.csv
	
	ecommercedatabase.ipynb
	ecommercedatabase.py
	
	ecomsql.sql
	
	Tableau Public link: https://public.tableau.com/app/profile/neil.maniar
	
	
Goal of the project is to update the code from the first version, explore the data for business case questions in sql server, and display the data in a Tableau Dashboard.

Step 1. Create the relational database tables in python 
    
    using a smaller version of what types of tables ecommerce companies would have
    tables:
        product: ['sku','name','price','quantity','cogs']
            sku: unique id for each product created with random strings
            name: item name scraped using Beautiful soup library from Lego.com
            price: item price scraped using Beautiful soup library from Lego.com
            quantity: Onhand quanity of each item created using a normal distribution with mean 35.
            cogs: cost of goods sold for each item, calculated as 50% price
            
        orders: ['order_id','created_at','amount']
            order_id: Unique id for each individual order created with random number string
            created_at: datetime created with python datetime library
            amount: Total order amount calculated using 'quantity_ordered' from ordered_items table using merge and groupby
            
        ordered_items: ['order_id','sku','quantity_ordered']
            order_id: assigned random order_ids to table using the same order_id from orders table
            sku: assigned order_id skus from product table
            quantity_ordered: created usign random weighted values for 'how many of each sku were in each order'
     
     full details in python file
   
Step 2. Upload tables to SQL Server and decide what business case questions can be answered
    
    1. What are the top sellers? What are the worst
            select top 5 p.name, sum(quantity_ordered) as total_ordered
            from ecom2.dbo.ordereditems as oi
            inner join ecom2.dbo.product as p
            on oi.sku = p.sku
            group by p.name
            order by total_ordered DESC (ASC)
            
    2. What is the average order size
            select avg(amount_ordered) as avg_order
            from ecom2.dbo.orders
    
    3. When are most orders placed? (time of year)
            select sum(case when datepart(QUARTER,o.created_at) = 1 then quantity_ordered else null end) as q1,
                   sum(case when datepart(QUARTER,o.created_at) = 2 then quantity_ordered else null end) as q2,
                   sum(case when datepart(QUARTER,o.created_at) = 3 then quantity_ordered else null end) as q3,
                   sum(case when datepart(QUARTER,o.created_at) = 4 then quantity_ordered else null end) as q4
            from ecom2.dbo.orders as o
            inner join ecom2.dbo.ordereditems as oi
            on o.order_id = oi.order_id
            
    4. What is the profit? profit by time?
    
            with new_table as 
                (select p.sku, sum(quantity_ordered) as total_ordered
	            from ecom2.dbo.ordereditems as oi
	            inner join ecom2.dbo.product as p
	            on oi.sku = p.sku
	            group by p.sku)
            select sum(new_table.total_ordered * (p1.price - p1.cogs))
            from new_table
            inner join ecom2.dbo.product as p1
            on new_table.sku = p1.sku
            
            
            with new_table as 
                (select p.sku, sum(quantity_ordered) as total_ordered
	            from ecom2.dbo.ordereditems as oi
	            inner join ecom2.dbo.product as p
	            on oi.sku = p.sku
	            group by p.sku)
            select sum(case when datepart(QUARTER,o.created_at) = 1 then (new_table.total_ordered * (p1.price - p1.cogs)) else null end) as q1,
                   sum(case when datepart(QUARTER,o.created_at) = 2 then (new_table.total_ordered * (p1.price - p1.cogs)) else null end) as q2,
                   sum(case when datepart(QUARTER,o.created_at) = 3 then (new_table.total_ordered * (p1.price - p1.cogs)) else null end) as q3,
                   sum(case when datepart(QUARTER,o.created_at) = 4 then (new_table.total_ordered * (p1.price - p1.cogs)) else null end) as q4
            from new_table
            inner join ecom2.dbo.product as p1
            on new_table.sku = p1.sku
            inner join ecom2.dbo.ordereditems as oi
            on p1.sku = oi.sku
            inner join ecom2.dbo.orders as o
            on oi.order_id = o.order_id



A full look at all the SQL queries made:
	
	/* Goal is to answer business related questions
    Some things to consider:
    1. Is the data accurate? 
    2. What are the top sellers / What are the worst sellers
    3. What region has the most purchasers
    4. What age group orders the most products
*/ 

   --Modifying the tables to change datatypes---

    ALTER TABLE ecom.dbo.product 
    ALTER COLUMN prices DECIMAL(18,2)
    ALTER TABLE ecom.dbo.product 
    ALTER COLUMN inventory INT
    ALTER TABLE ecom.dbo.orders
    ALTER COLUMN total DECIMAL(18,2)
    ALTER TABLE ecom.dbo.orders 
    ALTER COLUMN created_at DATETIME
    ALTER TABLE ecom.dbo.invoices
    ALTER COLUMN quantity INT
    ALTER TABLE ecom.dbo.users
    ALTER COLUMN age DECIMAL(18,2)

    --id numbers that start with zero are pulling incorrectly 
    --Example: 0035 = 35 
    --Created a temp table and testing updates before updating original
    SELECT product_id
    INTO #temp
    FROM ecom.dbo.product

    SELECT *
    FROM #temp

    UPDATE #temp
        SET product_id = CASE
	    WHEN LEN(product_id) = 3
	    THEN CONCAT('0',product_id)
	    WHEN LEN(product_id) = 2
	    THEN CONCAT('00',product_id)
	    ELSE product_id
	    END
    DROP TABLE #temp

    UPDATE ecom.dbo.product
       SET product_id = CASE
	   WHEN LEN(product_id) = 3
	   THEN CONCAT('0',product_id)
	   WHEN LEN(product_id) = 2
	   THEN CONCAT('00',product_id)
	   ELSE product_id
	   END

    UPDATE ecom.dbo.invoices
        SET product_id = CASE
	    WHEN LEN(product_id) = 3
	    THEN CONCAT('0',product_id)
	    WHEN LEN(product_id) = 2
	    THEN CONCAT('00',product_id)
	    ELSE product_id
	    END


    --What are the total sales?--
    SELECT iv.product_id, iv.quantity, p.names, p.prices, p.prices*iv.quantity AS total_sale
    FROM ecom.dbo.invoices AS iv
    INNER JOIN ecom.dbo.product AS p
    ON iv.product_id = p.product_id

    /*If we find the total using the orders table only and then check against the invoices table we see there is a difference.
      It if we assume the ordered quantities are correct it seems that the order totals are not populating correctly
    */

    SELECT SUM(os.total)
    FROM ecom.dbo.orders AS os

    SELECT SUM(p.prices * iv.quantity)
    FROM ecom.dbo.invoices AS iv
    FULL JOIN ecom.dbo.product AS p
    ON iv.product_id = p.product_id

    /*We can create a new table that will be account for the correct sales */

    CREATE TABLE ecom.dbo.sales (
       invoice_id VARCHAR(50),
       order_id VARCHAR(50),
       order_quantity int,
       price DECIMAL(18,2),
  	   total_sale DECIMAL(18,2)
    );

    ALTER TABLE ecom.dbo.sales
    ADD product_id VARCHAR(50);

    INSERT INTO ecom.dbo.sales (invoice_id,order_id,order_quantity,price,total_sale,product_id)
    SELECT iv.invoice_id, iv.order_id, iv.quantity,p.prices, p.prices * iv.quantity, iv.product_id
    FROM ecom.dbo.invoices AS iv
    INNER JOIN ecom.dbo.product AS P
    ON iv.product_id = p.product_id

    --check Total Sales: 122749.61--
    SELECT SUM(total_sale) as all_sales
    FROM ecom.dbo.sales

    --What were the top 5 products sold and how many were sold--
    --There are 97 products but some have the same name

    SELECT TOP 5 p.names, SUM(s.order_quantity) AS total_sold
    FROM ecom.dbo.sales AS s
    INNER JOIN ecom.dbo.product AS p
    ON s.product_id = p.product_id
    GROUP BY p.names
    ORDER BY total_sold DESC

    --What products are worst selling products?
    --Revrese order by
    SELECT TOP 5 p.names, SUM(s.order_quantity) AS total_sold
    FROM ecom.dbo.sales AS s
    INNER JOIN ecom.dbo.product AS p
    ON s.product_id = p.product_id
    GROUP BY p.names
    ORDER BY total_sold ASC

    --What region has the highest sales-- 
    ----Mid Atlantic--
    SELECT u.region, SUM(s.total_sale) as total_sales, AVG(s.total_sale) as avg_sale
    FROM ecom.dbo.users AS u
    INNER JOIN ecom.dbo.orders as os
    ON u.user_id = os.user_id
    INNER JOIN ecom.dbo.sales as s
    ON os.order_id = s.order_id
    GROUP BY u.region
    ORDER BY total_sales DESC

    -- What are the sales by region for users under 40

    SELECT u.region, SUM(CASE WHEN u.age < 40 THEN s.total_sale ELSE 0 END) AS sale_under_40,
    AVG(CASE WHEN u.age < 40 THEN s.total_sale ELSE 0 END) AS avgsale_under_40
    FROM ecom.dbo.users AS u
    INNER JOIN ecom.dbo.orders as os
    ON u.user_id = os.user_id
    INNER JOIN ecom.dbo.sales as s
    ON os.order_id = s.order_id
    GROUP BY u.region

    --sales by customer age segment
    SELECT u.region,
    SUM(CASE WHEN u.age < 20 THEN s.total_sale ELSE 0 END) AS sale_under_20,
    SUM(CASE WHEN u.age < 30 and u.age > 20 THEN s.total_sale ELSE 0 END) AS sale_under_30,
    SUM(CASE WHEN u.age < 40 and u.age > 30 THEN s.total_sale ELSE 0 END) AS sale_under_40,
    SUM(CASE WHEN u.age < 50 and u.age > 40 THEN s.total_sale ELSE 0 END) AS sale_under_50,
    SUM(CASE WHEN u.age > 50 THEN s.total_sale ELSE 0 END) AS sale_over_50
    FROM ecom.dbo.users AS u
    INNER JOIN ecom.dbo.orders as os
    ON u.user_id = os.user_id
    INNER JOIN ecom.dbo.sales as s
    ON os.order_id = s.order_id
    GROUP BY u.region
