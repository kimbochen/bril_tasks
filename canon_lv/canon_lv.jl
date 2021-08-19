using JSON


abstract type Value end

struct Constant <: Value
    value::Int
end

struct AddMul <: Value
    opr1::String
    opr2::String
end

struct SubDiv <: Value
    opr1::String
    opr2::String
end

struct Identity <: Value
    ref_var::String
end

struct Print <: Value
    print_var::String
end


function canonlocalvalue(instrs)
    var2canon = Dict()  # variable -> canonical variable
    val2canon = Dict()  # value -> canonical variable
    canon2val = Dict()
    value_method = Dict(
        "const" => Constant,
        "id" => Identity,
        "print" => Print,
        "add" => Constant,
        "mul" => Constant,
        "sub" => Constant,
        "div" => SubDiv
    )

    for instr in instrs
        create_value = value_method[instr["op"]]
        value = create_value(instr, var2canon, canon2val)
        canoninstr(instr, value, var2canon, val2canon, canon2val)
    end
end

function Constant(instr, var2canon, canon2val)
    if instr["op"] == "const"
        Constant(instr["value"])
    else
        opr1, opr2 = [canon2val[var2canon[var]].value for var in instr["args"]]
        value = if instr["op"] == "add"
            opr1 + opr2
        elseif instr["op"] == "sub"
            opr1 - opr2
        elseif instr["op"] == "mul"
            opr1 * opr2
        else
            throw("Op $(instr["op"]) called the wrong constructor")
        end

        instr["op"] = "const"
        instr["value"] = value
        delete!(instr, "args")

        Constant(value)
    end
end

function AddMul(instr, var2canon, canon2val)
    opr1, opr2 = (var2canon[var] for var in instr["args"])
    if opr1 > opr2
        AddMul(opr2, opr1)
    else
        AddMul(opr1, opr2)
    end
end

function SubDiv(instr, var2canon, canon2val)
    opr1, opr2 = (var2canon[var] for var in instr["args"])
    SubDiv(opr1, opr2)
end

function Identity(instr, var2canon, canon2val)
    var = instr["args"][1]
    Identity(var2canon[var])
end

function Print(instr, var2canon, canon2val)
    var = instr["args"][1]
    Print(var2canon[var])
end

function canoninstr(instr, value::Constant, var2canon, val2canon, canon2val)
    if value in keys(val2canon)
        var = val2canon[value]

        instr["op"] = "id"
        instr["args"] = [var]
        delete!(instr, "value")

        var2canon[instr["dest"]] = var
    else
        var = instr["dest"]
        var2canon[var] = var
        val2canon[value] = var
        canon2val[var] = value
    end
end

function canoninstr(instr, value::Union{AddMul, SubDiv}, var2canon, val2canon, canon2val)
    if value in keys(val2canon)
        var = val2canon[value]
        instr["op"] = "id"
        instr["args"] = [var]
        var2canon[instr["dest"]] = var
    else
        instr["args"] = [value.opr1, value.opr2]
        var = instr["dest"]
        var2canon[var] = var
        val2canon[value] = var
        canon2val[var] = value
    end
end

function canoninstr(instr, value::Identity, var2canon, val2canon, canon2val)
    instr["args"][1] = value.ref_var
    var2canon[instr["dest"]] = value.ref_var
end

function canoninstr(instr, value::Print, var2canon, val2canon, canon2val)
    instr["args"][1] = value.print_var
end


function main()
    prog = JSON.parse(join(readlines(stdin)))
    instrs = prog["functions"][1]["instrs"]
    canonlocalvalue(instrs)
    JSON.print(prog, 2)
end
    
main()
