@testset "Biquadratic fields" begin
  FieldsDB.fields(4, 2, db, root(div(fmpz(10)^12, 3), 2), only_real = true)
  flds = load_fields(db)
  @test length(flds) == 136
  for i = 1:length(flds)
    K = number_field(flds[i])

    @test FieldsDB.areramified_primes_known(flds[i])
    rpi = ramified_primes(flds[i])
    rp = Set(rpi)
    rpK = Set(collect(keys(factor(discriminant(maximal_order(K))).fac)))
    @test rp == rpK

    @test !FieldsDB.isclass_group_known(flds[i])
    @test FieldsDB.assumes_GRH(flds[i]) === missing
    FieldsDB.set_class_group(flds[i])
    @test FieldsDB.isclass_group_known(flds[i])
    @test FieldsDB.assumes_GRH(flds[i]) == 1
    C = class_group(K)[1]
    CK = class_group(flds[i])
    @test isisomorphic(C, CK)

    s = signature(flds[i])
    s1 = signature(K)
    @test s == s1

    @test !FieldsDB.isregulator_known(flds[i])
    FieldsDB.set_regulator(flds[i])
    @test FieldsDB.isregulator_known(flds[i])
    #TEST THAT THE REGULATOR IS CORRECT!

    @test !FieldsDB.aresubfields_known(flds[i])
    FieldsDB.set_subfields(flds[i])
    @test FieldsDB.aresubfields_known(flds[i])
    lS = subfields(flds[i])
    lS1 = AnticNumberField[x[1] for x in subfields(K)]
    lS2 = FieldsDB.isomorphism_class_representatives(lS1)
    @test length(lS) == length(lS2)

    FieldsDB.set_galois_group(flds[i])
    @test FieldsDB.isgalois_group_known(flds[i])
    g = galois_group(K)[1]
    gK = galois_group(flds[i])
    @test degree(g) == degree(gK)
    @test isisomorphic(g, gK)[1]

    @test !FieldsDB.iscanonical_polynomial_known(flds[i])
    FieldsDB.set_canonical_defining_polynomial(flds[i])
    @test FieldsDB.iscanonical_polynomial_known(flds[i])
    @test FieldsDB.has_canonical_defining_polynomial(flds[i]) == 1
    K1 = simplify(K, canonical = true)[1]
    f = defining_polynomial(flds[i], cached = false)
    Qx = parent(f)
    f1 = K1.pol(gen(Qx))
    @test f == f1

    @test FieldsDB.isautomorphism_order_known(flds[i])
    auts = automorphisms(K)
    n = FieldsDB.automorphisms_order(flds[i])
    @test length(auts) == n

    @test FieldsDB.iscm_property_known(flds[i])
    fl = FieldsDB.Hecke.iscm_field(K)[1]
    tf = FieldsDB.is_cm(flds[i])
    @test fl == (tf == 1)
    @test tf == FieldsDB.is_cm(flds[i])

    @test FieldsDB.istorsion_unit_size_known(flds[i])
    n1 = FieldsDB.Hecke.torsion_units_order(K)
    n2 = FieldsDB.torsion_units_size(flds[i])
    @test n1 == n2
  end
end

@testset "Quaternion group fields" begin

  FieldsDB.fields(8, 4, db, fmpz(10)^12)
  flds = load_fields(db, degree_range = 8:9)
  @test length(flds) == 2
  for i = 1:length(flds)
    K = number_field(flds[i])

    @test FieldsDB.areramified_primes_known(flds[i])
    rpi = ramified_primes(flds[i])
    rp = Set(rpi)
    rpK = Set(collect(keys(factor(discriminant(maximal_order(K))).fac)))
    @test rp == rpK

    @test !FieldsDB.isclass_group_known(flds[i])
    FieldsDB.set_class_group(flds[i])
    @test FieldsDB.isclass_group_known(flds[i])
    C = class_group(K)[1]
    CK = class_group(flds[i])
    @test isisomorphic(C, CK)

    @test !FieldsDB.isregulator_known(flds[i])
    FieldsDB.set_regulator(flds[i])
    @test FieldsDB.isregulator_known(flds[i])
    r = regulator(K)
    rK = regulator(flds[i])
    @test overlaps(r, rK)

    @test !FieldsDB.aresubfields_known(flds[i])
    FieldsDB.set_subfields(flds[i])
    @test FieldsDB.aresubfields_known(flds[i])
    lS = subfields(flds[i])
    lS1 = AnticNumberField[x[1] for x in subfields(K)]
    lS2 = FieldsDB.isomorphism_class_representatives(lS1)
    @test length(lS) == length(lS2)

    FieldsDB.set_galois_group(flds[i])
    @test FieldsDB.isgalois_group_known(flds[i])
    g = galois_group(K)[1]
    gK = galois_group(flds[i])
    @test degree(g) == degree(gK)
    @test isisomorphic(g, gK)[1]

    @test !FieldsDB.iscanonical_polynomial_known(flds[i])
    FieldsDB.set_canonical_defining_polynomial(flds[i])
    @test FieldsDB.iscanonical_polynomial_known(flds[i])
    K1 = simplify(K, canonical = true)[1]
    f = defining_polynomial(flds[i], cached = false)
    Qx = parent(f)
    f1 = K.pol(gen(Qx))
    @test f == f1

    @test FieldsDB.isautomorphism_order_known(flds[i])
    auts = automorphisms(K)
    n = FieldsDB.automorphisms_order(flds[i])

    @test FieldsDB.iscm_property_known(flds[i])
    fl = FieldsDB.Hecke.iscm_field(K)[1]
    tf = FieldsDB.is_cm(flds[i])
    @test fl == (tf == 1)

    @test FieldsDB.istorsion_unit_size_known(flds[i])
    n1 = FieldsDB.Hecke.torsion_units_order(K)
    n2 = FieldsDB.torsion_units_size(flds[i])
    @test n1 == n2
  end
end

@testset "Queries" begin
  lf = load_fields(db, signature = (0, 4))
  @test length(lf) == 1
  @test count_fields(db, signature = (8, 0)) == 1
  @test count_fields(db, signature = (4, 0)) == 136
  @test count_fields(db, discriminant_range = (fmpz(12230590464), fmpz(12230590464))) == 2
  @test !contains_field(db, signature = (8, 0), class_group_ranks_range = Dict(fmpz(2) => (2, 2)))
  @test count_fields(db, signature = (0, 4), class_group_ranks_range = Dict(fmpz(2) => (1, 2))) == 1
  GP = FieldsDB.isomorphic_transitive_perm_group(small_group(4, 2), 4)
  @test count_fields(db, galois_group = GP, discriminant_range = (-fmpz(10)^10, fmpz(10)^10)) == 136
end


@testset "Large entries" begin

  G = small_group(40, 1)
  GP = FieldsDB.isomorphic_transitive_perm_group(G, 40)
  FieldsDB.insert_group(db, GP)
  @test FieldsDB._find_group_id(db, GP) !== missing

  G1 = symmetric_group(34)
  FieldsDB.insert_group(db, G1)
  #@test FieldsDB._find_group_id(db, G1) !== missing
  
  Qx, x = PolynomialRing(FlintQQ, "x")
  f = x^1000-2
  K, a = number_field(f)
  OK = maximal_order(K)
  FieldsDB.insert_field(db, K)
  x = find_DBfield(db, K)
  @test discriminant(x) == discriminant(OK)
end

  

