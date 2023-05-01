#!/bin/bash

# field will look like this (every fifth row/column will be marked with ╬):
# <Puzzle name>  MM:SS
#   ║11
#   ║11
#   ║11322
# ══╬════╬
#  2║██
#  1║  █
#  3║███
#  3║  ███
# 22╬██ ██

term_h=$( tput lines )
term_w=$( tput cols )
INF=10000000000

clear
echo Loading...

nonograms_path_list=( $( find ./ext -name "*.non") )

nonograms_list=( )

function load_puzzle {
	_input=$1
	_title=""
	_w=0
	_h=0
	_colored=false
	
	while IFS= read -r line
	do
		if [[ "$line" =~ ^title ]]; then
			[[ "$line" =~ \"(.+)\" ]]
			_title="${BASH_REMATCH[1]}"
		fi
		
		if [[ "$line" =~ ^width ]]; then
			[[ "$line" =~ [0-9]+ ]]
			_w=${BASH_REMATCH[0]}
		fi
		
		if [[ "$line" =~ ^height ]]; then
			[[ "$line" =~ [0-9]+ ]]
			_h=${BASH_REMATCH[0]}
		fi
		
		if [[ "$line" =~ ^color ]]; then
			_colored=true
		fi
		
	done < "${_input}"
	
	_max_rowlen=0
	_max_collen=0
	_rows_cnt=$INF
	_col_cnt=$INF
	
	while IFS= read -r line
	do
		if [[ $_rows_cnt -lt $_h ]]; then
			if [[ "$line" =~ [0-9]+[a-z] ]]; then
				_colored=true
			else
				_currow=$( echo "$line" | tr -cd ',' | wc -m )
				_currow=$(( $_currow + 1 ))
				_max_rowlen=$(( $_max_rowlen > $_currow ? $_max_rowlen : $_currow ))
				a=3
			fi
			
			_rows_cnt=$(( $_rows_cnt + 1 ))
		fi

		if [[ $_col_cnt -lt $_w ]]; then
			if [[ "$line" =~ [0-9]+[a-z] ]]; then
				_colored=true
			else
				_curcol=$( echo "$line" | tr -cd ',' | wc -m )
				_curcol=$(( $_curcol + 1 ))
				_max_collen=$(( $_max_collen > $_curcol ? $_max_collen : $_curcol ))
			fi
			
			_col_cnt=$(( $_col_cnt + 1 ))
		fi
		
		if [[ "$line" =~ ^rows ]]; then
			_rows_cnt=0
		fi

		if [[ "$line" =~ ^columns ]]; then
			_col_cnt=0
		fi
	done < "${_input}"
	
	# echo $item $_colored $_max_collen $_max_rowlen
	
	# see layout for explanations
	if [[ ( "$_colored" = false ) && ( $term_w -gt $(( $_w + 1 + $_max_rowlen )) ) && ( $term_h -gt $(( $_h + 1 + 1 + $_max_collen )) ) ]]; then
		nonograms_list+=( "${_title} (${_w}x${_h})" )
	fi
};

#parse puzzles
for item in ${nonograms_path_list[@]}; do
	load_puzzle ${item} 
done

echo Welcome to NonoCon - nonogram game in console
echo "Choose a puzzle from the list below (some puzzles may be excluded because they won't fit into your terminal):"

select chosen in "${nonograms_list[@]}"
do
	if [[ -z ${chosen} ]]; then
		echo Wrong number, please choose another
	else
		break
	fi
done

puzzle_number=$(($REPLY - 1))
echo $(($puzzle_number + 1)) : $chosen ${nonograms_path_list[$puzzle_number]}
