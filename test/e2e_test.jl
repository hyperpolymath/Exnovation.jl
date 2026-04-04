# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# E2E pipeline tests for Exnovation.jl
# Tests the full exnovation decision pipeline: assessment → scoring → stage gates
# → portfolio → budget allocation → JSON export.

using Test
using Exnovation

@testset "E2E Pipeline Tests" begin

    @testset "Full pipeline: legacy software retirement decision" begin
        # 1. Define the legacy item
        item = ExnovationItem(:LegacyERP, "ERP system from 2002", "Finance")

        # 2. Build drivers and barriers
        drivers = [
            Driver(:SecurityRisk,   0.85, "Critical CVEs unpatched"),
            Driver(:MaintenanceCost, 0.75, "60% of IT budget on maintenance"),
            Driver(:VendorEOL,       0.90, "Vendor ending support"),
        ]
        barriers = [
            Barrier(Cognitive, 0.6, "Sunk-cost: $12M invested"),
            Barrier(Political,  0.5, "CFO resistance to change"),
            Barrier(Behavioral, 0.3, "Staff process dependency"),
        ]

        # 3. Decision criteria and assessment
        criteria = DecisionCriteria(0.35, 0.25, 0.20, 0.20)
        assessment = ExnovationAssessment(
            item, drivers, barriers, criteria,
            12_000_000.0,  # sunk cost
            3_000_000.0,   # annual maintenance cost
            8_000_000.0,   # replacement cost
            0.7,           # strategic obsolescence
            0.8,           # technical debt
            0.75,          # risk exposure
        )

        # 4. Score the assessment
        score = exnovation_score(assessment)
        @test score.driver_score  > 0.0
        @test score.barrier_score > 0.0
        @test score.sunk_cost_bias > 0.5  # large sunk cost → high bias

        # 5. Recommendation
        rec = recommendation(assessment)
        @test rec in (:exnovate, :pilot, :defer)

        # 6. Debiasing actions
        actions = debiasing_actions(barriers)
        @test !isempty(actions)

        # 7. Failure analysis
        fail_criteria = IntelligentFailureCriteria(0.8, 0.7, 0.9, 0.8, 0.7, 0.8, 0.85)
        failure = FailureAssessment(Intelligent, fail_criteria, 0.7, 0.8)
        fsummary = failure_summary(failure)
        @test fsummary.intelligent_failure_score > 0.0
        @test fsummary.failure_type == Intelligent

        # 8. Full decision pipeline
        case = ExnovationCase(assessment, failure, RiskGovernance(0.6, 0.75, :govern))
        report = decision_pipeline(case)
        @test report.recommendation in (:exnovate, :pilot, :defer)

        # 9. JSON export
        dir = mktempdir()
        path = joinpath(dir, "legacy_erp_report.json")
        write_report_json(path, report)
        @test isfile(path)
        @test filesize(path) > 0

        # 10. Stage gates
        gates = [
            StageGate(:screen,  0.3),
            StageGate(:assess,  0.5),
            StageGate(:commit,  0.7),
            StageGate(:execute, 0.9),
        ]
        gate_results = run_stage_gates(assessment, gates)
        @test length(gate_results) == 4
        @test haskey(gate_results, :screen)
        @test haskey(gate_results, :commit)
    end

    @testset "Full pipeline: portfolio with budget constraint" begin
        item_a = ExnovationItem(:SystemA, "Legacy billing system", "Finance")
        item_b = ExnovationItem(:SystemB, "Old CRM platform",     "Sales")

        make_assessment(item, sunk, maint, replace) = ExnovationAssessment(
            item,
            [Driver(:Risk, 0.7, "Risk driver")],
            [Barrier(Cognitive, 0.3, "Bias")],
            DecisionCriteria(0.25, 0.25, 0.25, 0.25),
            sunk, maint, replace, 0.5, 0.5, 0.5,
        )

        a1 = make_assessment(item_a, 5_000_000.0, 1_000_000.0, 3_000_000.0)
        a2 = make_assessment(item_b, 2_000_000.0, 800_000.0,   2_500_000.0)

        impact1 = ImpactModel(3_000_000.0, 500_000.0, 0.9)
        impact2 = ImpactModel(2_500_000.0, 400_000.0, 0.85)

        fail_crit = IntelligentFailureCriteria(0.7, 0.6, 0.8, 0.7, 0.6, 0.7, 0.75)
        fail = FailureAssessment(Intelligent, fail_crit, 0.6, 0.7)
        gov  = RiskGovernance(0.5, 0.6, :govern)

        case1 = ExnovationCase(a1, fail, gov)
        case2 = ExnovationCase(a2, fail, gov)

        pitem1 = PortfolioItem(case1, impact1)
        pitem2 = PortfolioItem(case2, impact2)

        scores = portfolio_scores([pitem1, pitem2])
        @test length(scores) == 2

        # Allocate with sufficient budget for both
        allocated = allocate_budget([pitem1, pitem2]; capex_budget=6_000_000.0)
        @test allocated isa Vector
        @test length(allocated) <= 2

        # Allocate with only enough for one
        limited = allocate_budget([pitem1, pitem2]; capex_budget=2_600_000.0)
        @test length(limited) <= 1
    end

    @testset "Error handling: edge cases" begin
        item = ExnovationItem(:X, "Item", "Dept")
        # Zero drivers is valid — driver_score should be 0
        a = ExnovationAssessment(item, Driver[], Barrier[], DecisionCriteria(0.25, 0.25, 0.25, 0.25),
                                  0.0, 0.0, 0.0, 0.0, 0.0, 0.0)
        s = exnovation_score(a)
        @test s.driver_score == 0.0
    end

    @testset "Round-trip consistency: recommendation stability" begin
        # Same inputs always produce the same recommendation
        item = ExnovationItem(:Stable, "Stable item", "IT")
        drivers  = [Driver(:D1, 0.8, "Driver")]
        barriers = [Barrier(Cognitive, 0.3, "Barrier")]
        crit = DecisionCriteria(0.25, 0.25, 0.25, 0.25)
        a = ExnovationAssessment(item, drivers, barriers, crit,
                                  1000.0, 500.0, 800.0, 0.5, 0.6, 0.5)

        rec1 = recommendation(a)
        rec2 = recommendation(a)
        @test rec1 == rec2
    end

end
