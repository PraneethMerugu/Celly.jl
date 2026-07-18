using Test
using CorePotts

@testset "semantic identifiers and schemas" begin
    @test value(CellID(7)) == UInt32(7)
    @test value(CellTypeID(3)) == UInt32(3)
    @test value(MediumID(2)) == UInt32(2)
    @test value(CellSlot(4)) == UInt32(4)
    @test value(CellGeneration(9)) == UInt64(9)
    @test nslots(CellCapacity(32)) == 32
    @test_throws ArgumentError CellID(0)
    @test_throws ArgumentError MediumID(-1)
    @test_throws ArgumentError CellGeneration(-1)

    portable = portable_numerical_policy()
    @test real_type(portable) === Float32
    @test accumulation_type(portable) === Float32
    @test portable.math isa AccurateMath
    @test portable.reductions isa DeterministicReductions
    @test portable.overflow isa CheckedModelBounds
    wide = NumericalPolicy(Float32, Float64; math = QualifiedFastMath(),
        reductions = TolerantReductions(), overflow = QualifiedUncheckedBounds())
    @test real_type(wide) === Float32
    @test accumulation_type(wide) === Float64

    volume = ComponentIdentity(:volume, v"1.0.0", :energy)
    tracker = ComponentIdentity(:volume_tracker, "1.0.0", :tracker)
    target = PropertyDescriptor(:target_volume, Int32, ConstantInitializer(Int32(0));
        requester = volume)
    same_target = PropertyDescriptor(:target_volume, Int32, ConstantInitializer(Int32(0));
        requester = tracker)
    schema = merge_property_schemas(PropertySchema(target), PropertySchema(same_target))
    @test property_keys(schema) == (:target_volume,)
    @test length(property_requesters(property_descriptor(schema, :target_volume))) == 2

    incompatible = PropertyDescriptor(:target_volume, Float32, ConstantInitializer(0.0f0);
        requester = tracker)
    @test_throws PropertySchemaConflictError merge_property_schemas(
        PropertySchema(target), PropertySchema(incompatible))
    @test_throws ArgumentError PropertyDescriptor(:host_metadata, String,
        ConstantInitializer("not device compatible"); requester = volume)
end
