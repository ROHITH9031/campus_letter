import assert from 'node:assert/strict';
import test from 'node:test';
import request from 'supertest';
import { createApp } from '../src/app.js';
import { config } from '../src/config.js';

config.requireAuth = false;

function createMemoryRepository() {
  const letters = [];
  return {
    async list(ownerId) {
      return letters.filter((letter) => !ownerId || letter.ownerId === ownerId);
    },
    async findById(id, ownerId) {
      return letters.find((letter) => letter.id === id && (!ownerId || letter.ownerId === ownerId)) ?? null;
    },
    async create(letter) { letters.unshift(letter); return letter; },
    async update(id, changes, ownerId) {
      const index = letters.findIndex(
        (letter) => letter.id === id && (!ownerId || letter.ownerId === ownerId),
      );
      if (index === -1) return null;
      letters[index] = { ...letters[index], ...changes };
      return letters[index];
    },
    async delete(id, ownerId) {
      const index = letters.findIndex(
        (letter) => letter.id === id && (!ownerId || letter.ownerId === ownerId),
      );
      return index === -1 ? null : letters.splice(index, 1)[0];
    },
  };
}

test('reports API health', async () => {
  const response = await request(createApp({ repository: createMemoryRepository() }))
    .get('/api/health');
  assert.equal(response.status, 200);
  assert.equal(response.body.status, 'ok');
  assert.equal(response.body.database, 'json');
});

test('rejects invalid JWTs when authentication is enabled', async () => {
  const previous = process.env.REQUIRE_AUTH;
  process.env.REQUIRE_AUTH = 'true';
  const original = config.requireAuth;
  config.requireAuth = true;
  const response = await request(createApp({ repository: createMemoryRepository() }))
    .get('/api/letters');
  config.requireAuth = original;
  if (previous === undefined) delete process.env.REQUIRE_AUTH;
  else process.env.REQUIRE_AUTH = previous;
  assert.equal(response.status, 401);
});

test('reports API information at the server root', async () => {
  const response = await request(createApp({ repository: createMemoryRepository() }))
    .get('/');
  assert.equal(response.status, 200);
  assert.equal(response.body.health, '/api/health');
});

test('creates, reads, updates, filters, and deletes a letter', async () => {
  const app = createApp({ repository: createMemoryRepository() });
  const createResponse = await request(app).post('/api/letters').send({
    type: 'normal',
    date: '27/10/2026',
    recipient: 'Dean - Academics',
    institution: 'SRKR Engineering College',
    subject: 'Attendance request',
    salutation: 'Respected Sir/Madam,',
    message: 'Please consider my request.',
    senderName: 'Student',
  });

  assert.equal(createResponse.status, 201);
  const id = createResponse.body.data.id;
  assert.equal(createResponse.body.data.type, 'normal');

  const getResponse = await request(app).get(`/api/letters/${id}`);
  assert.equal(getResponse.status, 200);
  assert.equal(getResponse.body.data.details.subject, 'Attendance request');

  const updateResponse = await request(app).patch(`/api/letters/${id}`)
    .send({ subject: 'Updated request' });
  assert.equal(updateResponse.status, 200);
  assert.equal(updateResponse.body.data.details.subject, 'Updated request');

  const listResponse = await request(app).get('/api/letters?type=normal');
  assert.equal(listResponse.status, 200);
  assert.equal(listResponse.body.data.length, 1);

  const deleteResponse = await request(app).delete(`/api/letters/${id}`);
  assert.equal(deleteResponse.status, 204);
  assert.equal((await request(app).get(`/api/letters/${id}`)).status, 404);
});

test('rejects invalid letter input', async () => {
  const response = await request(createApp({ repository: createMemoryRepository() }))
    .post('/api/letters')
    .send({ type: 'unknown' });
  assert.equal(response.status, 400);
  assert.match(response.body.error.message, /type/);
});

test('rejects incomplete letter input', async () => {
  const response = await request(createApp({ repository: createMemoryRepository() }))
    .post('/api/letters')
    .send({ type: 'normal', subject: 'Missing required fields' });
  assert.equal(response.status, 400);
  assert.equal(response.body.error.message, 'Invalid letter fields');
  assert.ok(response.body.error.details.date);
});
