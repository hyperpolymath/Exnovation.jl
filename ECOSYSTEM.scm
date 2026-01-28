;; SPDX-License-Identifier: PMPL-1.0-or-later
;; ECOSYSTEM.scm - Project ecosystem positioning
;; Media-Type: application/vnd.ecosystem+scm

(ecosystem
 (metadata
  (version "1.0.0")
  (created "2025-01-28")
  (updated "2025-01-28"))

 (project
  (name "Exnovation.jl")
  (version "0.1.0")
  (type "library")
  (purpose "Strategic removal framework for organizational decision-making"))

 (position-in-ecosystem
  "Exnovation.jl provides a structured approach to deciding what to phase out,
   stop, or remove from an organization. It complements innovation frameworks by
   modeling the forces (drivers and barriers) that affect exnovation decisions.

   The package integrates intelligent failure theory to ensure that planned
   removals are undertaken with appropriate risk governance and learning
   mechanisms. It is conceptually grounded in academic research on exnovation
   and intelligent failure (Holbek & Knudsen; Hartley & Knell).

   Within the hyperpolymath ecosystem, it is a sibling to BowtieRisk.jl,
   sharing decision-making DNA but focused on removal rather than prevention.
   It provides portfolio tools for prioritizing multiple exnovation candidates
   and allocating budget to the highest-value initiatives.")

 (related-projects
  ((project "BowtieRisk.jl")
   (relationship "sibling-standard")
   (connection "Both model structured decision-making; BowtieRisk focuses on
                threat prevention and consequence mitigation, Exnovation focuses
                on strategic removal of legacy practices. Both use barrier models
                and risk governance. Potential for shared vocabulary."))

  ((project "Causals.jl")
   (relationship "potential-consumer")
   (connection "Causals.jl could consume exnovation outcomes to model causal
                impact of removal decisions. For example, analyzing how phasing
                out a legacy system affects organizational performance metrics."))

  ((project "HackenbushGames.jl")
   (relationship "inspiration")
   (connection "Game-theoretic models of removal (cutting edges in Hackenbush)
                inspired strategic thinking about what to remove. Exnovation
                formalizes this in organizational contexts."))

  ((project "KnotTheory.jl")
   (relationship "distant-cousin")
   (connection "Topological thinking about untangling complexity parallels
                the conceptual work of identifying what to remove to simplify
                organizational structures."))

  ((project "Holbek & Knudsen (2020)")
   (relationship "academic-foundation")
   (connection "Conceptual source for exnovation theory: sunk-cost bias,
                cognitive/emotional/behavioral barriers, and the relationship
                between exnovation and innovation."))

  ((project "Hartley & Knell")
   (relationship "academic-foundation")
   (connection "Source for intelligent failure framework: planned action,
                outcome uncertainty, modest scale, rapid response, familiar
                context, explicit assumptions, checkpoint learning.")))

 (what-this-is
  "A Julia library for modeling exnovation decisions"
  "A framework for identifying drivers and barriers to phase-out"
  "An intelligent failure assessment tool"
  "A portfolio management system for prioritizing removals"
  "A decision pipeline with debiasing actions"
  "A tool for calculating sunk-cost bias and strategic fit")

 (what-this-is-not
  "Not an innovation management framework (it models removal, not creation)"
  "Not a general project management tool (focused on exnovation decisions)"
  "Not a financial forecasting system (uses simple capex/opex models)"
  "Not a risk prevention tool (that's BowtieRisk.jl; this is about strategic removal)"
  "Not a data collection platform (you supply your own organizational data)"
  "Not a prescriptive system (it supports decisions, not automates them)"
  "Not a replacement for human judgment (it structures analysis, not replaces it)"))
