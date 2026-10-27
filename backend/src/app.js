import cors from 'cors';
import express from 'express';
import rateLimit from 'express-rate-limit';
import helmet from 'helmet';
import { config } from './config.js';
import { errorHandler } from './errors.js';
import { LetterRepository } from './repository.js';
import { LetterService } from './letter-service.js';
import { createRouter } from './routes.js';

export function createApp({
  repository = new LetterRepository(config.dataFile),
  database = 'json',
} = {}) {
  const app = express();
  const service = new LetterService(repository);

  app.use(helmet());
  app.use(cors({
    origin: (origin, callback) => {
      if (!origin || config.clientOrigins.includes(origin)) {
        return callback(null, true);
      }
      return callback(new Error('Origin is not allowed by CORS'));
    },
    methods: ['GET', 'POST', 'PATCH', 'DELETE'],
    allowedHeaders: ['Content-Type', 'Authorization'],
  }));
  app.use(rateLimit({ windowMs: 15 * 60 * 1000, limit: 300, standardHeaders: 'draft-8' }));
  app.use(express.json({ limit: '100kb' }));
  app.get('/', (_request, response) => {
    response.json({
      name: 'Campus Letter API',
      status: 'ok',
      health: '/api/health',
      letters: '/api/letters',
    });
  });
  app.use('/api', createRouter(service, database));
  app.use((_request, response) => {
    response.status(404).json({ error: { message: 'Route not found' } });
  });
  app.use(errorHandler);

  return app;
}
