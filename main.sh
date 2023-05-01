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

function check_puzzle {
	_input=$1
	_title=""
	_w=0
	_h=0
	_colored=false

	_max_rowlen=0
	_max_collen=0
	_rows_cnt=$INF
	_col_cnt=$INF
	
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

		if [[ $_rows_cnt -lt $_h ]]; then
			if [[ "$line" =~ [0-9]+[a-z] ]]; then
				_colored=true
			else
				_currow=$( echo "$line" | tr -cd ',' | wc -m )
				_currow=$(( $_currow + 1 ))
				_max_rowlen=$(( $_max_rowlen > $_currow ? $_max_rowlen : $_currow ))
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
		return 0
	else
		return 1
	fi
};

function load_puzzle {
	if check_puzzle $1; then
		nonograms_list+=( "${_title} (${_w}x${_h})" )
	fi
};

#parse puzzles
for item in ${nonograms_path_list[@]}; do
	load_puzzle ${item} 
done

clear

echo Welcome to NonoCon - nonogram game in console!
echo "Choose a puzzle from the list below (some puzzles may be excluded because they won't fit into your terminal):"

select chosen in "${nonograms_list[@]}"
do
	if [[ -z ${chosen} ]]; then
		echo Wrong number, please choose another
	else
		break
	fi
done

puzzle_name=$chosen
puzzle_number=$(($REPLY - 1))
puzzle_path=${nonograms_path_list[$puzzle_number]}
echo $(($puzzle_number + 1)) : $puzzle_name $puzzle_path

clear
echo Loading $chosen...

check_puzzle ${puzzle_path}

w=$_w
h=$_h
max_rowlen=$max_rowlen
max_collen=$_max_collen

_rows_cnt=$INF
_col_cnt=$INF
rows=( )
cols=( )

field=( )
goal=( )

while IFS= read -r line
do		
	if [[ "$line" =~ ^goal ]]; then
		[[ "$line" =~ \"(.+)\" ]]
		
		goal_str=${BASH_REMATCH[1]}
		for (( i = 0; i < ${#goal_str}; ++i )); do
			goal+=( ${goal_str:i:1} )
		done
	fi

	if [[ $_rows_cnt -lt $_h ]]; then
		_tmparr=($( echo "$line" | tr ',' '\n'))
		
		for i in ${!_tmparr[@]}; do
			rows+=( "${_tmparr[$i]}" )
		done

		for (( i = 0; i < $(( max_rowlen - ${#_tmparr[@]} )); ++i )); do
			rows+=( "0" )
		done

		_rows_cnt=$(( $_rows_cnt + 1 ))
	fi

	if [[ $_col_cnt -lt $_w ]]; then
		_tmparr=($( echo "$line" | tr ',' '\n'))
		
		for i in ${!_tmparr[@]}; do
			cols+=( "${_tmparr[$i]}" )
		done

		for (( i = 0; i < $(( max_collen - ${#_tmparr[@]} )); ++i )); do
			cols+=( "0" )
		done
		
		_col_cnt=$(( $_col_cnt + 1 ))
	fi

	if [[ "$line" =~ ^width ]]; then
		[[ "$line" =~ [0-9]+ ]]
		_w=${BASH_REMATCH[0]}
	fi
	
	if [[ "$line" =~ ^height ]]; then
		[[ "$line" =~ [0-9]+ ]]
		_h=${BASH_REMATCH[0]}
	fi

	if [[ "$line" =~ ^rows ]]; then
		_rows_cnt=0
	fi

	if [[ "$line" =~ ^columns ]]; then
		_col_cnt=0
	fi

done < "${puzzle_path}"

field=(${goal[@]})
for i in ${!field[@]}; do
	field[$i]=0
done

clear
