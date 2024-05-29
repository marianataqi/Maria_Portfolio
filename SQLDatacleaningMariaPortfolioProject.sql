/*

Cleaning Data in SQL Queries

*/


Select *
From Maria.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------

-- Standardize Date Format


Select saleDate Converted, CONVERT(Date,SaleDate)
From Maria.dbo.NashvilleHousing


Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

-- If it doesn't Update properly

ALTER TABLE NashvilleHousing
Add SaleDateConverted Date;

Update NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)


 --------------------------------------------------------------------------------------------------------------------------

-- Populate Property Address data
-- First of all we have some null data in this column and we need to solve this 
-- we will check address from each ID that somewhere is null
Select *
From Maria.dbo.NashvilleHousing
Where PropertyAddress is null
order by ParcelID



Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress
From Maria.dbo.NashvilleHousing a
JOIN Maria.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From Maria.dbo.NashvilleHousing a
JOIN Maria.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null

--Now we Replace all Nulls with propper data

Update a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From Maria.dbo.NashvilleHousing a
JOIN Maria.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null

--After replacing null data we can check for sure if there is any null
Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
From Maria.dbo.NashvilleHousing a
JOIN Maria.dbo.NashvilleHousing b
	on a.ParcelID = b.ParcelID
	AND a.UniqueID <> b.UniqueID
Where a.PropertyAddress is null

-- Now as you can see all null replaced with acurate data
--------------------------------------------------------------------------------------------------------------------------

-- Breaking out Address into Individual Columns (Address, City, State)


Select PropertyAddress
From Maria.dbo.NashvilleHousing
Where PropertyAddress is null
--order by ParcelID
-- as you can see we have no null data any more in this column

Select distinct PropertyAddress
From Maria.dbo.NashvilleHousing

--order by ParcelID


--We have 45068 unique address
--Now we need to seperate city and address in Propertyaddress column;
SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)  ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) , LEN(PropertyAddress)) as Address

From Maria.dbo.NashvilleHousing

--we need to get rid of "," so we add "-1" in substring to have propper 2 column

SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address

From Maria.dbo.NashvilleHousing

-- we are about to create  columns with new values that we targeted
ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

select * from Maria.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))




Select *
From Maria.dbo.NashvilleHousing



--as you can see we used PARSENAME and REPLACE functions to : 
--REPLACE(OwnerAddress, ',', '.'): This function replaces commas (,) in the OwnerAddress column with dots (.).
--PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3): This function extracts the third part of the address after replacing
--commas with dots. In SQL Server, PARSENAME is typically used to parse object names in four-part naming convention,
--but here it's repurposed to parse parts of the address after replacing commas with dots. It's a bit of a hack,
--but can work depending on the structure of the addresses.

Select OwnerAddress
From Maria.dbo.NashvilleHousing


Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From Maria.dbo.NashvilleHousing

--So, as you can see,we splited the OwnerAddress column into its individual parts

ALTER TABLE NashvilleHousing
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)



Select *
From Maria.dbo.NashvilleHousing




--------------------------------------------------------------------------------------------------------------------------


--First of all we will change Y and N to Yes and No in "Sold as Vacant" field


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From Maria.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2




Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END
From Maria.dbo.NashvilleHousing


Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
	   When SoldAsVacant = 'N' THEN 'No'
	   ELSE SoldAsVacant
	   END






-----------------------------------------------------------------------------------------------------------------------------------------------------------

-- Remove Duplicates
--1. ROW_NUMBER() OVER (...) row_num: This is the main part of the query. It assigns a row number to
--   each row based on the specified partitioning and ordering.
--2. PARTITION BY ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference:
--   This defines the partitioning of the data. It means that the ROW_NUMBER() function
--   will restart numbering from 1 for each unique combination of values in the specified 
--   columns (ParcelId, PropertyAddress, SalePrice, SaleDate, LegalReference).
--3. ORDER BY UniqueId: This specifies the ordering of rows within each partition.
--   Rows will be ordered by the UniqueId column.

select *,
   ROW_NUMBER() over(
   Partition By ParcelId,
                PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				order by
				  UniqueId
				  ) row_num
from Maria.dbo.NashvilleHousing

-- we will use CTE and windows functions to reach this target!! ( I need to fix this code!)
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Maria.dbo.NashvilleHousing
--order by ParcelID



Select *
From RowNumCTE
Where row_num = 1
--Order by PropertyAddress
-----------------------------------------------------------
WITH RowNumCTE AS (
    SELECT *,
        ROW_NUMBER() OVER (
            PARTITION BYParcelID,
				      PropertyAddress,
				      SalePrice,
				      SaleDate,
				      LegalReference
            ORDER BY UniqueID
        ) AS row_num
    FROM Maria.dbo.NashvilleHousing
)

SELECT *
FROM RowNumCTE
WHERE row_num = 1 -- Keep only rows with row_num = 1 to remove duplicates




Select *
From Maria.dbo.NashvilleHousing




---------------------------------------------------------------------------------------------------------

-- Delete Unused Columns



Select *
From Maria.dbo.NashvilleHousing


ALTER TABLE Maria.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate




---Now you can have this clean data
Select *
From Maria.dbo.NashvilleHousing









-----------------------------------------------------------------------------------------------
-----------------------------------------------------------------------------------------------

--- Importing Data using OPENROWSET and BULK INSERT	

--  More advanced and looks cooler, but have to configure server appropriately to do correctly
--  Wanted to provide this in case you wanted to try it


--sp_configure 'show advanced options', 1;
--RECONFIGURE;
--GO
--sp_configure 'Ad Hoc Distributed Queries', 1;
--RECONFIGURE;
--GO


--USE PortfolioProject 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'AllowInProcess', 1 

--GO 

--EXEC master.dbo.sp_MSset_oledb_prop N'Microsoft.ACE.OLEDB.12.0', N'DynamicParameters', 1 

--GO 


---- Using BULK INSERT

--USE PortfolioProject;
--GO
--BULK INSERT nashvilleHousing FROM 'C:\Temp\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv'
--   WITH (
--      FIELDTERMINATOR = ',',
--      ROWTERMINATOR = '\n'
--);
--GO


---- Using OPENROWSET
--USE PortfolioProject;
--GO
--SELECT * INTO nashvilleHousing
--FROM OPENROWSET('Microsoft.ACE.OLEDB.12.0',
--    'Excel 12.0; Database=C:\Users\alexf\OneDrive\Documents\SQL Server Management Studio\Nashville Housing Data for Data Cleaning Project.csv', [Sheet1$]);
--GO
