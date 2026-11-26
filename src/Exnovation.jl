# SPDX-License-Identifier: MPL-2.0
"""
    Exnovation

Decision support for exnovation: the deliberate retirement of legacy systems,
practices and products. An [`ExnovationAssessment`](@ref) weighs *drivers*
(forces pushing for phase-out) against *barriers* (forces resisting it),
scores the result, and maps it to a recommendation (`:exnovate`, `:pilot` or
`:defer`). Higher level helpers cover debiasing, intelligent-failure analysis,
stage gates, portfolio ranking and budget allocation.

All scores are on a `0.0` to `1.0` scale unless stated otherwise.
"""
module Exnovation

using JSON3

include("JSI.jl")
using .JSI

export JustSustainabilityIndex, evaluate_jsi

export ExnovationItem, Driver, Barrier, BarrierType
export Cognitive, Emotional, Behavioral, Structural, Political
export DecisionCriteria, ExnovationAssessment
export exnovation_score, recommendation
export barrier_templates, debiasing_actions
export FailureType, Intelligent, Preventable, Complex
export IntelligentFailureCriteria, FailureAssessment
export intelligent_failure_score, failure_summary
export RiskGovernance, ExnovationCase, decision_pipeline, write_report_json
export StageGate, run_stage_gates
export ImpactModel, PortfolioItem, portfolio_scores, allocate_budget

# ── Helpers ───────────────────────────────────────────────────────────────────

_unit(x::Real) = clamp(Float64(x), 0.0, 1.0)

_mean_weight(xs) = isempty(xs) ? 0.0 : sum(x -> _unit(x.weight), xs) / length(xs)

# ── Core model ────────────────────────────────────────────────────────────────

"""
    ExnovationItem(name, description, context)

A legacy practice, product or routine being considered for phase-out.
`item.id` is an alias for `item.name`.
"""
struct ExnovationItem
    name::Symbol
    description::String
    context::String
end

Base.getproperty(item::ExnovationItem, s::Symbol) =
    s === :id ? getfield(item, :name) : getfield(item, s)
Base.propertynames(::ExnovationItem, private::Bool=false) =
    (:name, :id, :description, :context)

"""
    Driver(name, weight, description)

A force pushing towards phase-out. `weight` is the strength in `[0, 1]`.
"""
struct Driver
    name::Symbol
    weight::Float64
    description::String
end

"""
Categories of barrier that resist phase-out.
"""
@enum BarrierType Cognitive Emotional Behavioral Structural Political

"""
    Barrier(kind, weight, description)

A force resisting phase-out, typed by [`BarrierType`](@ref).
`weight` is the strength in `[0, 1]`.
"""
struct Barrier
    kind::BarrierType
    weight::Float64
    description::String
end

"""
    DecisionCriteria(sunk_cost_weight, strategic_fit_weight, performance_weight, risk_weight)

Relative importance of the four assessment criteria. The weights are
normalised by their sum when scoring, so they need not add up to one.
Keyword construction is also supported.
"""
Base.@kwdef struct DecisionCriteria
    sunk_cost_weight::Float64
    strategic_fit_weight::Float64
    performance_weight::Float64
    risk_weight::Float64
end

"""
    ExnovationAssessment(item, drivers, barriers, criteria,
                         sunk_cost, forward_value, replacement_value,
                         strategic_fit, performance, risk)

Everything known about one exnovation candidate. The last six fields can also
be given as keywords (`replacement_value` defaults to `0.0`):

- `sunk_cost`, `forward_value`, `replacement_value`: monetary amounts
  (already invested, value still to be had from keeping it, cost to replace it)
- `strategic_fit` and `performance` in `[0, 1]`: lower is worse
- `risk` in `[0, 1]`: higher is worse
"""
struct ExnovationAssessment
    item::ExnovationItem
    drivers::Vector{Driver}
    barriers::Vector{Barrier}
    criteria::DecisionCriteria
    sunk_cost::Float64
    forward_value::Float64
    replacement_value::Float64
    strategic_fit::Float64
    performance::Float64
    risk::Float64
end

ExnovationAssessment(item, drivers, barriers, criteria;
                     sunk_cost, forward_value, replacement_value=0.0,
                     strategic_fit, performance, risk) =
    ExnovationAssessment(item, drivers, barriers, criteria, sunk_cost,
                         forward_value, replacement_value, strategic_fit,
                         performance, risk)

"""
    exnovation_score(assessment)

Score an assessment. Returns a named tuple:

- `driver_score`: mean driver weight (`0.0` without drivers)
- `barrier_score`: mean barrier weight (`0.0` without barriers)
- `criteria_score`: criteria-weighted pressure to exnovate, built from the
  sunk-cost drag `1 - sunk_cost_bias`, strategic misfit `1 - strategic_fit`,
  under-performance `1 - performance` and `risk`
- `total_score`: `0.4 * driver_score + 0.3 * (1 - barrier_score) +
  0.3 * criteria_score`
- `sunk_cost_bias`: `sunk_cost / (sunk_cost + forward_value)`, the share of the
  stake that is already spent (`0.0` when both are zero)
"""
function exnovation_score(a::ExnovationAssessment)
    driver_score = _mean_weight(a.drivers)
    barrier_score = _mean_weight(a.barriers)

    sunk = max(a.sunk_cost, 0.0)
    spend = sunk + max(a.forward_value, 0.0)
    sunk_cost_bias = spend > 0 ? sunk / spend : 0.0

    c = a.criteria
    wsum = c.sunk_cost_weight + c.strategic_fit_weight +
           c.performance_weight + c.risk_weight
    criteria_score = wsum > 0 ?
        (c.sunk_cost_weight * (1 - sunk_cost_bias) +
         c.strategic_fit_weight * (1 - _unit(a.strategic_fit)) +
         c.performance_weight * (1 - _unit(a.performance)) +
         c.risk_weight * _unit(a.risk)) / wsum : 0.0

    total_score = 0.4 * driver_score + 0.3 * (1 - barrier_score) + 0.3 * criteria_score
    return (; driver_score, barrier_score, criteria_score, total_score, sunk_cost_bias)
end

const EXNOVATE_THRESHOLD = 0.65
const PILOT_THRESHOLD = 0.45

"""
    recommendation(assessment) -> :exnovate | :pilot | :defer

`:exnovate` when `total_score >= 0.65`, `:pilot` when it is at least `0.45`,
otherwise `:defer`.
"""
function recommendation(a::ExnovationAssessment)
    total = exnovation_score(a).total_score
    return total >= EXNOVATE_THRESHOLD ? :exnovate :
           total >= PILOT_THRESHOLD ? :pilot : :defer
end

# ── Debiasing ─────────────────────────────────────────────────────────────────

"""
    barrier_templates() -> Dict{Symbol,Vector{String}}

Debiasing actions per barrier category, keyed by the lower-case category name
(`:cognitive`, `:emotional`, `:behavioral`, `:structural`, `:political`).
"""
barrier_templates() = Dict{Symbol,Vector{String}}(
    :cognitive => [
        "Reframe the decision around forward-looking value, ignoring spent cost",
        "Run a pre-mortem on the decision to keep the legacy item",
    ],
    :emotional => [
        "Acknowledge the team's attachment and recognise what the legacy item achieved",
        "Define a transition path that preserves what people value in their work",
    ],
    :behavioral => [
        "Introduce the replacement through small default-changing nudges",
        "Retire old routines in stages with a visible cut-over date",
    ],
    :structural => [
        "Map contracts, SLAs and dependencies and sequence their renegotiation",
        "Assign a single owner to unwind each organisational dependency",
    ],
    :political => [
        "Engage stakeholders early and make the decision criteria transparent",
        "Secure an executive sponsor to arbitrate between competing interests",
    ],
)

_template_key(kind::BarrierType) = Symbol(lowercase(string(kind)))

"""
    debiasing_actions(barriers) -> Vector{String}

Debiasing actions for the categories present in `barriers`, strongest
barrier first, without duplicates.
"""
function debiasing_actions(barriers::AbstractVector{Barrier})
    templates = barrier_templates()
    actions = String[]
    for b in sort(barriers; by = b -> b.weight, rev = true)
        for action in templates[_template_key(b.kind)]
            action in actions || push!(actions, action)
        end
    end
    return actions
end

# ── Intelligent failure ───────────────────────────────────────────────────────

"""
Classification of a failure: `Intelligent` failures are worth the learning,
`Preventable` ones are not, and `Complex` ones sit in between.
"""
@enum FailureType Intelligent Preventable Complex

"""
    IntelligentFailureCriteria(new_territory, opportunity_driven, informed_by_knowledge,
                               small_as_possible, clear_hypothesis, learning_captured,
                               safe_to_report)

Seven criteria in `[0, 1]` describing how close a failure is to an
intelligent failure.
"""
struct IntelligentFailureCriteria
    new_territory::Float64
    opportunity_driven::Float64
    informed_by_knowledge::Float64
    small_as_possible::Float64
    clear_hypothesis::Float64
    learning_captured::Float64
    safe_to_report::Float64
end

"""
    FailureAssessment(type, criteria, learning_value, containment)

A failure (or possible failure) of an exnovation step, with the learning it
yields and how well it is contained, both in `[0, 1]`.
"""
struct FailureAssessment
    type::FailureType
    criteria::IntelligentFailureCriteria
    learning_value::Float64
    containment::Float64
end

_failure_credit(t::FailureType) = t == Intelligent ? 1.0 : t == Complex ? 0.5 : 0.0

"""
    intelligent_failure_score(failure)

`0.6 * mean(criteria) + 0.2 * learning_value + 0.2 * containment`, scaled by
the credit of the failure type (`Intelligent` 1.0, `Complex` 0.5,
`Preventable` 0.0).
"""
function intelligent_failure_score(f::FailureAssessment)
    c = f.criteria
    mean_criteria = sum(_unit, (c.new_territory, c.opportunity_driven,
                                c.informed_by_knowledge, c.small_as_possible,
                                c.clear_hypothesis, c.learning_captured,
                                c.safe_to_report)) / 7
    raw = 0.6 * mean_criteria + 0.2 * _unit(f.learning_value) + 0.2 * _unit(f.containment)
    return raw * _failure_credit(f.type)
end

"""
    failure_summary(failure)

Named tuple with `failure_type`, `intelligent_failure_score`,
`learning_value` and `containment`.
"""
failure_summary(f::FailureAssessment) = (
    failure_type = f.type,
    intelligent_failure_score = intelligent_failure_score(f),
    learning_value = f.learning_value,
    containment = f.containment,
)

# ── Decision pipeline ─────────────────────────────────────────────────────────

"""
    RiskGovernance(risk_appetite, oversight, posture)

Governance context: appetite and oversight in `[0, 1]`, and a free-form
`posture` symbol such as `:govern`, `:balanced`, `:minimize` or `:maximize`.
Oversight of `0.7` or more makes the pipeline stage an `:exnovate`
recommendation as a pilot.
"""
struct RiskGovernance
    risk_appetite::Float64
    oversight::Float64
    posture::Symbol
end

"""
    ExnovationCase(assessment, failure, governance)

An assessment with its optional failure analysis (`nothing` to omit) and
governance context.
"""
struct ExnovationCase
    assessment::ExnovationAssessment
    failure::Union{Nothing,FailureAssessment}
    governance::RiskGovernance
end

const OVERSIGHT_PILOT_THRESHOLD = 0.7

"""
    decision_pipeline(case)

Run scoring, failure analysis and governance for `case`. Returns a named tuple
with `item`, `recommendation`, `exnovation` (the [`exnovation_score`](@ref)
result), `failure` (a [`failure_summary`](@ref) with the type as a string, or
`nothing`), `governance` and human-readable `notes`. Every field is plain data,
so the report serialises directly with [`write_report_json`](@ref).
"""
function decision_pipeline(case::ExnovationCase)
    a = case.assessment
    score = exnovation_score(a)
    rec = recommendation(a)
    notes = String[]

    if score.sunk_cost_bias > 0.6
        push!(notes, "High sunk cost bias: judge the item on forward-looking value only.")
    end
    if score.barrier_score > 0.5
        push!(notes, "Strong barriers: apply the debiasing actions before committing.")
    end
    if a.replacement_value > a.forward_value
        push!(notes, "Replacement cost exceeds the remaining value of the incumbent.")
    end

    failure = nothing
    if case.failure !== nothing
        fs = failure_summary(case.failure)
        failure = merge(fs, (failure_type = string(fs.failure_type),))
        if fs.intelligent_failure_score >= 0.7
            push!(notes, "Failure risk qualifies as an intelligent failure: proceed and capture the learning.")
        else
            push!(notes, "Failure risk is below the intelligent-failure bar: tighten containment first.")
        end
    end

    gov = case.governance
    if rec == :exnovate && gov.oversight >= OVERSIGHT_PILOT_THRESHOLD
        rec = :pilot
        push!(notes, "Governance oversight requires a pilot before full exnovation.")
    end

    return (
        item = a.item.name,
        recommendation = rec,
        exnovation = score,
        failure = failure,
        governance = (risk_appetite = gov.risk_appetite,
                      oversight = gov.oversight,
                      posture = gov.posture),
        notes = notes,
    )
end

"""
    write_report_json(path, report)

Write a [`decision_pipeline`](@ref) report to `path` as pretty-printed JSON.
"""
function write_report_json(path::AbstractString, report)
    open(path, "w") do io
        JSON3.pretty(io, report)
    end
    return path
end

# ── Stage gates ───────────────────────────────────────────────────────────────

"""
    StageGate(name, threshold)

A gate passed when the assessment's `total_score` reaches `threshold`.
"""
struct StageGate
    name::Symbol
    threshold::Float64
end

"""
    run_stage_gates(assessment, gates) -> Dict{Symbol,Bool}

Whether the assessment passes each gate, keyed by gate name.
"""
function run_stage_gates(a::ExnovationAssessment, gates::AbstractVector{StageGate})
    total = exnovation_score(a).total_score
    return Dict{Symbol,Bool}(g.name => total >= g.threshold for g in gates)
end

# ── Portfolio ─────────────────────────────────────────────────────────────────

"""
    ImpactModel(capex, opex, public_value)

Cost of acting (`capex` up front, `opex` per year) and the public value in
`[0, 1]` gained by doing so.
"""
struct ImpactModel
    capex::Float64
    opex::Float64
    public_value::Float64
end

"""
    PortfolioItem(case, impact)

One candidate in a portfolio.
"""
struct PortfolioItem
    case::ExnovationCase
    impact::ImpactModel
end

_name(p::PortfolioItem) = p.case.assessment.item.name

_scores(p::PortfolioItem) =
    (_name(p), exnovation_score(p.case.assessment).total_score, _unit(p.impact.public_value))

"""
    portfolio_scores(items)

Vector of `(name, exnovation_score, impact_score)` tuples, highest combined
score first. The exnovation score is the assessment's `total_score` and the
impact score is the item's `public_value`.
"""
function portfolio_scores(items::AbstractVector{PortfolioItem})
    return sort!(map(_scores, items); by = r -> r[2] + r[3], rev = true)
end

"""
    allocate_budget(items; capex_budget)

Names of the items to fund within `capex_budget`. Items are taken in order of
combined score per unit of capex, skipping any that no longer fit.
"""
function allocate_budget(items::AbstractVector{PortfolioItem}; capex_budget::Real)
    density(p) = let (_, e, i) = _scores(p)
        (e + i) / max(p.impact.capex, eps())
    end
    remaining = Float64(capex_budget)
    selected = Symbol[]
    for p in sort(items; by = density, rev = true)
        if p.impact.capex <= remaining
            push!(selected, _name(p))
            remaining -= p.impact.capex
        end
    end
    return selected
end

end # module
