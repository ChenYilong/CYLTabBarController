export class AppError extends Error {
  constructor(status, code, message) {
    super(message);
    this.name = "AppError";
    this.status = status;
    this.code = code;
  }
}

export function isAppError(error) {
  return error instanceof AppError;
}
