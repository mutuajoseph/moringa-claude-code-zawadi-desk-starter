import type { ActionStatus } from "@/lib/actions";

export function StatusBadge({ status }: { status: ActionStatus }) {
  return (
    <span className={`badge badge-${status}`}>
      <span className="srOnly">Status: </span>
      {status}
    </span>
  );
}
