import { NextRequest, NextResponse } from "next/server";
import { projectNotFound } from "@/lib/errors";
import { findProject } from "@/lib/projects";

type RouteContext = {
  params: Promise<{ projectId: string }>;
};

export async function GET(_request: NextRequest, context: RouteContext) {
  const { projectId } = await context.params;
  if (!findProject(projectId)) {
    return NextResponse.json(projectNotFound(projectId), { status: 404 });
  }
  return NextResponse.json(
    { code: "NOT_IMPLEMENTED", message: "Dev A builds this endpoint during the workshop." },
    { status: 501 },
  );
}

export async function POST(_request: NextRequest, context: RouteContext) {
  const { projectId } = await context.params;
  if (!findProject(projectId)) {
    return NextResponse.json(projectNotFound(projectId), { status: 404 });
  }
  return NextResponse.json(
    { code: "NOT_IMPLEMENTED", message: "Dev A builds this endpoint during the workshop." },
    { status: 501 },
  );
}
