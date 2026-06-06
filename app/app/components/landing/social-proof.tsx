import { Quote, Star } from "lucide-react";
import { SectionHeading } from "./shared";
import { testimonials } from "./data";

export function SocialProof() {
  return (
    <section id="testimonials" className="relative overflow-hidden py-20 sm:py-28">
      <div className="mx-auto w-full max-w-7xl px-4 sm:px-6">
        <SectionHeading
          eyebrow="Creator love"
          title="Loved by"
          highlight="content creators"
          body="Creators use Stillora to turn static content into platform-ready videos without opening a complicated editor."
        />
        <div className="mx-auto mb-12 grid max-w-3xl grid-cols-2 gap-4 md:grid-cols-4">
          {[
            ["10,000+", "Videos exported"],
            ["4.9/5", "Average rating"],
            ["3s", "Avg setup time"],
            ["5 presets", "Platform formats"],
          ].map(([value, label]) => (
            <div key={label} className="rounded-lg border border-border/60 bg-card/60 p-4 text-center">
              <div className="gradient-text mb-0.5 text-xl font-extrabold sm:text-2xl">{value}</div>
              <div className="text-xs text-muted-foreground">{label}</div>
            </div>
          ))}
        </div>
        <div className="grid grid-cols-1 gap-5 sm:gap-6 md:grid-cols-3">
          {testimonials.map((testimonial) => (
            <div key={testimonial.author} className="relative rounded-lg border border-border/60 bg-card/70 p-6 sm:p-8">
              <Quote className="absolute right-5 top-5 size-6 text-primary/15" />
              <div className="mb-5 flex gap-1">
                {Array.from({ length: 5 }).map((_, index) => (
                  <Star key={index} className="size-4 fill-amber-400 text-amber-400" />
                ))}
              </div>
              <p className="mb-6 text-sm leading-relaxed text-foreground/90 sm:text-base">&quot;{testimonial.quote}&quot;</p>
              <div className="flex items-center gap-3">
                <div className={`grid size-10 flex-shrink-0 place-items-center rounded-full bg-gradient-to-br ${testimonial.color}`}>
                  <span className="text-xs font-bold text-white">{testimonial.avatar}</span>
                </div>
                <div>
                  <p className="text-sm font-semibold text-foreground">{testimonial.author}</p>
                  <p className="text-xs text-muted-foreground">{testimonial.role}</p>
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}
