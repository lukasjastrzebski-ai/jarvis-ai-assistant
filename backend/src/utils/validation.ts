/**
 * Request validation utilities
 */

export interface ValidationError {
  field: string;
  message: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationError[];
}

/**
 * Validate email format
 */
export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

/**
 * Validate that a string is not empty
 */
export function isNotEmpty(value: string | undefined | null): value is string {
  return typeof value === 'string' && value.trim().length > 0;
}

/**
 * Validate string length
 */
export function isValidLength(
  value: string,
  min: number,
  max: number
): boolean {
  return value.length >= min && value.length <= max;
}

/**
 * Validate UUID format
 */
export function isValidUUID(value: string): boolean {
  return /^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(value);
}

/**
 * Validate ISO date string
 */
export function isValidISODate(value: string): boolean {
  const date = new Date(value);
  return !isNaN(date.getTime()) && value === date.toISOString();
}

/**
 * Schema-based validator
 */
type ValidatorFn = (value: unknown) => boolean;

interface SchemaField {
  required?: boolean;
  type?: 'string' | 'number' | 'boolean' | 'object' | 'array';
  validator?: ValidatorFn;
  message?: string;
}

type Schema = Record<string, SchemaField>;

/**
 * Validate object against schema
 */
export function validateSchema(
  data: Record<string, unknown>,
  schema: Schema
): ValidationResult {
  const errors: ValidationError[] = [];

  for (const [field, rules] of Object.entries(schema)) {
    const value = data[field];

    // Check required
    if (rules.required && (value === undefined || value === null || value === '')) {
      errors.push({
        field,
        message: rules.message || `${field} is required`,
      });
      continue;
    }

    // Skip further validation if optional and not provided
    if (value === undefined || value === null) {
      continue;
    }

    // Check type
    if (rules.type) {
      const actualType = Array.isArray(value) ? 'array' : typeof value;
      if (actualType !== rules.type) {
        errors.push({
          field,
          message: rules.message || `${field} must be a ${rules.type}`,
        });
        continue;
      }
    }

    // Check custom validator
    if (rules.validator && !rules.validator(value)) {
      errors.push({
        field,
        message: rules.message || `${field} is invalid`,
      });
    }
  }

  return {
    valid: errors.length === 0,
    errors,
  };
}

/**
 * Common validation schemas
 */
export const schemas = {
  register: {
    email: {
      required: true,
      type: 'string' as const,
      validator: (v: unknown) => isValidEmail(v as string),
      message: 'Valid email is required',
    },
    password: {
      required: true,
      type: 'string' as const,
      validator: (v: unknown) => isValidLength(v as string, 8, 128),
      message: 'Password must be 8-128 characters',
    },
  },
  login: {
    email: {
      required: true,
      type: 'string' as const,
      message: 'Email is required',
    },
    password: {
      required: true,
      type: 'string' as const,
      message: 'Password is required',
    },
  },
};
