#!/bin/bash


finalString=""

# strained
# 2248614488 CRC32
test1="lush bagpipe stacking mice imitate village gang efficient strained different together vain puck roped pancakes shocking liar moisture memoir sorry syndrome kettle swept dehydrate"

# tipsy
test2="itself pamphlet language gimmick sake arises guest opened itself went huge ribbon kidneys motherly awning vary gave apricot tipsy olive algebra jury nexus nostril"

for w in $test1; do
	#finalString+=$(printf '%s' "${w:0:3}")
	finalString+=$(printf '%s' "${w:0:3}")
done

checksum=$(printf '%s' $finalString | gzip -1 -c | tail -c8 | od -t u4 -N 4 -A n)

# Take the checksum index modulo 24
wordIndex=$(( checksum % 24 ))

echo $checksum
echo $finalString
echo $wordIndex

twentyfivestWord=${filtered25Words["${wordIndex-1},2"]}
