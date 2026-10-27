import { mkdir, readFile, rename, writeFile } from 'node:fs/promises';
import path from 'node:path';

export class LetterRepository {
  constructor(filePath) {
    this.filePath = filePath;
    this.writeQueue = Promise.resolve();
  }

  async list(ownerId) {
    const letters = await this.#read();
    return ownerId ? letters.filter((letter) => letter.ownerId === ownerId) : letters;
  }

  async findById(id, ownerId) {
    const letters = await this.#read();
    return letters.find((letter) => letter.id === id && (!ownerId || letter.ownerId === ownerId)) ?? null;
  }

  async create(letter) {
    return this.#update((letters) => [letter, ...letters]);
  }

  async update(id, changes, ownerId) {
    let updated;
    await this.#update((letters) => {
      const index = letters.findIndex(
        (letter) => letter.id === id && (!ownerId || letter.ownerId === ownerId),
      );
      if (index === -1) return letters;
      updated = { ...letters[index], ...changes };
      return letters.with(index, updated);
    });
    return updated ?? null;
  }

  async delete(id, ownerId) {
    let deleted;
    await this.#update((letters) => {
      deleted = letters.find(
        (letter) => letter.id === id && (!ownerId || letter.ownerId === ownerId),
      );
      return letters.filter(
        (letter) => !(letter.id === id && (!ownerId || letter.ownerId === ownerId)),
      );
    });
    return deleted ?? null;
  }

  async #read() {
    try {
      const content = await readFile(this.filePath, 'utf8');
      const letters = JSON.parse(content);
      if (!Array.isArray(letters)) {
        throw new Error('Letter data must be an array');
      }
      return letters;
    } catch (error) {
      if (error.code === 'ENOENT') return [];
      if (error instanceof SyntaxError) {
        throw new Error(`Invalid JSON in ${this.filePath}`);
      }
      throw error;
    }
  }

  async #update(transform) {
    const operation = this.writeQueue.then(async () => {
      const letters = await this.#read();
      const updated = transform(letters);
      await mkdir(path.dirname(this.filePath), { recursive: true });
      const temporaryPath = `${this.filePath}.tmp`;
      await writeFile(temporaryPath, `${JSON.stringify(updated, null, 2)}\n`, 'utf8');
      await rename(temporaryPath, this.filePath);
      return updated;
    });
    this.writeQueue = operation.catch(() => {});
    return operation;
  }
}
