syntax match alphaComment "\v#.*"

syntax keyword alphaKeyword
    \ if
    \ let
    \ be
    \ loop
    \ when
    \ with
    \ from
    \ to
    \ begin
    \ end
    \ fun
    \ proc
    \ take
    \ else
    \ return

syntax match alphaNumber "\v-?<\d+>"
syntax keyword alphaBoolean
    \ true
    \ false

syntax keyword alphaOperator
    \ +
    \ -
    \ *
    \ /
    \ %
    \ :=
    \ >=
    \ <=
    \ <
    \ >
    \ is
    \ !=
    \ <
    \ and
    \ or
    \ not

highlight default link alphaComment Comment

highlight default link alphaNumber Number
highlight default link alphaBoolean Boolean

highlight default link alphaOperator Operator
highlight default link alphaKeyword Keyword
