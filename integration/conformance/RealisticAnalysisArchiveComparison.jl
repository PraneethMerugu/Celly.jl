const REALISTIC_ARCHIVE_FLOAT_RTOL = 1.0e-10
const REALISTIC_ARCHIVE_FLOAT_ATOL = 1.0e-12

function _test_realistic_archive_number(actual::Real, archived::Real)
    @test isapprox(actual, archived;
        rtol = REALISTIC_ARCHIVE_FLOAT_RTOL,
        atol = REALISTIC_ARCHIVE_FLOAT_ATOL)
end

function test_realistic_analysis_archive(recomputed::AbstractDict,
        archived::AbstractDict)
    @test Set(keys(recomputed)) == Set(keys(archived))
    for table in ("schema", "identity", "multiplicity", "result")
        @test recomputed[table] == archived[table]
    end

    recomputed_endpoints = recomputed["endpoints"]
    archived_endpoints = archived["endpoints"]
    @test length(recomputed_endpoints) == length(archived_endpoints)
    total = length(recomputed_endpoints)
    familywise_alpha = Float64(recomputed["multiplicity"]["familywise_alpha"])
    rank_dependent_fields = Set(("holm_rank", "holm_local_alpha", "adjusted_interval"))

    for (actual, expected) in zip(recomputed_endpoints, archived_endpoints)
        @test Set(keys(actual)) == Set(keys(expected))
        @test (actual["workload"], actual["endpoint"], actual["kind"]) ==
            (expected["workload"], expected["endpoint"], expected["kind"])
        @test actual["passed"] == expected["passed"]

        for field in setdiff(Set(keys(actual)), rank_dependent_fields)
            left, right = actual[field], expected[field]
            if left isa Real && right isa Real
                _test_realistic_archive_number(left, right)
            else
                @test left == right
            end
        end

        actual_rank = actual["holm_rank"]
        expected_rank = expected["holm_rank"]
        _test_realistic_archive_number(actual["holm_local_alpha"],
            familywise_alpha / (total - actual_rank + 1))
        _test_realistic_archive_number(expected["holm_local_alpha"],
            familywise_alpha / (total - expected_rank + 1))

        if actual_rank == expected_rank
            for (left, right) in zip(actual["adjusted_interval"],
                    expected["adjusted_interval"])
                _test_realistic_archive_number(left, right)
            end
        else
            # Numerically tied p-values can exchange adjacent Holm ranks across
            # architectures. The p-value, decision, and rank-derived alpha remain
            # checked above; the corresponding interval is valid for its own rank.
            @test isapprox(actual["raw_equivalence_p"],
                expected["raw_equivalence_p"];
                rtol = REALISTIC_ARCHIVE_FLOAT_RTOL,
                atol = REALISTIC_ARCHIVE_FLOAT_ATOL)
        end
    end
end
