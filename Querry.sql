-- =============================================
-- Create the core tables for paper metadata
-- =============================================

-- This table stores basic information about each paper

CREATE TABLE Paper_Basic_Info_Table (
    Paper_ID VARCHAR(255) PRIMARY KEY,  -- UT (Unique identifier)
    Article_Title TEXT,
    Abstract TEXT,
    Publication_Year INT,
    Journal_Name TEXT,                 -- From Source_Title
    DOI VARCHAR(255),
    WoS_Categories TEXT,
    Research_Areas TEXT,
    Author_Keywords TEXT,
    Keywords_Plus TEXT
);
-- This table contains author names and their affiliated institutions
CREATE TABLE Author_Info_Table (
    Author_Name VARCHAR(255) PRIMARY KEY,
    Affliated_institution TEXT
);
-- Author_Address_Table supports multiple addresses per author
CREATE TABLE Author_Address_Table (
    Author_Name VARCHAR(255),
    Address_Order INT,
    Address TEXT,
    PRIMARY KEY (Author_Name, Address_Order),
    FOREIGN KEY (Author_Name) REFERENCES Author_Info_Table(Author_Name)
);
-- This table links authors to papers with author order
CREATE TABLE Paper_Author_Relation_Table (
    Paper_ID VARCHAR(50),
    Author_Name VARCHAR(255),
    Author_Order INT,
    PRIMARY KEY (Paper_ID, Author_Name),
    FOREIGN KEY (Paper_ID) REFERENCES Paper_Basic_Info_Table(Paper_ID),
    FOREIGN KEY (Author_Name) REFERENCES Author_Info_Table(Author_Name)
);
-- =============================================
-- Create citation relation table from raw data
-- =============================================

-- Aggregates citations from a source table into a new citation relation table

CREATE TABLE Citation_Relation_Table AS
SELECT 
    `from` AS Citing_Paper_ID,
    `to` AS Cited_Paper_ID,
    COUNT(*) AS Citation_Count
FROM 
    cite_relationship
GROUP BY 
    `from`, `to`;
-- Add constraints and foreign keys to citation table
ALTER TABLE Citation_Relation_Table
MODIFY Citing_Paper_ID VARCHAR(50),
MODIFY Cited_Paper_ID VARCHAR(50),
ADD PRIMARY KEY (Citing_Paper_ID, Cited_Paper_ID),
ADD FOREIGN KEY (Citing_Paper_ID) REFERENCES Paper_Basic_Info_Table(Paper_ID),
ADD FOREIGN KEY (Cited_Paper_ID) REFERENCES Paper_Basic_Info_Table(Paper_ID);
-- =============================================
-- Top 5 journals by publication count per year
-- =============================================
SELECT *
FROM (
    SELECT 
        Publication_Year,
        Journal_Name,
        COUNT(*) AS Paper_Count,
        RANK() OVER (PARTITION BY Publication_Year ORDER BY COUNT(*) DESC) AS Rank_In_Year
    FROM Paper_Basic_Info_Table
    GROUP BY Publication_Year, Journal_Name
) AS RankedJournals
WHERE Rank_In_Year <= 5;
-- =============================================
-- Authors with 5 or more publications
-- =============================================
SELECT 
    Author_Name,
    COUNT(*) AS Paper_Count
FROM 
    Paper_Author_Relation_Table
GROUP BY 
    Author_Name
HAVING 
    COUNT(*) >= 5;
-- =============================================
-- Find mutually citing paper pairs (each cites the other at least twice)
-- =============================================
SELECT 
    LEAST(a.Citing_Paper_ID, a.Cited_Paper_ID) AS Paper_A,
    GREATEST(a.Citing_Paper_ID, a.Cited_Paper_ID) AS Paper_B,
    COUNT(*) AS Mutual_Citation_Count
FROM 
    Citation_Relation_Table AS a
JOIN 
    Citation_Relation_Table AS b
    ON a.Citing_Paper_ID = b.Cited_Paper_ID
   AND a.Cited_Paper_ID = b.Citing_Paper_ID
WHERE 
    a.Citing_Paper_ID <> a.Cited_Paper_ID
GROUP BY 
    LEAST(a.Citing_Paper_ID, a.Cited_Paper_ID),
    GREATEST(a.Citing_Paper_ID, a.Cited_Paper_ID)
HAVING 
    COUNT(*) >= 2;