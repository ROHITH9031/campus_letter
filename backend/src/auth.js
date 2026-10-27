import jwt from 'jsonwebtoken';
import { config } from './config.js';
import { AppError } from './errors.js';

export function authenticate(request, _response, next) {
  if (!config.requireAuth) return next();

  const header = request.get('authorization');
  const token = header?.startsWith('Bearer ') ? header.slice(7).trim() : '';
  if (!token) return next(new AppError(401, 'Authorization Bearer token is required'));

  try {
    request.user = jwt.verify(token, config.jwtSecret);
    if (!request.user.sub || typeof request.user.sub !== 'string') {
      return next(new AppError(401, 'JWT must include a subject claim'));
    }
    return next();
  } catch {
    return next(new AppError(401, 'Invalid or expired JWT token'));
  }
}

export function verifyToken(request, response, next) {
  const header = request.get('authorization');
  const token = header?.startsWith('Bearer ') ? header.slice(7).trim() : '';
  if (!token) return next(new AppError(401, 'Authorization Bearer token is required'));

  try {
    request.user = jwt.verify(token, config.jwtSecret);
    if (!request.user.sub || typeof request.user.sub !== 'string') {
      return next(new AppError(401, 'JWT must include a subject claim'));
    }
    return response.json({ valid: true, user: request.user });
  } catch {
    return next(new AppError(401, 'Invalid or expired JWT token'));
  }
}
