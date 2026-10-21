DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'orders_customer_fk') THEN
    ALTER TABLE lab.orders
      ADD CONSTRAINT orders_customer_fk FOREIGN KEY (customer_id)
      REFERENCES lab.customers (customer_id) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'order_items_order_fk') THEN
    ALTER TABLE lab.order_items
      ADD CONSTRAINT order_items_order_fk FOREIGN KEY (order_id)
      REFERENCES lab.orders (order_id) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'order_items_product_fk') THEN
    ALTER TABLE lab.order_items
      ADD CONSTRAINT order_items_product_fk FOREIGN KEY (product_id)
      REFERENCES lab.products (product_id) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'events_customer_fk') THEN
    ALTER TABLE lab.events
      ADD CONSTRAINT events_customer_fk FOREIGN KEY (customer_id)
      REFERENCES lab.customers (customer_id) NOT VALID;
  END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'measurements_customer_fk') THEN
    ALTER TABLE lab.measurements
      ADD CONSTRAINT measurements_customer_fk FOREIGN KEY (customer_id)
      REFERENCES lab.customers (customer_id) NOT VALID;
  END IF;
END
$$;

ALTER TABLE lab.orders VALIDATE CONSTRAINT orders_customer_fk;
ALTER TABLE lab.order_items VALIDATE CONSTRAINT order_items_order_fk;
ALTER TABLE lab.order_items VALIDATE CONSTRAINT order_items_product_fk;
ALTER TABLE lab.events VALIDATE CONSTRAINT events_customer_fk;
ALTER TABLE lab.measurements VALIDATE CONSTRAINT measurements_customer_fk;

CREATE INDEX IF NOT EXISTS events_customer_id_idx ON lab.events (customer_id);
CREATE UNIQUE INDEX IF NOT EXISTS products_sku_unique_idx ON lab.products (sku);
CREATE INDEX IF NOT EXISTS orders_customer_id_idx ON lab.orders (customer_id);
CREATE INDEX IF NOT EXISTS order_items_order_id_idx ON lab.order_items (order_id);
CREATE INDEX IF NOT EXISTS order_items_product_id_idx ON lab.order_items (product_id);
CREATE INDEX IF NOT EXISTS events_payload_gin_idx ON lab.events USING gin (payload);
CREATE INDEX IF NOT EXISTS events_time_brin_idx ON lab.events USING brin (occurred_at);
CREATE INDEX IF NOT EXISTS measurements_customer_id_idx ON lab.measurements (customer_id);
CREATE INDEX IF NOT EXISTS measurements_time_brin_idx ON lab.measurements USING brin (measured_at);
CREATE INDEX IF NOT EXISTS documents_search_gin_idx ON lab.documents USING gin (search_vector);
CREATE INDEX IF NOT EXISTS documents_jsonb_gin_idx ON lab.documents USING gin (jsonb_metadata);

ANALYZE lab.customers;
ANALYZE lab.products;
ANALYZE lab.orders;
ANALYZE lab.order_items;
ANALYZE lab.events;
ANALYZE lab.measurements;
ANALYZE lab.documents;
ANALYZE lab.type_playground;
