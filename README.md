# Exnovation.jl

Exnovation.jl is a Julia framework for modeling exnovation decisions: phasing
out legacy practices, products, or routines to make room for new innovation.
It is inspired by the conceptual treatment in Holbek & Knudsen (2020) and is
structured to capture drivers, barriers, and decision criteria in a transparent
way.

This package does **not** embed proprietary content; it provides a clean model
and simple scoring helpers so you can encode your own organizational context.

## Core Concepts

- **Exnovation item**: a practice, product, or routine being considered for
  phase-out.
- **Drivers**: forces pushing toward exnovation (e.g., regulatory pressure,
  obsolete technology, sustainability targets).
- **Barriers**: cognitive, emotional, behavioral, or structural resistance.
- **Intelligent failure**: planned experimentation with bounded risk and
  deliberate learning checkpoints.
- **Decision criteria**: weighted factors such as sunk cost bias, strategic fit,
  performance, and risk.
- **Debiasing actions**: prompts to counter sunk-cost and status-quo effects.

## Quick Start

```julia
using Exnovation

item = ExnovationItem(:LegacyCRM, "Legacy CRM system", "Sales operations")

drivers = [
    Driver(:SecurityRisk, 0.7, "Legacy stack has known vulnerabilities"),
    Driver(:Sustainability, 0.4, "Cloud move reduces footprint"),
]

barriers = [
    Barrier(Cognitive, 0.5, "Sunk-cost framing in past investments"),
    Barrier(Behavioral, 0.3, "Habits and routines tied to old workflows"),
]

criteria = DecisionCriteria(0.3, 0.3, 0.2, 0.2)

assessment = ExnovationAssessment(
    item,
    drivers,
    barriers,
    criteria,
    1_200_000.0,  # sunk_cost
    350_000.0,    # forward_value
    900_000.0,    # replacement_value
    0.4,          # strategic_fit (lower is worse)
    0.6,          # performance (lower is worse)
    0.7,          # risk (higher is worse)
)

score = exnovation_score(assessment)
println(score)
println(recommendation(assessment))
```

```julia
# Intelligent failure readiness
criteria = IntelligentFailureCriteria(
    0.9,  # planned_action
    0.7,  # outcome_uncertainty
    0.8,  # modest_scale
    0.9,  # rapid_response
    0.8,  # familiar_context
    0.7,  # explicit_assumptions
    0.8,  # checkpoint_learning
)

failure = FailureAssessment(Intelligent, criteria, 0.6, 0.7)
summary = failure_summary(failure)
println(summary.intelligent_failure_score)
```

## Conceptual Alignment

The model is aligned with ideas from the Holbek & Knudsen manuscript on
exnovation: exnovation as making space for innovation, the role of sunk-cost
bias, and the impact of cognitive, emotional, and behavioral barriers.

It also integrates the Hartley & Knell article on innovation, intelligent
failure, and exnovation by modeling intelligent failure criteria and making
them explicit in the decision flow.

## Development

```bash
julia --project=. -e 'using Pkg; Pkg.instantiate()'
julia --project=. -e 'using Pkg; Pkg.test()'
```
