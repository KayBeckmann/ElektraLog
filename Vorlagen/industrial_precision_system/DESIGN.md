---
name: Industrial Precision System
colors:
  surface: '#fbf8fa'
  surface-dim: '#dcd9db'
  surface-bright: '#fbf8fa'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f5f3f4'
  surface-container: '#f0edef'
  surface-container-high: '#eae7e9'
  surface-container-highest: '#e4e2e3'
  on-surface: '#1b1b1d'
  on-surface-variant: '#45474c'
  inverse-surface: '#303032'
  inverse-on-surface: '#f3f0f2'
  outline: '#75777d'
  outline-variant: '#c5c6cd'
  surface-tint: '#545f73'
  primary: '#091426'
  on-primary: '#ffffff'
  primary-container: '#1e293b'
  on-primary-container: '#8590a6'
  inverse-primary: '#bcc7de'
  secondary: '#505f76'
  on-secondary: '#ffffff'
  secondary-container: '#d0e1fb'
  on-secondary-container: '#54647a'
  tertiary: '#1e1200'
  on-tertiary: '#ffffff'
  tertiary-container: '#35260c'
  on-tertiary-container: '#a38c6a'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#d8e3fb'
  primary-fixed-dim: '#bcc7de'
  on-primary-fixed: '#111c2d'
  on-primary-fixed-variant: '#3c475a'
  secondary-fixed: '#d3e4fe'
  secondary-fixed-dim: '#b7c8e1'
  on-secondary-fixed: '#0b1c30'
  on-secondary-fixed-variant: '#38485d'
  tertiary-fixed: '#fadfb8'
  tertiary-fixed-dim: '#ddc39d'
  on-tertiary-fixed: '#271902'
  on-tertiary-fixed-variant: '#564427'
  background: '#fbf8fa'
  on-background: '#1b1b1d'
  surface-variant: '#e4e2e3'
typography:
  display-lg:
    fontFamily: Inter
    fontSize: 32px
    fontWeight: '700'
    lineHeight: '1.2'
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Inter
    fontSize: 24px
    fontWeight: '600'
    lineHeight: '1.3'
  title-sm:
    fontFamily: Inter
    fontSize: 18px
    fontWeight: '600'
    lineHeight: '1.4'
  body-base:
    fontFamily: Inter
    fontSize: 16px
    fontWeight: '400'
    lineHeight: '1.6'
  body-sm:
    fontFamily: Inter
    fontSize: 14px
    fontWeight: '400'
    lineHeight: '1.5'
  label-caps:
    fontFamily: Inter
    fontSize: 12px
    fontWeight: '700'
    lineHeight: '1'
    letterSpacing: 0.05em
  data-mono:
    fontFamily: JetBrains Mono
    fontSize: 14px
    fontWeight: '500'
    lineHeight: '1.4'
rounded:
  sm: 0.125rem
  DEFAULT: 0.25rem
  md: 0.375rem
  lg: 0.5rem
  xl: 0.75rem
  full: 9999px
spacing:
  base: 4px
  xs: 4px
  sm: 8px
  md: 16px
  lg: 24px
  xl: 40px
  container-margin: 16px
  gutter: 16px
---

## Brand & Style

The design system is engineered for the high-stakes environment of DGUV V3 electrical testing. It prioritizes utility over decoration, adopting a **Corporate/Modern** aesthetic with an **Industrial** edge. The visual language conveys reliability, precision, and efficiency, ensuring that inspectors can navigate complex data structures with zero ambiguity.

The style utilizes high-contrast interfaces and a structured layout to mirror the rigorous nature of safety compliance. By focusing on clarity and functional density, the design system minimizes cognitive load during field inspections, positioning itself as a tool as dependable as the hardware being tested.

## Colors

The palette is strictly functional, utilizing color as a primary data signal rather than decoration.

- **Primary (Slate/Navy):** Used for structural elements, headers, and primary actions to establish an atmosphere of institutional trust.
- **Surface & Background:** A clean, cool-gray foundation (#F8FAFC) reduces eye strain and provides a high-contrast backdrop for status indicators.
- **Semantic Accents:** These are the most critical colors in the system. 
    - **Success Green:** Reserved exclusively for "Passed" status and safe conditions.
    - **Alert Red:** Used for "Failed" inspections and critical safety violations.
    - **Caution Amber:** Indicates "Maintenance Required" or "Warning" states.
- **Neutral Grays:** Utilized for secondary text, borders, and inactive states to maintain a clear visual hierarchy.

## Typography

The design system uses **Inter** for its exceptional legibility in professional software environments. To emphasize the technical nature of electrical data (serial numbers, voltage readings, and timestamps), **JetBrains Mono** is introduced as a secondary font for specific data values.

- **Hierarchy:** Strong contrast between bold headers and regular body text ensures quick scanning of inspection reports.
- **Data-First:** Use the `data-mono` style for numerical values and technical identifiers to prevent character confusion (e.g., '0' vs 'O').
- **Mobile Readability:** Text never drops below 14px for body content to ensure legibility on handheld devices in varying lighting conditions on-site.

## Layout & Spacing

This design system employs a **fluid-to-fixed grid** hybrid. On mobile devices, a 4-column fluid layout is used with 16px margins. On desktop, a 12-column fixed grid (max-width 1440px) organizes dense technical data.

- **Rhythm:** A 4px baseline grid governs all vertical spacing, ensuring a disciplined, systematic appearance.
- **Density:** High-density layouts are preferred for data tables and equipment lists, while touch-targets for mobile inspection inputs are expanded to a minimum of 44x44px.
- **Tree Structures:** Electrical hierarchies use a systematic indentation of 20px per level to clearly visualize the relationship between distributors, circuits, and appliances.

## Elevation & Depth

To maintain an industrial and functional feel, the design system avoids heavy shadows in favor of **Tonal Layers** and **Low-Contrast Outlines**.

- **Level 0 (Background):** The base layer (#F8FAFC).
- **Level 1 (Cards/Containers):** Flat white surfaces with a 1px border (#E2E8F0).
- **Level 2 (Active/Floating):** Used for active dropdowns or mobile navigation bars, utilizing a very subtle, tight shadow (0px 2px 4px rgba(0, 0, 0, 0.05)) to suggest a slight lift without appearing "airy."
- **Focus States:** High-visibility 2px solid outlines in the primary color indicate active keyboard or touch focus.

## Shapes

The shape language is "Soft" (4px radius), striking a balance between the rigid precision of industrial equipment and the modern friendliness of professional software. 

- **Small Components:** Checkboxes and small tags use a 2px radius for a sharper, more technical look.
- **Standard Components:** Buttons, input fields, and cards use the default 4px radius.
- **Full Rounding:** Only used for "Status Pills" to make them instantly distinguishable from interactive buttons.

## Components

- **Buttons:** Large, high-contrast touch targets. Primary buttons are solid Slate (#1E293B). Secondary actions use ghost styles with 1px borders.
- **Status Badges:** Pill-shaped indicators. "Passed" uses a Success Green background with white text; "Failed" uses Alert Red. These must include both color and a label (e.g., "✓ PASS") to ensure accessibility.
- **Input Fields:** Clearly labeled with `label-caps` typography. Error states are indicated by a 2px Alert Red bottom border.
- **Hierarchical Tree:** Use chevron icons to collapse/expand sections of the electrical grid. Lines connect parent nodes to children to provide a visual "map" of the installation.
- **Progress Indicators:** Linear bars are used for long-form inspections. The bar fills with Success Green as mandatory fields are completed.
- **Inspection Cards:** Each equipment item is housed in a card. The card header features the serial number in `data-mono` and the current status badge in the top-right corner.