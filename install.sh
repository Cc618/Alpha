#!/bin/bash

out=/usr/bin/alpha

content="#!/bin/bash"
content="$content\njulia -e 'import Alpha; Alpha.alphamain()' \$@"

printf "$content" > "$out"
chmod +x "$out"
