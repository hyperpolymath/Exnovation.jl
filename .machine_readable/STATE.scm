;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm for Exnovation.jl
;; Format: https://github.com/hyperpolymath/elegant-STATE

(define state
  '((metadata
     (project . "Exnovation.jl")
     (version . "1.0.0")
     (updated . "2026-02-12")
     (maintainers . ("Jonathan D.A. Jewell <jonathan.jewell@open.ac.uk>")))

    (project-context
     (description . "Framework for measuring and accelerating legacy system retirement")
     (domain . "sociotechnical-systems")
     (languages . ("Julia"))
     (primary-purpose . "Quantify and manage organizational exnovation processes"))

    (current-position
     (phase . "beta")
     (overall-completion . 85)
     (working-features
       "ExnovationItem and core types"
       "Driver and Barrier enums (including Political)"
       "Functional barrier assessment"
       "Sunk cost bias detection"
       "Intelligent failure assessment"
       "Debiasing action recommendations"
       "Value-at-risk calculations"
       "API documentation with Documenter.jl"
       "Comprehensive test suite (32 tests)"
       "Quick Start examples"))

    (route-to-mvp
     (completed-milestones
       "Core types and enums"
       "Barrier scoring and categorization"
       "Debiasing logic for all barrier types"
       "Intelligent failure concepts"
       "Documentation and examples"
       "Political barrier support added"
       "RSR template cleanup completed"
       "License headers fixed (PMPL-1.0-or-later)")
     (next-milestones
       "Input validation for public API"
       "Performance benchmarks"
       "Integration examples with real systems"
       "Case studies from industry"))

    (blockers-and-issues
     (technical-debt
       "Input validation needs to be added"
       "Permissions missing in CI workflow")
     (known-issues
       "None currently - 32/32 tests passing"))

    (critical-next-actions
     (immediate
       "Complete remaining SONNET-TASKS (8-14)"
       "Add input validation to public API"
       "Fix CI workflow permissions"
       "Push to remotes")
     (short-term
       "Add performance benchmarks"
       "Create integration examples"
       "Write case studies")
     (long-term
       "Build ecosystem of exnovation metrics"
       "Integrate with organizational change frameworks"
       "Research validation studies"))

    (session-history
     (sessions
       ((date . "2026-02-12")
        (agent . "Claude Sonnet 4.5")
        (summary . "Fixed Political barrier, updated docs, cleaned RSR template, started SCM files")
        (completion-delta . +13))))))

;; Helper functions for querying state

(define (get-completion-percentage state)
  (cdr (assoc 'overall-completion (assoc 'current-position state))))

(define (get-blockers state)
  (cdr (assoc 'blockers-and-issues state)))

(define (get-next-actions state)
  (cdr (assoc 'critical-next-actions state)))
