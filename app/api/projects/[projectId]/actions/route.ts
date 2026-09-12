import { NextRequest, NextResponse } from "next/server";
import { z } from "zod";
import { addAction, listActions, type Action } from "@/lib/actions";
import { projectNotFound, validationFailed } from "@/lib/errors";
import { findProject } from "@/lib/projects";

type RouteContext = {
  params: Promise<{ projectId: string }>;
};

const createActionSchema = z.object({
  title: z.string().trim().min(1).max(200),
  owner: z.string().trim().min(1),
  dueDate: z.string().datetime().nullish(),
});

export async function GET(_request: NextRequest, context: RouteContext) {
  const { projectId } = await context.params;
  if (!findProject(projectId)) {
    return NextResponse.json(projectNotFound(projectId), { status: 404 });
  }
  return NextResponse.json(listActions(projectId));
}

export async function POST(request: NextRequest, context: RouteContext) {
  const { projectId } = await context.params;
  if (!findProject(projectId)) {
    return NextResponse.json(projectNotFound(projectId), { status: 404 });
  }

  let payload: unknown;
  try {
    payload = await request.json();
  } catch {
    return NextResponse.json(validationFailed("Request body must be JSON.", ["body"]), { status: 400 });
  }

  const parsed = createActionSchema.safeParse(payload);
  if (!parsed.success) {
    const fields = [...new Set(parsed.error.issues.map((issue) => String(issue.path[0] ?? "body")))];
    return NextResponse.json(validationFailed("Some fields are invalid.", fields), { status: 400 });
  }

  const action: Action = {
    id: crypto.randomUUID(),
    title: parsed.data.title,
    owner: parsed.data.owner,
    dueDate: parsed.data.dueDate ?? null,
    status: "open",
    createdAt: new Date().toISOString(),
  };

  return NextResponse.json(addAction(projectId, action), { status: 201 });
}
