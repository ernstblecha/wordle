#!/bin/bash

SELF=$(realpath "$0")
DIR=$(dirname "$SELF")
ME=$(basename "$0")

if [ "$ME" = "wordlede" ]; then
	wordlist="$DIR/wordle.de"
elif [ "$ME" = "wordleen" ]; then
	wordlist="$DIR/wordle.en"
else
	echo "no wordlist selected"
	wordlist="/usr/share/dict/words"
fi

echo $wordlist

if [[ $# == 1 ]]; then
	grep -i -P '^(\w){5}$' "$wordlist" | grep -i -P "^$1$" | shuf -n 30 | sort
elif [[ $# == 2 ]]; then
	grep -i -P '^(\w){5}$' "$wordlist" | grep -i -v -P "^[$2]....$" | grep -i -v -P "^.[$2]...$" | grep -i -v -P "^..[$2]..$" | grep -i -v -P "^...[$2].$" | grep -i -v -P "^....[$2]$" | grep -i -P "^$1$" | shuf -n 30 | sort
elif [[ $# == 3 ]]; then
	pattern=$(echo $3 | sed -e 's/./(?=.*&)/g')
	grep -i -P '^(\w){5}$' "$wordlist" | grep -i -v -P "^[$2]....$" | grep -i -v -P "^.[$2]...$" | grep -i -v -P "^..[$2]..$" | grep -i -v -P "^...[$2].$" | grep -i -v -P "^....[$2]$" | grep -i -P "^$1$" | grep -i -P "^$pattern" | shuf -n 30 | sort
elif [[ $# == 0 ]]; then
	echo "$ME ..... forbiddenletters containedletters"
	echo "have you tried adieu?"
fi

#grep -i -P '^(\w){5}$' /usr/share/dict/words | grep -i -v -P '^[wertuiasdhcm]....$' | grep -i -v -P '^.[wertuiasdhcm]...$' | grep -i -v -P '^..[wertuiasdhcm]..$' | grep -i -v -P '^...[wertuiasdhcm].$' | grep -i -v -P '^....[wertuiasdhcm]$' | grep -i -P '^..ol.$'
