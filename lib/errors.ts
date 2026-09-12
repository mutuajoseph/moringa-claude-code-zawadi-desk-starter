export type ApiErrorBody = {
  code: string;
  message: string;
  fields?: string[];
};

export function validationFailed(message: string, fields: string[]) {
  return { code: "VALIDATION_FAILED", message, fields } satisfies ApiErrorBody;
}

export function projectNotFound(projectId: string) {
  return {
    code: "PROJECT_NOT_FOUND",
    message: `Project ${projectId} was not found.`,
  } satisfies ApiErrorBody;
}
