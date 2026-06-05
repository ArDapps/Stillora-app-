export function SectionHeading({
  title,
  description,
  centered = false,
}: {
  title: string;
  description?: string;
  centered?: boolean;
}) {
  return (
    <div className={centered ? "mx-auto max-w-2xl text-center" : "max-w-2xl"}>
      <h2 className="text-3xl font-semibold tracking-tight sm:text-4xl">{title}</h2>
      {description ? (
        <p className="mt-4 text-lg leading-relaxed text-[var(--color-muted)]">{description}</p>
      ) : null}
    </div>
  );
}
