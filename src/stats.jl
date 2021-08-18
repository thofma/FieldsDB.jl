################################################################################
#
#   Fields by group and signature
#
################################################################################
@doc Markdown.doc"""
    fields_by_group(db::Database, G::PermGroup) 

Prints a table containing the number of fields with Galois group G in the database
grouped by signature.
"""
function fields_by_group(db::LibPQ.Connection, G::PermGroup; update::Bool = false)
  if update
    update_fields_grp_signature(db)
  end
  id = FieldsDB._find_group_id(db, G)
  if id === missing
    println("Group not in database")
  end
  query = "SELECT real_embeddings, number FROM fields_by_grp_sign WHERE group_id = $(id)"
  result = Tables.columntable(execute(db, query, column_types = Dict(:number => Int, :real_embeddings => Int)))
  M = Array{String, 2}(undef, length(result[1]), 2)
  for i = 1:length(result[1])
    s = result[1][i]
    M[i, 1] = "($s, $(div(degree(GP)-s, 2)))"
    M[i, 2] = string(result[2][i])
  end
  t = Tables.table(M)
  pretty_table(t, ["Signature", "Number of fields"], crop = :none)
end

@doc Markdown.doc"""
    fields_by_group_and_signature(db::Database, G::PermGroup) 

Prints a table containing the number of fields in the database
grouped by signature and Galois group G.
"""
function fields_by_group_and_signature(db::LibPQ.Connection; update::Bool = false)
  if update
    update_fields_grp_signature(db)
  end
  query = "SELECT * FROM fields_by_grp_sign"
  result = Tables.columntable(execute(db, query, column_types = Dict(:group_id => Int, :number => Int, :real_embeddings => Int)))
  M = Array{String, 2}(undef, length(result[1]), 3)
  for i = 1:length(result[1])
    GP = find_group(db, result[1][i])
    M[i, 1] = _print_group(db, GP)
    s = result[2][i]
    M[i, 2] = "($s, $(div(degree(GP)-s, 2)))"
    M[i, 3] = string(result[3][i])
  end
  t = Tables.table(M)
  pretty_table(t, ["Galois group", "Signature", "Number of fields"], crop = :none)
end

function insert_data(db::LibPQ.Connection, grp_id::Int, signature::Int, nmb::Int)
  query = "SELECT * FROM fields_by_grp_sign WHERE group_id = $(grp_id) AND real_embeddings = $(signature) LIMIT 1"
  result = Tables.columntable(execute(db, query))
  if length(result[1]) == 1
    query = "UPDATE fields_by_grp_sign SET number = $(nmb) WHERE group_id = $(grp_id) AND real_embeddings = $(signature)"
    execute(db, query)
  else
    LibPQ.load!(
      (real_embeddings = [signature[1]], 
      group_id = [grp_id],
      number = [nmb]
      ),
      db,
      "INSERT INTO fields_by_grp_sign (
        real_embeddings, 
        group_id,
        automorphisms_order, 
        number
      ) VALUES (\$1, \$2, \$3);",
    )
  end
  return nothing
end

function update_fields_grp_signature(db::LibPQ.Connection)
  query = "SELECT group_id, real_embeddings, COUNT(field_id) "
  query *= "FROM field GROUP BY group_id, real_embeddings"
  result = Tables.columntable(execute(db, query))
  for i = 1:length(result[1])
    insert_data(db, result[1][i], result[2][i], result[3][i])
  end 
  return nothing
end

function fields_by_degree(db::LibPQ.Connection)
  query = "SELECT degree, real_embeddings, COUNT(field_id) "
  query *= "FROM field GROUP BY degree, real_embeddings ORDER BY degree, real_embeddings"
  result = Tables.columntable(execute(db, query, column_types = Dict(:degree => Int, :real_embeddings => Int)))
  M = Array{String, 2}(undef, length(result[1]), 3)
  for i = 1:length(result[1])
    if i == 1 || result[1][i-1] != result[1][i]
      M[i, 1] = string(result[1][i])
    else
      M[i, 1] = " "
    end
    s = result[2][i]
    M[i, 2] = "($s, $(div(result[1][i]-s, 2)))"
    M[i, 3] = string(result[3][i])
  end
  t = Tables.table(M)
  pretty_table(t, ["Degree", "Signature", "Number of fields"], crop = :none)
  return nothing
end

function class_numbers_by_degree(db::LibPQ.Connection)
  M = Array{String, 2}(undef, 48, 12)
  for i = 1:48
    for j = 1:12
      M[i, j] = ""
    end
  end
  query = "SELECT degree, COUNT(field_id) FROM field WHERE class_group_id = (SELECT class_group_id FROM class_group WHERE group_order = 1) GROUP BY degree"
  result = Tables.columntable(execute(db, query))
  for j = 1:length(result[1])
    M[result[1][j], 1] = string(result[2][j])
  end
  for i = 2:11
    query = "SELECT degree, COUNT(field_id) FROM field WHERE class_group_id = ANY(SELECT class_group_id FROM class_group WHERE group_order BETWEEN $(10^(i-2)+1) AND $(10^(i-1))) GROUP BY degree"
    result = Tables.columntable(execute(db, query))
    for j = 1:length(result[1])
      M[result[1][j], i] = string(result[2][j])
    end
  end
  t = Tables.table(M)
  header1 = Vector{String}(undef, 12)
  header2 = Vector{String}(undef, 12)
  header3 = Vector{String}(undef, 12)
  header1[1] = " "
  header2[1] = "h = 1"
  header3[1] = " "
  for i = 2:12
    header1[i] = "10^$(i-2)"
    header2[i] = "< h  <="
    header3[i] = "10^$(i-1)"
  end
  pretty_table(t, header = (header1, header2, header3), row_names = ["$i" for i in 1:48], crop = :none)
  return nothing
end

function _missing_class_groups_by_degree(db::LibPQ.Connection)
  query = "SELECT degree, COUNT(*) FROM field WHERE class_group_id IS NULL GROUP BY degree"
  result = Tables.columntable(execute(db, query))
  pretty_table(result, crop = :none)
  return nothing
end

function _missing_subfields_by_degree(db::LibPQ.Connection)
  query = "SELECT degree, COUNT(*) FROM field WHERE subfields IS NULL GROUP BY degree"
  result = Tables.columntable(execute(db, query))
  pretty_table(result, crop = :none)
  return nothing
end

@doc Markdown.doc"""
    minimal_discriminant(db::Database, G::PermGroup, signature::Tuple{Int, Int}) -> Bool, fmpz

Returns the minimum absolute discriminant of any fields in the database with the given Galois group and signature
and a boolean, depending on whether the discriminant has been proven to be minimal or not.
"""
function minimal_discriminant(db::LibPQ.Connection, GP::PermGroup, signature::Tuple{Int, Int}; update::Bool = false)
  @assert signature in possible_signatures(GP)
  if update
    update_minimal_discriminant(db, GP, signature)
    return _minimal_discriminant(db, GP, signature)
  end
  if !has_entry_minimal_discriminant(db, GP, signature)
    error("Info not found. Try using the update command")
  end
  return _minimal_discriminant(db, GP, signature)

end

function has_entry_minimal_discriminant(db::LibPQ.Connection, GP::PermGroup, signature::Tuple{Int, Int})
  grp_id = _find_group_id(db, GP)
  query = "SELECT 1 FROM minimal_discriminant WHERE group_id = $(grp_id) AND real_embeddings = $(signature[1]) LIMIT 1"
  result = execute(db, query)
  return length(result) == 1
end



function update_minimal_discriminant(db, GP, signature)
  grp_id = _find_group_id(db, GP)
  if grp_id === missing
    error("Field in database with the required property does not exist!")
  end
  query = "SELECT MIN(ABS(discriminant)) FROM field WHERE group_id = $(grp_id) AND real_embeddings = $(signature[1])"
  result = execute(db, query)
  d1 = result[1, 1]
  if d1 === missing
    error("Field in database with the required property does not exist!")
  end
  d = BigInt(d1)
  query = "SELECT field_id FROM field WHERE group_id = $(grp_id) AND real_embeddings = $(signature[1]) AND discriminant = $(d)"
  result1 = execute(db, query)
  v = Int[result1[i, 1] for i = 1:length(result1)]
  cd = find_completeness_data(db, GP, signature)
  proof = d <= max(cd[1], cd[2])
  if has_entry_minimal_discriminant(db, GP, signature)
    query = "UPDATE minimal_discriminant SET proven = \$2, fields = \$1, discriminant = $d WHERE group_id = $(grp_id) AND real_embeddings = $(signature[1])"
    execute(db, query, [v, proof])
  else
    LibPQ.load!(
        (real_embeddings = [signature[1]],  
        discriminant = [BigInt(d)], 
        group_id = [grp_id],
        fields = [v],
        proven = [proof]
        ),
        db,
        "INSERT INTO minimal_discriminant (
          real_embeddings, 
          discriminant, 
          group_id,
          fields,
          proven
        ) VALUES (\$1, \$2, \$3, \$4, \$5);",
      )
  end
  return nothing
end

function _minimal_discriminant(db::LibPQ.Connection, GP::PermGroup, signature::Tuple{Int, Int})
  id = _find_group_id(db, GP)
  query = "SELECT discriminant, proven FROM minimal_discriminant WHERE group_id = $id AND real_embeddings = $(signature[1])"
  result = execute(db, query, column_types = Dict(:discriminant => BigInt))
  return result[1, 2], fmpz(result[1, 1])
end