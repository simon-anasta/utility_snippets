/*
Convert Stata binary .dta  files to Excel or CSV formats
2022-05-31
*/

/* Read dta file */
use "I:\MAA20XX-YY\path\for\input\file_name.dta", clear

/* write Excel file */
export excel using "I:\MAA20XX-YY\path\for\output\file_name.xlsx", firstrow(variables)  sheet(data) replace 

/* write CSV file */
export delimited using "I:\MAA20XX-YY\path\for\output\file_name.csv", replace 
