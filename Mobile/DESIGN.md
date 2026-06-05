---
name: Professional Magic
colors:
  surface: '#0b1326'
  surface-dim: '#0b1326'
  surface-bright: '#31394d'
  surface-container-lowest: '#060e20'
  surface-container-low: '#131b2e'
  surface-container: '#171f33'
  surface-container-high: '#222a3d'
  surface-container-highest: '#2d3449'
  on-surface: '#dae2fd'
  on-surface-variant: '#ccc3d8'
  inverse-surface: '#dae2fd'
  inverse-on-surface: '#283044'
  outline: '#958da1'
  outline-variant: '#4a4455'
  surface-tint: '#d2bbff'
  primary: '#d2bbff'
  on-primary: '#3f008e'
  primary-container: '#7c3aed'
  on-primary-container: '#ede0ff'
  inverse-primary: '#732ee4'
  secondary: '#ffe083'
  on-secondary: '#3c2f00'
  secondary-container: '#eec200'
  on-secondary-container: '#645000'
  tertiary: '#c3c0ff'
  on-tertiary: '#272377'
  tertiary-container: '#5f5db1'
  on-tertiary-container: '#e6e3ff'
  error: '#ffb4ab'
  on-error: '#690005'
  error-container: '#93000a'
  on-error-container: '#ffdad6'
  primary-fixed: '#eaddff'
  primary-fixed-dim: '#d2bbff'
  on-primary-fixed: '#25005a'
  on-primary-fixed-variant: '#5a00c6'
  secondary-fixed: '#ffe083'
  secondary-fixed-dim: '#eec200'
  on-secondary-fixed: '#231b00'
  on-secondary-fixed-variant: '#574500'
  tertiary-fixed: '#e2dfff'
  tertiary-fixed-dim: '#c3c0ff'
  on-tertiary-fixed: '#100563'
  on-tertiary-fixed-variant: '#3e3c8f'
  background: '#0b1326'
  on-background: '#dae2fd'
  surface-variant: '#2d3449'
typography:
  display-lg:
    fontFamily: Geist
    fontSize: 56px
    fontWeight: '700'
    lineHeight: 64px
    letterSpacing: -0.04em
  display-md:
    fontFamily: Geist
    fontSize: 40px
    fontWeight: '600'
    lineHeight: 48px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Geist
    fontSize: 32px
    fontWeight: '600'
    lineHeight: 40px
    letterSpacing: -0.02em
  headline-lg-mobile:
    fontFamily: Geist
    fontSize: 28px
    fontWeight: '600'
    lineHeight: 36px
  title-lg:
    fontFamily: Geist
    fontSize: 20px
    fontWeight: '500'
    lineHeight: 28px
  body-lg:
    fontFamily: Geist
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
  body-sm:
    fontFamily: Geist
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
  label-md:
    fontFamily: Geist
    fontSize: 12px
    fontWeight: '500'
    lineHeight: 16px
    letterSpacing: 0.05em
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 8px
  sm: 16px
  md: 24px
  lg: 40px
  xl: 64px
  gutter: 24px
  margin-mobile: 16px
  margin-desktop: 80px
---

## Brand & Style

This design system is built on the narrative of "Professional Magic"—a fusion of high-precision engineering and fluid, ethereal aesthetics. It targets a premium audience that values technological sophistication and minimalist elegance.

The visual style is a blend of **Minimalism** and **Glassmorphism**. It utilizes a "Midnight Onyx" backdrop to allow "Electric Violet" and "Liquid Gold" to feel like light sources within the UI. The interface should feel like a high-end physical tool that has been digitized; it is precise, responsive, and carries a weight of quality. 

The emotional response is one of calm confidence, innovation, and exclusivity. Motion should be subtle and physics-based, emphasizing the "fluid" nature of the brand.

## Colors

The palette is anchored by **Midnight Onyx** (#020617), providing a deep, ink-like foundation that enhances the luminosity of accent colors. 

- **Electric Violet (#7C3AED):** Used for primary actions, progress indicators, and core brand moments. It represents the "Magic."
- **Liquid Gold (#FACC15):** Used sparingly as an accent for high-value interactions, success states, or premium features. It represents "Professionalism" and prestige.
- **Deep Indigo (#312E81):** Provides a tonal bridge between the dark neutrals and the vibrant violet, used for secondary buttons or subtle backgrounds.
- **Surface Strategy:** We use a multi-tiered surface system. `container-low` is for background-adjacent elements, while `container-high` is for elevated cards and modals to create a sense of physical layering.

## Typography

The typography system relies exclusively on **Geist** to maintain a technical, developer-centric precision. 

The scale emphasizes high contrast between large, bold display text and highly legible, functional body copy. Tight letter-spacing is applied to larger headlines to enhance the premium "editorial" feel. For data-dense views, use `body-sm` and `label-md` to maintain hierarchy without clutter. All text is rendered with high-contrast ratios against the Midnight Onyx background to ensure accessibility in a dark-mode-first environment.

## Layout & Spacing

The layout follows a **Fluid Grid** philosophy using an 8px rhythmic base. 

- **Desktop:** 12-column grid with 24px gutters. Margins are generous (80px) to allow the "Professional" minimalism to breathe.
- **Mobile:** 4-column grid with 16px margins.
- **Rhythm:** Spacing should follow the defined constants. Use `lg` (40px) or `xl` (64px) for vertical section breaks to maintain the premium, spacious feel. Small UI components should use `xs` (8px) and `sm` (16px) for internal padding.

## Elevation & Depth

This design system avoids traditional heavy drop shadows. Depth is achieved through **Tonal Layering** and **Glassmorphism**:

1.  **Luminous Outlines:** Surfaces are separated by 1px solid borders using `glass-stroke`. On higher-tier containers, these borders may have a subtle gradient to mimic a light source.
2.  **Backdrop Blurs:** Modals and navigation overlays use a 20px-40px background blur with a 70% opacity fill of `container-default`.
3.  **Inner Glows:** To emphasize the "Magic," primary buttons and active states feature a faint 4px inner glow of Electric Violet to suggest the element is "powered on."

## Shapes

The shape language is defined by **Soft** precision. 

Standard components (inputs, buttons) use a `0.25rem` (4px) radius. Larger containers (cards, modals) scale up to `0.75rem` (12px). This "Round Four" approach ensures the UI feels modern and approachable without losing the sharp, professional edge associated with high-tech software.

## Components

- **Buttons:** Primary buttons use a solid Electric Violet fill with white text. Secondary buttons use a Deep Indigo stroke with Violet text. Apply a subtle transition on hover that increases the luminosity of the color.
- **Input Fields:** Use `container-low` background with a `glass-stroke` border. On focus, the border transitions to Electric Violet with a faint outer glow.
- **Chips:** Small, highly rounded elements with Indigo backgrounds and Violet or Gold text labels. Used for tagging and status.
- **Cards:** Utilize `container-default` with a 1px border. For "featured" cards, use a Liquid Gold top-border (2px) to denote premium status.
- **Selection Controls:** Checkboxes and radios use Electric Violet for the selected state. Icons should be sharp and minimal.
- **Progress Indicators:** Use a Liquid Gold accent for 100% completion states to provide a "reward" sensation, otherwise stick to Electric Violet.