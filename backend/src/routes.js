import { Router } from 'express';
import { authenticate, verifyToken } from './auth.js';

export function createRouter(service, database = 'mongodb') {
  const router = Router();

  router.get('/health', (_request, response) => {
    response.json({ status: 'ok', service: 'campus-letter-api', database });
  });

  router.get('/auth/verify', verifyToken);
  router.use('/letters', authenticate);

  router.get('/letters', async (request, response) => {
    response.json({ data: await service.list(request.query.type, request.user?.sub) });
  });

  router.post('/letters', async (request, response) => {
    const letter = await service.create(request.body, request.user?.sub);
    response.status(201).json({ data: letter });
  });

  router.get('/letters/:id', async (request, response) => {
    response.json({ data: await service.get(request.params.id, request.user?.sub) });
  });

  router.patch('/letters/:id', async (request, response) => {
    response.json({
      data: await service.update(request.params.id, request.body, request.user?.sub),
    });
  });

  router.delete('/letters/:id', async (request, response) => {
    await service.delete(request.params.id, request.user?.sub);
    response.status(204).send();
  });

  return router;
}
