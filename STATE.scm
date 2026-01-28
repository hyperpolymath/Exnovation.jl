;; SPDX-License-Identifier: PMPL-1.0-or-later
;; STATE.scm - Current project state snapshot
;; Media-Type: application/vnd.state+scm

(define state
  '((metadata
     (version "0.1.0")
     (schema-version "1.0.0")
     (created "2025-01-28")
     (updated "2025-01-28")
     (project "Exnovation.jl")
     (repo "hyperpolymath/Exnovation.jl"))

    (project-context
     (name "Exnovation.jl")
     (tagline "Strategic removal framework for phasing out legacy practices")
     (tech-stack
      (language "Julia 1.9+")
      (dependencies "JSON3")
      (testing "Test stdlib")))

    (current-position
     (phase "Production")
     (overall-completion 95)
     (components
      ((name "Core modeling")
       (completion 100)
       (status "Complete"))
      ((name "Decision criteria")
       (completion 100)
       (status "Complete"))
      ((name "Intelligent failure assessment")
       (completion 100)
       (status "Complete"))
      ((name "Portfolio management")
       (completion 100)
       (status "Complete"))
      ((name "JSON export")
       (completion 100)
       (status "Complete"))
      ((name "Stage gates")
       (completion 100)
       (status "Complete"))
      ((name "Documentation")
       (completion 85)
       (status "Good coverage, examples present"))
      ((name "Test coverage")
       (completion 90)
       (status "Core functionality tested"))))

     (working-features
      "ExnovationItem and ExnovationAssessment modeling"
      "Driver and barrier framework (5 barrier types)"
      "Sunk-cost bias calculation"
      "Decision criteria scoring (4 weighted factors)"
      "Intelligent failure criteria (7-factor model)"
      "Risk governance integration"
      "Decision pipeline with debiasing actions"
      "Portfolio scoring and budget allocation"
      "Stage-gate checkpoints"
      "JSON report export"
      "Barrier templates"))

    (route-to-mvp
     (status "MVP Achieved")
     (milestones
      ((id "M1")
       (name "Core framework")
       (status "Complete")
       (completion 100)
       (items
        "ExnovationItem, Driver, Barrier structs"
        "DecisionCriteria model"
        "Basic scoring functions"))
      ((id "M2")
       (name "Intelligent failure integration")
       (status "Complete")
       (completion 100)
       (items
        "IntelligentFailureCriteria (7 factors)"
        "FailureAssessment and summary"
        "Integration with decision pipeline"))
      ((id "M3")
       (name "Decision support")
       (status "Complete")
       (completion 100)
       (items
        "Recommendation logic (exnovate/pilot/defer)"
        "Debiasing actions"
        "Risk governance modeling"
        "Notes generation"))
      ((id "M4")
       (name "Portfolio features")
       (status "Complete")
       (completion 100)
       (items
        "ImpactModel (capex/opex/public value)"
        "Portfolio scoring"
        "Budget allocation algorithm"))
      ((id "M5")
       (name "Production polish")
       (status "In Progress")
       (completion 90)
       (items
        "JSON export"
        "Stage-gate system"
        "Barrier templates"
        "Comprehensive tests"
        "README documentation"))))

    (blockers-and-issues
     (critical ())
     (high ())
     (medium
      ((id "I1")
       (title "Academic citation integration")
       (description "Add formal citations for Holbek & Knudsen (2020) and Hartley & Knell framework")
       (impact "Documentation completeness"))
      ((id "I2")
       (title "Extended examples")
       (description "More real-world case studies in docs")
       (impact "User adoption")))
     (low
      ((id "I3")
       (title "Visualization helpers")
       (description "Plot.jl integration for barrier/driver visualization")
       (impact "Nice-to-have for analysis"))))

    (critical-next-actions
     (immediate
      "Package is production-ready, monitor for user feedback")
     (this-week
      "Add academic citations to README"
      "Consider extended examples documentation")
     (this-month
      "Gather feedback from organizational decision-making users"
      "Evaluate integration with BowtieRisk.jl"
      "Consider visualization layer"))

    (session-history
     ((timestamp "2025-01-28")
      (accomplishments
       "Initial STATE.scm creation"
       "Analyzed complete codebase"
       "Documented 95% completion status")))))

;; Helper functions

(define (get-completion-percentage state)
  "Return overall project completion as integer"
  (let ((pos (assoc 'current-position state)))
    (cadr (assoc 'overall-completion pos))))

(define (get-blockers state severity)
  "Return list of blockers with given severity"
  (let* ((blockers (assoc 'blockers-and-issues state))
         (level (assoc severity blockers)))
    (if level (cadr level) '())))

(define (get-milestone state milestone-id)
  "Return milestone data by ID"
  (let* ((route (assoc 'route-to-mvp state))
         (milestones (cadr (assoc 'milestones route))))
    (find (lambda (m) (equal? (cadr (assoc 'id m)) milestone-id))
          milestones)))
