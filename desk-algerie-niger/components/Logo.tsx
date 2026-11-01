// Emblème du Desk : deux points reliés par une route (aucun symbole d'État).
export function Embleme({ className = "" }: { className?: string }) {
  return (
    <svg viewBox="0 0 40 40" aria-hidden="true" className={className}>
      <rect width="40" height="40" rx="9" fill="currentColor" opacity="0.12" />
      <path
        d="M11 9 C 26 13, 10 25, 29 31"
        fill="none"
        stroke="var(--c-ocre-clair)"
        strokeWidth="3"
        strokeLinecap="round"
      />
      <circle cx="11" cy="9" r="3.6" fill="currentColor" />
      <circle cx="29" cy="31" r="3.6" fill="currentColor" />
    </svg>
  );
}
