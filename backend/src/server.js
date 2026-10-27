import { createApp } from './app.js';
import { config } from './config.js';
import { connectMongo, disconnectMongo, MongoLetterRepository } from './mongo.js';
import { LetterRepository } from './repository.js';

let repository;
let database;
if (config.mongoUri) {
  await connectMongo(config.mongoUri);
  repository = new MongoLetterRepository();
  database = 'mongodb';
} else {
  repository = new LetterRepository(config.dataFile);
  database = 'json-development-fallback';
}

const app = createApp({ repository, database });
const server = app.listen(config.port, config.host, () => {
  console.log(`Campus Letter API listening on http://${config.host}:${config.port}`);
});

function shutdown(signal) {
  console.log(`${signal} received; shutting down`);
  server.close((error) => {
    disconnectMongo()
      .catch((disconnectError) => console.error(disconnectError))
      .finally(() => {
        if (error) {
          console.error(error);
          process.exitCode = 1;
        }
      });
  });
}

process.on('SIGINT', () => shutdown('SIGINT'));
process.on('SIGTERM', () => shutdown('SIGTERM'));
