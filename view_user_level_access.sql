--- Creating temporary table for permissions list --- 
SELECT entity_class,  
      NAME AS entity_name,  
      subentity_name,  
      permission_name  
INTO   #permsummary  
FROM   ( 
--- Collecting object-level permissions --- 
SELECT 'OBJECT' AS entity_class,  
              NAME,  
              subentity_name,  
              permission_name  
       FROM   sys.objects  
              CROSS apply Fn_my_permissions(Quotename(NAME), 'OBJECT') a  
       UNION ALL 
--- Collecting database-level permissions ---  
       SELECT 'DATABASE' AS entity_class,  
              NAME,  
              subentity_name,  
              permission_name  
       FROM   sys.databases  
              CROSS apply Fn_my_permissions(Quotename(NAME), 'DATABASE') a  
       UNION ALL 
--- Collecting server-level permissions ---  
       SELECT 'SERVER'     AS entity_class,  
              @@SERVERNAME AS NAME,  
              subentity_name,  
              permission_name  
       FROM   Fn_my_permissions(NULL, 'SERVER')) p  
--- Grouping all effective permissions for single object --- 
SELECT DISTINCT entity_class,  
               entity_name,  
               subentity_name,  
               permissions  
FROM   (SELECT *  
       FROM   #permsummary) p1  
      CROSS APPLY (SELECT permission_name + ', '  
                   FROM   (SELECT *  
                           FROM   #permsummary) p2  
                   WHERE  p2.entity_class = p1.entity_class  
                          AND p2.entity_name = p1.entity_name  
                          AND p2.subentity_name = p1.subentity_name  
                   ORDER  BY entity_class  
                   FOR xml path('')) D ( permissions )  
--- Delete temporary table --- 
DROP TABLE #permsummary
