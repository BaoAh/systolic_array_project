#!/bin/bash

timestamp=$(date +%Y/%m/%d-%H:%M:%S)
printf "// This is generated automatically on ${timestamp}\n"

STATES=("S_WAIT"                        \
        "S_READ_A"                      \
        "S_READ_B"                      \
        "S_FEED"                        \
        "S_BLK_CHK"                     \
        "S_WRIT"                        \
        "S_BLK_B"                       \
        "S_BLK_A"                       \
        "S_END"                         \
)

OUT_FLAGS=("CMD_WAIT"                   \
           "CMD_READ_A"                 \
           "CMD_READ_B"                 \
           "CMD_FEED"                   \
           "CMD_WRIT"                   \
           "CMD_BLK_B"                  \
           "CMD_BLK_A"                  \
)

INT_FLAGS=("INT_WAIT"                   \
           "INT_READ_A"                 \
           "INT_READ_B"                 \
           "INT_FEED"                   \
           "INT_WRIT"                   \
           "INT_BLK_B"                  \
           "INT_BLK_A"                  \
)

def_pattern="%-30s \t %-3s\n"
# Generate macro
printf "\`ifndef __FLAG_DEF__\n"
printf "\`define __FLAG_DEF__\n"

# Generate interrupt flags
len=${#INT_FLAGS[@]}
printf "\n// There're ${len} interrupt flags in this design\n"
for((idx=0; idx<${len}; idx++))
do
  printf "$def_pattern" "\`define ${INT_FLAGS[$idx]}" "${idx}"
done

# Generate interrupt flag width
printf "$def_pattern" "\`define INT_FLAG_W" "`expr ${idx}`"

# Generate output flags
len=${#OUT_FLAGS[@]}
printf "\n// There're ${len} output flags in this design\n"
for((idx=0; idx<${len}; idx++))
do
  printf "$def_pattern" "\`define ${OUT_FLAGS[$idx]}" "${idx}"
done

# Generate output flag width
printf "$def_pattern" "\`define CMD_FLAG_W" "`expr ${idx}`"


# Generate FSM states
len=${#STATES[@]}
printf "\n// There're ${len} states in this design\n"
for((idx=0; idx<${len}; idx++))
do
  printf "$def_pattern" "\`define ${STATES[$idx]}" "${idx}"
done

# Generate FSM init vector
printf "$def_pattern" "\`define S_ZVEC"     "${len}'b0"
printf "$def_pattern" "\`define STATE_W"    "${len}"

# Generate other macro
printf "\n// Macro from template\n"
printf "$def_pattern" "\`define BUF_SIZE"             "6"

printf "\n// Self-defined macro\n"
printf "$def_pattern" "\`define CNT_W"                "5"
printf "$def_pattern" "\`define GLB_CNT_W"            "3"
printf "$def_pattern" "\`define LOC_CNT_W"            "3"

# Generate end macro
printf "\n\`endif\n"
