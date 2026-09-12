export type ActionStatus = "open" | "blocked" | "done";

export type Action = {
  id: string;
  title: string;
  owner: string;
  dueDate: string | null;
  status: ActionStatus;
  createdAt: string;
};

export type ActionList = {
  items: Action[];
  total: number;
};

const actionsByProject = new Map<string, Action[]>();

export function listActions(projectId: string): ActionList {
  const items = [...(actionsByProject.get(projectId) ?? [])].sort((a, b) =>
    b.createdAt.localeCompare(a.createdAt),
  );
  return { items, total: items.length };
}

export function addAction(projectId: string, action: Action) {
  const existing = actionsByProject.get(projectId) ?? [];
  actionsByProject.set(projectId, [action, ...existing]);
  return action;
}
