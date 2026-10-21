SELECT 'customers' AS table_name, count(*) AS rows FROM lab.customers
UNION ALL SELECT 'products', count(*) FROM lab.products
UNION ALL SELECT 'orders', count(*) FROM lab.orders
UNION ALL SELECT 'order_items', count(*) FROM lab.order_items
UNION ALL SELECT 'events', count(*) FROM lab.events
UNION ALL SELECT 'events_1', count(*) FROM lab.events_1
UNION ALL SELECT 'events_2', count(*) FROM lab.events_2
UNION ALL SELECT 'measurements', count(*) FROM lab.measurements
UNION ALL SELECT 'measurements_1', count(*) FROM lab.measurements_1
UNION ALL SELECT 'measurements_2', count(*) FROM lab.measurements_2
UNION ALL SELECT 'documents', count(*) FROM lab.documents
UNION ALL SELECT 'type_playground', count(*) FROM lab.type_playground
ORDER BY table_name;
