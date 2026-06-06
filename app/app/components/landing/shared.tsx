export function SocialBadge({
  badge,
  gradient,
  label,
  size = "md",
}: {
  badge: string;
  gradient: string;
  label: string;
  size?: "sm" | "md";
}) {
  return (
    <span
      aria-label={label}
      className={`grid flex-shrink-0 place-items-center rounded-lg bg-gradient-to-br ${gradient} text-[10px] font-black text-white shadow-lg ${
        size === "sm" ? "size-7" : "size-11 sm:size-12"
      }`}
      title={label}
    >
      {badge}
    </span>
  );
}

export function SectionHeading({
  eyebrow,
  title,
  highlight,
  body,
}: {
  eyebrow: string;
  title: string;
  highlight: string;
  body: string;
}) {
  return (
    <div className="mx-auto mb-12 max-w-2xl text-center sm:mb-16">
      <div className="mb-4 inline-flex items-center gap-2 rounded-full border border-primary/20 bg-primary/10 px-3 py-1 text-xs font-semibold text-primary">
        {eyebrow}
      </div>
      <h2 className="mb-4 text-3xl font-extrabold text-foreground sm:text-4xl md:text-5xl">
        {title} <span className="gradient-text">{highlight}</span>
      </h2>
      <p className="text-base text-muted-foreground sm:text-lg">{body}</p>
    </div>
  );
}
