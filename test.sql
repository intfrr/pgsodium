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
SELECT plan(15);

SELECT lives_ok($$SELECT pgsodium_randombytes_random()$$, 'randombytes_random');
SELECT lives_ok($$SELECT pgsodium_randombytes_uniform(10)$$, 'randombytes_uniform');
SELECT lives_ok($$SELECT pgsodium_randombytes_buf(10)$$, 'randombytes_buf');

SELECT pgsodium_crypto_secretbox_keygen() boxkey \gset
SELECT pgsodium_crypto_secretbox_noncegen() secretboxnonce \gset

SELECT pgsodium_crypto_secretbox('bob is your uncle', :'boxkey', :'secretboxnonce') secretbox \gset

SELECT is(pgsodium_crypto_secretbox_open(:'secretbox', :'boxkey', :'secretboxnonce'),
          'bob is your uncle', 'secretbox_open');

SELECT pgsodium_crypto_auth_keygen() authkey \gset

SELECT pgsodium_crypto_auth('bob is your uncle', :'authkey') auth_mac \gset

SELECT ok(pgsodium_crypto_auth_verify(:'auth_mac', 'bob is your uncle', :'authkey'),
          'crypto_auth_verify');
SELECT ok(not pgsodium_crypto_auth_verify('bad mac', 'bob is your uncle', :'authkey'),
          'crypto_auth_verify bad mac');
SELECT ok(not pgsodium_crypto_auth_verify(:'auth_mac', 'bob is your uncle', 'bad key'),
          'crypto_auth_verify bad key');

SELECT is(pgsodium_crypto_generichash('bob is your uncle'),
          '\x6c80c5f772572423c3910a9561710313e4b6e74abc0d65f577a8ac1583673657',
          'crypto_generichash');

SELECT is(pgsodium_crypto_generichash('bob is your uncle', NULL),
          '\x6c80c5f772572423c3910a9561710313e4b6e74abc0d65f577a8ac1583673657',
          'crypto_generichash NULL key');

SELECT is(pgsodium_crypto_generichash('bob is your uncle', 'super sekret key'),
          '\xe8e9e180d918ea9afe0bf44d1945ec356b2b6845e9a4c31acc6c02d826036e41',
          'crypto_generichash with key');

SELECT is(pgsodium_crypto_shorthash('bob is your uncle', 'super sekret key'),
          '\xe080614efb824a15',
          'crypto_shorthash');

SELECT pgsodium_crypto_box_noncegen() boxnonce \gset
SELECT public, secret FROM pgsodium_crypto_box_keypair() \gset bob_
SELECT public, secret FROM pgsodium_crypto_box_keypair() \gset alice_

SELECT pgsodium_crypto_box('bob is your uncle', :'boxnonce', :'bob_public', :'alice_secret') box \gset

SELECT is(pgsodium_crypto_box_open(:'box', :'boxnonce', :'alice_public', :'bob_secret'),
          'bob is your uncle', 'box_open');

SELECT public, secret FROM pgsodium_crypto_sign_keypair() \gset sign_

SELECT pgsodium_crypto_sign('bob is your uncle', :'sign_secret') signed \gset

SELECT is(pgsodium_crypto_sign_open(:'signed', :'sign_public'),
          'bob is your uncle', 'sign_open');

SELECT lives_ok($$SELECT pgsodium_crypto_pwhash_saltgen()$$, 'pgsodium_crypto_pwhash_saltgen');

SELECT is(pgsodium_crypto_pwhash('Correct Horse Battery Staple', '\xccfe2b51d426f88f6f8f18c24635616b'),
        '\xc864fcfca5e92a04200143139f635f0925c4d58c201f8922bb42e86da828d3c1',
        'pgsodium_crypto_pwhash');

SELECT * FROM finish();
ROLLBACK;
