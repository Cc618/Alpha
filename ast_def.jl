# Abstract syntax tree components

# The 3 main components are :
# - Declaration : Declares a new variable or function
# - Statement : An instruction
# - Expression : A value

# --- Types ---
@enum TypeKind k_int_t k_void_t k_proc_t k_fn_t
@enum SymKind k_sym_local k_sym_arg k_sym_global
@enum StmtKind k_stmt_block k_stmt_exp k_stmt_decl k_stmt_return k_stmt_ifelse
@enum ExpKind k_exp_add k_exp_mul k_exp_id k_exp_int k_exp_set

# Declaration
mutable struct Decl
    type
    id
    # For variables
    value
    # For functions
    body
    nlocals
end

# Statement
mutable struct Stmt
    kind
    # stmt_block
    stmts
    # stmt_exp stmt_return stmt_ifelse.condition
    exp
    # stmt_decl
    decl
    # stmt_ifelse
    ifbody
    elsebody
end

# Expression
mutable struct Exp
    kind
    type
    # Operators
    left
    right
    # Literals
    value
    # exp_id
    id
    # For semantic analysis
    sym
    # For code gen
    register
end

# Symbol
# Data about low level variable
mutable struct Sym
    kind
    type
    # sym_global
    id
    # sym_local sym_arg
    position
end

# A symbol table
# Can be thought as a scope
mutable struct SymTable
    syms::Dict{String, Sym}
    # TODO : nargs withing SymTable or Decl ?
    nargs
    decl
end

mutable struct DeclType
    kind
    # For functions
    args
end

mutable struct Arg
    id
end

# --- Constructors ---
function decl_new(type::DeclType, id::String; value = nothing,
        body = nothing)
    return Decl(type, id, value, body, 0)
end

function stmt_new(kind::StmtKind; stmts = nothing, exp = nothing,
        decl = nothing, ifbody = nothing, elsebody = nothing)
    return Stmt(kind, stmts, exp, decl, ifbody, elsebody)
end

function exp_new(kind::ExpKind; type = nothing, left = nothing,
        right = nothing, value = nothing, id = nothing,
        sym = nothing, register = nothing)
    return Exp(kind, type, left, right, value, id, sym, register)
end

function sym_new(kind::SymKind, type::DeclType, id::String, position = 0)
    return Sym(kind, type, id, position)
end

symtable_new(decl) = SymTable(Dict{String, Sym}(), 0, decl)

decltype_new(kind::TypeKind; args = nothing) = DeclType(kind, args)
