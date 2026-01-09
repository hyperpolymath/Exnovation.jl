module Exnovation

using JSON3

export BarrierType, Cognitive, Emotional, Behavioral, Structural
export FailureType, Preventable, Unavoidable, Intelligent
export ExnovationItem, Driver, Barrier, DecisionCriteria
export ExnovationAssessment, ExnovationSummary
export IntelligentFailureCriteria, FailureAssessment, FailureSummary
export RiskGovernance, ExnovationCase, DecisionReport
export sunk_cost_bias_index, exnovation_score, recommendation
export debiasing_actions, intelligent_failure_score, failure_summary
export decision_pipeline, write_report_json

@enum BarrierType Cognitive Emotional Behavioral Structural
@enum FailureType Preventable Unavoidable Intelligent

"""
Represents a practice, product, or routine considered for phase-out.
"""
struct ExnovationItem
    name::Symbol
    description::String
    context::String
end

"""
Driver that pushes toward exnovation.
"""
struct Driver
    name::Symbol
    weight::Float64
    description::String
end

"""
Barrier that resists exnovation.
"""
struct Barrier
    kind::BarrierType
    weight::Float64
    description::String
end

"""
Weights for decision criteria. Values are expected in 0..1.
"""
struct DecisionCriteria
    sunk_cost_weight::Float64
    strategic_fit_weight::Float64
    performance_weight::Float64
    risk_weight::Float64
end

"""
Assessment bundle for an exnovation decision.
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

"""
Computed summary for an assessment.
"""
struct ExnovationSummary
    driver_score::Float64
    barrier_score::Float64
    criteria_score::Float64
    total_score::Float64
    sunk_cost_bias::Float64
end

"""
Criteria for intelligent failure: values are expected in 0..1.
"""
struct IntelligentFailureCriteria
    planned_action::Float64
    outcome_uncertainty::Float64
    modest_scale::Float64
    rapid_response::Float64
    familiar_context::Float64
    explicit_assumptions::Float64
    checkpoint_learning::Float64
end

"""
Assessment of a failure or experiment context.
"""
struct FailureAssessment
    failure_type::FailureType
    criteria::IntelligentFailureCriteria
    risk_governance::Float64
    learning_practice::Float64
end

"""
Summary of intelligent failure readiness.
"""
struct FailureSummary
    intelligent_failure_score::Float64
    risk_governance::Float64
    learning_practice::Float64
    failure_type::FailureType
end

"""
Risk governance profile (0..1 values).
"""
struct RiskGovernance
    appetite::Float64
    uncertainty::Float64
    mode::Symbol
end

"""
Complete case for decision-making.
"""
struct ExnovationCase
    assessment::ExnovationAssessment
    failure::Union{FailureAssessment, Nothing}
    risk_governance::RiskGovernance
end

"""
Decision report with summaries and recommendation.
"""
struct DecisionReport
    exnovation::ExnovationSummary
    failure::Union{FailureSummary, Nothing}
    risk_governance::RiskGovernance
    recommendation::Symbol
    notes::Vector{String}
end

function _clamp01(x::Float64)
    clamp(x, 0.0, 1.0)
end

"""
Approximate sunk-cost bias index based on past vs forward value.
"""
function sunk_cost_bias_index(sunk_cost::Float64, forward_value::Float64)
    total = max(sunk_cost + forward_value, 0.0)
    total == 0.0 ? 0.0 : _clamp01(sunk_cost / total)
end

function _driver_score(drivers::Vector{Driver})
    sum(_clamp01(d.weight) for d in drivers)
end

function _barrier_score(barriers::Vector{Barrier})
    sum(_clamp01(b.weight) for b in barriers)
end

function _criteria_score(a::ExnovationAssessment)
    bias = sunk_cost_bias_index(a.sunk_cost, a.forward_value)
    fit = 1.0 - _clamp01(a.strategic_fit)
    perf = 1.0 - _clamp01(a.performance)
    risk = _clamp01(a.risk)

    c = a.criteria
    (c.sunk_cost_weight * bias) +
    (c.strategic_fit_weight * fit) +
    (c.performance_weight * perf) +
    (c.risk_weight * risk)
end

"""
Compute an exnovation summary with separate components.
"""
function exnovation_score(a::ExnovationAssessment)
    dscore = _driver_score(a.drivers)
    bscore = _barrier_score(a.barriers)
    cscore = _criteria_score(a)
    total = dscore + cscore - bscore
    ExnovationSummary(dscore, bscore, cscore, total, sunk_cost_bias_index(a.sunk_cost, a.forward_value))
end

"""
Return a recommendation based on total score.
"""
function recommendation(a::ExnovationAssessment)
    summary = exnovation_score(a)
    if summary.total_score >= 1.0
        return :exnovate
    elseif summary.total_score >= 0.4
        return :pilot
    else
        return :defer
    end
end

"""
Suggest debiasing actions based on barrier types.
"""
function debiasing_actions(barriers::Vector{Barrier})
    actions = String[]
    for barrier in barriers
        if barrier.kind == Cognitive
            push!(actions, "Reframe costs as sunk; compare only forward-looking value.")
            push!(actions, "Use a premortem to surface hidden failure risks.")
        elseif barrier.kind == Emotional
            push!(actions, "Acknowledge identity and attachment; design a ritualized retirement.")
        elseif barrier.kind == Behavioral
            push!(actions, "Replace routines with default alternatives and training.")
        elseif barrier.kind == Structural
            push!(actions, "Adjust incentives and ownership so legacy metrics no longer dominate.")
        end
    end
    unique(actions)
end

"""
Compute an intelligent failure score (0..1) from criteria.
"""
function intelligent_failure_score(criteria::IntelligentFailureCriteria)
    values = (
        criteria.planned_action,
        criteria.outcome_uncertainty,
        criteria.modest_scale,
        criteria.rapid_response,
        criteria.familiar_context,
        criteria.explicit_assumptions,
        criteria.checkpoint_learning,
    )
    sum(_clamp01(v) for v in values) / length(values)
end

"""
Return a structured summary for failure assessment.
"""
function failure_summary(assessment::FailureAssessment)
    FailureSummary(
        intelligent_failure_score(assessment.criteria),
        _clamp01(assessment.risk_governance),
        _clamp01(assessment.learning_practice),
        assessment.failure_type,
    )
end

"""
Run a decision pipeline over an exnovation case.
"""
function decision_pipeline(case::ExnovationCase)
    ex_summary = exnovation_score(case.assessment)
    fail_summary = case.failure === nothing ? nothing : failure_summary(case.failure)
    notes = String[]

    if ex_summary.sunk_cost_bias > 0.6
        push!(notes, "High sunk-cost bias detected; apply debiasing actions.")
    end
    if case.risk_governance.mode == :minimize && case.risk_governance.uncertainty > 0.6
        push!(notes, "High uncertainty with risk-minimization mode; consider risk governance or pilot.")
    end
    if fail_summary !== nothing && fail_summary.intelligent_failure_score < 0.5
        push!(notes, "Experiment setup is weak; improve intelligent failure criteria.")
    end

    DecisionReport(ex_summary, fail_summary, case.risk_governance, recommendation(case.assessment), notes)
end

"""
Write a decision report to JSON.
"""
function write_report_json(path::AbstractString, report::DecisionReport)
    obj = Dict{String, Any}()
    obj["recommendation"] = String(report.recommendation)
    obj["notes"] = report.notes
    obj["risk_governance"] = Dict(
        "appetite" => report.risk_governance.appetite,
        "uncertainty" => report.risk_governance.uncertainty,
        "mode" => String(report.risk_governance.mode),
    )
    obj["exnovation"] = Dict(
        "driver_score" => report.exnovation.driver_score,
        "barrier_score" => report.exnovation.barrier_score,
        "criteria_score" => report.exnovation.criteria_score,
        "total_score" => report.exnovation.total_score,
        "sunk_cost_bias" => report.exnovation.sunk_cost_bias,
    )
    if report.failure !== nothing
        obj["failure"] = Dict(
            "intelligent_failure_score" => report.failure.intelligent_failure_score,
            "risk_governance" => report.failure.risk_governance,
            "learning_practice" => report.failure.learning_practice,
            "failure_type" => String(Symbol(report.failure.failure_type)),
        )
    end
    open(path, "w") do io
        JSON3.write(io, obj)
    end
    nothing
end

end # module
