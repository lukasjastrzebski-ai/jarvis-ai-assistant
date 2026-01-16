/**
 * JWT utilities for token generation and verification
 *
 * In production, use a proper JWT library and secure secrets.
 * This implementation uses Web Crypto API available in Cloudflare Workers.
 */

export interface JWTPayload {
  sub: string;      // Subject (user ID)
  email?: string;
  exp: number;      // Expiration timestamp
  iat: number;      // Issued at timestamp
  type: 'access' | 'refresh';
}

export interface TokenPair {
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
}

// Token expiration times (in seconds)
const ACCESS_TOKEN_EXPIRY = 15 * 60;        // 15 minutes
const REFRESH_TOKEN_EXPIRY = 7 * 24 * 60 * 60; // 7 days

/**
 * Base64URL encode
 */
function base64UrlEncode(data: string): string {
  return btoa(data)
    .replace(/\+/g, '-')
    .replace(/\//g, '_')
    .replace(/=+$/, '');
}

/**
 * Base64URL decode
 */
function base64UrlDecode(data: string): string {
  const padded = data + '='.repeat((4 - data.length % 4) % 4);
  return atob(padded.replace(/-/g, '+').replace(/_/g, '/'));
}

/**
 * Create HMAC signature using Web Crypto API
 */
async function createSignature(data: string, secret: string): Promise<string> {
  const encoder = new TextEncoder();
  const keyData = encoder.encode(secret);
  const dataToSign = encoder.encode(data);

  const key = await crypto.subtle.importKey(
    'raw',
    keyData,
    { name: 'HMAC', hash: 'SHA-256' },
    false,
    ['sign']
  );

  const signature = await crypto.subtle.sign('HMAC', key, dataToSign);
  const signatureArray = new Uint8Array(signature);
  const signatureString = String.fromCharCode(...signatureArray);
  return base64UrlEncode(signatureString);
}

/**
 * Generate a JWT token
 */
export async function generateToken(
  payload: Omit<JWTPayload, 'iat' | 'exp'>,
  secret: string,
  expiresIn: number
): Promise<string> {
  const now = Math.floor(Date.now() / 1000);

  const header = {
    alg: 'HS256',
    typ: 'JWT',
  };

  const fullPayload: JWTPayload = {
    ...payload,
    iat: now,
    exp: now + expiresIn,
  };

  const encodedHeader = base64UrlEncode(JSON.stringify(header));
  const encodedPayload = base64UrlEncode(JSON.stringify(fullPayload));
  const dataToSign = `${encodedHeader}.${encodedPayload}`;

  const signature = await createSignature(dataToSign, secret);

  return `${dataToSign}.${signature}`;
}

/**
 * Verify and decode a JWT token
 */
export async function verifyToken(
  token: string,
  secret: string
): Promise<JWTPayload | null> {
  try {
    const parts = token.split('.');
    if (parts.length !== 3) {
      return null;
    }

    const [encodedHeader, encodedPayload, signature] = parts;
    const dataToSign = `${encodedHeader}.${encodedPayload}`;

    const expectedSignature = await createSignature(dataToSign, secret);

    if (signature !== expectedSignature) {
      return null;
    }

    const payload = JSON.parse(base64UrlDecode(encodedPayload)) as JWTPayload;

    // Check expiration
    const now = Math.floor(Date.now() / 1000);
    if (payload.exp < now) {
      return null;
    }

    return payload;
  } catch {
    return null;
  }
}

/**
 * Generate access and refresh token pair
 */
export async function generateTokenPair(
  userId: string,
  email: string,
  secret: string
): Promise<TokenPair> {
  const accessToken = await generateToken(
    { sub: userId, email, type: 'access' },
    secret,
    ACCESS_TOKEN_EXPIRY
  );

  const refreshToken = await generateToken(
    { sub: userId, type: 'refresh' },
    secret,
    REFRESH_TOKEN_EXPIRY
  );

  return {
    accessToken,
    refreshToken,
    expiresIn: ACCESS_TOKEN_EXPIRY,
  };
}
