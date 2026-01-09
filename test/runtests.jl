using Test
using Exnovation

@testset "Exnovation" begin
    item = ExnovationItem(:Legacy, "Legacy tool", "Operations")

    drivers = [
        Driver(:Risk, 0.6, "High risk"),
        Driver(:Compliance, 0.4, "Regulatory pressure"),
    ]

    barriers = [
        Barrier(Cognitive, 0.5, "Sunk-cost framing"),
        Barrier(Behavioral, 0.2, "Process inertia"),
    ]

    criteria = DecisionCriteria(0.3, 0.3, 0.2, 0.2)

    assessment = ExnovationAssessment(
        item,
        drivers,
        barriers,
        criteria,
        100.0,
        50.0,
        120.0,
        0.4,
        0.6,
        0.7,
    )

    summary = exnovation_score(assessment)
    @test summary.driver_score > 0.0
    @test summary.barrier_score > 0.0
    @test summary.criteria_score > 0.0
    @test summary.sunk_cost_bias > 0.0

    rec = recommendation(assessment)
    @test rec in (:exnovate, :pilot, :defer)

    actions = debiasing_actions(barriers)
    @test !isempty(actions)
end
