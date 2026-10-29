#!/usr/bin/env node
import assert from 'node:assert/strict';
import http from 'node:http';
import { invokeSecretGuard } from './secretguard-client.mjs';

const fake = 'sk-proj-NOTAREALKEY';
const server = http.createServer((request, response) => {
  response.setHeader('content-type', 'application/json');
  if (request.url === '/echo-secret') {
    response.end(JSON.stringify({ echoed: fake }));
    return;
  }
  response.end(JSON.stringify({ ok: request.headers.authorization === `Bearer ${fake}` }));
});

await new Promise(resolve => server.listen(0, '127.0.0.1', resolve));
const address = server.address();
const base = `http://127.0.0.1:${address.port}`;
const prior = process.env.SECRETGUARD_JS_TEST_KEY;
try {
  process.env.SECRETGUARD_JS_TEST_KEY = `${fake}\n`;
  const result = await invokeSecretGuard({
    uri: `${base}/safe`,
    secretName: 'SECRETGUARD_JS_TEST_KEY',
  });
  assert.deepEqual(result, { ok: true });

  await assert.rejects(
    () => invokeSecretGuard({ uri: `${base}/echo-secret`, secretName: 'SECRETGUARD_JS_TEST_KEY' }),
    error => error.message === '<error message withheld: response contained credential material>'
  );

  const realFetch = globalThis.fetch;
  globalThis.fetch = async () => {
    throw new Error('remote access_token=NOTAREALVALUE password=NOTAREALVALUE');
  };
  try {
    await assert.rejects(
      () => invokeSecretGuard({ uri: `${base}/safe`, secretName: 'SECRETGUARD_JS_TEST_KEY' }),
      error => error.message.includes('<redacted>') && !error.message.includes('NOTAREALVALUE')
    );
  } finally {
    globalThis.fetch = realFetch;
  }

  delete process.env.SECRETGUARD_JS_TEST_KEY;
  await assert.rejects(
    () => invokeSecretGuard({ uri: `${base}/safe`, secretName: 'SECRETGUARD_JS_TEST_KEY' }),
    error => error.message.includes('SECRETGUARD_JS_TEST_KEY') && !error.message.includes(fake)
  );
} finally {
  if (prior === undefined) delete process.env.SECRETGUARD_JS_TEST_KEY;
  else process.env.SECRETGUARD_JS_TEST_KEY = prior;
  await new Promise(resolve => server.close(resolve));
}
console.log('secretguard-client.test.mjs passed');
