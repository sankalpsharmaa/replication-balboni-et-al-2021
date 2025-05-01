/* Replication file for online appendix: */
/* "Cycles of Deforestation? Politics and Forest Burning in Indonesia" */
/* Authors: Clare Balboni, Robin Burgess, Anton Heil, Jonathan Old, Ben Olken */

/*----------------------------------------------------
    1. Global settings
----------------------------------------------------*/
set seed 987654321

/*----------------------------------------------------
    2. Appendix B: Full regression results by land types
----------------------------------------------------*/


global replication "/Users/sankalpsharma/replication-balboni-et-al-2021"

cap mkdir $replication/output/tables

use "$replication/data/data_cycles_of_fire.dta", clear

xtset kab_code year

/* Keep only observations in electoral cycles */
keep if election_in_2yrs==1 | election_next_year==1 | election_this_year==1 | election_last_year==1 | election_2yrs_ago==1

/* Define special characters */
local tabstop = uchar(9)
local space = uchar(160)
local de = uchar(916)

/* Initialize analysis parameters */
local types num area slab_lag
local typenames "Ignitions" "Area burned" "Slash and burn"
local n_types : word count `types'

local outcomes forest productive protected concession palm fibre logging nomansland
local outcomenames "Entire`tabstop'forest" "Productive" "Protected" "Concession" "Oil`tabstop'Palm" "Fibre" "Logging" "Unleased"
local n_outcomes : word count `outcomes'

local fes year year_province
local fenames "Year" "Year*Province"
local fenames y yp
local n_fes : word count `fes'

local spec "election_in_2yrs election_next_year election_this_year election_last_year"
local tablenumber = 0

/* Main analysis loop */
forv b = 1/`n_fes' {
    local fe : word `b' of `fes'
    local fename: word `b' of `fenames'

    forv t = 1/`n_types' {
        local tablenumber = `tablenumber' + 1
        local type : word `t' of `types'
        local typename : word `t' of `typenames'
        local typename : di "`typename'"

        forv a = 1/`n_outcomes' {
            local outcome : word `a' of `outcomes'
            local lbl : var la `type'_`outcome'
            local outcomename : word `a' of `outcomenames'
            local outcomename : di "`outcomename'"

            /* Set append/replace for output */
            if `a'==1 local apprep replace
            else local apprep append

            /* Get number of observations */
            qui reg `type'_`outcome' `spec' i.kab_code i.`fe'
            local obs = `e(N)'

            /* Run Poisson regression */
            poi2hdfe `type'_`outcome' `spec', id1(kab_code) id2(`fe') cluster(kab_code)
            est sto `type'_`outcome'_`fename'

            /* Joint significance test */
            test `spec'
            if `r(p)' < 0.01 local test1 "\textless 0.01"
            else local test1 : di %9.3fc `r(p)'
            local test1 "`test1'"

            /* This year vs. last year test */
            test election_this_year=election_last_year
            if `r(p)' < 0.01 local test2 "\textless 0.01"
            else local test2 : di %9.3fc `r(p)'
            local test2 "`test2'"

            /* Calculate mean of dependent variable */
            quietly sum `type'_`outcome' if e(sample)
            local omean : di %9.2fc `r(mean)'

            /* Prepare coefficients for results */
            matrix b = e(b)
            local thisyear = b[1,3]
            local lastyear = b[1,4]
            local diff = `lastyear'-`thisyear'
            local diff: di %9.3fc `diff'

            /* Add test results to stored estimates */
            est resto `type'_`outcome'_`fename'
            estadd local obs1 "`obs'"
            estadd local omean1 "`omean'"
            estadd local test1 "`test1'"
            estadd local test2 "`test2'"
            estadd local diff2 "`diff'"
            estadd local dfe "District"
            
            /* Set year FE label */
            if "`fe'" == "year" estadd local yfe "Year"
            else if "`fe'" == "year_province" estadd local yfe "Prov-year"
            
            est sto `type'_`outcome'_`fename'
        }

        /* Generate LaTeX table output */
        #delimit ;
        estout `type'_forest_`fename' `type'_concession_`fename'  
              `type'_palm_`fename' `type'_fibre_`fename' 
              `type'_logging_`fename' `type'_nomansland_`fename' 
              `type'_protected_`fename'
            using "$replication/output/tables/table_b`tablenumber'.tex", style(tex)  
            wrap varwidth(25) 
            varlabels(
              election_in_2yrs "\hspace{0.2cm} In 2 years"
              election_next_year "\hspace{0.2cm} Next year"
              election_this_year "\hspace{0.2cm} This year"
              election_last_year "\hspace{0.2cm} Last year"
              )
            keep(`spec')
            cells(b(star fmt(%9.3f)) se(par)) 
            hlinechar("{hline @1}")
            stats(obs1 omean1 dfe yfe test1 diff2 test2, 
                labels("\midrule \addlinespace Observations"  
                      "Mean of DV" 
                      "Spatial FE" 
                      "Temporal FE" 
                      "Joint p-value"  
                      "\textbf{This vs. last:} \\ \hspace{0.2cm} Difference"
                      "  \hspace{0.2cm} p-value"))
            stardrop(`spec')
            nolabel replace collabels(none) mlabels(none)
            note("\bottomrule");
        #delimit cr
    }
}

/*----------------------------------------------------
    3. Appendix C: Robustness for children/parents splits
----------------------------------------------------*/
use "$replication/data/data_cycles_of_fire.dta", clear
xtset kab_code year

/* Keep only observations in electoral cycles */
keep if election_in_2yrs==1 | election_next_year==1 | election_this_year==1 | election_last_year==1 | election_2yrs_ago==1

/* Generate zero reference for coefplot */
cap gen zero = 0
mean zero
est sto mean

/* Initialize analysis parameters */
local tabstop = uchar(9)
local space = uchar(160)
local de = uchar(916)

local types num area slab_lag
local typenames "Ignitions" "Area burned" "Slash and burn"
local n_types : word count `types'

local outcomes forest productive protected
local outcomenames "Entire`space'forest" "Productive" "Protected"
local n_outcomes : word count `outcomes'

local spec "election_in_2yrs election_next_year election_this_year election_last_year"
local figurenumber = 0

/* Robustness check loop */
foreach exclude_var of varlist is_child is_parent {
    local figurenumber = `figurenumber' + 1

    forv t = 1/`n_types' {
        local type : word `t' of `types'
        local typename : word `t' of `typenames'
        local typename : di "`typename'"

        forv a = 1/`n_outcomes' {
            local outcome : word `a' of `outcomes'
            local lbl : var la `type'_`outcome'
            local outcomename : word `a' of `outcomenames'
            local outcomename : di "`outcomename'"

            /* Set append/replace for output */
            if `a'==1 local apprep replace
            else local apprep append

            /* Get number of observations */
            qui reg `type'_`outcome' `spec' i.kab_code i.year if `exclude_var'!=1
            local obs = `e(N)'

            /* Run Poisson regression */
            poi2hdfe `type'_`outcome' `spec' if `exclude_var'!=1, id1(kab_code) id2(year) cluster(kab_code)
            est sto `type'_`outcome'_yr

            /* Joint significance test */
            test `spec'
            if `r(p)' < 0.01 local test1 "< 0.01"
            else local test1 : di %9.3fc `r(p)'
            local test1 `test1'

            /* This year vs. last year test */
            test election_this_year=election_last_year
            if `r(p)' < 0.01 local test2 "p < 0.01"
            else {
                local test2 : di %9.3fc `r(p)'
                local test2 = subinstr(string(`test2'), " ", "", 5)
                local test2 : di "p = 0`test2'"
            }
            local test2 `test2'

            /* Calculate mean of dependent variable */
            quietly sum `type'_`outcome' if e(sample)
            local mdv : di %9.2fc `r(mean)'
            local mdv = subinstr(string(`mdv'), " ", "", 5)
            if `mdv' < 1 local mdv : di "0`mdv'"
            else if `mdv' >= 1 local mdv : di "`mdv'"

            /* Prepare coefficients for plotting */
            matrix b = e(b)
            local thisyear = b[1,3]
            local lastyear = b[1,4]
            local diff = `lastyear'-`thisyear'
            local diff: di %9.3fc `diff'
            local diff = subinstr(string(`diff'), " ", "", 5)

            if `lastyear' - `thisyear' > 0 local diff: di "`de' = 0`diff'"
            else if `lastyear' - `thisyear' < 0 {
                local diff = - `diff'
                local diff: di "`de' = -0`diff'"
            }

            local halfdiff = 0.5*(`lastyear'+`thisyear')+0.075
            local halfdiff2 = 0.5*(`lastyear'+`thisyear')-0.075

            /* Set graph parameters */
            if `a'!=1 local ti ""
            else if `a'==1 local ti `typename'

            if `a'!=3 local xti ""
            else if `a'==3 local xti "Closest election"

            if `t'!=1 {
                local yti ""
                local note1 ""
                local note2 ""
                local align = 6
            }
            else if `t'==1 {
                local yti `outcomename'
                local note1 "Mean of dependent variable: "
                local note2 "Joint p-value for cycle:`tabstop'`tabstop'"
                local align = 7
            }

            est resto `type'_`outcome'_yr

            /* Generate coefficient plot */
            #delimit ;
            coefplot (mean) (., ciopts(recast(rline) lcolor(navy)) recast(connected) 
                    lcolor(navy) mcolor(navy)),
                    vertical legend(off) 
                    keep(election_in_2yrs election_next_year election_this_year election_last_year zero)
                    order(election_in_2yrs election_next_year election_this_year election_last_year zero)
                    coeflabels(zero="t-2"
                              election_this_year="t"
                              election_last_year="t-1"
                              election_next_year="t+1"
                              election_in_2yrs="t+2")
                    pstyle(small) nooffset
                    graphregion(color(white) margin(tiny))
                    title("`ti'", size(huge) color(black))
                    xtitle("`xti'", size(vlarge)) 
                    ytitle("`yti'", size(huge) color(black))
                    ysc(range(-0.9))
                    ylab(-0.8 "-0.8" -0.4 "-0.4" 0 "0" 0.4 "0.4" 0.8 "0.8", 
                        gmin gmax labsize(large))
                    xlabel(,labsize(large))
                    text(`halfdiff' 4.3 "`diff'", place(e) size(large) col(black))
                    text(`halfdiff2' 4.3 "`test2'", place(e) size(large) col(black))
                    addplot((pci `thisyear' 4.2 `lastyear' 4.2, ylab(0(0.05)0.2) 
                           xlab(0(200)1000) lpattern(solid) col(gs5))
                           (pci `thisyear' 4.1 `thisyear' 4.2, ylab(0(0.05)0.2)
                           xlab(0(200)1000) lpattern(solid) col(gs5))
                           (pci `lastyear' 4.1 `lastyear' 4.2, ylab(0(0.05)0.2)
                           xlab(0(200)1000) lpattern(solid) col(gs5)))
                    note("`note1'`mdv' pixels" "`note2' `test1'", 
                        span size(large) position(`align'));
            #delimit cr

            local x "`type'_`outcome'_year"
            tempfile `x'
            graph save `x.gph', replace 
        }
    }

    /* Combine graphs */
    #delimit ;
    graph combine
        num_forest_year.gph
        area_forest_year.gph
        slab_lag_forest_year.gph
        num_productive_year.gph
        area_productive_year.gph
        slab_lag_productive_year.gph
        num_protected_year.gph
        area_protected_year.gph
        slab_lag_protected_year.gph,
        ycommon col(3) imargin(2 1 1 1) iscale(*0.5) ysize(10) xsize(10)
        graphregion(color(white));
    graph export $replication/output/figures/figure_c`figurenumber'.pdf, as(pdf) replace;
    #delimit cr
}
