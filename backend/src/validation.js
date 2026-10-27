import { AppError } from './errors.js';

const types = new Set(['languageNest', 'normal']);
const fieldsByType = {
  languageNest: [
    'date',
    'eventName',
    'eventDate',
    'studentOrganizers',
    'eventDescription',
    'teamName',
  ],
  normal: [
    'date',
    'recipient',
    'institution',
    'subject',
    'salutation',
    'message',
    'senderName',
  ],
};

export function validateLetterInput(input, { partial = false } = {}) {
  if (!input || typeof input !== 'object' || Array.isArray(input)) {
    throw new AppError(400, 'Request body must be a JSON object');
  }

  if (!partial && !types.has(input.type)) {
    throw new AppError(400, 'type must be either "languageNest" or "normal"');
  }

  const fields = fieldsByType[input.type] ?? Object.values(fieldsByType).flat();
  const details = {};
  for (const field of fields) {
    if (!(field in input)) continue;
    if (typeof input[field] !== 'string') {
      details[field] = 'must be a string';
    } else if (input[field].length > 5000) {
      details[field] = 'must be 5000 characters or fewer';
    }
  }

  if (Object.keys(details).length > 0) {
    throw new AppError(400, 'Invalid letter fields', details);
  }

  return Object.fromEntries(
    fields
      .filter((field) => field in input)
      .map((field) => [field, input[field].trim()]),
  );
}

export function validateType(type) {
  if (type !== undefined && !types.has(type)) {
    throw new AppError(400, 'type must be either "languageNest" or "normal"');
  }
}
