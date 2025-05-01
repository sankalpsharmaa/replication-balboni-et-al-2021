/* Makefile for replicating "Cycles of Deforestation? Politics and Forest Burning in Indonesia"
Authors: Clare Balboni, Robin Burgess, Anton Heil, Jonathan Old, Ben Olken
*/

clear all
set more off
set matsize 10000		

set seed 987654321

/***********************************************
Change "replication" file path to your local directory 
where you pulled the GitHub repository
***********************************************/

global replication "/Users/sankalpsharma/replication-balboni-et-al-2021"
cap mkdir $replication/output/tables
cap mkdir $replication/output/figures

global data "$replication/data"
global output "$replication/output
global tex "$replication/tex

local packages poi2hdfe hdfe reg2hdfe		
foreach p of local packages {
	cap which `p'.ado
	if _rc==111 ssc install `p'
	}

/* Run replication of main paper figure */ 
do "$replication/fig1.do"

/* Replicate online appendix tables */ 
do "$replication/appendix.do"
