#!/bin/bash

# field will look like this (every fifth row/column will be marked with ╬):
# <Puzzle name>
#   ║11
#   ║11
#   ║11322
# ══╬════╬
#  2║██
#  1║  █
#  3║███
#  3║  ███
# 22╬██ ██

TERM_H=$( tput lines )
TERM_W=$( tput cols )
INF=10000000000

clear
echo Loading...

nonograms_path_list=( $( find ./ext ./local -name "*.non") )

valid_nonograms_list=( )
valid_nonograms_list_paths=( )

function CheckPuzzle {
	CHECKPUZZLE_input=$1
	CHECKPUZZLE_title=""
	CHECKPUZZLE_w=0
	CHECKPUZZLE_h=0
	CHECKPUZZLE_iscolored=0

	CHECKPUZZLE_maxrows=0
	CHECKPUZZLE_maxcols=0
	CHECKPUZZLE_rowscnt=$INF
	CHECKPUZZLE_colscnt=$INF
	
	while IFS= read -r _line
	do
		if [[ "$_line" =~ ^title ]]; then
			[[ "$_line" =~ \"(.+)\" ]]
			CHECKPUZZLE_title="${BASH_REMATCH[1]}"
		fi
		
		if [[ "$_line" =~ ^width ]]; then
			[[ "$_line" =~ [0-9]+ ]]
			CHECKPUZZLE_w=${BASH_REMATCH[0]}
		fi
		
		if [[ "$_line" =~ ^height ]]; then
			[[ "$_line" =~ [0-9]+ ]]
			CHECKPUZZLE_h=${BASH_REMATCH[0]}
		fi
		
		if [[ "$_line" =~ ^color ]]; then
			CHECKPUZZLE_iscolored=1
		fi

		if [[ $CHECKPUZZLE_rowscnt -lt $CHECKPUZZLE_h ]]; then
			if [[ "$_line" =~ [0-9]+[a-z] ]]; then
				CHECKPUZZLE_iscolored=1
			else
				_currow=$( echo "$_line" | tr -cd ',' | wc -m )
				_currow=$(( _currow + 1 ))
				CHECKPUZZLE_maxrows=$(( CHECKPUZZLE_maxrows > _currow ? CHECKPUZZLE_maxrows : _currow ))
			fi
			
			CHECKPUZZLE_rowscnt=$(( CHECKPUZZLE_rowscnt + 1 ))
		fi

		if [[ $CHECKPUZZLE_colscnt -lt $CHECKPUZZLE_w ]]; then
			if [[ "$_line" =~ [0-9]+[a-z] ]]; then
				CHECKPUZZLE_iscolored=1
			else
				_curcol=$( echo "$_line" | tr -cd ',' | wc -m )
				_curcol=$(( _curcol + 1 ))
				CHECKPUZZLE_maxcols=$(( CHECKPUZZLE_maxcols > _curcol ? CHECKPUZZLE_maxcols : _curcol ))
			fi
			
			CHECKPUZZLE_colscnt=$(( CHECKPUZZLE_colscnt + 1 ))
		fi
		
		if [[ "$_line" =~ ^rows ]]; then
			CHECKPUZZLE_rowscnt=0
		fi

		if [[ "$_line" =~ ^columns ]]; then
			CHECKPUZZLE_colscnt=0
		fi
		
	done < "${CHECKPUZZLE_input}"
	
	# echo $CHECKPUZZLE_input $CHECKPUZZLE_iscolored $CHECKPUZZLE_maxcols $CHECKPUZZLE_maxrows
	
	# see layout for explanations
	if [[ ( $CHECKPUZZLE_iscolored = 0 ) && ( $TERM_W -gt $(( CHECKPUZZLE_w + CHECKPUZZLE_maxrows + 1 )) ) 
	&& ( $TERM_H -gt $(( CHECKPUZZLE_h + CHECKPUZZLE_maxcols + 2 )) ) ]]; then
		return 0
	else
		return 1
	fi
};

function load_puzzle {
	if CheckPuzzle "$1"; then
		valid_nonograms_list+=( "${CHECKPUZZLE_title} (${CHECKPUZZLE_w}x${CHECKPUZZLE_h})" )
		valid_nonograms_list_paths+=( "$1" )
	fi
};

#parse puzzles
for _item in "${nonograms_path_list[@]}"; do
	load_puzzle "$_item" 
done

clear

echo Welcome to NonoCon - nonogram game in console!
echo "Choose a puzzle from the list below (some puzzles may be excluded because they won't fit into your terminal):"

select _chosen in "${valid_nonograms_list[@]}"
do
	if [[ -z ${_chosen} ]]; then
		echo Wrong number, please choose another
	else
		break
	fi
done

PUZZLE_NAME=$_chosen
PUZZLE_NUMBER=$(( REPLY - 1 ))
PUZZLE_PATH=${valid_nonograms_list_paths[$PUZZLE_NUMBER]}

clear
echo Loading "$PUZZLE_NAME"...

CheckPuzzle "$PUZZLE_PATH"

PUZZLE_W=$CHECKPUZZLE_w
PUZZLE_H=$CHECKPUZZLE_h
PUZZLE_MAXROWS=$CHECKPUZZLE_maxrows
PUZZLE_MAXCOLS=$CHECKPUZZLE_maxcols

FIELD_H=$(( PUZZLE_H + PUZZLE_MAXCOLS + 2 ))
FIELD_W=$(( PUZZLE_W + PUZZLE_MAXROWS + 1 ))

rowscnt=$INF
colscnt=$INF
ROWS=( )
COLS=( )

field=( )
GOAL=( )

#CHECK THE FUCKING VARIABLES
while IFS= read -r line
do		
	if [[ "$line" =~ ^goal ]]; then
		[[ "$line" =~ \"(.+)\" ]]
		
		_goal_str=${BASH_REMATCH[1]}
		for (( i = 0; i < ${#_goal_str}; ++i )); do
			GOAL+=( ${_goal_str:i:1} )
		done
	fi

	if [[ $rowscnt -lt $PUZZLE_H ]]; then
		_tmparr=( $( echo "$line" | tr ',' '\n' | rev) )
		
		for i in "${!_tmparr[@]}"; do
			ROWS+=( "${_tmparr[$i]}" )
		done

		for (( i = 0; i < $(( PUZZLE_MAXROWS - ${#_tmparr[@]} )); ++i )); do
			ROWS+=( "0" )
		done

		rowscnt=$(( rowscnt + 1 ))
	fi

	if [[ $colscnt -lt $PUZZLE_W ]]; then
		_tmparr=($( echo "$line" | tr ',' '\n' | rev ))
		
		for i in "${!_tmparr[@]}"; do
			COLS+=( "${_tmparr[$i]}" )
		done

		for (( i = 0; i < $(( PUZZLE_MAXCOLS - ${#_tmparr[@]} )); ++i )); do
			COLS+=( "0" )
		done
		
		colscnt=$(( colscnt + 1 ))
	fi

	if [[ "$line" =~ ^rows ]]; then
		rowscnt=0
	fi

	if [[ "$line" =~ ^columns ]]; then
		colscnt=0
	fi

done < "${PUZZLE_PATH}"

field=(${GOAL[@]})
for i in "${!field[@]}"; do
	field[i]=0
done

clear

#drawing a field

tput cup 0 $(( (PUZZLE_W + PUZZLE_MAXROWS + 1)/2 ))
echo "$PUZZLE_NAME"

#vignette part
for (( i = 0; i < FIELD_H - 1 ; ++i )); do
	tput cup $(( i + 1)) $PUZZLE_MAXROWS

	if ! (( (i - PUZZLE_MAXCOLS) % 5 )); then
		echo ╬
	else
		echo ║
	fi
done

for (( i = 0; i < FIELD_W; ++i )); do
	tput cup $(( PUZZLE_MAXCOLS + 1 )) $i

	if ! (( (i - PUZZLE_MAXROWS) % 5 )); then
		echo ╬
	else
		echo ═
	fi
done

#numbers
for i in "${!ROWS[@]}"; do
	str=${ROWS[$i]}

	if [[ $str != "0" ]]; then
		tput cup $(( i/PUZZLE_MAXROWS + PUZZLE_MAXCOLS + 1 + 1 )) $(( PUZZLE_MAXROWS - i%PUZZLE_MAXROWS - 1 ))
		echo "${str:0:1}"
	fi
done

for i in "${!COLS[@]}"; do
	str=${COLS[$i]}

	if [[ $str != "0" ]]; then
		tput cup $(( PUZZLE_MAXCOLS - i%PUZZLE_MAXCOLS - 1 + 1 )) $(( i/PUZZLE_MAXCOLS + PUZZLE_MAXROWS + 1 ))
		echo "${str:0:1}"
	fi
done

function is_complete {
	for i in "${!field[@]}"; do
		if [[ ${field[i]} != ${GOAL[i]} ]]; then
			return 0
		fi
	done

	return 1
};

tput cnorm
tput cup $(( PUZZLE_MAXCOLS + 2 )) $(( PUZZLE_MAXROWS + 1 ))

cur_x=$(( PUZZLE_MAXCOLS + 2 ))
cur_y=$(( PUZZLE_MAXROWS + 1 ))

change_cell=0

while is_complete
do
	read -rsn1 input
    case "$input"
	in
		h)
			cur_y=$(( cur_y - 1 > PUZZLE_MAXROWS + 1 ? cur_y - 1 : PUZZLE_MAXROWS + 1 ))
			;;
		j)
			cur_x=$(( cur_x - 1 > PUZZLE_MAXCOLS + 2 ? cur_x - 1 : PUZZLE_MAXCOLS + 2 ))
			;;
		k)
			cur_x=$(( cur_x + 1 < FIELD_H - 1 ? cur_x + 1 : FIELD_H - 1 ))
			;;
		l)
			cur_y=$(( cur_y + 1 < FIELD_W - 1 ? cur_y + 1 : FIELD_W - 1 ))
			;;
		f)
			change_cell=1
			;;
		q)
			break
			;;
    esac

	tput cup $cur_x $cur_y
	
	if [[ $change_cell = 1 ]]; then
		cell_coord=$(( PUZZLE_W*(cur_x - PUZZLE_MAXCOLS - 2) + (cur_y - PUZZLE_ROWS - 1) - 2 ))
		
		if [[ ${field[$cell_coord]} = 0 ]]; then
			printf "▓\b"
			field[cell_coord]=1
		else
			printf " \b"
			field[cell_coord]=0
		fi
	fi
	change_cell=0
done

tput cup $TERM_H 0