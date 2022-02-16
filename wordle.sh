#!/bin/bash

ME=$(basename "$0")

nrOfLetters=5

function die {
	>&2 echo "${BASH_LINENO[0]}: $1"
	exit 1
}

function debug {
	#>&2 echo "${BASH_LINENO[0]}: $1"
	return
}

function verifyIndex {
	local input=$1
	if [ ${#input} == 2 ]; then
		local index=${input:1:1}
		if [ "$index" -lt 1 ] || [ "$index" -gt $nrOfLetters ]; then
			die "invalid index given (range)"
		fi
	else
		die "invalid index given (length)"
	fi
}

function getIndex {
	local input=$1
	if [ ${#input} == 2 ]; then
		local index=${input:1:1}
		if [ "$index" -lt 1 ] || [ "$index" -gt $nrOfLetters ]; then
			die "invalid index given (range)"
		fi
		echo "$index"
	else
		die "invalid index given (length)"
	fi
}

function sanitizeString {
	echo "$1" | tr -dc '[:alnum:]' | tr '[:upper:]' '[:lower:]'
}

function sanitizePipe {
	tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'
}

function getWordlist {
	cat "$wordlist"
}

function inclusionPattern {
	local localInclusions=${includes[$1]}
	local charClass=$localInclusions
	charClass=$([ "$charClass" == "" ] && echo "a-z" || echo "$charClass")
	echo "[$charClass]"
}

function filterInclusions {
	local pattern="^"
	for i in $(seq 1 $nrOfLetters); do
		pattern="$pattern$(inclusionPattern "$i")"
	done
	pattern="$pattern$"
	debug "$pattern"
	grep -i -P "$pattern"
}

function exclusionPattern {
	local globalExclusions=${excludes[0]}
	local localExclusions=${excludes[$1]}
	echo "[$globalExclusions$localExclusions]"
}

function exclusionElement {
	local index=$1
	local charClass
	charClass="$(exclusionPattern "$index")"
	charClass=$([ "$charClass" == "[]" ] && echo "0" || echo "$charClass")
	local pattern="^"
	for i in $(seq 1 $nrOfLetters); do
		if [ "$i" == "$index" ]; then
			pattern="$pattern$charClass"
		else
			pattern="$pattern$(inclusionPattern "$i")"
		fi
	done
	pattern="$pattern$"
	debug "$pattern"
	grep -i -v -P "$pattern"
}

function exclusionRecursion {
	local index="$1"
	if [ "$index" -gt 1 ]; then
		exclusionElement "$index" | exclusionRecursion "$((index - 1))"
	else
		exclusionElement "$index"
	fi
}

function filterExclusions {
	exclusionRecursion "$nrOfLetters"
}

function filterMustHaves {
	local pattern
	# no idea how to do this with patern matching
	# shellcheck disable=SC2001
	pattern="^$(echo "${includes[0]}" | sed -e 's/./(?=.*&)/g')"
	debug "$pattern"
	grep -i -P "$pattern"
}

function limitOutput {
	shuf -n 30 | sort
}

if [ $# -le 1 ]; then
	echo "example: $ME wordlist + nsel - dfg +1 i : l"
	echo "+ ... global must have letters"
	echo "- ... global exclusion letters"
	echo "+1 ... inclusion letters for position 1"
	echo "-4 ... exclusion letters for position 4"
        echo "wordlist is a list of allowed words, one word per line"
	exit 0
fi

includes=("")
excludes=("")

wordlist=$1
if [[ -f "$wordlist" ]] && [[ -r "$wordlist" ]]; then
	shift
else
	die "invalid wordlist given"
fi

while [ $# -gt 1 ]; do

	input=$(sanitizeString "$2")

	case "$1" in
		+)
			includes[0]="${includes[0]}$input"
			debug "must haves: ${includes[0]}";;
		-)
			excludes[0]="${excludes[0]}$input"
			debug "global exclusions: ${excludes[0]}";;
		+*)
			verifyIndex "$1"
			index=$(getIndex "$1")
			includes[$index]="${includes[$index]}$input"
			debug "inclusions for $index: ${includes[$index]}";;
		-*)
			verifyIndex "$1"
			index=$(getIndex "$1")
			excludes[$index]="${excludes[$index]}$input"
			debug "exclusions for $index: ${excludes[$index]}";;
		*)
			die "invalid parameter";;
	esac
	shift
	shift
done

if [ $# -gt 0 ]; then
	die "leftover parameters"
fi;

debug "includes: $(printf "%s\n" "${includes[@]@K}")"
debug "excludes: $(printf "%s\n" "${excludes[@]@K}")"
debug "wordlist: $wordlist"

getWordlist | sanitizePipe | filterInclusions | filterExclusions | filterMustHaves | limitOutput | xargs -n5
