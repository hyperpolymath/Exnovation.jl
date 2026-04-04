# SPDX-License-Identifier: MPL-2.0
# (PMPL-1.0-or-later preferred; MPL-2.0 required for Julia ecosystem)
# Property-based tests for Exnovation.jl
# Verifies scoring and decision invariants across randomly generated assessments.

using Test
using Exnovation

@testset "Property-Based Tests" begin

    # Helper: build a random valid assessment
    function rand_assessment()
        item = ExnovationItem(:Item, "Random item", "Dept")
        n_drivers  = rand(0:5)
        n_barriers = rand(0:4)
        drivers  = [Driver(Symbol("D$i"), rand(), "Driver $i") for i in 1:n_drivers]
        btype    = [Cognitive, Behavioral, Political][rand(1:3)]
        barriers = [Barrier(btype, rand(), "Barrier $i") for i in 1:n_barriers]
        w = rand(4); w = w ./ sum(w)
        crit = DecisionCriteria(w[1], w[2], w[3], w[4])
        sunk    = rand() * 1_000_000
        maint   = rand() * 200_000
        replace = rand() * 1_500_000
        ob, td, re = rand(), rand(), rand()
        ExnovationAssessment(item, drivers, barriers, crit, sunk, maint, replace, ob, td, re)
    end

    @testset "Invariant: recommendation is always one of {:exnovate, :pilot, :defer}" begin
        for _ in 1:50
            a = rand_assessment()
            rec = recommendation(a)
            @test rec in (:exnovate, :pilot, :defer)
        end
    end

    @testset "Invariant: driver_score >= 0 always" begin
        for _ in 1:50
            a = rand_assessment()
            s = exnovation_score(a)
            @test s.driver_score >= 0.0
        end
    end

    @testset "Invariant: barrier_score >= 0 always" begin
        for _ in 1:50
            a = rand_assessment()
            s = exnovation_score(a)
            @test s.barrier_score >= 0.0
        end
    end

    @testset "Invariant: sunk_cost_bias >= 0 always" begin
        for _ in 1:50
            a = rand_assessment()
            s = exnovation_score(a)
            @test s.sunk_cost_bias >= 0.0
        end
    end

    @testset "Invariant: higher drivers tend toward :exnovate recommendation" begin
        # With very strong drivers and weak barriers, recommendation should not be :defer
        for _ in 1:50
            item = ExnovationItem(:Test, "Test", "IT")
            drivers  = [Driver(Symbol("D$i"), 0.9 + 0.1 * rand(), "D$i") for i in 1:3]
            barriers = [Barrier(Cognitive, rand() * 0.1, "Weak barrier")]
            crit = DecisionCriteria(0.25, 0.25, 0.25, 0.25)
            a = ExnovationAssessment(item, drivers, barriers, crit,
                                      10.0, 1000.0, 500.0, 0.9, 0.9, 0.9)
            rec = recommendation(a)
            @test rec in (:exnovate, :pilot)  # Should NOT defer with strong drivers
        end
    end

    @testset "Invariant: budget allocation never exceeds n items in portfolio" begin
        for _ in 1:50
            n = rand(1:5)
            items = map(1:n) do i
                item = ExnovationItem(Symbol("I$i"), "Item $i", "Dept")
                a = ExnovationAssessment(item,
                    [Driver(:D, rand(), "D")], [Barrier(Cognitive, rand()*0.3, "B")],
                    DecisionCriteria(0.25, 0.25, 0.25, 0.25),
                    rand()*1000.0, rand()*500.0, rand()*800.0, rand(), rand(), rand())
                fail_crit = IntelligentFailureCriteria(rand(), rand(), rand(), rand(), rand(), rand(), rand())
                fail = FailureAssessment(Intelligent, fail_crit, rand(), rand())
                gov  = RiskGovernance(rand(), rand(), :govern)
                case = ExnovationCase(a, fail, gov)
                impact = ImpactModel(rand()*1000.0, rand()*500.0, rand())
                PortfolioItem(case, impact)
            end
            budget = rand() * 5000.0
            allocated = allocate_budget(items; capex_budget=budget)
            @test length(allocated) <= n
        end
    end

end
