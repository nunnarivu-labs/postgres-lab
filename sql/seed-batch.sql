\set ON_ERROR_STOP on
BEGIN;

INSERT INTO lab.customers (
  customer_id, customer_uuid, display_name, initials, email, is_active,
  birth_date, signup_at, last_seen_at, network, device_mac, preferences, profile
)
SELECT g,
       md5('postgres-lab-customer-' || g)::uuid,
       'Customer ' || g,
       'C' || lpad((g % 10)::text, 1, '0'),
       'customer-' || g || '@example.test',
       (g % 10 <> 0),
       date '1970-01-01' + (g % 18000)::integer,
       timestamptz '2020-01-01 00:00:00+00' + g * interval '1 second',
       CASE WHEN g % 7 = 0 THEN NULL
            ELSE timestamp '2021-01-01 00:00:00' + g * interval '1 second' END,
       ('10.0.' || (g % 256) || '.' || (g % 250))::inet,
       ('02:00:00:00:' || lpad(to_hex(g % 256), 2, '0') || ':' ||
        lpad(to_hex((g / 256) % 256), 2, '0'))::macaddr,
       ARRAY['email', CASE WHEN g % 2 = 0 THEN 'sms' ELSE 'push' END],
       jsonb_build_object('tier', (g % 5), 'marketing', (g % 3 = 0))
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (customer_id) DO NOTHING;

INSERT INTO lab.products (
  product_id, sku, name, price, approximate_weight, scientific_measure,
  category, tags, content_hash, stock_count
)
SELECT g,
       'SKU-' || lpad(g::text, 12, '0'),
       'Product ' || g,
       ((g % 1000000)::numeric / 100),
       ((g % 10000)::real / 100),
       ((g % 1000000)::double precision / 1000),
       'category-' || (g % 32),
       ARRAY[(g % 1000)::integer, ((g + 17) % 1000)::integer],
       decode(md5('postgres-lab-product-' || g), 'hex'),
       (g % 10000)::integer
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (product_id) DO NOTHING;

INSERT INTO lab.orders (
  order_id, customer_id, placed_at, expected_ship_interval, status,
  total, attributes, source_ip
)
SELECT g,
       ((g * 48271) % :rows) + 1,
       timestamptz '2022-01-01 00:00:00+00' + g * interval '2 seconds',
       ((g % 5) + 1) * interval '1 day',
       (ARRAY['pending', 'paid', 'shipped', 'cancelled']::lab.order_status[])[(g % 4) + 1],
       ((g % 100000)::numeric / 100),
       json_build_object('channel', (g % 8), 'coupon', (g % 11 = 0)),
       ('192.0.' || (g % 256) || '.0/24')::cidr
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (order_id) DO NOTHING;

INSERT INTO lab.order_items (
  order_item_id, order_id, product_id, quantity, unit_price
)
SELECT g,
       g,
       ((g * 69621) % :rows) + 1,
       ((g % 5) + 1)::smallint,
       ((g % 100000)::numeric / 100)
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (order_item_id) DO NOTHING;

INSERT INTO lab.events (
  event_id, customer_id, occurred_at, event_name, payload, labels,
  searchable, raw_sample
)
SELECT g,
       ((g * 48271) % :rows) + 1,
       timestamptz '2023-01-01 00:00:00+00' + g * interval '1 second',
       'event-' || (g % 16),
       jsonb_build_object('kind', (g % 16), 'score', (g % 1000), 'active', (g % 2 = 0)),
       ARRAY['batch-' || (g % 20), 'kind-' || (g % 16)],
       to_tsvector('english', 'event payload customer ' || g),
       decode(substr(md5('event-' || g) || md5('event-payload-' || g), 1, 32), 'hex')
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (event_id) DO NOTHING;

INSERT INTO lab.events (
  event_id, customer_id, occurred_at, event_name, payload, labels,
  searchable, raw_sample
)
SELECT 50000000 + g,
       ((g * 48271) % :rows) + 1,
       timestamptz '2024-01-01 00:00:00+00' + g * interval '1 second',
       'event-' || (g % 16),
       jsonb_build_object('kind', (g % 16), 'score', (g % 1000), 'active', (g % 2 = 0)),
       ARRAY['batch-' || (g % 20), 'kind-' || (g % 16)],
       to_tsvector('english', 'event payload customer ' || g),
       decode(substr(md5('event2-' || g) || md5('event-payload2-' || g), 1, 32), 'hex')
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (event_id) DO NOTHING;

INSERT INTO lab.measurements (
  measurement_id, customer_id, measured_at, small_value, integer_value,
  big_value, exact_value, point_value, coverage, address
)
SELECT g,
       ((g * 48271) % :rows) + 1,
       timestamptz '2024-01-01 00:00:00+00' + g * interval '1 second',
       (g % 32768)::smallint,
       (g % 1000000)::integer,
       g::bigint * 1000,
       (g % 1000000)::numeric / 1000000,
       point((g % 100000)::float8 / 100, (g % 90000)::float8 / 100),
       int8range(g::bigint, g::bigint + 10, '[)'),
       ('2001:db8:' || to_hex(g % 65536) || '::1')::inet
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (measurement_id) DO NOTHING;

INSERT INTO lab.measurements (
  measurement_id, customer_id, measured_at, small_value, integer_value,
  big_value, exact_value, point_value, coverage, address
)
SELECT 50000000 + g,
       ((g * 48271) % :rows) + 1,
       timestamptz '2025-01-01 00:00:00+00' + g * interval '1 second',
       (g % 32768)::smallint,
       (g % 1000000)::integer,
       (50000000 + g)::bigint * 1000,
       (g % 1000000)::numeric / 1000000,
       point((g % 100000)::float8 / 100, (g % 90000)::float8 / 100),
       int8range((50000000 + g)::bigint, (50000000 + g)::bigint + 10, '[)'),
       ('2001:db8:' || to_hex(g % 65536) || '::1')::inet
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (measurement_id) DO NOTHING;

INSERT INTO lab.documents (
  document_id, title, body, xml_metadata, json_metadata, jsonb_metadata,
  search_vector, available_during, flags
)
SELECT g,
       'Document ' || g,
       'Synthetic document ' || g || ' with searchable terms postgres database query performance.',
       xmlelement(name document, xmlattributes(g AS id)),
       json_build_object('document_id', g, 'format', 'xml-and-json'),
       jsonb_build_object('document_id', g, 'status', (g % 4), 'indexed', (g % 2 = 0)),
       to_tsvector('english', 'synthetic document postgres database query performance ' || g),
       tstzrange(timestamptz '2024-01-01 00:00:00+00' + g * interval '1 second',
                 timestamptz '2024-01-02 00:00:00+00' + g * interval '1 second', '[)'),
       (g::bit(32))::bit varying
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (document_id) DO NOTHING;

INSERT INTO lab.type_playground (
  sample_id, integer_value, exact_value, approximate_value, bool_value,
  time_value, timestamp_value, timetz_value, mac8_value, circle_value,
  polygon_value, int_range, int_multirange, composite_value, enum_value, amount
)
SELECT g,
       (g % 1000000)::integer,
       (g % 100000000)::numeric / 10000,
       (g % 1000000)::double precision / 17,
       (g % 2 = 0),
       time '00:00:00' + (g % 86400) * interval '1 second',
       timestamp '2020-01-01 00:00:00' + g * interval '1 second',
       timetz '12:00:00+00' + (g % 3600) * interval '1 second',
       ('02:00:00:00:00:00:' || lpad(to_hex(g % 256), 2, '0') || ':' ||
        lpad(to_hex((g / 256) % 256), 2, '0'))::macaddr8,
       circle(point((g % 1000)::float8, (g % 997)::float8), ((g % 50) + 1)::float8),
       '((0,0),(1,0),(1,1),(0,1))'::polygon,
       int4range((g % 100000)::integer, (g % 100000)::integer + 100, '[)'),
       int4multirange(int4range((g % 100000)::integer, (g % 100000)::integer + 10, '[)'),
                      int4range((g % 100000)::integer + 20, (g % 100000)::integer + 30, '[)')),
       ROW((g % 1000)::integer, 'sample-' || g)::lab.sample_composite,
       (ARRAY['pending', 'paid', 'shipped', 'cancelled']::lab.order_status[])[(g % 4) + 1],
       (g % 100000)::numeric / 100
FROM generate_series(:start_id::bigint, :end_id::bigint) AS s(g)
ON CONFLICT (sample_id) DO NOTHING;

COMMIT;
