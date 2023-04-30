#!/bin/bash

nonograms_list=( $( find ./ext -name "*.non") )

echo ${#nonograms_list[@]}
for elm in ${nonograms_list[@]}; do
	echo $elm
done