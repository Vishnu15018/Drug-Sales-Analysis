select top(10) * from projectdata;

                                                 --- Exploratory data analysis ---- 
                      ------------------Univariate analysis on the numerical data----------------------------------
-- Create the stored procedure for  eda ------
CREATE PROCEDURE EDA_Numeric
    @columnName NVARCHAR(100),
    @TableName NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;

    -- Calculate the mean (first moment)
    DECLARE @mean FLOAT;
    DECLARE @meanQuery NVARCHAR(MAX) = N'
        SELECT @mean = AVG(' + QUOTENAME(@columnName) + N')
        FROM ' + QUOTENAME(@TableName) + N';
    ';

    EXEC sp_executesql @meanQuery, N'@mean FLOAT OUTPUT', @mean OUTPUT;

    -- Calculate the variance (second moment)
    DECLARE @variance FLOAT;
    DECLARE @varianceQuery NVARCHAR(MAX) = N'
        SELECT @variance = AVG((' + QUOTENAME(@columnName) + N' - @mean) * (' + QUOTENAME(@columnName) + N' - @mean))
        FROM ' + QUOTENAME(@TableName) + N';
    ';

    EXEC sp_executesql @varianceQuery, N'@mean FLOAT, @variance FLOAT OUTPUT', @mean, @variance OUTPUT;

    -- Calculate the skewness (third moment)
    DECLARE @skewness FLOAT;
    DECLARE @skewnessQuery NVARCHAR(MAX) = N'
        SELECT @skewness = SUM(POWER(' + QUOTENAME(@columnName) + N' - @mean, 3)) / (COUNT(' + QUOTENAME(@columnName) + N') * POWER(SQRT(@variance), 3))
       FROM ' + QUOTENAME(@TableName) + N';
    ';

    EXEC sp_executesql @skewnessQuery, N'@mean FLOAT, @variance FLOAT, @skewness FLOAT OUTPUT', @mean, @variance, @skewness OUTPUT;

    -- Calculate the kurtosis (fourth moment)
    DECLARE @kurtosis FLOAT;
    DECLARE @kurtosisQuery NVARCHAR(MAX) = N'
        SELECT @kurtosis = SUM(POWER(' + QUOTENAME(@columnName) + N' - @mean, 4)) / (COUNT(' + QUOTENAME(@columnName) + N') * POWER(@variance, 2))
      FROM ' + QUOTENAME(@TableName) + N';
    ';

    EXEC sp_executesql @kurtosisQuery, N'@mean FLOAT, @variance FLOAT, @kurtosis FLOAT OUTPUT', @mean, @variance, @kurtosis OUTPUT;

    -- Print the results
	print   'column: '+ CAST(@columnName as varchar(30)); 
    PRINT 'Mean: ' + CAST(@mean AS NVARCHAR(20));
    PRINT 'Variance: ' + CAST(@variance AS NVARCHAR(20));
    print 'Standard deviation: ' +CAST(SQRT(@variance) as nvarchar(20))
    PRINT 'Skewness: ' + CAST(@skewness AS NVARCHAR(20));
    PRINT 'Kurtosis: ' + CAST(@kurtosis AS NVARCHAR(20));
END;

-- column quantity...
exec EDA_Numeric @columnName = 'quantity' ,@TableName = 'projectdata';

-- column ReturnQuantity
exec EDA_Numeric @columnName = 'ReturnQuantity' ,@TableName = 'projectdata';

-- column   Final Cost
exec EDA_Numeric @columnName = 'Final_Cost' ,@TableName = 'projectdata';

---coulmn FInal Sales
exec EDA_Numeric @columnName = 'Final_Sales' ,@TableName = 'projectdata';
-- column 'RtnMR
exec EDA_Numeric @columnName='RtnMRP' ,@TableName = 'projectdata';

                              -- adding identity column to uniquely identify the rows--------------------------
ALTER TABLE projectdata
ADD ID INT IDENTITY(1, 1);
select top(10) * from projectdata;



--------------------------------------------Multivariate analysis ----------------------------------------------------------
                  --------------- between the categorical and numerical column------------
--- procedure for eda on category 
create procedure EDA_CAT
    @columnName2 varchar(20),
    @TableName2 varchar(20)

AS
BEGIN
     SET NOCOUNT ON;
    declare @query nvarchar(max);
    set @query = N'
    select '+QUOTENAME(@columnName2)+ N',count(ID) as count,avg(Quantity) as mean_quantity,avg(ReturnQuantity)as mean_Returnquantity,avg(Final_Cost) as mean_Final_Cost, avg(Final_Sales) as mean_Final_Sales
    FROM ' + QUOTENAME(@TableName2) + N' as pd group by(pd.'+QUOTENAME(@columnName2)+ N') order by count DESC;' ;
	exec sp_executesql @query;
END


exec EDA_CAT @columnName2='Typeofsales',@TableName2='projectdata';

exec EDA_CAT @columnName2='Specialisation',@TableName2='projectdata';

exec EDA_CAT @columnName2='Dept',@TableName2='projectdata';

exec EDA_CAT @columnName2='Formulation',@TableName2='projectdata';

select top(10) * from projectdata ;

--------------  sum aggregation   on numerical data based on grouping the categorical data ------
--- procedure for eda on category  for sum aggregration ---------------
create procedure EDA_CAT_SUM
    @columnName3 varchar(20),
    @TableName3 varchar(20)

AS
BEGIN
     SET NOCOUNT ON;
    declare @query nvarchar(max);
    set @query = N'
    select '+QUOTENAME(@columnName3)+ N',count(ID) as count,sum(Quantity) as sum_quantity,sum(ReturnQuantity)as sum_Returnquantity,sum(Final_Cost) as sum_Final_Cost, sum(Final_Sales) as sum_Final_Sales
    FROM ' + QUOTENAME(@TableName3) + N' as pd group by(pd.'+QUOTENAME(@columnName3)+ N') order by count DESC;' ;
	exec sp_executesql @query;
END


exec EDA_CAT_SUM @columnName3='Typeofsales',@TableName3='projectdata';

exec EDA_CAT_SUM @columnName3='Specialisation',@TableName3='projectdata';

exec EDA_CAT_SUM @columnName3='Dept',@TableName3='projectdata';

exec EDA_CAT_SUM @columnName3='Formulation',@TableName3='projectdata';

exec EDA_CAT_SUM @columnName3='SubCat' ,@TableName3='projectdata';
exec EDA_CAT_SUM @columnName3='SubCat1' ,@TableName3='projectdata';
exec EDA_CAT_SUM @columnName3='DrugName' ,@TableName3='projectdata';

----- analysis------
--1.Anti infectives and INtravenous and other sterile solution are the top most performed drugs with respect to sales , but the demand with respect to quantity is highest in INtravenous and other sterile solutions
-- 2.there may be viral , bacterial infections,abdominal related infections,cardio related conditions , fever related disease  or any specific medical condition more prevalent.
---3.Almost 90.8 sales Sales belongs to  Injections , fluids electrolytes , tablets and capsules .
--- 4.for details about the infections and diseases we need to go through the patient disese data.[Those data arr not in our scope]
-- 5. Given the high sales of "INJECTIONS," "IV FLUIDS, ELECTROLYTES, TPN," and "TABLETS & CAPSULES," it may be wise to ensure sufficient inventory levels for these subcategories to meet customer demand and avoid stockouts.
--6. top5 specalisation are specialisation4 , 7, 8,3 ,20. there may be a chance that among these specalization any one must belongs to treating the corona related cases.[ as the data is taken from 2022]
--7 Almost 87% percent of drugs bought patients are from deparment1 
--8 Dept 1 has highest demand and sales compared to all other departments (almost 89% sales are from department1) , and also among all three departments money was spent on dept1.




-------------------------------------------DATA PREPROCESSING ---------------------------------------------------------------
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
---But In august highest return quantity is recodred








     

    
    













