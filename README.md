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
