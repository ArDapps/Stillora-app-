export function SectionHeading({
  title,
  description,
  centered = false,
  eyebrow,
}: {
  title: string;
  description?: string;
  centered?: boolean;
  eyebrow?: string;
}) {
  return (
    <div className={centered ? "mx-auto max-w-3xl text-center" : "max-w-3xl"}>
      {eyebrow ? <span className="landing-kicker">{eyebrow}</span> : null}
      <h2 className="mt-4 text-4xl font-black leading-tight sm:text-5xl">{title}</h2>
      {description ? (
        <p className="mt-4 text-lg leading-8 text-[var(--color-muted)]">{description}</p>
      ) : null}
    </div>
  );
}
