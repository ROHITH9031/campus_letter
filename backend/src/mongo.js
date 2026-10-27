import mongoose from 'mongoose';

const letterSchema = new mongoose.Schema(
  {
    id: { type: String, required: true, unique: true, index: true },
    ownerId: { type: String, index: true },
    type: { type: String, enum: ['languageNest', 'normal'], required: true, index: true },
    details: { type: Map, of: String, required: true },
    createdAt: { type: Date, required: true },
    updatedAt: { type: Date, required: true },
  },
  { collection: 'letters', versionKey: false },
);

export const LetterModel = mongoose.models.Letter ?? mongoose.model('Letter', letterSchema);

function toLetter(document) {
  if (!document) return null;
  const details = document.details instanceof Map
    ? Object.fromEntries(document.details)
    : document.details ?? {};
  return {
    id: document.id,
    type: document.type,
    details,
    createdAt: new Date(document.createdAt).toISOString(),
    updatedAt: new Date(document.updatedAt).toISOString(),
  };
}

export class MongoLetterRepository {
  async list(ownerId) {
    const letters = await LetterModel.find(ownerId ? { ownerId } : {}).sort({ createdAt: -1 }).lean();
    return letters.map(toLetter);
  }

  async findById(id, ownerId) {
    return toLetter(await LetterModel.findOne({
      id,
      ...(ownerId ? { ownerId } : {}),
    }).lean());
  }

  async create(letter) {
    const created = await LetterModel.create(letter);
    return toLetter(created.toObject());
  }

  async update(id, changes, ownerId) {
    const updated = await LetterModel.findOneAndUpdate(
      { id, ...(ownerId ? { ownerId } : {}) },
      { $set: changes },
      { new: true, runValidators: true },
    ).lean();
    return toLetter(updated);
  }

  async delete(id, ownerId) {
    return toLetter(await LetterModel.findOneAndDelete({
      id,
      ...(ownerId ? { ownerId } : {}),
    }).lean());
  }
}

export async function connectMongo(uri) {
  if (!uri) throw new Error('MONGO_URI is required to start the backend');
  await mongoose.connect(uri, { serverSelectionTimeoutMS: 5000 });
}

export async function disconnectMongo() {
  await mongoose.disconnect();
}
