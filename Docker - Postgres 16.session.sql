SELECT salary , 

    Row_number() OVER(ORDER BY salary DESC) as rn,
    RANK()       OVER(ORDER BY salary DESC) as RNK,
    DENSE_RANK() OVER(ORDER BY salary DESC) as DRNK
FROM (VALUES(100), (100), (90), (80), (80), (70)) AS t(salary);
