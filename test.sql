\set ECHO none
\set QUIET 1

\pset format unaligned
\pset tuples_only true
\pset pager

\set ON_ERROR_ROLLBACK 1
\set ON_ERROR_STOP true
\set QUIET 1

DROP EXTENSION IF EXISTS pgsodium;
CREATE EXTENSION pgsodium;

BEGIN;
SELECT plan(7);

SELECT lives_ok($$SELECT pgsodium_randombytes_random()$$, 'randombytes_random');
SELECT lives_ok($$SELECT pgsodium_randombytes_uniform(10)$$, 'randombytes_uniform');
SELECT lives_ok($$SELECT pgsodium_randombytes_buf(10)$$, 'randombytes_buf');

CREATE TABLE test_secretbox (
       id SERIAL PRIMARY KEY,
       message text NOT NULL,
       crypted bytea,
       key bytea DEFAULT pgsodium_crypto_secretbox_keygen(),
       nonce bytea DEFAULT pgsodium_crypto_secretbox_noncegen()
       );

INSERT INTO test_secretbox (message) VALUES ('bob is your uncle');
UPDATE test_secretbox SET crypted = pgsodium_crypto_secretbox(message, key, nonce);

-- SELECT * from test_secretbox;

-- WITH t AS (SELECT * FROM test_secretbox)
--      SELECT pgsodium_crypto_secretbox_open(t.crypted, t.key, t.nonce) FROM t;

SELECT pgsodium_crypto_auth_keygen() authkey \gset
\set quoted_authkey '\'' :authkey '\''

SELECT pgsodium_crypto_auth('bob is your uncle', :quoted_authkey) auth_mac \gset
\set quoted_auth_mac '\'' :auth_mac '\''

SELECT ok(pgsodium_crypto_auth_verify(:quoted_auth_mac, 'bob is your uncle', :quoted_authkey),
          'crypto_auth_verify');
SELECT ok(not pgsodium_crypto_auth_verify('bad mac', 'bob is your uncle', :quoted_authkey),
          'crypto_auth_verify bad mac');
SELECT ok(not pgsodium_crypto_auth_verify(:quoted_auth_mac, 'bob is your uncle', 'bad key'),
          'crypto_auth_verify bad key');

SELECT is(pgsodium_crypto_generichash('bob is your uncle'),
          '\x6540d56aa40be032add2afa9a7709b4dd20c1f12632a7fec7656e44ca6d101f2',
          'crypto_generichash');

SELECT * FROM finish();
ROLLBACK;
