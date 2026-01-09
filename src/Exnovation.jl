module Exnovation

export BarrierType, Cognitive, Emotional, Behavioral, Structural
export ExnovationItem, Driver, Barrier, DecisionCriteria
export ExnovationAssessment, ExnovationSummary
export sunk_cost_bias_index, exnovation_score, recommendation
export debiasing_actions

@enum BarrierType Cognitive Emotional Behavioral Structural

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

end # module
