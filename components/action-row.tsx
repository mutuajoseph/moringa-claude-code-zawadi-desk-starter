import type { Action } from "@/lib/actions";
import { StatusBadge } from "@/components/status-badge";

// Fixed locale and UTC so the server and the client render the same string.
const dueDateFormat = new Intl.DateTimeFormat("en-GB", {
  day: "numeric",
  month: "short",
  timeZone: "UTC",
  year: "numeric",
});

function formatDueDate(dueDate: string | null) {
  if (dueDate === null) return "No due date";
  const parsed = new Date(dueDate);
  if (Number.isNaN(parsed.getTime())) return "No due date";
  return `Due ${dueDateFormat.format(parsed)}`;
}

export function ActionRow({ action }: { action: Action }) {
  return (
    <article className="actionRow" tabIndex={0}>
      <div>
        <h3>{action.title}</h3>
        <p className="actionRowMeta">
          <span>{action.owner}</span>
          <span aria-hidden="true">&middot;</span>
          <span>{formatDueDate(action.dueDate)}</span>
        </p>
      </div>
      <StatusBadge status={action.status} />
    </article>
  );
}
