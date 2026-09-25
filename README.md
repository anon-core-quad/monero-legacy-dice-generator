# About

Offline-friendly command-line utility for creating Monero Legacy mnemonic seed phrases using physical dice rolls. It transforms manually entered dice-roll data into entropy and derives a standard wallet recovery phrase, giving users a transparent way to generate seeds without depending on online services or hidden system randomness.

Designed for users who value verifiable entropy, self-custody, and privacy, the tool provides a simple CLI workflow for generating wallet mnemonics from randomness they can observe and control.

- usable offline
- no dependency
- very fast auditable code
- essential
- privacy oriented
- no extra redundant features

Reccomended usage with live operative system without internet connection. (eg. [Tails Linux](https://tails.net/))
Generate the key and annotate it in a traditional way: paper and pencil!

# Theory

To generate a strong wallet, you need a strong source of entropy. This because the private key is nothing more than a simple number between 2^1 and 2^256.

Generally speaking, to be secure against a bruteforce attack you need at least 128 bits of entropy. 

The human race are not a good source of unbiased entropy. Something that it seems random it's the result of our personal experiences mixed with our personal temperament.

You have only two choices to get a random number:
- RNG function from a electronic device, like a PC or hardware wallet
- __The vibrations of the universe canalized thought a multiple throws of dices__

The former is the fastest and comfortable choice, but you can't be shure that at some point someone finds out a vulnerability in this functions and at our expense we discover that the key you have generated is not much random as you thought.

The huge number behind 256 bits of entropy:

```2^256 = 1.157920892373162e+77```


A standard dice D6 entropy:

```D6entropy = log(6) / log(2) = log2(6) = 2.584962500721156 ~ 2.585 bits```


To know how much throws you need, you must divide the entropy target with the entropy of the single dice throw:

```NumberOfThrows = EntropyTarget / D6Entropy = 256 / 2.584962500721156 = 99.03431865204266 ~ 99```


To prove mathematically, multipliy the dice entropy with the number of throws founded

```EntropyTarget = D6Entropy * NumberOfThrows = log2(6) * 99 = 2.584962500721156 * 99 = 255.91128757139444 ~ 256 bits```


PS: if your dice have only 2 faces, you just flipping a coin :)
log2(2) = 1 * 256 = 256 bits

```D6entropy = log(2) / log(2) = log2(2) = 1 bit```


In monero legacy seeds, each words have less than 11 bits of entropy.
We have 1626 words 
https://github.com/monero-project/monero/blob/master/src/mnemonics/english.h 
https://raw.githubusercontent.com/SafeKeys/monero-mnemonic-seeds/refs/heads/main/mnemonics/english.md


```SingleWordEntropy = log(1626) / log(2) = 10.667111542075027 ~ 11 bits```

```SingleWordEntropy * 24 Words = 256.01067700980065 ~ 256 bits```


So we need to consider 11 bits per word, so the words are encoded in this way:

Decimal     Binary          Word        Hex
-------------------------------------------------
1           00000000001     abbey       001
2           00000000010     abducts     002
3           00000000011     ability     003
4           00000000100     ablaze      004
                [...]
256         00100000000     cocoa       100
                [...]    
1024        10000000000     oven        400
                [...]    
1625        11001011001     zones       659
1626        11001011010     zoom        65A
1627        11001011011                 65B
                [...]    
2048        11111111111                 7FF

The values above 1626 are discarded, for this reason we need to insert the double of entropy. This way, we have a fairly high chance of finding all 24 valid words.
If an unluky case happen, the script alert you to add some values in the entropy sequence to change the final result.

Additional documentation https://kdmukai-bot.github.io/seedsigner-ai-analysis/dice/standard.html

# Checksum

To generate the checksum we need to take the first 3 characters of each word and concatenate them. 
The algorithm used for the checksum is CRC32, applied to the concatenated global string achieved.

The final step is to take the checksum index modulo 24, the number of words generated.

The result is a index to apply to the 24 words list generated. Get the word corrispondent to the calculated index and we have the 25th word of the seed phrase. 

https://docs.getmonero.org/mnemonics/legacy/

# Test script

Just for testing purpose you can generate a pseudo-random sequence of throws with this command:

```shuf -r -i 1-6 -n 204 | tr -d '\n'```


**DO NOT USE THE GENERATE SEQUENCE FOR REAL WALLET!!
USE PHYSICAL DICES!!!**


# Usage

Monero legacy seeds have 256 bits of entropy. The script request you to insert 512 entropy because you need to generate
exactly 24 words. These words have 10.6 bits and rounded to 11 you achieve a range between 00000000001 and 11001011010.
If the entropy generate a number above this range, the script skip it and pass to the next value in the goal to achieve the final 24 words.

Generate 25 words seed from default D6 dice throws

```bash monero-legacy-dice-generator.sh -s <sequence_of_values>```


Generate 24 words seed from coin flipping

```bash monero-legacy-dice-generator.sh -s <sequence_of_values> -f 2```


Generate 25 words seed from D8 

```bash monero-legacy-dice-generator.sh -s <sequence_of_values> -f 8 ```


# Additional documentation and tools

https://jollymort.github.io/monero-wallet-generator/monero-wallet-generator-d6.html

https://kdmukai-bot.github.io/seedsigner-ai-analysis/dice/standard.html

https://docs.getmonero.org/mnemonics/legacy/

https://github.com/monero-project/monero/tree/master/src/mnemonics

# Disclaimer

This software and any outputs it generates are provided “as is” and without warranties of any kind, express or implied. The authors and contributors make no representations regarding the accuracy, reliability, security, legality, or suitability of the software or its outputs.

You are solely responsible for reviewing, validating, testing, and appropriately using any output generated by this software before relying on it or distributing it. The software may produce inaccurate, incomplete, biased, harmful, or otherwise unsuitable results.

To the fullest extent permitted by applicable law, the authors and contributors shall not be liable for any direct, indirect, incidental, consequential, or other damages, losses, claims, or liabilities arising from or related to the use of this software or its outputs.

Use of this software is at your own risk.

