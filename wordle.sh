#!/bin/bash

SELF=$(realpath "$0")
DIR=$(dirname "$SELF")
ME=$(basename "$0")

function getWordlist {
	if [ "$ME" = "wordlede" ]; then
		cat "$DIR/wordle.de"
	elif [ "$ME" = "wordleen" ]; then
		cat "$DIR/wordle.en"
	else
		cat "/usr/share/dict/words"
	fi
}

function filterFiveLetters {
	grep -i -P '^(\w){5}$'
}

function filterPattern {
	pattern="$1"
	grep -i -P "^$pattern$"
}

function filterUnusedLetter {
	prePattern="$1"
	letters="$2"
	postPattern="$3"
	grep -i -v -P "^$prePattern[$letters]$postPattern$"
}

function filterUnusedLetters {
	letters="$1"
	filterUnusedLetter "" $letters "...." | filterUnusedLetter "." $letters "..." | filterUnusedLetter ".." $letters ".." | filterUnusedLetter "..." $letters "." | filterUnusedLetter "...." $letters ""
}

function filterUsedLetters {
	pattern="$(echo $1 | sed -e 's/./(?=.*&)/g')"
	grep -i -P "^$pattern"
}

function limitOutput {
	shuf -n 30 | sort
}

if [[ $# == 1 ]]; then
	getWordlist | filterFiveLetters | filterPattern "$1" | limitOutput
elif [[ $# == 2 ]]; then
	getWordlist | filterFiveLetters | filterUnusedLetters "$2" | filterPattern "$1" | limitOutput
elif [[ $# == 3 ]]; then
	getWordlist | filterFiveLetters | filterUnusedLetters "$2" | filterPattern "$1" | filterUsedLetters "$3" | limitOutput
elif [[ $# == 0 ]]; then
	echo "$ME ..... forbiddenletters containedletters"
	echo "have you tried adieu?"
fi

