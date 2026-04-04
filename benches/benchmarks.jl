# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# BenchmarkTools benchmarks for Exnovation.jl
# Measures exnovation scoring, stage gates, and portfolio operations at varying scale.

using BenchmarkTools
using Exnovation

# ── Helper factories ──────────────────────────────────────────────────────────

function make_assessment(n_drivers::Int, n_barriers::Int)
    item = ExnovationItem(:Bench, "Benchmark item", "IT")
    drivers  = [Driver(Symbol("D$i"), 0.5 + 0.1*(i%5), "Driver $i") for i in 1:n_drivers]
    barriers = [Barrier(Cognitive, 0.3, "Barrier $i") for i in 1:n_barriers]
    crit = DecisionCriteria(0.25, 0.25, 0.25, 0.25)
    ExnovationAssessment(item, drivers, barriers, crit,
                          500_000.0, 100_000.0, 300_000.0, 0.6, 0.7, 0.65)
end

function make_portfolio_item(i::Int)
    item = ExnovationItem(Symbol("I$i"), "Item $i", "Dept")
    a = make_assessment(3, 2)
    fail_crit = IntelligentFailureCriteria(0.7, 0.6, 0.8, 0.7, 0.6, 0.7, 0.75)
    fail = FailureAssessment(Intelligent, fail_crit, 0.6, 0.7)
    gov  = RiskGovernance(0.5, 0.6, :govern)
    case = ExnovationCase(a, fail, gov)
    PortfolioItem(case, ImpactModel(300_000.0, 100_000.0, 0.85))
end

# Small: 2 drivers, 2 barriers
a_small  = make_assessment(2, 2)
# Medium: 10 drivers, 5 barriers
a_medium = make_assessment(10, 5)
# Large: 30 drivers, 15 barriers
a_large  = make_assessment(30, 15)

# ── Scoring benchmarks ────────────────────────────────────────────────────────

println("=== exnovation_score (small: 2 drivers) ===")
@benchmark exnovation_score($a_small)

println("=== exnovation_score (medium: 10 drivers) ===")
@benchmark exnovation_score($a_medium)

println("=== exnovation_score (large: 30 drivers) ===")
@benchmark exnovation_score($a_large)

# ── Stage gate benchmarks ─────────────────────────────────────────────────────

gates_small  = [StageGate(:screen, 0.3)]
gates_medium = [StageGate(Symbol("g$i"), i/10.0) for i in 1:5]
gates_large  = [StageGate(Symbol("g$i"), i/20.0) for i in 1:15]

println("=== run_stage_gates (small: 1 gate) ===")
@benchmark run_stage_gates($a_small, $gates_small)

println("=== run_stage_gates (medium: 5 gates) ===")
@benchmark run_stage_gates($a_medium, $gates_medium)

println("=== run_stage_gates (large: 15 gates) ===")
@benchmark run_stage_gates($a_large, $gates_large)

# ── Portfolio benchmarks ──────────────────────────────────────────────────────

portfolio_small  = [make_portfolio_item(i) for i in 1:3]
portfolio_medium = [make_portfolio_item(i) for i in 1:10]
portfolio_large  = [make_portfolio_item(i) for i in 1:30]

println("=== portfolio_scores (small: 3 items) ===")
@benchmark portfolio_scores($portfolio_small)

println("=== portfolio_scores (medium: 10 items) ===")
@benchmark portfolio_scores($portfolio_medium)

println("=== portfolio_scores (large: 30 items) ===")
@benchmark portfolio_scores($portfolio_large)
