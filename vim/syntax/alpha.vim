syntax match alphaComment "\v#.*"

syntax keyword alphaKeyword
    \ fun
    \ proc
    \ take
    \ begin
    \ end
    \ let
    \ be
    \ is
    \ return
    \ if
    \ else
    \ loop
    \ with
    \ when
    \ from
    \ to
    \ print
    \ scan

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
    \ +=
    \ -=
    \ /=
    \ *=
    \ %=
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
