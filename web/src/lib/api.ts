const API_URL = process.env.NEXT_PUBLIC_API_URL ?? "http://localhost:5000";
const ACCESS_KEY = "evdekiler.accessToken";
const REFRESH_KEY = "evdekiler.refreshToken";

export class ApiError extends Error {
  status: number;

  constructor(message: string, status: number) {
    super(message);
    this.status = status;
  }
}

export type Me = { id: string; email: string; displayName: string; role: string };
type TokenResponse = { accessToken: string; refreshToken: string };

function saveTokens(tokens: TokenResponse) {
  localStorage.setItem(ACCESS_KEY, tokens.accessToken);
  localStorage.setItem(REFRESH_KEY, tokens.refreshToken);
}

function clearTokens() {
  localStorage.removeItem(ACCESS_KEY);
  localStorage.removeItem(REFRESH_KEY);
}

async function toError(res: Response): Promise<ApiError> {
  let message = "Bir şeyler ters gitti.";
  try {
    const data = await res.json();
    const first = data?.errors ? Object.values(data.errors)[0] : null;
    if (Array.isArray(first) && first.length > 0) message = String(first[0]);
    else if (typeof data?.detail === "string") message = data.detail;
  } catch {
    // Cevap JSON değilse varsayılan mesaj kalır
  }
  return new ApiError(message, res.status);
}

let refreshing: Promise<boolean> | null = null;

async function refreshTokens(): Promise<boolean> {
  const refreshToken = localStorage.getItem(REFRESH_KEY);
  if (!refreshToken) return false;

  const res = await fetch(`${API_URL}/api/auth/refresh`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ refreshToken }),
  });

  if (!res.ok) {
    clearTokens();
    return false;
  }

  saveTokens(await res.json());
  return true;
}

export async function api<T>(
  path: string,
  options: { method?: string; body?: unknown } = {},
  retried = false,
): Promise<T> {
  const headers: Record<string, string> = {};
  const token = localStorage.getItem(ACCESS_KEY);
  if (token) headers.Authorization = `Bearer ${token}`;

  let body: BodyInit | undefined;
  if (options.body instanceof FormData) {
    body = options.body;
  } else if (options.body !== undefined) {
    headers["Content-Type"] = "application/json";
    body = JSON.stringify(options.body);
  }

  const res = await fetch(`${API_URL}${path}`, {
    method: options.method ?? "GET",
    headers,
    body,
  });

  if (res.status === 401 && !retried && !path.startsWith("/api/auth/")) {
    refreshing ??= refreshTokens().finally(() => {
      refreshing = null;
    });
    if (await refreshing) return api<T>(path, options, true);
  }

  if (!res.ok) throw await toError(res);

  const text = await res.text();
  return (text ? JSON.parse(text) : undefined) as T;
}

export async function login(email: string, password: string): Promise<Me> {
  const tokens = await api<TokenResponse>("/api/auth/login", {
    method: "POST",
    body: { email, password },
  });
  saveTokens(tokens);

  const me = await api<Me>("/api/users/me");
  if (me.role !== "Admin") {
    clearTokens();
    throw new ApiError("Bu panel sadece yöneticiler içindir.", 403);
  }
  return me;
}

export function getMe(): Promise<Me> {
  return api<Me>("/api/users/me");
}

export async function logout(): Promise<void> {
  const refreshToken = localStorage.getItem(REFRESH_KEY);
  try {
    if (refreshToken) {
      await api("/api/auth/logout", { method: "POST", body: { refreshToken } });
    }
  } finally {
    clearTokens();
  }
}