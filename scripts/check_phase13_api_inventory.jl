using TOML

const ROOT = normpath(joinpath(@__DIR__, ".."))
const INVENTORY = joinpath(
    ROOT, "design", "audits", "phase-13-api-inventory.toml")

include(joinpath(@__DIR__, "generate_phase13_api_inventory.jl"))

isfile(INVENTORY) || error("missing generated Phase 13 API inventory")
committed = read(INVENTORY)
mktempdir() do directory
    regenerated_path = joinpath(directory, "phase-13-api-inventory.toml")
    open(regenerated_path, "w") do io
        TOML.print(io, build_inventory(); sorted = true)
    end
    regenerated = read(regenerated_path)
    committed == regenerated || error(
        "Phase 13 API inventory is stale; regenerate it with " *
        "`julia --project=. --startup-file=no scripts/generate_phase13_api_inventory.jl --force`")
end

inventory = TOML.parsefile(INVENTORY)
for module_name in ("CorePotts", "PottsToolkit")
    module_inventory = inventory["modules"][module_name]
    isempty(module_inventory["undocumented_stable"]) || error(
        "$module_name has undocumented stable API: " *
        join(module_inventory["undocumented_stable"], ", "))
    sum(values(module_inventory["counts"])) == module_inventory["export_count"] ||
        error("$module_name API classifications do not cover every export")
end

println("Phase 13 API inventory is current, exhaustive, and every stable binding is documented")
