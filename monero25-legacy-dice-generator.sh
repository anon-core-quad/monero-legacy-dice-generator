#!/bin/bash

DEBUG=1


readonly PREFIX_LENGTH=3
readonly WORD_FILE="monero25-english.md"

ENTROPY=264 #needed to generate 256 bits of entropy
#NEEDED_QUARTINES=66
LAST_HEX_WORD="65A"
LAST_WORD_INDEX=1626

SEED_WORDS=24

# Dice faces, default is 6 => D6
# Note: if you have 2 faces, you are probably flipping a coin :)
dice_faces=6

# The full sequence entered from prompt, contain the resuls achieved by the throws of dices or coins
dice_throws_sequence=''

show_help() {
	local bold=$'\033[1m'
    local reset=$'\033[0m'
	local dim=$'\033[2m'
    local cyan=$'\033[36m'
cat <<EOF
Usage: $0 [OPTIONS]

Description:
Generate Monero Legacy Seed words from physical dice rolls - offline, transparent, and privacy-focused.

Options:
${bold}-h${reset}			Show this help message 
${bold}-s${reset}			The numbers rolled on the dice, witout spaces	[required]
${bold}-f${reset}			The number of faces of the dice
			[default: 6]

Examples:
Generate 25 words seed from default D6 dice throws
${dim}$ bash $0 -s 123124465261[...]4135612546${reset}

Generate 25 words seed from coin flipping
${dim}$ bash $0 -s 1212122222[...]122222211 -f 2 

Generate 25 words seed from D8
${dim}$ bash $0 -s 123124465261[...]5612546 -f 8 		
EOF
}

all_in_range() {
    local lo=1 hi=$dice_faces
    shift 2
	returnValue=0

	for ((x=0; x<${#dice_throws_sequence}; x++)); do
		val=${dice_throws_sequence:x:1}
		if (( val < lo || val > hi )); then 
			returnValue=1
			break
		fi
	done

    echo $returnValue
}

while getopts "hf:s:" opt; do
	case $opt in
		h) show_help && exit 0;;
		f) dice_faces=$(echo $OPTARG);;
		s) dice_throws_sequence=$(echo $OPTARG | tr -d ' ');;
  	esac
done

checkInsertedNumbers=$(all_in_range)

if [[ ${checkInsertedNumbers} -eq 1 ]]; then 
	echo "ERROR: You must insert number between 1 and $dice_faces"	
	exit 1
fi

# Convert dice throws sequence in a hash sha256, so it's pointless to get more entropy
sha512value=$(sha512sum <<<$dice_throws_sequence | awk '{print $1}')


# Calculate the number of rolls needed, based on how many faces have the dices
base_entropy=$(echo "l($dice_faces)/l(2)" | bc -l)
needed_number_of_rolls=$(bc -l <<< "$ENTROPY / $base_entropy")

# Round result to units
needed_number_of_rolls=$(awk -v rolls="$needed_number_of_rolls" 'BEGIN { printf "%.0f\n", rolls }')

printf "%-20s %-10s\n" "Param" "Value"
echo "----------------------------"
printf "%-20s %-10s\n" "Entropy" "$ENTROPY"
printf "%-20s %-10s\n" "Dice Faces" "$dice_faces"
printf "%-20s %-10s\n" "Needed throws" "$needed_number_of_rolls"
printf "%-20s %-10s\n" "Inserted throws" "${#dice_throws_sequence}"
echo "----------------------------"

echo -e "\nInserted sequence:\n$dice_throws_sequence\n"


if [ $DEBUG -eq 0 ]; then
	if [ ${#dice_throws_sequence} -lt $needed_number_of_rolls ]; then 
		echo "ERROR: you need at least $needed_number_of_rolls values."	
		exit 1
	fi
fi

echo -e "Generated SHA512 from sequence:\n$sha512value \n"



#the new way uses the key derivation of
# https://github.com/diybitcoinhardware/embit/blob/2bf81739eb5f01f8ad59d23c492fd9d9564eed48/src/embit/bip39.py#L86
#PBKDF2_ROUNDS = 2048
##password used for the salt (a sha256sum )
#password = hashlib.sha256(dice_rolls.encode()).digest()
#entropy_bytes  = hashlib.pbkdf2_hmac(
#        "sha512",
#        dice_rolls.encode("utf-8"),
#        password,
#        PBKDF2_ROUNDS,
#        32,
#    )

#if [[ $DEBUG -eq 0 ]]; then
#	# Take the first 3 characters of each word and concatenate them
#	firstThreeCharactersOfEachWord="lusbagstamicimivilganeffstrdiftogvaipucroppansholiamoimemsorsynketswedeh"
#fi


#echo ${#sha512value}

#exit 1


# Lookup table for binary conversion
hex2bin=(0000 0001 0010 0011 0100 0101 0110 0111 1000 1001 1010 1011 1100 1101 1110 1111)

BINARY_CONVERSION=""
for (( i=0; i<${#sha512value}; i++ )); do
    hexValue=$((16#${sha512value:$i:1}))
	BINARY_CONVERSION+=${hex2bin[hexValue]}
done


# Original words from here https://github.com/monero-project/monero/blob/master/src/mnemonics/english.h
if [[ $DEBUG -eq 0 && ! -f ${WORD_FILE} ]]; then
	# Download Monero English word list
	wget -O ${WORD_FILE} https://raw.githubusercontent.com/SafeKeys/monero-mnemonic-seeds/refs/heads/main/mnemonics/english.md
	echo -e "\n"
fi

declare -A moneroLegacySeedwords
j=1
while IFS= read -r line; do
	moneroLegacySeedwords[$j]=$line
	((j++))
done < <(cat ${WORD_FILE} | tail -n +3 | awk '{print $4}')

#echo ${moneroLegacySeedwords}
#exit 1

#echo $BINARY_CONVERSION

declare -A finalMatrix
i=1
while IFS= read -r group; do
	decimalConversion=$((2#$group+1))
	finalMatrix["$i,0"]=$group
	finalMatrix["$i,1"]=$decimalConversion
	finalMatrix["$i,2"]=${moneroLegacySeedwords[$decimalConversion]}
	finalMatrix["$i,3"]=$index
	((i += 1))
done < <(fold -w11 <<< "$BINARY_CONVERSION")

#echo -n $BINARY_CONVERSION[0] | tr [:lower:] [:upper:] | xargs -I{} sh -c 'echo "obase=10; ibase=2; {}"' | bc

rows=$(printf '%s\n' "${!finalMatrix[@]}" | cut -d',' -f1 | sort -un | wc -l)
#echo ${rows}

# Print a table of the results

declare -A filtered25Words
j=1
i=1
firstThreeCharactersOfEachWord=""


#firstThreeCharactersOfEachWord=$(echo "lush bagpipe stacking mice imitate village gang efficient strained different together vain puck roped pancakes shocking liar moisture memoir sorry syndrome kettle swept dehydrate" | tr -d ' ')
#firstThreeCharactersOfEachWord=$(echo "itself pamphlet language gimmick sake arises guest opened itself went huge ribbon kidneys motherly awning vary gave apricot tipsy olive algebra jury nexus nostril" | tr -d ' ')  #tipsy

#firstThreeCharactersOfEachWord=$(echo "fetches sincerely kiosk haystack drying adult hectare distance fowls trendy mews evenings rural identity nouns observant baffles nephew racetrack duties tell aimless tell deity" | tr -d ' ')


while : ; do
	
	if [[ $i -ge ${rows} || $j -gt $((SEED_WORDS)) ]]; then
		break
	fi

    if [[ ${finalMatrix["$i,1"]} -le $LAST_WORD_INDEX ]]; then
		filtered25Words["$j,0"]=${finalMatrix[$i,0]}
		filtered25Words["$j,1"]=${finalMatrix[$i,1]}
		filtered25Words["$j,2"]=${finalMatrix[$i,2]}
		filtered25Words["$j,3"]=$j
		firstThreeCharactersOfEachWord+="${filtered25Words[$j,2]:0:3}"
		((j += 1))
    fi
	
	((i += 1))
done

echo "$firstThreeCharactersOfEachWord"

# Calculate the CRC32 checksum of the concatenated string. In this case, the checksum gives us the decimal number
checksum=$(printf '%s' $firstThreeCharactersOfEachWord | gzip -1 -c | tail -c8 | od -t u4 -N 4 -A n)   

# Take the checksum index modulo 24
wordIndex=$(( (checksum % SEED_WORDS) + 1 ))


echo $checksum
echo ${wordIndex}

echo $filtered25Words

twentyfivestWord=${filtered25Words[${wordIndex},2]}

# The 8th index of the wordlist is strained (don't forget that the wordlist is 0-indexed). So, the checksum word is strained.


echo -e "CHECKSUM WORD $twentyfivestWord \n"

printf "%-8s %-15s %-10s %-20s\n" "Position" "Binary" "Decimal+1" "Word"
printf "%s\n" "---------------------------------------"

for ((j=1; j<=${SEED_WORDS}; j++)); do
	printf "%-8s %-15s %-10s %-20s\n" "${filtered25Words[$j,3]}" "${filtered25Words[$j,0]}" "${filtered25Words[$j,1]}" "${filtered25Words[$j,2]}"
done
filtered25Words["25,0"]=""
filtered25Words["25,1"]=0
filtered25Words["25,2"]=$twentyfivestWord
filtered25Words["25,3"]=25

printf "%-8s %-15s %-10s %-20s\n" "${filtered25Words[25,3]}" "${filtered25Words[25,0]}" "${filtered25Words[25,1]}" "${filtered25Words[25,2]}"


# Print inline seed words
printf "SEED WORDS:\n"
printf '=%.0s' $(seq 1 $((COLUMNS)))
printf "\n"
for i in $(seq 1 $((SEED_WORDS+1))); do
    printf "%s " "${filtered25Words[$i,2]}"
done
printf "\n"
printf '=%.0s' $(seq 1 $((COLUMNS)))
printf "\n"