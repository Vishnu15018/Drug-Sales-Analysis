 --- Data preprocessing 
 --creating a copy of the original data
 SELECT *
INTO copyprojectdata
FROM projectdata;

-- No of rows before deleting 
select count(*) as count from copyprojectdata;

-- Remove duplicate rows and commit
BEGIN TRANSACTION;

WITH DuplicateRows AS (
    SELECT *,
        ROW_NUMBER() OVER (PARTITION BY Typeofsales, Patient_ID, Specialisation, Dept, Dateofbill, Quantity, ReturnQuantity, Final_Cost, Final_Sales, RtnMRP, Formulation, DrugName, SubCat, SubCat1 ORDER BY ID) AS RowNumber
    FROM projectdata
)
DELETE FROM DuplicateRows
WHERE RowNumber > 1;

COMMIT TRANSACTION;
---no of rows after deleting 

select count(*) as count from projectdata;

--- finding values and filling the null values 

create procedure findnull
     @columnname varchar(30),
	 @tablename varchar(30)
	as
	begin 
	declare @query Nvarchar(max);
	set @query = N'
	        select  '''+@columnname+N''' as column_name ,count(*)  as count_null
			from '+QUOTENAME(@tablename)+N'  
			where '+quotename(@columnname)+N'  IS NULL;
	';
	exec  sp_executesql @query;
	end

select top(10) * from projectdata;
exec findnull @columnname='Typeofsales', @tablename='projectdata';
exec findnull @columnname='Patient_ID', @tablename='projectdata';
exec findnull @columnname='DEPT', @tablename='projectdata';
exec findnull @columnname='Dateofbill', @tablename='projectdata';
exec findnull @columnname='Quantity', @tablename='projectdata';
exec findnull @columnname='ReturnQuantity', @tablename='projectdata';
exec findnull @columnname='Final_Cost', @tablename='projectdata';
exec findnull @columnname='Final_Sales', @tablename='projectdata';
exec findnull @columnname='RtnMRP', @tablename='projectdata';
exec findnull @columnname='Formulation', @tablename='projectdata';
exec findnull @columnname='DrugName', @tablename='projectdata';
exec findnull @columnname='SubCat', @tablename='projectdata';
exec findnull @columnname='SubCat1', @tablename='projectdata';

-- anlaysis In column Formulation 650 nulls are there 
--- in Drugname 1659 are there 
--in column name subcat 1659 are there 
-- in column name suncat2 1682 nulls are there

-- filling the null values 
-- where the  formulation and drugname is both null values 
select * from projectdata where Formulation IS NULL and DrugName IS NULL;
--- rather than removing the null values  I am filling it with unknown 
--- resason is hereonly the null values are related to only drugnames , formulation and subcategories, rather than removing it we can fill it with unknown so that these can be useful for analysing sales .. 
update projectdata
set Formulation='Unknown'
where Formulation IS NULL;

update projectdata
set DrugName='Unknown'
where DrugName IS NULL;

update projectdata
set SubCat='Unknown'
where SubCat IS NULL;

update projectdata
set SubCat1='Unknown'
where SubCat1 IS NULL;

--- Tranformations typecatsting 

-- Update and transform the Dateofbill column values
begin transaction
		begin try
				update projectdata
				set Dateofbill=convert(date,replace(Dateofbill,'-', '/'),101);

				alter table projectdata
				alter column Dateofbill DATE;

				 commit;
		 END TRY

		 BEGIN CATCH
		       ROLLBACK;
		END CATCH;
select top(10) * from projectdata;
-- checking datatype of date
   SELECT COLUMN_NAME, DATA_TYPE, CHARACTER_MAXIMUM_LENGTH, NUMERIC_PRECISION, NUMERIC_SCALE
    FROM INFORMATION_SCHEMA.COLUMNS
    WHERE TABLE_NAME = 'projectdata' AND COLUMN_NAME = 'Dateofbill';
	-- check any null values in dateofbill
select count(*) from projectdata where Dateofbill is null;


----
select top(10) * from projectdata;

--Outlier Analysis
--- zscore method 3

CREATE PROCEDURE FindOutliers
    @column_name NVARCHAR(50),
    @table_name NVARCHAR(50)
AS
BEGIN
    DECLARE @sql_query NVARCHAR(MAX);

    -- Step 1: Build the dynamic SQL query
    SET @sql_query = N'
        DECLARE @mean FLOAT, @stddev FLOAT;
        DECLARE @zscore_threshold FLOAT = 3;

        SELECT @mean = AVG(' + QUOTENAME(@column_name) + N'),
               @stddev = STDEV(' + QUOTENAME(@column_name) + N')
        FROM ' + QUOTENAME(@table_name) + N';

        SELECT COUNT(ID) AS count_outliers
        FROM ' + QUOTENAME(@table_name) + N'
        WHERE ' + QUOTENAME(@column_name) + N' NOT BETWEEN (@mean - @zscore_threshold * @stddev) AND (@mean + @zscore_threshold * @stddev);
    ';

    -- Step 2: Execute the dynamic SQL query
    EXEC sp_executesql @sql_query;
END
-- Column Quantity
exec FindOutliers @column_name='Quantity',@table_name='projectdata';

-- column Final_Cost
exec FindOutliers @column_name='Final_Cost',@table_name='projectdata';

-- column 'Final_Sales
exec FindOutliers @column_name='Final_Sales',@table_name='projectdata';

--- Handling the outliers 
--1.Reason for the outliers 
--outliers in this datasets are natural outliers. 
--3.These outliers occurs because sometimes some patient needs antibiotics and other costly drug to cure a specific disease and also when a patient bought more quantity of a drug it leads to hish transaction value , these high values causes outliers in sales 
--4.we need to keep these outliers as well to perform sales analysis
--5.as these outliers are natural we need to keep those outliers.
-- 6.We need to analyze this outliers seperately, by creating a new column cost_per_unit and price _category


--reason for creation of the cost_per_unit and price_category columns 
---- i)To analyze the sales better, to find the market segments by seperatley analysing the ouliers drugs that belongs to high and medium range.
--- II)To gain more view into the sales segments of each department.

-- adding the cost_per_unit column
ALTER TABLE projectdata
ADD cost_per_unit DECIMAL(10, 2); -- Adjust the data type and precision as needed


UPDATE projectdata
SET cost_per_unit = 
    CASE
        WHEN Quantity > 0 THEN Final_Cost / Quantity
        WHEN ReturnQuantity > 0 THEN Final_Cost / ReturnQuantity
        ELSE 0 -- or any default value you prefer
    END;


select top(10)* from projectdata;

--- creating the column price _category

		ALTER TABLE projectdata
		ADD price_category VARCHAR(20); -- Adjust the data type and length as needed


		  DECLARE @mean FLOAT, @std FLOAT;
		  DECLARE @zscore_threshold FLOAT = 3;
		select @mean=AVG(cost_per_unit) , @std=STDEV(cost_per_unit) from  projectdata;
		UPDATE projectdata
		SET price_category =
			CASE
				WHEN cost_per_unit >= 0 AND cost_per_unit <= 200 THEN 'Low'
				WHEN cost_per_unit > 200 AND cost_per_unit <=  @mean + (3 * @std) THEN 'Medium'
				ELSE 'High'
			END;



----- Adding column profit for profit analysis ---------------------------------

ALTER TABLE projectdata
ADD Profit DECIMAL(10,2); -- Adjust the data type and precision as needed

UPDATE projectdata
SET Profit = Final_Sales - Final_Cost;
commit;

-----------
select top(10) * from projectdata;

-------- analysing the data using the month -------------------
SELECT 
    YEAR(Dateofbill) AS Year,
    DATENAME(MONTH, Dateofbill) AS Month,
    SUM(Quantity) AS Total_Quantity,
    SUM(ReturnQuantity) AS Total_Return_Quantity,
    SUM(Final_Cost) AS Total_Final_Cost,
    SUM(Final_Sales) AS Total_Final_Sales
FROM projectdata
GROUP BY YEAR(Dateofbill), DATENAME(MONTH, Dateofbill)
ORDER BY YEAR(Dateofbill), DATENAME(MONTH,Dateofbill);

--------ANALYSIS----------------------------
---december has the highest sales  and highest demand with respect to quantity.
---But In august highest return quantity is recored






     
