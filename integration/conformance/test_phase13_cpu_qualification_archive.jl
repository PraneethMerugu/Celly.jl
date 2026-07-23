using TOML
using SHA

@testset "Phase 13 CPU transition qualification archive" begin
    directory = normpath(joinpath(@__DIR__, "..", "..", "design",
        "evidence", "phase-13", "empirical", "cpu"))
    index = TOML.parsefile(joinpath(directory, "index.toml"))
    @test index["status"] == "all-applicable-cpu-transition-rows-pass"
    @test index["eligible_rows"] == index["passed_rows"] == 8
    @test index["failed_rows"] == 0
    @test length(index["artifacts"]) == 8
    identities = Set{Tuple{String, String}}()
    for artifact in index["artifacts"]
        path = joinpath(directory, artifact["file"])
        @test isfile(path)
        @test bytes2hex(sha256(read(path))) == artifact["sha256"]
        record = TOML.parsefile(path)
        report = ProductionEvidenceArchive.validate_production_evidence(record)
        @test report.valid
        @test record["result"]["status"] == "statistical-pass"
        @test record["result"]["qualification_passed"]
        @test record["sampling"]["profile"] == "qualification"
        @test record["sampling"]["replicas"] == 262_144
        @test record["identity"]["source_revision"] == index["source_revision"]
        push!(identities, (record["identity"]["row_id"],
            record["identity"]["algorithm_identity"]))
    end
    @test length(identities) == 8
end
