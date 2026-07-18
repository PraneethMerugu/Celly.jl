using KernelAbstractions

@kernel function _rng_probe_kernel!(output, addresses, contract, seed)
    index = @index(Global, Linear)
    if index <= length(addresses)
        words = rng_words(contract, seed, addresses[index])
        base = 4 * (index - 1)
        output[base + 1] = words[1]
        output[base + 2] = words[2]
        output[base + 3] = words[3]
        output[base + 4] = words[4]
    end
end

@testset "Philox4x32-10 raw known answers" begin
    @test philox4x32_10(ntuple(_ -> UInt32(0), 4), ntuple(_ -> UInt32(0), 2)) ==
          (0x6627e8d5, 0xe169c58d, 0xbc57ac4c, 0x9b00dbd8)
    @test philox4x32_10(ntuple(_ -> typemax(UInt32), 4),
        ntuple(_ -> typemax(UInt32), 2)) ==
          (0x408f276d, 0x41c83b0e, 0xa20bc7c6, 0x6d5451fd)
    @test philox4x32_10(
        (0x243f6a88, 0x85a308d3, 0x13198a2e, 0x03707344),
        (0xa4093822, 0x299f31d0)) ==
          (0xd16cfe09, 0x94fdcceb, 0x5001e420, 0x24126ea1)
end

@testset "semantic RNG address contract" begin
    contract = Philox4x32x10V1()
    seed = UInt64(0x0123456789abcdef)
    address = RNGAddress(stream = ProposalRecipientStream, mcs = 17, subround = 2,
        operation = 33, entity_kind = SiteEntity, entity = 91, invocation = 4, draw = 7)
    counter0, counter1, key = rng_counter_key(contract, seed, address)
    @test counter0 == 0x0402000000000011
    @test counter1 == 0x01d030210000005b
    @test key == 0x5b145ecefa74362b
    @test rng_words(contract, seed, address) ==
          (0x5b00c369, 0x92f3ce04, 0x12df44ce, 0x8daeafe9)
    @test rng_contract_version(contract) == v"1.0.0"

    reused = RNGAddress(stream = EventStream, mcs = 4, operation = 2,
        entity_kind = CellEntity, entity = 8, generation = 3)
    former = RNGAddress(stream = EventStream, mcs = 4, operation = 2,
        entity_kind = CellEntity, entity = 8, generation = 2)
    @test rng_words(contract, seed, reused) != rng_words(contract, seed, former)
    @test_throws ArgumentError RNGAddress(stream = EventStream, entity_kind = SiteEntity,
        generation = 1)
    @test_throws ArgumentError RNGAddress(stream = EventStream, operation = 4096)
    @test_throws ArgumentError RNGAddress(stream = EventStream, draw = 1024)
end

@testset "portable primitive distributions" begin
    contract = Philox4x32x10V1()
    seed = UInt64(77)
    address = RNGAddress(stream = AcceptanceStream, mcs = 9,
        operation = 1, entity_kind = SiteEntity, entity = 12)
    value32 = uniform_open01(Float32, contract, seed, address)
    value64 = uniform_open01(Float64, contract, seed, address)
    @test 0.0f0 < value32 < 1.0f0
    @test 0.0 < value64 < 1.0
    @test bounded_uint(contract, seed, address, UInt32(7)) < 7
    @test !bernoulli(contract, seed, address, 0.0f0)
    @test bernoulli(contract, seed, address, 1.0f0)
    @test_throws ArgumentError bernoulli(contract, seed, address, -0.1f0)
    @test_throws ArgumentError bounded_uint(contract, seed, address, UInt32(0))

    normal32 = normal_box_muller(Float32, contract, seed, address)
    normal64 = normal_box_muller(Float64, contract, seed, address)
    @test isfinite(normal32)
    @test isfinite(normal64)
    @test poisson_inversion(contract, seed, address, 0.0) == 0
    @test poisson_inversion(contract, seed, address, 4.0) >= 0
    @test poisson_normal_approx(contract, seed, address, 100.0) >= 0
    @test_throws ArgumentError poisson_inversion(contract, seed, address, 65.0)

    table = CategoricalTable((1.0f0, 2.0f0, 3.0f0))
    @test 1 <= categorical_index(table, contract, seed, address) <= 3
    @test_throws ArgumentError CategoricalTable((0.0f0, 0.0f0))
    permutation = zeros(UInt16, 8)
    @test sort(small_permutation!(permutation, contract, seed, address)) == UInt16.(1:8)
    @test small_permutation!(zeros(UInt16, 8), contract, seed, address) == permutation
    @test distribution_profile(contract, uniform_open01).portability === :bitwise
    @test distribution_profile(contract, normal_box_muller).portability === :statistical
end

@testset "distribution moments" begin
    contract = Philox4x32x10V1()
    seed = UInt64(0x12345678)
    sample_count = 50_000
    normals = Vector{Float64}(undef, sample_count)
    poisson = Vector{Int}(undef, sample_count)
    for index in 1:sample_count
        address = RNGAddress(stream = HSTStream, mcs = index, operation = 1,
            entity_kind = GlobalEntity)
        normals[index] = normal_box_muller(Float64, contract, seed, address)
        poisson[index] = poisson_inversion(contract, seed, address, 4.0)
    end
    @test abs(sum(normals) / sample_count) < 0.025
    normal_variance = sum(value -> value^2, normals) / sample_count -
                      (sum(normals) / sample_count)^2
    @test abs(normal_variance - 1) < 0.04
    poisson_mean = sum(poisson) / sample_count
    poisson_variance = sum(value -> (value - poisson_mean)^2, poisson) / sample_count
    @test abs(poisson_mean - 4) < 0.05
    @test abs(poisson_variance - 4) < 0.12
end

@testset "KernelAbstractions semantic RNG probe" begin
    contract = Philox4x32x10V1()
    seed = UInt64(0xfeedbeef)
    addresses = [RNGAddress(stream = ProposalDirectionStream, mcs = 3,
        operation = 1, entity_kind = SiteEntity, entity = index) for index in 1:32]
    expected = reduce(vcat, collect(rng_words(contract, seed, address)) for address in addresses)
    output = zeros(UInt32, 4 * length(addresses))
    backend = KernelAbstractions.CPU()
    kernel = _rng_probe_kernel!(backend, 64)
    kernel(output, addresses, contract, seed; ndrange = length(addresses))
    KernelAbstractions.synchronize(backend)
    @test output == expected
    @test isbitstype(RNGAddress)
    @test isbitstype(Philox4x32x10V1)
end
