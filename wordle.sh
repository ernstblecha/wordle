#!/bin/bash

SELF=$(realpath "$0")
DIR=$(dirname "$SELF")
ME=$(basename "$0")

function die {
	>&2 echo "${BASH_LINENO[0]}: $1"
	exit 1
}

function debug {
	#>&2 echo "${BASH_LINENO[0]}: $1"
	return
}

function verifyIndex {
	input=$1
	if [ ${#input} == 2 ]; then
		index=${input:1:1}
		if [ $index -lt 1 ] || [ $index -gt 5 ]; then
			die "invalid index given (range)"
		fi
	else
		die "invalid index given (length)"
	fi
}

function getIndex {
	input=$1
	if [ ${#input} == 2 ]; then
		index=${input:1:1}
		if [ $index -lt 1 ] || [ $index -gt 5 ]; then
			die "invalid index given (range)"
		fi
		echo $index
	else
		die "invalid index given (length)"
	fi
}

function sanitizeString {
	echo $1 | tr -dc '[:alnum:]' | tr '[:upper:]' '[:lower:]'
}

function sanitizePipe {
	tr -dc '[:alnum:]\n\r' | tr '[:upper:]' '[:lower:]'
}

function getWordlist {
	cat "$wordlist"
}

function inclusionPattern {
	globalInclusions=${includes[0]}
	localInclusions=${includes[$1]}
	charClass=$globalInclusions$localInclusions
	charClass=$([ "$charClass" == "" ] && echo "a-z" || echo $charClass)
	echo "[$charClass]"
}

function filterInclusions {
	pattern="^$(inclusionPattern 1)$(inclusionPattern 2)$(inclusionPattern 3)$(inclusionPattern 4)$(inclusionPattern 5)$"
	debug "$pattern"
	grep -i -P "$pattern"
}

function exclusionPattern {
	globalExclusions=${excludes[0]}
	localExclusions=${excludes[$1]}
	echo "[$globalExclusions$localExclusions]"
}

function exclusionElement {
	charClass="$(exclusionPattern $1)"
	charClass=$([ $charClass == "[]" ] && echo "0" || echo "$charClass")
	prePattern="$2"
	postPattern="$3"
	pattern="^$prePattern$charClass$postPattern$"
	debug "$pattern"
	grep -i -v -P "$pattern"
}

function filterExclusions {
	exclusionElement 1 "" "...." | exclusionElement 2 "." "..." | exclusionElement 3 ".." ".." | exclusionElement 4 "..." "." | exclusionElement 5 "...." ""
}

function filterMustHaves {
	pattern="^$(echo $mustHaves | sed -e 's/./(?=.*&)/g')"
	debug "$pattern"
	grep -i -P "$pattern"
}

function limitOutput {
	shuf -n 30 | sort
}

if [ $# == 0 ]; then
	echo "$ME wordlist + nsel - dfg +1 i : l"
	echo "+ ... global inclusion letters"
	echo "- ... global exclusion letters"
	echo ": ... global must have letters"
	echo "+1 ... inclusion letters for position 1"
	echo "-4 ... exclusion letters for position 4"
	exit 1
fi


includes=("" "" "" "" "" "")
excludes=("" "" "" "" "" "")
mustHaves=""

wordlist=$1
if [[ -f "$wordlist" ]] && [[ -r "$wordlist" ]]; then
	shift
else
	die "invalid wordlist given"
fi

while [ $# -gt 1 ]; do

	case "$1" in
		+)
			index="0"
			includes[$index]="${includes[$index]}$(sanitizeString $2)"
			debug "global inclusions: ${includes[$index]}";;
		-)
			index="0"
			excludes[$index]="${excludes[$index]}$(sanitizeString $2)"
			debug "global exclusions: ${excludes[$index]}";;
		:)
			mustHaves="$mustHaves$(sanitizeString $2)"
			debug "must haves: $mustHaves";;
		+*)
			verifyIndex "$1"
			index=$(getIndex "$1")
			includes[$index]="${includes[$index]}$(sanitizeString $2)"
			debug "inclusions for $index: ${includes[$index]}";;
		-*)
			verifyIndex "$1"
			index=$(getIndex "$1")
			excludes[$index]="${excludes[$index]}$(sanitizeString $2)"
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

debug "${includes[0]} | ${includes[1]} | ${includes[2]} | ${includes[3]} | ${includes[4]} | ${includes[5]}"
debug "${excludes[0]} | ${excludes[1]} | ${excludes[2]} | ${excludes[3]} | ${excludes[4]} | ${excludes[5]}"
debug $wordlist

getWordlist | sanitizePipe | filterInclusions | filterExclusions | filterMustHaves | limitOutput
