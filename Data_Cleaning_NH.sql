/*

CLEANING DATA USING MYSQL
Andrew Gomez Martinez

*/



/* STANDARDIZING DATE FORMAT */

-- Adding new column
ALTER TABLE NashHousing
ADD SaleDateConverted Date;

-- Inserting converted dates into column
UPDATE nashhousing
SET SaleDateConverted = STR_TO_DATE(SaleDate, '%M %d,%Y');



/* POPULLATING PROPERY ADDRESS WHERE THERE ARE NONE */

-- Using Inner Join where ParcelID matches
UPDATE nashhousing AS a
JOIN nashhousing AS b
	ON a.ParcelID = b.ParcelID
    AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.propertyaddress,b.propertyaddress)
WHERE a.PropertyAddress IS NULL;



/* BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (Street, City, State) */

-- Using SUBSTRING() & LOCATE()
-- Street
ALTER TABLE nashhousing
Add PropertySplitStreet varchar(255);
UPDATE nashhousing
SET PropertySplitStreet = substring(Propertyaddress, 1, locate(',', PropertyAddress) - 1);

-- City
ALTER TABLE nashhousing
Add PropertySplitCity varchar(255);
UPDATE nashhousing
SET PropertySplitCity = substring(propertyaddress, locate(',', PropertyAddress) + 1);

-- PropertyAddress contains no state


-- Using SUBSTRING_INDEX() & LTRIM() for OwnerAddress
-- Street
ALTER TABLE nashhousing
ADD OwnerSplitStreet varchar(255);
UPDATE nashhousing
SET OwnerSplitStreet = substring_index(owneraddress, ',', 1);

-- City
ALTER TABLE nashhousing
ADD OwnerSplitCity varchar(255);
UPDATE nashhousing
SET OwnerSplitCity = LTRIM(SUBSTRING_INDEX(substring_index(owneraddress, ',', 2), ',', -1));

-- State
ALTER TABLE nashhousing
ADD OwnerSplitState varchar(255);
UPDATE nashhousing
SET OwnerSplitState = LTRIM(substring_index(owneraddress, ',', -1));



/* CHANGING Y AND N TO YES AND NO IN "SOLD AS VACANT" FIELD */

UPDATE NashHousing
SET SoldAsVacant = 
	CASE
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
        WHEN SoldAsVacant = 'N' THEN 'No'
        Else SoldAsVacant
	END;
        
        
/* REMOVE DUPLICATES */
-- Note: Normally I don't delete data that's in a database.

-- Using ROW_NUMBER() to delete data
DELETE FROM NashHousing
WHERE UniqueID in (
	SELECT UniqueID
	FROM (
		SELECT UniqueID,
			ROW_NUMBER() OVER (
				PARTITION BY ParcelID, PropertyAddress, SalePrice, SaleDate, LegalReference
				ORDER BY UniqueID
				) AS row_num
		FROM NashHousing
		) AS r
	WHERE row_num > 1
);



/* DELETING UNUSED COLUMNS */

-- Dropping not needed columns
ALTER TABLE NashHousing
	DROP OwnerAddress,
    DROP TaxDistrict,
    DROP PropertyAddress,
    DROP SaleDate;



/* END */