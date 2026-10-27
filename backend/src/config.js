import 'dotenv/config';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const backendRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..');

export const config = {
  host: process.env.HOST ?? '0.0.0.0',
  port: Number.parseInt(process.env.PORT ?? '3000', 10),
  clientOrigins: (process.env.CLIENT_ORIGIN ?? 'http://localhost:8080')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),
  dataFile: path.resolve(backendRoot, process.env.DATA_FILE ?? './data/letters.json'),
  mongoUri: process.env.MONGO_URI ?? '',
  jwtSecret: process.env.JWT_SECRET ?? '',
  jwtExampleToken: process.env.JWT_EXAMPLE_TOKEN ?? '',
  requireAuth: process.env.REQUIRE_AUTH === 'true',
  nodeEnv: process.env.NODE_ENV ?? 'development',
};

if (!Number.isInteger(config.port) || config.port < 1 || config.port > 65535) {
  throw new Error('PORT must be an integer between 1 and 65535');
}

if (!config.mongoUri) {
  console.warn(
    'MONGO_URI is not configured; using the local JSON repository. '
      + 'Copy .env.example to .env and set MONGO_URI to use MongoDB.',
  );
}

if (config.requireAuth && config.jwtSecret.length < 32) {
  throw new Error('JWT_SECRET must be at least 32 characters when REQUIRE_AUTH=true');
}

if (config.nodeEnv === 'production') {
  if (!config.mongoUri) {
    throw new Error('MONGO_URI is required in production');
  }
  if (!config.requireAuth) {
    throw new Error('REQUIRE_AUTH=true is required in production');
  }
  if (config.host === '127.0.0.1' || config.host === 'localhost') {
    console.warn('HOST is loopback-only; configure HOST=0.0.0.0 for a container deployment.');
  }
}
