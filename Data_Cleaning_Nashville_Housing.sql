/*

Cleaning Data in SQL Queries

*/

------------------------------------------------------

-- Standardize Date Format

UPDATE nashville_housing.housing_data 
SET saledate = TO_DATE(saledate, 'Month DD, YYYY');

ALTER TABLE nashville_housing.housing_data 
ALTER COLUMN saledate SET DATA TYPE date
USING TO_DATE(saledate, 'YYYY-MM-DD');


------------------------------------------------------

-- Populate Property Adress Data

UPDATE nashville_housing.housing_data AS c
SET propertyaddress = b.propertyaddress 
FROM nashville_housing.housing_data AS a
JOIN nashville_housing.housing_data AS b
ON a.parcelid = b.parcelid
AND a.uniqueid <> b.uniqueid
WHERE c.propertyaddress IS NULL AND c.uniqueid = a.uniqueid;


------------------------------------------------------

-- Breaking out address into individual columns (Address, City, State)

ALTER TABLE nashville_housing.housing_data
ADD COLUMN address TEXT, 
ADD COLUMN city TEXT;

UPDATE nashville_housing.housing_data
SET address = (SELECT SUBSTRING(propertyaddress, 1, POSITION(',' IN propertyaddress) - 1) AS address),
	city = (SELECT SUBSTRING(propertyaddress, (POSITION(',' IN propertyaddress)+2), LENGTH(propertyaddress)) AS city)

ALTER TABLE nashville_housing.housing_data
RENAME COLUMN city TO propertycity;

ALTER TABLE nashville_housing.housing_data
RENAME COLUMN address TO propertysplitaddress;


------------------------------------------------------
-- Do the same for owner address

ALTER TABLE nashville_housing.housing_data
ADD COLUMN owner_street TEXT,
ADD COLUMN owner_city TEXT,
ADD COLUMN owner_state TEXT;

UPDATE nashville_housing.housing_data
SET owner_street = (SELECT SUBSTRING(owneraddress, 1, POSITION(',' IN owneraddress)-1));

UPDATE nashville_housing.housing_data
SET owner_city = (SELECT SUBSTRING(owneraddress, POSITION(',' IN owneraddress)+2));

UPDATE nashville_housing.housing_data
SET owner_state = (SELECT SUBSTRING(owner_city, POSITION(',' IN owner_city)+2));

UPDATE nashville_housing.housing_data
SET owner_city = (SELECT SUBSTRING(owner_city, 1, POSITION(',' IN owner_city)-1));


------------------------------------------------------

-- Change Y and N to Yes and No in 'Sold as vacant' field

SELECT DISTINCT(soldasvacant), COUNT(soldasvacant)
FROM nashville_housing.housing_data
GROUP BY soldasvacant;

UPDATE nashville_housing.housing_data
SET soldasvacant = (CASE WHEN soldasvacant='N' THEN 'No'
	WHEN soldasvacant='Y' THEN 'Yes'
	ELSE soldasvacant
	END)


------------------------------------------------------

-- Remove Duplicates

WITH rownumCTE AS(
SELECT *, ROW_NUMBER() OVER (PARTITION BY parcelid, propertyaddress, saleprice, saledate, legalreference ORDER BY uniqueid) AS row_num
FROM nashville_housing.housing_data
)

DELETE FROM nashville_housing.housing_data AS n
WHERE n.uniqueid IN (SELECT uniqueid FROM rownumCTE WHERE row_num <> 1);


------------------------------------------------------

-- Delete unused columns
ALTER TABLE nashville_housing.housing_data
DROP COLUMN owneraddress, 
DROP COLUMN taxdistrict,
DROP COLUMN propertyaddress;




