/* Replicating figure 1 */

/* open dataset */
use "$replication/data/data_cycles_of_fire.dta", clear

/* set as panel */
xtset kab_code year

/* Keep only observations in electoral cycles */
keep if election_in_2yrs==1 | election_next_year==1 | election_this_year==1 | election_last_year==1 | election_2yrs_ago==1

/* Generate zero reference for coefplot */
cap gen zero = 0
mean zero
est sto mean

/* Define special characters */
local tabstop = uchar(9)
local space = uchar(160)
local de = uchar(916)

/* Initialize analysis parameters */
local types num area slab_lag
local typenames "Ignitions" "Area burned" "Slash and burn"
local n_types : word count `types'

local outcomes forest productive protected
local outcomenames "Entire`space'forest" "Productive" "Protected"
local n_outcomes : word count `outcomes'

local spec "election_in_2yrs election_next_year election_this_year election_last_year"

/* Main analysis loop */
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
        qui reg `type'_`outcome' `spec' i.kab_code i.year 
        local obs = `e(N)'

        /* Run Poisson regression */
        poi2hdfe `type'_`outcome' `spec', id1(kab_code) id2(year) cluster(kab_code)
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
        coefplot (mean) (., ciopts(recast(rline) lcolor(navy)) 
                recast(connected) lcolor(navy) mcolor(navy)),
                vertical legend(off) 
                keep(election_in_2yrs election_next_year election_this_year election_last_year zero)
                order(zero election_last_year election_this_year election_next_year election_in_2yrs)
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
                ylab(-0.8 "-0.8" -0.4 "-0.4" 0 "0" 0.4 "0.4" 0.8 "0.8", gmin gmax labsize(large))
                xlabel(,labsize(large))
                text(`halfdiff' 4.3 "`diff'", place(e) size(large) col(black))
                text(`halfdiff2' 4.3 "`test2'", place(e) size(large) col(black))
                addplot((pci `thisyear' 4.2 `lastyear' 4.2, ylab(0(0.05)0.2) 
                        xlab(0(200)1000) lpattern(solid) col(gs5))
                        (pci `thisyear' 4.1 `thisyear' 4.2, ylab(0(0.05)0.2)
                        xlab(0(200)1000) lpattern(solid) col(gs5))
                        (pci `lastyear' 4.1 `lastyear' 4.2, ylab(0(0.05)0.2)
                        xlab(0(200)1000) lpattern(solid) col(gs5)))
                note("`note1'`mdv' pixels" "`note2' `test1'", span size(large) position(`align'));
        #delimit cr

        local x "`type'_`outcome'_year"
        tempfile `x'
        graph save $replication/output/figures/`x'.gph, replace 
    }
}

/* Combine all graphs */
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
#delimit cr

/* Export final figure */
graph export "$replication/output/figures/figure_1.pdf", as(pdf) replace 