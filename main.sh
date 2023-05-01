#!/bin/bash

nonograms_path_list=( $( find ./ext -name "*.non") )

nonograms_list=( )

for item in ${nonograms_path_list[@]};
do
	_input=${item}
	_title=""
	_w=0
	_h=0

	while IFS= read -r line
	do
		if [[ "$line" =~ ^title ]]
		then
			[[ "$line" =~ \"(.+)\" ]]
			_title="${BASH_REMATCH[1]}"
		fi

		if [[ "$line" =~ ^width ]]
		then
			[[ "$line" =~ [0-9]+ ]]
			_w=${BASH_REMATCH[0]}
		fi

		if [[ "$line" =~ ^height ]]
		then
			[[ "$line" =~ [0-9]+ ]]
			_h=${BASH_REMATCH[0]}
		fi
	done < "${_input}"
	
	nonograms_list+=( "${_title} (${_w}x${_h})" )
done

echo Welcome to NonoCon - nonogram game in console
echo Choose a puzzle from the list below:

select chosen in "${nonograms_list[@]}"
do
	if [[ -z ${chosen} ]]
	then
		echo Wrong number, please choose another
	else
		break
	fi
done

echo $REPLY : $chosen ${nonograms_path_list[( $REPLY - 1 )]}