#!/bin/bash

./udiff -a a -b b -o two_column_diff -t 1e-3
./udiff -a h.ic0 -b h2.ic0 -o spice_ic_diff -r spice_ic
./udiff -a h_op0_0.mm -b h_op0_0_1.mm -o sparse_diff -r sparse_matrix -f 111111 -x mm_sparse
./udiff -a h_op0_0.name.mm -b h_op0_0_1.name.mm -o sparse_name_diff -r sparse_matrix -f 111111 -x mm_sparse

all_case="two_column_diff spice_ic_diff sparse_diff sparse_name_diff"
for file in `ls golden`; do
	diff -q $file golden/$file
done
