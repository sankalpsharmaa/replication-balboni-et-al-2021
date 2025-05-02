# Replication of "Cycles of Deforestation? Politics and Forest Burning in Indonesia"

This repository contains the replication code for the paper "Cycles of Deforestation? Politics and Forest Burning in Indonesia" by Clare Balboni, Robin Burgess, Anton Heil, Jonathan Old, and Ben Olken.

## Setup Instructions

1. **Prerequisites**
   - Stata 14 or later
   - Required Stata packages:
     - `poi2hdfe`
     - `hdfe`
     - `reg2hdfe`

2. **Installation**
   - Clone this repository to your local machine
   - The required Stata packages will be automatically installed when you run the replication code

3. **Directory Structure**
   - `data/`: Contains the main dataset `data_cycles_of_fire.dta`
   - `output/`: Will contain generated tables and figures
   - `tex/`: Contains LaTeX files for the paper
   - `fig1.do`: Main figure replication code
   - `appendix.do`: Appendix tables replication code
   - `makefile.do`: Main script that runs all replication code

## Running the Replication

1. Open Stata
2. Navigate to the repository directory
3. Edit the `makefile.do` file:
   - Update the `global replication` path to point to your local repository directory
4. Run the replication by executing:
   ```
   do makefile.do
   ```

This will:
- Install any missing required packages
- Create necessary output directories
- Generate Figure 1 from the main paper
- Generate all appendix tables

## Output

The replication will generate:
- Figures in `output/figures/`
- Tables in `output/tables/`

## Notes

- The replication uses a fixed seed (987654321) to ensure reproducibility
- The code requires approximately 10,000 matrix size (`set matsize 10000`)
- All output directories will be created automatically if they don't exist
