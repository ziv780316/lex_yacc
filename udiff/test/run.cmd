#!/bin/bash

./udiff -a a -b b -o two_column_diff -t 1e-3
./udiff -a h.ic0 -b h2.ic0 -o spice_ic_diff -r spice_ic
