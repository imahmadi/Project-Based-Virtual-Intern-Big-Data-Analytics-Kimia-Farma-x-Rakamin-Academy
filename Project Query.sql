--===========================================================
--======= CREATE SALES SUMMARY TABLE  =======================
--=======                             =======================
--======= Contains the summary of all =======================
--======= available Table             =======================
--===========================================================

WITH t4 AS(
SELECT t1.id_invoice,
		t1.tanggal AS order_date,
		t1.id_customer,
		t2.nama AS company_name,
		t2.cabang_sales AS sales_branch,
		t2."group" AS customer_group,
		t1.id_barang AS id_product,
		t3.nama_barang AS product_name,
		t3.kemasan AS packaging,
		t1.jumlah_barang AS total_product,
		t1.harga AS total_price,
		t1.mata_uang AS currency,
		t3.lini AS product_line
FROM penjualan AS t1
LEFT JOIN pelanggan AS t2
	ON t1.id_customer = t2.id_customer
LEFT JOIN barang AS t3
	ON t1.id_barang = t3.kode_barang)

SELECT *
INTO sales_summary
FROM t4;

--=================================================================
--======= CREATE AGGREGATE TABLE Monthly Total Transaction ========
--=======                                                 =========
--======= Table that Exclusively to Aggregate monthly     =========
--======= data in general                                 =========
--=================================================================

WITH cte1 AS(
SELECT MONTH(order_date) as "month",
		DATENAME(month, order_date) AS month_n, 
		COUNT(*) AS total_transaction,
		SUM(total_product) AS total_product,
		ROUND(SUM(total_price),2) AS total_income
FROM sales_summary
GROUP BY MONTH(order_date), DATENAME(month, order_date))

SELECT t1."month",
		t1.month_n,
		t1.total_transaction,
		CAST((((CAST((t1.total_transaction - t2.total_transaction) AS decimal))/ t2.total_transaction) * 100) AS int) AS percent_diff_transaction,
		t1.total_product,
		CAST((((CAST((t1.total_product - t2.total_product) AS decimal))/ t2.total_product) * 100) AS int) AS percent_diff_product,
		t1.total_income,
		CAST((((t1.total_income - t2.total_income)/ t2.total_income) * 100) AS int) AS percent_diff_income
INTO agg_monthly_sales_total
FROM cte1 AS t1
LEFT JOIN cte1 AS t2
ON t1."month" = t2."month"+1

--=================================================================
--======= CREATE AGGREGATE TABLE Monthly Total Sales Product ======
--=======                                                 =========
--======= Table that Aggregate monthly data by Product    =========
--=================================================================

WITH 
t1 AS(
	SELECT product_name,
			MONTH(order_date) as "month",
			DATENAME(month, order_date) AS month_n,
			COUNT(*) AS total_order,
			SUM(total_product) AS total_product,
			ROUND(SUM(total_price),2) AS total_price
	FROM sales_summary
	GROUP BY product_name, MONTH(order_date), DATENAME(month, order_date)
),
t2 AS(
	SELECT *, ROW_NUMBER() OVER(PARTITION BY product_name ORDER BY "month") AS rn
	FROM t1
)

SELECT t3.product_name,
		t3."month",
		t3.month_n,
		t3.total_order,
		CAST((((CAST((t3.total_order - t4.total_order) AS decimal))/ t4.total_order) * 100) AS int) AS percent_diff_order,
		t3.total_product,
		CAST((((CAST((t3.total_product - t4.total_product) AS decimal))/ t4.total_product) * 100) AS int) AS percent_diff_product,
		t3.total_price,
		CAST((((t3.total_price - t4.total_price)/ t4.total_price) * 100) AS int) AS percent_diff_price
INTO agg_monthly_sales_product
FROM t2 AS t3
LEFT JOIN t2 AS t4
	ON t3.product_name = t4.product_name AND t3.rn = t4.rn + 1;

--=================================================================
--======= CREATE AGGREGATE TABLE Monthly Sales by Branch ==========
--=======                                                 =========
--======= Table that Aggregate monthly data by City       =========
--=================================================================

SELECT sales_branch, 
		DATENAME(month, order_date) AS month_n, 
		company_name,
		customer_group,
		product_name,
		COUNT(*) AS total_order,
		SUM(total_product) AS total_product,
		ROUND(SUM(total_price),2) AS total_price
INTO agg_monthly_sales_branch
FROM sales_summary
GROUP BY sales_branch, 
		DATENAME(month, order_date), 
		company_name,
		customer_group,
		product_name;
