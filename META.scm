;; SPDX-License-Identifier: PMPL-1.0-or-later
;; META.scm - Meta-level information and architectural decisions
;; Media-Type: application/meta+scheme

(define meta
  '((project
     (name "Exnovation.jl")
     (tagline "Strategic removal framework for organizational decisions")
     (license "PMPL-1.0-or-later")
     (author "Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>"))

    (architecture-decisions
     ((adr-001
       (status "accepted")
       (date "2024")
       (title "Struct-based immutable modeling")
       (context "Need clear, type-safe representation of exnovation concepts")
       (decision "Use Julia structs for all domain concepts (ExnovationItem,
                  Driver, Barrier, etc.). No mutable state. Scoring functions
                  are pure and return new summary objects.")
       (consequences "Positive: Type safety, clear API boundaries, easy testing.
                      Negative: Cannot mutate assessments in-place (but this
                      aligns with functional style)."))

      (adr-002
       (status "accepted")
       (date "2024")
       (title "Barrier taxonomy with 5 types")
       (context "Organizations face different kinds of resistance to exnovation")
       (decision "Model barriers as enum with 5 types: Cognitive, Emotional,
                  Behavioral, Structural, Political. Each barrier has a type,
                  weight (0..1), and description.")
       (consequences "Positive: Clear taxonomy aligns with academic literature.
                      Specific debiasing actions per barrier type.
                      Negative: 5 types may not cover all cases, but provides
                      good starting taxonomy."))

      (adr-003
       (status "accepted")
       (date "2024")
       (title "Weighted decision criteria")
       (context "Multiple factors influence exnovation decisions with varying importance")
       (decision "Use DecisionCriteria struct with 4 weights: sunk_cost,
                  strategic_fit, performance, risk. Users set weights explicitly.
                  Total score = drivers + criteria - barriers.")
       (consequences "Positive: Explicit weights make trade-offs transparent.
                      Negative: Requires users to set weights thoughtfully."))

      (adr-004
       (status "accepted")
       (date "2024")
       (title "Intelligent failure integration")
       (context "Academic framework (Hartley & Knell) provides criteria for
                 intelligent failure vs preventable/unavoidable")
       (decision "Implement 7-factor intelligent failure criteria: planned_action,
                  outcome_uncertainty, modest_scale, rapid_response, familiar_context,
                  explicit_assumptions, checkpoint_learning. Score 0..1 for each.")
       (consequences "Positive: Direct implementation of published framework.
                      Makes experimentation readiness explicit.
                      Negative: 7 factors may feel complex for some users."))

      (adr-005
       (status "accepted")
       (date "2024")
       (title "Three-tier recommendation system")
       (context "Decisions need actionable categorization")
       (decision "Recommendations: :exnovate (score >= 1.0), :pilot (0.4-1.0),
                  :defer (< 0.4). Thresholds based on total score.")
       (consequences "Positive: Simple, actionable categories.
                      Negative: Thresholds are somewhat arbitrary, but provide
                      reasonable defaults."))

      (adr-006
       (status "accepted")
       (date "2024")
       (title "JSON export for integration")
       (context "Decision reports need to be consumed by other systems")
       (decision "Provide write_report_json function that exports DecisionReport
                  to JSON with nested structure for exnovation, failure, and
                  risk governance summaries.")
       (consequences "Positive: Standard format for integration with dashboards,
                      databases, or other tools.
                      Negative: JSON lacks semantic richness of native Julia types."))

      (adr-007
       (status "accepted")
       (date "2024")
       (title "Portfolio management with impact model")
       (context "Organizations often evaluate multiple exnovation candidates")
       (decision "ImpactModel captures capex, opex, and public_value. Portfolio
                  items combine case + impact. Scoring ranks by total_score +
                  impact_score. Budget allocation is greedy (highest score first).")
       (consequences "Positive: Simple portfolio prioritization.
                      Negative: Greedy allocation may not be globally optimal.
                      Could add constraint solver in future."))

      (adr-008
       (status "accepted")
       (date "2024")
       (title "Stage-gate checkpoints")
       (context "Organizations often have governance stages for major decisions")
       (decision "StageGate struct with name and threshold. run_stage_gates
                  returns pass/fail for each gate based on total score.")
       (consequences "Positive: Flexible governance integration.
                      Negative: Only checks total score, not individual components.
                      Could extend to check specific criteria."))

      (adr-009
       (status "accepted")
       (date "2024")
       (title "Minimal dependencies")
       (context "Package should be lightweight and easy to install")
       (decision "Only depend on JSON3 for export. Use Julia stdlib for everything else.")
       (consequences "Positive: Fast installation, minimal version conflicts.
                      Negative: No built-in plotting or advanced features.
                      Users can integrate with Plots.jl or Makie.jl separately."))

      (adr-010
       (status "accepted")
       (date "2024")
       (title "Clamping for robustness")
       (context "User input may exceed expected 0..1 ranges")
       (decision "Clamp all weights and scores to 0..1 using _clamp01 helper.
                  Prevents unbounded scores from breaking logic.")
       (consequences "Positive: Robust to input errors.
                      Negative: Silently corrects invalid input (no warnings).
                      Could add validation layer in future.")))

    (development-practices
     (code-style
      "Follow Julia best practices: lowercase with underscores, CamelCase for types"
      "Pure functions where possible; avoid mutable state"
      "Docstrings for all public functions"
      "SPDX license header in all source files")

     (security
      "No external network calls or file system access beyond JSON export"
      "No eval or code generation"
      "All dependencies pinned in Project.toml")

     (testing
      "Test suite in test/runtests.jl"
      "Coverage of core scoring logic, decision pipeline, portfolio management"
      "Use @testset for organization")

     (versioning
      "Semantic versioning (SemVer)"
      "0.1.0 indicates initial stable API"
      "Breaking changes will bump major version")

     (documentation
      "README.adoc as primary documentation"
      "Code examples in README show common workflows"
      "Docstrings provide API reference"
      "Documenter.jl setup in docs/")

     (branching
      "Main branch is stable"
      "Feature branches for new work"
      "PRs required for changes"))

    (design-rationale
     (why-julia
      "Strong numerical computing foundation for scoring algorithms"
      "Type system provides safety without verbosity"
      "Easy integration with data science ecosystem"
      "REPL-friendly for interactive exploration")

     (why-structs-not-objects
      "Julia structs with methods provide clear separation of data and behavior"
      "Immutability aligns with decision-making snapshots"
      "Easier to reason about and test than mutable objects")

     (why-enums-for-types
      "BarrierType and FailureType enums provide type safety and exhaustiveness"
      "Prevents typos and invalid categories"
      "Clear in function signatures")

     (why-separate-summary-types
      "ExnovationSummary and FailureSummary separate computed results from inputs"
      "Makes it clear what is user-provided vs calculated"
      "Easier to extend calculations without changing input structs")

     (why-sunk-cost-bias-explicit
      "Behavioral economics research shows sunk-cost bias is a major barrier"
      "Making it a first-class metric highlights its importance"
      "Provides automatic calculation rather than requiring users to estimate")

     (why-debiasing-actions
      "Decision support should include actionable interventions"
      "Different barrier types require different debiasing strategies"
      "Prompts users to address psychological and structural issues")

     (why-three-recommendations
      "More than 3 categories feels over-engineered"
      "Fewer than 3 lacks nuance (binary exnovate/defer is too coarse)"
      "Pilot provides a middle ground for experimentation")

     (why-portfolio-features
      "Organizations rarely make isolated decisions"
      "Portfolio view enables strategic prioritization"
      "Budget allocation makes resource constraints explicit")

     (why-json-export
      "JSON is lingua franca for system integration"
      "Enables dashboard visualization, database storage, API consumption"
      "Simple to implement with JSON3.jl"))))
