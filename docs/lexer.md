# Lexer
The lexer is included within the parser module.
This document describes the syntax of regular expressions (regexes)
parsed by the lexer.

## Syntax
The syntax is inspired by standard regexes.
However, the syntax is slightly different than other regexes.

## Operators
- <state>\* : Kleen star, 0 or more <state>
- <state>? : 0 or 1 <state>

## Groups
### Special characters / groups
- alpha : \_a-zA-Z
- num : 0-9
- alnum : Union of alpha and num sets
- \n : Line feed
- \t : Tab
- \s : White space (\t or space)
- \s : Blank char (white space or line feed)
- . : All characters except line feed ([\n])
- ^' : . without '
- ^\" : . without "

### Characters to escape (with \\)
- \*
- \\
- "
- :
- \[

## Examples
- Identifiers :
```
[alpha][alnum]*
```
- Integers :
```
-?[num][num]*
```
- Julia inline comments :
```
#[.]*
```
