SELECT Top (1000) *
From PorfoilioProject.dbo.NashvilleHousing
Order by 1

--------------------------------------------------------------
/*Standardize the Date format*/
--create a new col for the converted date because I cant update the table
ALTER TABLE PorfoilioProject.dbo.NashvilleHousing
Add SaleDateConverted Date;
Update PorfoilioProject.dbo.NashvilleHousing
SET SaleDateConverted = Convert(date,SaleDate)

--Check the result
SELECT SaleDateConverted, Convert(date,SaleDateConverted) as ProperDate
From PorfoilioProject.dbo.NashvilleHousing
--------------------------------------------------------------
/*Populate Property Adress data*/
--There are some Null value in the Address col, while the ParcelID has duplicate value
-- check if the ParcelID of the Null Address has address 
SELECT NH1.ParcelID,NH1.PropertyAddress,NH2.ParcelID,NH2.PropertyAddress
From PorfoilioProject.dbo.NashvilleHousing as NH1
JOIN PorfoilioProject.dbo.NashvilleHousing as NH2
	ON NH1.ParcelID = NH2.ParcelID
	And NH1.[UniqueID ]<>NH2.[UniqueID ]
WHERE NH1.PropertyAddress is Null -- they do have ^^

--inserting the address from the same ParcelID that has to those that didnt
Update NH1
SET PropertyAddress = ISNULL(NH1.PropertyAddress,NH2.PropertyAddress)
From PorfoilioProject.dbo.NashvilleHousing as NH1
JOIN PorfoilioProject.dbo.NashvilleHousing as NH2
	ON NH1.ParcelID = NH2.ParcelID
	And NH1.[UniqueID ]<>NH2.[UniqueID ]
WHERE NH1.PropertyAddress is Null

--check the result
SELECT *
From PorfoilioProject.dbo.NashvilleHousing
Where PropertyAddress is null
 /*if there're still some nulls, can replace it with No Address
Update PorfoilioProject.dbo.NashvilleHousing
	SET PropertyAddress = ISNULL(PropertyAddress,'No Address')
WHERE PropertyAddress is Null
*/
-- try the same method with the other cols but it doesnt work, didnt have the data like Address
SELECT *
From PorfoilioProject.dbo.NashvilleHousing
Where OwnerName is null

SELECT NH1.ParcelID,NH1.OwnerName,NH2.ParcelID,NH2.OwnerName
From PorfoilioProject.dbo.NashvilleHousing as NH1
JOIN PorfoilioProject.dbo.NashvilleHousing as NH2
	ON NH1.ParcelID = NH2.ParcelID
	And NH1.[UniqueID ]<>NH2.[UniqueID ]
WHERE NH1.OwnerName is Null
--------------------------------------------------------------
/*Breaking out Address in to Individual Cols (Address, City, State)*/
--Try to extract the data
Select 
	SUBSTRING(PropertyAddress,1,CHARINDEX(' ',PropertyAddress)-1) AS HouseNum,
	SUBSTRING(PropertyAddress,CHARINDEX(' ',PropertyAddress)+1, CHARINDEX(',',PropertyAddress)-1) as StName,
	SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)) as City
From PorfoilioProject.dbo.NashvilleHousing

--add new cols to the table
ALTER TABLE PorfoilioProject.dbo.NashvilleHousing Add 
	PropertySliptedAddress Nvarchar(255),
	PropertySliptedCity Nvarchar(255);

Update PorfoilioProject.dbo.NashvilleHousing
SET PropertySliptedAddress = SUBSTRING(PropertyAddress,1,CHARINDEX(',',PropertyAddress)-1),
	PropertySliptedCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))


--check the result
--crack on the OwnerAddress. 
--I already check the extracting code, and it works perfectly, then, just move on to adding new data
ALTER TABLE PorfoilioProject.dbo.NashvilleHousing Add 
	OwnerSt Nvarchar(255),
	OwnerCity Nvarchar(255),
	OwnerState Nvarchar(255);

Update PorfoilioProject.dbo.NashvilleHousing
SET OwnerSt = PARSENAME(REPLACE(OwnerAddress,',','.'),3),
	OwnerCity = PARSENAME(REPLACE(OwnerAddress,',','.'),2),
	OwnerState = PARSENAME(REPLACE(OwnerAddress,',','.'),1)
--check the result
--------------------------------------------------------------
/*Change Y and N to Yes and No in "Sold as Vacant" field*/
--take a look at the situation of this col
SELECT Distinct(SoldAsVacant), COUNT(SoldAsVacant)
From PorfoilioProject.dbo.NashvilleHousing
Group by SoldAsVacant
Order by 2

--check the code use for replacing the data
Select SoldAsVacant,
	CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END as ProperSaV
From PorfoilioProject.dbo.NashvilleHousing
WHERE SoldAsVacant in ('Y','N')

--update the table
UPDATE PorfoilioProject.dbo.NashvilleHousing
	SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
		When SoldAsVacant = 'N' THEN 'No'
		ELSE SoldAsVacant
		END
--check the result
--------------------------------------------------------------
/*Remove Duplicates*/
--do this in a temp table. or CTE, not the database
-- find the duplicate, the row_num value of the duplicate will be greater than 1
Select *,
	ROW_NUMBER () OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference 
	ORDER BY UniqueID) as Row_num
From PorfoilioProject.dbo.NashvilleHousing
ORDER BY Row_num DESC

--delete the duplicate in CTE
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER () OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID) as row_num
From PorfoilioProject.dbo.NashvilleHousing
)
DELETE
From RowNumCTE
Where row_num > 1

--check the result
WITH RowNumCTE AS(
Select *,
	ROW_NUMBER () OVER (
	PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
	ORDER BY UniqueID) as row_num
From PorfoilioProject.dbo.NashvilleHousing
)
Select*
From RowNumCTE
Where row_num > 1
Order by 4
--------------------------------------------------------------
/*Delete unused cols*/
ALTER TABLE PorfoilioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict,PropertyAddress,DateSale

--------------------------------------------------------------
--------------------------------------------------------------
