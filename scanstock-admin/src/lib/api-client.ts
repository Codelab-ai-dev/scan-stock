// Centralized API client with error handling

export class ApiError extends Error {
  constructor(
    message: string,
    public status: number,
    public code?: string
  ) {
    super(message)
    this.name = 'ApiError'
  }
}

interface ApiResponse<T> {
  data: T | null
  error: ApiError | null
}

interface RequestOptions extends Omit<RequestInit, 'body'> {
  body?: unknown
}

async function request<T>(
  url: string,
  options: RequestOptions = {}
): Promise<ApiResponse<T>> {
  const { body, headers, ...rest } = options

  try {
    const response = await fetch(url, {
      ...rest,
      headers: {
        'Content-Type': 'application/json',
        ...headers,
      },
      body: body ? JSON.stringify(body) : undefined,
    })

    const data = await response.json()

    if (!response.ok) {
      return {
        data: null,
        error: new ApiError(
          data.error || 'Error en la solicitud',
          response.status,
          data.code
        ),
      }
    }

    return { data, error: null }
  } catch (err) {
    return {
      data: null,
      error: new ApiError(
        err instanceof Error ? err.message : 'Error de conexión',
        0,
        'NETWORK_ERROR'
      ),
    }
  }
}

export const api = {
  get: <T>(url: string, options?: RequestOptions) =>
    request<T>(url, { ...options, method: 'GET' }),

  post: <T>(url: string, body?: unknown, options?: RequestOptions) =>
    request<T>(url, { ...options, method: 'POST', body }),

  patch: <T>(url: string, body?: unknown, options?: RequestOptions) =>
    request<T>(url, { ...options, method: 'PATCH', body }),

  put: <T>(url: string, body?: unknown, options?: RequestOptions) =>
    request<T>(url, { ...options, method: 'PUT', body }),

  delete: <T>(url: string, options?: RequestOptions) =>
    request<T>(url, { ...options, method: 'DELETE' }),
}

// Helper for FormData requests (file uploads)
export async function uploadFile<T>(
  url: string,
  formData: FormData
): Promise<ApiResponse<T>> {
  try {
    const response = await fetch(url, {
      method: 'POST',
      body: formData,
    })

    const data = await response.json()

    if (!response.ok) {
      return {
        data: null,
        error: new ApiError(
          data.error || 'Error al subir archivo',
          response.status
        ),
      }
    }

    return { data, error: null }
  } catch (err) {
    return {
      data: null,
      error: new ApiError(
        err instanceof Error ? err.message : 'Error de conexión',
        0,
        'NETWORK_ERROR'
      ),
    }
  }
}

// Error messages in Spanish
export const errorMessages: Record<string, string> = {
  NETWORK_ERROR: 'Error de conexión. Verifica tu internet.',
  UNAUTHORIZED: 'No tienes autorización para esta acción.',
  NOT_FOUND: 'El recurso no fue encontrado.',
  VALIDATION_ERROR: 'Los datos enviados no son válidos.',
  SERVER_ERROR: 'Error del servidor. Intenta más tarde.',
}

export function getErrorMessage(error: ApiError): string {
  if (error.code && errorMessages[error.code]) {
    return errorMessages[error.code]
  }
  return error.message
}
