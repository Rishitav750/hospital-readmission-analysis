-- ============================================================
-- Hospital Readmission Analysis — Exploratory SQL
-- Dataset: Diabetes 130-US Hospitals (1999-2008), table: diabetic_data
-- Dialect: standard SQL (tested mentally against PostgreSQL / Snowflake)
-- ============================================================

-- 1. Overall scale of the dataset
SELECT
    COUNT(*)                         AS total_encounters,
    COUNT(DISTINCT patient_nbr)      AS unique_patients
FROM diabetic_data;

-- 2. Readmission label distribution (raw)
SELECT
    readmitted,
    COUNT(*)                                              AS encounters,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)    AS pct
FROM diabetic_data
GROUP BY readmitted
ORDER BY encounters DESC;

-- 3. Define the modeling target: 30-day readmission flag
--    (<30 = 1, everything else = 0)
SELECT
    CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END        AS readmit_30,
    COUNT(*)                                              AS encounters,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2)    AS pct
FROM diabetic_data
GROUP BY 1
ORDER BY 1;

-- 4. 30-day readmission rate by age band
SELECT
    age,
    COUNT(*)                                                          AS encounters,
    SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)               AS readmits_30,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
                  / COUNT(*), 2)                                      AS readmit_rate_pct
FROM diabetic_data
GROUP BY age
ORDER BY age;

-- 5. Readmission rate by number of prior inpatient visits
--    (one of the strongest predictors in the model)
SELECT
    number_inpatient,
    COUNT(*)                                                          AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
                  / COUNT(*), 2)                                      AS readmit_rate_pct
FROM diabetic_data
GROUP BY number_inpatient
ORDER BY number_inpatient;

-- 6. Readmission rate by discharge disposition (top driver group)
SELECT
    discharge_disposition_id,
    COUNT(*)                                                          AS encounters,
    ROUND(100.0 * SUM(CASE WHEN readmitted = '<30' THEN 1 ELSE 0 END)
                  / COUNT(*), 2)                                      AS readmit_rate_pct
FROM diabetic_data
GROUP BY discharge_disposition_id
HAVING COUNT(*) >= 100          -- ignore tiny, noisy buckets
ORDER BY readmit_rate_pct DESC;

-- 7. De-duplicate to first encounter per patient (avoids leakage in modeling)
--    Mirrors the cleaning step used in the Python pipeline.
WITH first_encounter AS (
    SELECT
        *,
        ROW_NUMBER() OVER (PARTITION BY patient_nbr
                           ORDER BY encounter_id) AS rn
    FROM diabetic_data
)
SELECT COUNT(*) AS first_encounter_rows
FROM first_encounter
WHERE rn = 1
  AND discharge_disposition_id NOT IN (11, 13, 14, 19, 20, 21);  -- exclude death/hospice

-- 8. Average length of stay & medication count, readmitted vs not
SELECT
    CASE WHEN readmitted = '<30' THEN 'Readmitted <30d' ELSE 'Not <30d' END AS grp,
    ROUND(AVG(time_in_hospital), 2)   AS avg_los_days,
    ROUND(AVG(num_medications), 2)    AS avg_medications,
    ROUND(AVG(number_diagnoses), 2)   AS avg_diagnoses
FROM diabetic_data
GROUP BY 1;
