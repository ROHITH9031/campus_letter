import { randomUUID } from 'node:crypto';
import { AppError } from './errors.js';
import { validateLetterInput, validateType } from './validation.js';

export class LetterService {
  constructor(repository, clock = () => new Date()) {
    this.repository = repository;
    this.clock = clock;
  }

  async list(type, ownerId) {
    validateType(type);
    const letters = await this.repository.list(ownerId);
    return type ? letters.filter((letter) => letter.type === type) : letters;
  }

  async get(id, ownerId) {
    const letter = await this.repository.findById(id, ownerId);
    if (!letter) throw new AppError(404, 'Letter not found');
    return letter;
  }

  async create(input, ownerId) {
    const details = validateLetterInput(input);
    const now = this.clock().toISOString();
    const letter = {
      id: randomUUID(),
      type: input.type,
      ...(ownerId ? { ownerId } : {}),
      details,
      createdAt: now,
      updatedAt: now,
    };
    return this.repository.create(letter);
  }

  async update(id, input, ownerId) {
    const existing = await this.get(id, ownerId);
    if (input.type && input.type !== existing.type) {
      throw new AppError(400, 'A letter type cannot be changed');
    }
    const details = validateLetterInput({ ...input, type: existing.type }, { partial: true });
    return this.repository.update(id, {
      details: { ...existing.details, ...details },
      updatedAt: this.clock().toISOString(),
    }, ownerId);
  }

  async delete(id, ownerId) {
    const deleted = await this.repository.delete(id, ownerId);
    if (!deleted) throw new AppError(404, 'Letter not found');
    return deleted;
  }
}
