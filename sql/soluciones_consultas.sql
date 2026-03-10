-- Soluciones de consultas (PostgreSQL)
-- Esquema esperado: FUENTE_SODA, BEBEDOR, FRECUENTA, BEBIDA, GUSTA, VENDE

-- Complejidad estimada por consulta (Big-O aproximado)
-- Notacion:
-- NB = |BEBEDOR|, NF = |FUENTE_SODA|, NFr = |FRECUENTA|,
-- NBe = |BEBIDA|, NG = |GUSTA|, NV = |VENDE|
--
-- Guia rapida para JOIN (depende del plan del optimizador):
-- - Nested Loop sin indice: O(n * m)
-- - Nested Loop con indice en tabla interna: O(n * log m) (aprox)
-- - Hash Join (promedio): O(n + m)
-- - Merge Join con entradas ordenadas: O(n + m)
-- - Merge Join con ordenamiento previo: O(n log n + m log m)
--
-- Las cotas numeradas 1..50 se listan como referencia base SIN indices,
-- por eso tienden a verse mas cercanas a producto de cardinalidades.
-- En PostgreSQL real, con PK/FK e indices, muchas consultas bajan
-- hacia comportamiento cercano a O(n + m) u O(n * log m).
-- 1:  O(NB * (NG + NBe))
-- 2:  O(NF * NFr)
-- 3:  O(NB * (NG + NFr))
-- 4:  O(NB * NBe * NG)
-- 5:  O(NB * (NG + NBe))
-- 6:  O(NB * NG^2)
-- 7:  O(NB * NFr^2)
-- 8:  O(NB + NFr)
-- 9:  O(NB * NFr^2)
-- 10: O(NFr * NV + NG)
-- 11: O(NB * NFr * NG * NV)
-- 12: O(NB * NFr * NG * NV)
-- 13: O(NB * NFr * NV * NG)
-- 14: O(NB * NFr * NV * NG)
-- 15: O(NB * NFr * NG * NV)
-- 16: O(NB * NFr * NV * NG)
-- 17: O(NB * NG * NFr * NV)
-- 18: O(NG + NBe)
-- 19: O(NFr + NG + NBe)
-- 20: O(NF * NV * NFr)
-- 21: O(NB * NBe * NG)
-- 22: O(NB * (NG + NFr))
-- 23: O(NB * (NF + NBe + NFr + NG))
-- 24: O(NBe * (NB + NF + NG + NV))
-- 25: O(NBe * (NV + NG))
-- 26: O(NV + NFr)
-- 27: O(NV + NFr + NG)
-- 28: O(NV + NFr + NG + NBe)
-- 29: O(NF + NFr + NG + NBe)
-- 30: O(NV + NFr + NBe)
-- 31: O(NV + NFr + NBe + NF)
-- 32: O(NB + NG + NFr)
-- 33: O(NBe + NV + NG)
-- 34: O(NV + NBe + NF)
-- 35: O(NV + NBe + NFr)
-- 36: O(NF * NG * NV)
-- 37: O(NV + NBe + NG + NB)
-- 38: O(NV + NG + NB)
-- 39: O(NV + NF + NBe)
-- 40: O(NBe * NG + NV)
-- 41: O(NB * NFr * NV * NG)
-- 42: O(NFr * NV * NG + NF)
-- 43: O(NB * NFr * NV * NG)
-- 44: O(NF * NFr * NV * NG)
-- 45: O(NF * NFr * NV * NG)
-- 46: O(NG + NFr + NF)
-- 47: O(NG + NBe)
-- 48: O(NG + NV + NF)
-- 49: O(NFr + NV + NG + NBe)
-- 50: O(NFr + NV + NG + NBe)

-- 1) Bebedores que no les gusta la malta.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE NOT EXISTS (
    SELECT 1
    FROM GUSTA g
    JOIN BEBIDA be ON be.CodBeb = g.CodBeb
    WHERE g.CI = b.CI
      AND be.NombreBeb = 'Malta'
);

-- 2) Las fuentes de soda que no son frecuentadas por Luis Perez.
SELECT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
WHERE NOT EXISTS (
    SELECT 1
    FROM FRECUENTA f
    WHERE f.CodFS = fs.CodFS
      AND f.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
);

-- 3) Los bebedores que les gusta al menos una bebida y que frecuentan al menos una fuente de soda.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE EXISTS (SELECT 1 FROM GUSTA g WHERE g.CI = b.CI)
  AND EXISTS (SELECT 1 FROM FRECUENTA f WHERE f.CI = b.CI);

-- 4) Para cada bebedor, las bebidas que no le gustan.
SELECT b.CI, b.Nombre, be.CodBeb, be.NombreBeb
FROM BEBEDOR b
CROSS JOIN BEBIDA be
WHERE NOT EXISTS (
    SELECT 1
    FROM GUSTA g
    WHERE g.CI = b.CI
      AND g.CodBeb = be.CodBeb
)
ORDER BY b.CI, be.CodBeb;

-- 5) Los bebedores que les gusta la malta y que no les gusta la Frescolita y la Coca-Cola.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE EXISTS (
    SELECT 1
    FROM GUSTA g
    JOIN BEBIDA be ON be.CodBeb = g.CodBeb
    WHERE g.CI = b.CI
      AND be.NombreBeb = 'Malta'
)
AND NOT EXISTS (
    SELECT 1
    FROM GUSTA g
    JOIN BEBIDA be ON be.CodBeb = g.CodBeb
    WHERE g.CI = b.CI
      AND be.NombreBeb IN ('Frescolita', 'Coca-Cola')
);

-- 6) Los bebedores que no les gusta las bebidas que le gusta a Luis Perez.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE NOT EXISTS (
    SELECT 1
    FROM GUSTA gl
    WHERE gl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
      AND EXISTS (
          SELECT 1
          FROM GUSTA g
          WHERE g.CI = b.CI
            AND g.CodBeb = gl.CodBeb
      )
);

-- 7) Los bebedores que frecuentan las fuentes de soda que frecuenta Luis Perez (todas).
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE NOT EXISTS (
    SELECT 1
    FROM FRECUENTA fl
    WHERE fl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
      AND NOT EXISTS (
          SELECT 1
          FROM FRECUENTA f
          WHERE f.CI = b.CI
            AND f.CodFS = fl.CodFS
      )
);

-- 8) Los bebedores que frecuentan algunas de las fuentes de soda que frecuenta Luis Perez.
SELECT DISTINCT b.CI, b.Nombre
FROM BEBEDOR b
JOIN FRECUENTA f ON f.CI = b.CI
WHERE f.CodFS IN (
    SELECT fl.CodFS
    FROM FRECUENTA fl
    WHERE fl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
);

-- 9) Los bebedores que frecuentan solo las fuentes de soda que frecuenta Luis Perez.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE EXISTS (SELECT 1 FROM FRECUENTA f WHERE f.CI = b.CI)
  AND NOT EXISTS (
      SELECT 1
      FROM FRECUENTA f
      WHERE f.CI = b.CI
        AND f.CodFS NOT IN (
            SELECT fl.CodFS
            FROM FRECUENTA fl
            WHERE fl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
        )
  );

-- 10) Los bebedores que frecuentan alguna fuente de soda que sirve al menos una bebida que les guste.
SELECT DISTINCT b.CI, b.Nombre
FROM BEBEDOR b
JOIN FRECUENTA f ON f.CI = b.CI
JOIN VENDE v ON v.CodFS = f.CodFS
JOIN GUSTA g ON g.CI = b.CI AND g.CodBeb = v.CodBeb;

-- 11) Los bebedores que frecuentan fuentes de soda que sirven al menos todas las bebidas que les gustan.
-- Interpretacion: existe al menos una fuente frecuentada por el bebedor que cubre todas sus bebidas gustadas.
SELECT DISTINCT b.CI, b.Nombre
FROM BEBEDOR b
JOIN FRECUENTA f ON f.CI = b.CI
WHERE NOT EXISTS (
    SELECT 1
    FROM GUSTA g
    WHERE g.CI = b.CI
      AND NOT EXISTS (
          SELECT 1
          FROM VENDE v
          WHERE v.CodFS = f.CodFS
            AND v.CodBeb = g.CodBeb
      )
);

-- 12) Los bebedores que solo frecuentan las fuentes de sodas que sirven al menos las bebidas que les gustan.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE EXISTS (SELECT 1 FROM FRECUENTA f WHERE f.CI = b.CI)
  AND NOT EXISTS (
      SELECT 1
      FROM FRECUENTA f
      WHERE f.CI = b.CI
        AND EXISTS (
            SELECT 1
            FROM GUSTA g
            WHERE g.CI = b.CI
              AND NOT EXISTS (
                  SELECT 1
                  FROM VENDE v
                  WHERE v.CodFS = f.CodFS
                    AND v.CodBeb = g.CodBeb
              )
        )
  );

-- 13) Los bebedores que unicamente frecuentan fuentes de soda que unicamente sirven algunas de las bebidas que les gustan.
-- Interpretacion: cada fuente frecuentada vende solo bebidas que al bebedor le gustan, y al menos una.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE EXISTS (SELECT 1 FROM FRECUENTA f WHERE f.CI = b.CI)
  AND NOT EXISTS (
      SELECT 1
      FROM FRECUENTA f
      WHERE f.CI = b.CI
        AND (
            EXISTS (
                SELECT 1
                FROM VENDE v
                WHERE v.CodFS = f.CodFS
                  AND NOT EXISTS (
                      SELECT 1
                      FROM GUSTA g
                      WHERE g.CI = b.CI
                        AND g.CodBeb = v.CodBeb
                  )
            )
            OR NOT EXISTS (
                SELECT 1
                FROM VENDE v
                JOIN GUSTA g ON g.CI = b.CI AND g.CodBeb = v.CodBeb
                WHERE v.CodFS = f.CodFS
            )
        )
  );

-- 14) Los bebedores que no frecuentan las fuentes de soda que sirven al menos una de las bebidas que no les gustan.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE NOT EXISTS (
    SELECT 1
    FROM FRECUENTA f
    JOIN VENDE v ON v.CodFS = f.CodFS
    WHERE f.CI = b.CI
      AND NOT EXISTS (
          SELECT 1
          FROM GUSTA g
          WHERE g.CI = b.CI
            AND g.CodBeb = v.CodBeb
      )
);

-- 15) Los bebedores que frecuentan las fuentes de soda que sirven las bebidas que le gustan a Luis Perez.
-- Interpretacion: existe una fuente frecuentada por el bebedor que sirve todas las bebidas que le gustan a Luis.
SELECT DISTINCT b.CI, b.Nombre
FROM BEBEDOR b
JOIN FRECUENTA f ON f.CI = b.CI
WHERE NOT EXISTS (
    SELECT 1
    FROM GUSTA gl
    WHERE gl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
      AND NOT EXISTS (
          SELECT 1
          FROM VENDE v
          WHERE v.CodFS = f.CodFS
            AND v.CodBeb = gl.CodBeb
      )
);

-- 16) Los bebedores a quienes les gustan las bebidas que sirven en las fuentes de soda que frecuentan.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE NOT EXISTS (
    SELECT 1
    FROM FRECUENTA f
    JOIN VENDE v ON v.CodFS = f.CodFS
    WHERE f.CI = b.CI
      AND NOT EXISTS (
          SELECT 1
          FROM GUSTA g
          WHERE g.CI = b.CI
            AND g.CodBeb = v.CodBeb
      )
);

-- 17) Los bebedores a quienes les gustan unicamente las bebidas que sirven en las fuentes de soda que frecuentan.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE NOT EXISTS (
    SELECT 1
    FROM GUSTA g
    WHERE g.CI = b.CI
      AND NOT EXISTS (
          SELECT 1
          FROM FRECUENTA f
          JOIN VENDE v ON v.CodFS = f.CodFS
          WHERE f.CI = b.CI
            AND v.CodBeb = g.CodBeb
      )
);

-- 18) Las bebidas que les gustan a las personas a quienes les gusta la malta.
SELECT DISTINCT be.CodBeb, be.NombreBeb
FROM GUSTA g
JOIN BEBIDA be ON be.CodBeb = g.CodBeb
WHERE g.CI IN (
    SELECT DISTINCT gm.CI
    FROM GUSTA gm
    JOIN BEBIDA bm ON bm.CodBeb = gm.CodBeb
    WHERE bm.NombreBeb = 'Malta'
)
ORDER BY be.CodBeb;

-- 19) Las fuentes de soda que son frecuentadas por las personas a quienes les gusta la malta.
SELECT DISTINCT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
JOIN FRECUENTA f ON f.CodFS = fs.CodFS
WHERE f.CI IN (
    SELECT DISTINCT gm.CI
    FROM GUSTA gm
    JOIN BEBIDA bm ON bm.CodBeb = gm.CodBeb
    WHERE bm.NombreBeb = 'Malta'
)
ORDER BY fs.CodFS;

-- 20) Las fuentes de soda que no venden al menos una de las bebidas que venden en las fuentes de soda frecuentadas por Luis Perez.
SELECT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
WHERE EXISTS (
    SELECT 1
    FROM VENDE vl
    WHERE vl.CodFS IN (
        SELECT fl.CodFS
        FROM FRECUENTA fl
        WHERE fl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
    )
      AND NOT EXISTS (
          SELECT 1
          FROM VENDE v
          WHERE v.CodFS = fs.CodFS
            AND v.CodBeb = vl.CodBeb
      )
);

-- 21) Los bebedores a quienes no les gustan al menos dos de las bebidas que no les gustan a Luis Perez.
WITH bebidas_no_luis AS (
    SELECT be.CodBeb
    FROM BEBIDA be
    WHERE NOT EXISTS (
        SELECT 1
        FROM GUSTA gl
        WHERE gl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
          AND gl.CodBeb = be.CodBeb
    )
)
SELECT b.CI, b.Nombre
FROM BEBEDOR b
JOIN bebidas_no_luis x ON TRUE
WHERE NOT EXISTS (
    SELECT 1
    FROM GUSTA g
    WHERE g.CI = b.CI
      AND g.CodBeb = x.CodBeb
)
GROUP BY b.CI, b.Nombre
HAVING COUNT(*) >= 2;

-- 22) Los bebedores a quienes no les gusta bebida alguna pero frecuentan al menos una fuente de soda.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE NOT EXISTS (SELECT 1 FROM GUSTA g WHERE g.CI = b.CI)
  AND EXISTS (SELECT 1 FROM FRECUENTA f WHERE f.CI = b.CI);

-- 23) Para cada bebedor, las fuentes de soda que no frecuenta y las bebidas que no les gusta.
SELECT
    b.CI,
    b.Nombre,
    ARRAY(
        SELECT fs.CodFS
        FROM FUENTE_SODA fs
        WHERE NOT EXISTS (
            SELECT 1
            FROM FRECUENTA f
            WHERE f.CI = b.CI
              AND f.CodFS = fs.CodFS
        )
        ORDER BY fs.CodFS
    ) AS fuentes_no_frecuenta,
    ARRAY(
        SELECT be.CodBeb
        FROM BEBIDA be
        WHERE NOT EXISTS (
            SELECT 1
            FROM GUSTA g
            WHERE g.CI = b.CI
              AND g.CodBeb = be.CodBeb
        )
        ORDER BY be.CodBeb
    ) AS bebidas_no_gusta
FROM BEBEDOR b
ORDER BY b.CI;

-- 24) Para cada bebida, las personas a quienes les gusta y las fuentes de soda que la sirven.
SELECT
    be.CodBeb,
    be.NombreBeb,
    ARRAY(
        SELECT b.CI
        FROM BEBEDOR b
        JOIN GUSTA g ON g.CI = b.CI
        WHERE g.CodBeb = be.CodBeb
        ORDER BY b.CI
    ) AS personas_que_gusta,
    ARRAY(
        SELECT fs.CodFS
        FROM FUENTE_SODA fs
        JOIN VENDE v ON v.CodFS = fs.CodFS
        WHERE v.CodBeb = be.CodBeb
        ORDER BY fs.CodFS
    ) AS fuentes_que_serve
FROM BEBIDA be
ORDER BY be.CodBeb;

-- 25) Las bebidas que son vendidas por al menos una fuente de soda pero que no existe persona alguna a quien le guste.
SELECT be.CodBeb, be.NombreBeb
FROM BEBIDA be
WHERE EXISTS (SELECT 1 FROM VENDE v WHERE v.CodBeb = be.CodBeb)
  AND NOT EXISTS (SELECT 1 FROM GUSTA g WHERE g.CodBeb = be.CodBeb)
ORDER BY be.CodBeb;

-- 26) Las bebidas que se venden en al menos dos de las fuentes de sodas frecuentadas por Luis Perez.
SELECT be.CodBeb, be.NombreBeb
FROM BEBIDA be
JOIN VENDE v ON v.CodBeb = be.CodBeb
WHERE v.CodFS IN (
    SELECT fl.CodFS
    FROM FRECUENTA fl
    WHERE fl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
)
GROUP BY be.CodBeb, be.NombreBeb
HAVING COUNT(DISTINCT v.CodFS) >= 2
ORDER BY be.CodBeb;

-- 27) Las bebidas que se sirven en las fuentes de soda que son frecuentadas por las personas que les gusta la malta.
SELECT DISTINCT be.CodBeb, be.NombreBeb
FROM BEBIDA be
JOIN VENDE v ON v.CodBeb = be.CodBeb
WHERE v.CodFS IN (
    SELECT DISTINCT f.CodFS
    FROM FRECUENTA f
    WHERE f.CI IN (
        SELECT gm.CI
        FROM GUSTA gm
        JOIN BEBIDA bm ON bm.CodBeb = gm.CodBeb
        WHERE bm.NombreBeb = 'Malta'
    )
)
ORDER BY be.CodBeb;

-- 28) Las bebidas que se sirven en las fuentes de soda que son frecuentadas por las personas que no les gusta la malta.
SELECT DISTINCT be.CodBeb, be.NombreBeb
FROM BEBIDA be
JOIN VENDE v ON v.CodBeb = be.CodBeb
WHERE v.CodFS IN (
    SELECT DISTINCT f.CodFS
    FROM FRECUENTA f
    WHERE f.CI IN (
        SELECT b.CI
        FROM BEBEDOR b
        WHERE NOT EXISTS (
            SELECT 1
            FROM GUSTA g
            JOIN BEBIDA be2 ON be2.CodBeb = g.CodBeb
            WHERE g.CI = b.CI
              AND be2.NombreBeb = 'Malta'
        )
    )
)
ORDER BY be.CodBeb;

-- 29) Las fuentes de soda que son frecuentadas por las personas a quienes les gusta la malta y que frecuentan "La Montana".
SELECT DISTINCT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
JOIN FRECUENTA f ON f.CodFS = fs.CodFS
WHERE f.CI IN (
    SELECT b.CI
    FROM BEBEDOR b
    WHERE EXISTS (
        SELECT 1
        FROM GUSTA g
        JOIN BEBIDA be ON be.CodBeb = g.CodBeb
        WHERE g.CI = b.CI
          AND be.NombreBeb = 'Malta'
    )
      AND EXISTS (
          SELECT 1
          FROM FRECUENTA fx
          JOIN FUENTE_SODA fsm ON fsm.CodFS = fx.CodFS
          WHERE fx.CI = b.CI
            AND fsm.NombreFS = 'La Montaña'
      )
)
ORDER BY fs.CodFS;

-- 30) La bebida mas servida entre las fuentes de soda que frecuenta Luis Perez.
WITH cte AS (
    SELECT v.CodBeb, COUNT(DISTINCT v.CodFS) AS n_fuentes
    FROM VENDE v
    WHERE v.CodFS IN (
        SELECT fl.CodFS
        FROM FRECUENTA fl
        WHERE fl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
    )
    GROUP BY v.CodBeb
), ranked AS (
    SELECT cte.*, DENSE_RANK() OVER (ORDER BY n_fuentes DESC) AS rk
    FROM cte
)
SELECT be.CodBeb, be.NombreBeb, r.n_fuentes
FROM ranked r
JOIN BEBIDA be ON be.CodBeb = r.CodBeb
WHERE r.rk = 1;

-- 31) La fuente de soda que sirve malta y es la mas frecuentada.
WITH fuentes_malta AS (
    SELECT DISTINCT v.CodFS
    FROM VENDE v
    JOIN BEBIDA be ON be.CodBeb = v.CodBeb
    WHERE be.NombreBeb = 'Malta'
), cte AS (
    SELECT fs.CodFS, fs.NombreFS, COUNT(DISTINCT f.CI) AS n_bebedores
    FROM FUENTE_SODA fs
    JOIN fuentes_malta fm ON fm.CodFS = fs.CodFS
    LEFT JOIN FRECUENTA f ON f.CodFS = fs.CodFS
    GROUP BY fs.CodFS, fs.NombreFS
), ranked AS (
    SELECT cte.*, DENSE_RANK() OVER (ORDER BY n_bebedores DESC) AS rk
    FROM cte
)
SELECT CodFS, NombreFS, n_bebedores
FROM ranked
WHERE rk = 1;

-- 32) El bebedor a quien mas bebidas le gustan y mas fuentes de soda frecuenta.
WITH cte AS (
    SELECT
        b.CI,
        b.Nombre,
        COUNT(DISTINCT g.CodBeb) AS n_bebidas_gusta,
        COUNT(DISTINCT f.CodFS) AS n_fuentes_frecuenta
    FROM BEBEDOR b
    LEFT JOIN GUSTA g ON g.CI = b.CI
    LEFT JOIN FRECUENTA f ON f.CI = b.CI
    GROUP BY b.CI, b.Nombre
), ranked AS (
    SELECT cte.*, DENSE_RANK() OVER (ORDER BY n_bebidas_gusta DESC, n_fuentes_frecuenta DESC) AS rk
    FROM cte
)
SELECT CI, Nombre, n_bebidas_gusta, n_fuentes_frecuenta
FROM ranked
WHERE rk = 1;

-- 33) Para cada bebida, numero de fuentes de soda que la sirven y numero de personas a quien le gustan.
SELECT
    be.CodBeb,
    be.NombreBeb,
    COUNT(DISTINCT v.CodFS) AS n_fuentes_que_serve,
    COUNT(DISTINCT g.CI) AS n_personas_que_gusta
FROM BEBIDA be
LEFT JOIN VENDE v ON v.CodBeb = be.CodBeb
LEFT JOIN GUSTA g ON g.CodBeb = be.CodBeb
GROUP BY be.CodBeb, be.NombreBeb
ORDER BY be.CodBeb;

-- 34) Las fuentes de soda que venden a menor precio la malta.
WITH precios AS (
    SELECT v.CodFS, v.precio
    FROM VENDE v
    JOIN BEBIDA be ON be.CodBeb = v.CodBeb
    WHERE be.NombreBeb = 'Malta'
), m AS (
    SELECT MIN(precio) AS min_precio
    FROM precios
)
SELECT fs.CodFS, fs.NombreFS, p.precio
FROM precios p
JOIN m ON p.precio = m.min_precio
JOIN FUENTE_SODA fs ON fs.CodFS = p.CodFS;

-- 35) El precio promedio de venta de la malta en las fuentes de soda frecuentadas por Luis Perez.
SELECT AVG(v.precio)::numeric(10,2) AS promedio_malta
FROM VENDE v
JOIN BEBIDA be ON be.CodBeb = v.CodBeb
WHERE be.NombreBeb = 'Malta'
  AND v.CodFS IN (
      SELECT fl.CodFS
      FROM FRECUENTA fl
      WHERE fl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
  );

-- 36) La bebida mas cara en las fuentes de soda que no venden al menos una de las bebidas que le gusta a Luis Perez.
WITH fuentes_objetivo AS (
    SELECT fs.CodFS
    FROM FUENTE_SODA fs
    WHERE EXISTS (
        SELECT 1
        FROM GUSTA gl
        WHERE gl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
          AND NOT EXISTS (
              SELECT 1
              FROM VENDE v2
              WHERE v2.CodFS = fs.CodFS
                AND v2.CodBeb = gl.CodBeb
          )
    )
), ranked AS (
    SELECT
        v.CodBeb,
        v.precio,
        DENSE_RANK() OVER (ORDER BY v.precio DESC) AS rk
    FROM VENDE v
    JOIN fuentes_objetivo fo ON fo.CodFS = v.CodFS
)
SELECT DISTINCT be.CodBeb, be.NombreBeb, r.precio
FROM ranked r
JOIN BEBIDA be ON be.CodBeb = r.CodBeb
WHERE r.rk = 1;

-- 37) Los bebedores a quienes les gusta la bebida mas cara vendida por las fuentes de soda que venden malta.
WITH fuentes_malta AS (
    SELECT DISTINCT v.CodFS
    FROM VENDE v
    JOIN BEBIDA be ON be.CodBeb = v.CodBeb
    WHERE be.NombreBeb = 'Malta'
), ranked AS (
    SELECT
        v.CodBeb,
        v.precio,
        DENSE_RANK() OVER (ORDER BY v.precio DESC) AS rk
    FROM VENDE v
    JOIN fuentes_malta fm ON fm.CodFS = v.CodFS
), bebidas_top AS (
    SELECT DISTINCT CodBeb
    FROM ranked
    WHERE rk = 1
)
SELECT DISTINCT b.CI, b.Nombre
FROM BEBEDOR b
JOIN GUSTA g ON g.CI = b.CI
JOIN bebidas_top bt ON bt.CodBeb = g.CodBeb;

-- 38) Las fuentes de soda que venden las bebidas que no le gustan a Luis Perez y que le gustan Jose Perez.
-- Nota: se asume el nombre literal 'Jose Perez' segun el enunciado.
SELECT DISTINCT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
JOIN VENDE v ON v.CodFS = fs.CodFS
WHERE v.CodBeb IN (
    SELECT g2.CodBeb
    FROM GUSTA g2
    WHERE g2.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Jose Perez')
      AND g2.CodBeb NOT IN (
          SELECT gl.CodBeb
          FROM GUSTA gl
          WHERE gl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
      )
);

-- 39) El precio promedio de venta de cada bebida en cada fuente de soda que la vende.
SELECT v.CodFS, fs.NombreFS, v.CodBeb, be.NombreBeb, AVG(v.precio)::numeric(10,2) AS precio_promedio
FROM VENDE v
JOIN FUENTE_SODA fs ON fs.CodFS = v.CodFS
JOIN BEBIDA be ON be.CodBeb = v.CodBeb
GROUP BY v.CodFS, fs.NombreFS, v.CodBeb, be.NombreBeb
ORDER BY v.CodFS, v.CodBeb;

-- 40) El precio promedio de venta de las bebidas que no le gustan a Luis Perez.
WITH bebidas_no_luis AS (
    SELECT be.CodBeb
    FROM BEBIDA be
    WHERE NOT EXISTS (
        SELECT 1
        FROM GUSTA gl
        WHERE gl.CI IN (SELECT CI FROM BEBEDOR WHERE Nombre = 'Luis Perez')
          AND gl.CodBeb = be.CodBeb
    )
)
SELECT AVG(v.precio)::numeric(10,2) AS precio_promedio
FROM VENDE v
JOIN bebidas_no_luis bnl ON bnl.CodBeb = v.CodBeb;

-- 41) Los bebedores que frecuentan al menos 3 fuentes de soda que sirven alguna bebida que les gusta.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
JOIN FRECUENTA f ON f.CI = b.CI
WHERE EXISTS (
    SELECT 1
    FROM VENDE v
    JOIN GUSTA g ON g.CI = b.CI AND g.CodBeb = v.CodBeb
    WHERE v.CodFS = f.CodFS
)
GROUP BY b.CI, b.Nombre
HAVING COUNT(DISTINCT f.CodFS) >= 3;

-- 42) Las fuentes de soda que son frecuentadas por al menos dos bebedores que le gustan al menos 3 de las bebidas que sirven.
WITH bebedor_fuente_ok AS (
    SELECT f.CI, f.CodFS
    FROM FRECUENTA f
    JOIN VENDE v ON v.CodFS = f.CodFS
    JOIN GUSTA g ON g.CI = f.CI AND g.CodBeb = v.CodBeb
    GROUP BY f.CI, f.CodFS
    HAVING COUNT(DISTINCT g.CodBeb) >= 3
)
SELECT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
JOIN bebedor_fuente_ok x ON x.CodFS = fs.CodFS
GROUP BY fs.CodFS, fs.NombreFS
HAVING COUNT(DISTINCT x.CI) >= 2;

-- 43) Los bebedores que no frecuentan fuentes de sodas que sirven al menos una bebida que les gusta.
SELECT b.CI, b.Nombre
FROM BEBEDOR b
WHERE NOT EXISTS (
    SELECT 1
    FROM FRECUENTA f
    JOIN VENDE v ON v.CodFS = f.CodFS
    JOIN GUSTA g ON g.CI = b.CI AND g.CodBeb = v.CodBeb
    WHERE f.CI = b.CI
);

-- 44) Las fuentes de soda que no sirven bebidas que no le gustan a al menos uno de los bebedores que la frecuentan.
SELECT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
WHERE NOT EXISTS (
    SELECT 1
    FROM FRECUENTA f
    JOIN VENDE v ON v.CodFS = f.CodFS
    WHERE f.CodFS = fs.CodFS
      AND NOT EXISTS (
          SELECT 1
          FROM GUSTA g
          WHERE g.CI = f.CI
            AND g.CodBeb = v.CodBeb
      )
);

-- 45) Las fuentes de soda que son frecuentadas solo por bebedores que no les gustan al menos una de las bebidas que estos sirven.
SELECT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
WHERE EXISTS (SELECT 1 FROM FRECUENTA f WHERE f.CodFS = fs.CodFS)
  AND NOT EXISTS (
      SELECT 1
      FROM FRECUENTA f
      WHERE f.CodFS = fs.CodFS
        AND NOT EXISTS (
            SELECT 1
            FROM VENDE v
            WHERE v.CodFS = fs.CodFS
              AND NOT EXISTS (
                  SELECT 1
                  FROM GUSTA g
                  WHERE g.CI = f.CI
                    AND g.CodBeb = v.CodBeb
              )
        )
  );

-- 46) Las fuentes de soda que son frecuentadas por el (los) bebedores que le(s) gustan el mayor numero de bebidas.
WITH top_bebedores AS (
    SELECT g.CI
    FROM GUSTA g
    GROUP BY g.CI
    HAVING COUNT(*) = (
        SELECT MAX(cnt)
        FROM (
            SELECT COUNT(*) AS cnt
            FROM GUSTA
            GROUP BY CI
        ) x
    )
)
SELECT DISTINCT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
JOIN FRECUENTA f ON f.CodFS = fs.CodFS
JOIN top_bebedores tb ON tb.CI = f.CI;

-- 47) La(s) bebida(s) que mas gusta(n).
WITH cte AS (
    SELECT g.CodBeb, COUNT(*) AS n_gusta
    FROM GUSTA g
    GROUP BY g.CodBeb
), ranked AS (
    SELECT cte.*, DENSE_RANK() OVER (ORDER BY n_gusta DESC) AS rk
    FROM cte
)
SELECT be.CodBeb, be.NombreBeb, r.n_gusta
FROM ranked r
JOIN BEBIDA be ON be.CodBeb = r.CodBeb
WHERE r.rk = 1;

-- 48) Las fuentes de soda que sirven la(s) bebida(s) que mas gusta(n).
WITH top_bebidas AS (
    SELECT g.CodBeb
    FROM GUSTA g
    GROUP BY g.CodBeb
    HAVING COUNT(*) = (
        SELECT MAX(cnt)
        FROM (
            SELECT COUNT(*) AS cnt
            FROM GUSTA
            GROUP BY CodBeb
        ) x
    )
)
SELECT DISTINCT fs.CodFS, fs.NombreFS
FROM FUENTE_SODA fs
JOIN VENDE v ON v.CodFS = fs.CodFS
JOIN top_bebidas tb ON tb.CodBeb = v.CodBeb;

-- 49) Las bebidas que son vendidas por la(s) fuente(s) de soda mas frecuentadas y que le(s) gusta(n) a los bebedor(es) que mas le(s) gustan bebidas.
WITH top_fuentes AS (
    SELECT f.CodFS
    FROM FRECUENTA f
    GROUP BY f.CodFS
    HAVING COUNT(*) = (
        SELECT MAX(cnt)
        FROM (
            SELECT COUNT(*) AS cnt
            FROM FRECUENTA
            GROUP BY CodFS
        ) x
    )
), top_bebedores AS (
    SELECT g.CI
    FROM GUSTA g
    GROUP BY g.CI
    HAVING COUNT(*) = (
        SELECT MAX(cnt)
        FROM (
            SELECT COUNT(*) AS cnt
            FROM GUSTA
            GROUP BY CI
        ) x
    )
)
SELECT DISTINCT be.CodBeb, be.NombreBeb
FROM BEBIDA be
WHERE be.CodBeb IN (
    SELECT v.CodBeb
    FROM VENDE v
    JOIN top_fuentes tf ON tf.CodFS = v.CodFS
)
AND be.CodBeb IN (
    SELECT g.CodBeb
    FROM GUSTA g
    JOIN top_bebedores tb ON tb.CI = g.CI
)
ORDER BY be.CodBeb;

-- 50) Las bebidas que son servidas en las fuentes de soda mas frecuentadas y que le gustan al menor numero de bebedores.
WITH top_fuentes AS (
    SELECT f.CodFS
    FROM FRECUENTA f
    GROUP BY f.CodFS
    HAVING COUNT(*) = (
        SELECT MAX(cnt)
        FROM (
            SELECT COUNT(*) AS cnt
            FROM FRECUENTA
            GROUP BY CodFS
        ) x
    )
), bebidas_en_top_fuentes AS (
    SELECT DISTINCT v.CodBeb
    FROM VENDE v
    JOIN top_fuentes tf ON tf.CodFS = v.CodFS
), conteo_gustos AS (
    SELECT btf.CodBeb, COUNT(g.CI) AS n_gusta
    FROM bebidas_en_top_fuentes btf
    LEFT JOIN GUSTA g ON g.CodBeb = btf.CodBeb
    GROUP BY btf.CodBeb
), ranked AS (
    SELECT cg.*, DENSE_RANK() OVER (ORDER BY n_gusta ASC) AS rk
    FROM conteo_gustos cg
)
SELECT be.CodBeb, be.NombreBeb, r.n_gusta
FROM ranked r
JOIN BEBIDA be ON be.CodBeb = r.CodBeb
WHERE r.rk = 1;
