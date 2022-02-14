#!/bin/bash

aspell -d de dump master | aspell -l de expand | sed -E -e 's/\s+/\n/g' | tr '[:upper:]' '[:lower:]' | grep -P "^.....$" | sort -u > wordle.de
aspell -d en dump master | aspell -l en expand | sed -E -e 's/\s+/\n/g' | tr '[:upper:]' '[:lower:]' | grep -P "^.....$" | sort -u > wordle.en
