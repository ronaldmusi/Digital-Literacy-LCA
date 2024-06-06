* Adolescent Girls Initiative for Learning and Empowerment Analysis
* Data file: adolescent_survey_anon
* Date: May 3, 2024
* Author: Ronald Musizvingoza

clear all

* Setting up the working directory
cd "C:\Users\musizvingoza\OneDrive - United Nations University\Datasets\Nigeria Adolescent\NGA_STATA14"
*cd "D:\Nigeria Adolescent\NGA_STATA14"


* Alternative directory (commented out)
* cd "C:\Users\user\OneDrive - United Nations University\Datasets\Nigeria Adolescent\NGA_STATA14"

* Load the dataset
use "adolescent_survey_anon.dta", clear

*merging adolescent dataset wirth caregiver dataset
sort adolescent_id

merge 1:1 adolescent_id using "caregiver_survey_anon.dta"

* Add numeric labels to data

*numlabel, detail add
*numlabel, add force // Converts all string labels to numeric labels, regardless of their current state

* Describe the data to get an overview
*describe

** generating and creating covariates
// Define an array of existing and new variable names
local old_vars state location delivery_type ch_15_last_age hb1_2_age_first_sex ch_10_age_preg ch_10_marital_status ch_16_religion ///
              aa3_9_idealmarry kn1_4_hiv_aids kn1_5_cure_hiv_aids ch8_menstration ch5_attend_school

local new_vars new_state residence school_type age age_sex age_preg marital_status religion ideal_marriage_age hiv_know hiv_cure menstration ///
               caregiver_sch

// Loop over the arrays to rename variables
forvalues i = 1/8 {
    local old_var : word `i' of `old_vars'
    local new_var : word `i' of `new_vars'
    gen `new_var' = `old_var'
}


ta ch_19_see, missing
ta ch_20_hear, missing
ta ch_21_walk, missing

// List of variables related to functional disability
local disability_vars ch_19_see ch_20_hear ch_21_walk ch_22_remembr ch_23_selfcare

// Initialize the composite variable
gen functional_disability = 0

// Loop through each variable to update the composite variable
foreach var of local disability_vars {
    // Recode missing values (.d and .c) as missing
    replace `var' = . if `var' == .d | `var' == .c
    // Update the composite variable
    replace functional_disability = functional_disability + (`var' > 0)
}

// Recode the composite variable to a binary outcome
recode functional_disability (1/5 = 2) (else = 1)

// Label the new variable and define value labels
label var functional_disability "Functional Disability Indicator"
label define fd_label 1 "No Disability" 2 "Some/Severe Disability"
label values functional_disability fd_label

// Display the distribution of the functional disability variable
tabulate functional_disability, missing

**number of siblings
gen siblings = ch_6_sisters + ch_7_brothers
ta siblings
* Generate the variable with a default category
gen siblings_cat = .

* Assign categories based on the number of siblings
replace siblings_cat = 1 if siblings == 0
replace siblings_cat = 2 if siblings >= 1 & siblings <= 4
replace siblings_cat = 3 if siblings >= 5 & siblings <= 9
replace siblings_cat = 4 if siblings >= 10

* Label the categories for better readability
label define siblings_cat 1 "0 siblings" 2 "1-4 siblings" 3 "5-9 siblings" 4 "More than 10 siblings"
label value siblings_cat siblings_cat
ta siblings_cat,missing

* Attach the label to the variable
label values siblings_cat siblings_cat_lbl
ta siblings_cat

*household size
gen new_hhsize = hh_size
* Generate the variable with a default category
gen newhhsize_cat = .

* Assign categories based on the number of siblings
replace newhhsize_cat = 1 if new_hhsize >= 0 & new_hhsize <= 5
replace newhhsize_cat = 2 if new_hhsize >= 6 & new_hhsize <= 10
replace newhhsize_cat = 3 if new_hhsize >= 10 & new_hhsize <= 20
replace newhhsize_cat = 4 if new_hhsize >= 20

* Label the categories for better readability
label define newhhsize_cat 1 "less than 5 members" 2 "6-10 members" 3 "10-20 members" 4 "More than 20 members"
label value newhhsize_cat newhhsize_cat
ta newhhsize_cat,missing

* caregiver sex
gen caregiver_sex = ch1_sex_respondent


*relationship to caregiver
* Generate the caregiver_rela variable and initialize with missing values
gen caregiver_rela = .

* Assign values based on ch2_relatn_adolecent
replace caregiver_rela = 1 if ch2_relatn_adolecent == 1 | ch2_relatn_adolecent == 2
replace caregiver_rela = 2 if ch2_relatn_adolecent == 3 | ch2_relatn_adolecent == 4
replace caregiver_rela = 3 if ch2_relatn_adolecent == 5 | ch2_relatn_adolecent == 6 | ch2_relatn_adolecent == 7 | ch2_relatn_adolecent == 8 | ch2_relatn_adolecent == 9
replace caregiver_rela = 4 if ch2_relatn_adolecent == 11 
replace caregiver_rela = 5 if ch2_relatn_adolecent == 10 | ch2_relatn_adolecent == 12

* Set missing values to "Other Relative" (category 3)
replace caregiver_rela = 3 if missing(caregiver_rela)

* Define labels for the caregiver_rela variable
label define caregiver_rela  1 "Bio CHILD" 2 "Sibling" 3 "Other Relative" 4 "Spouse" 5 "Not Related" 

* Apply the labels to the caregiver_rela variable
label value caregiver_rela caregiver_rela

* Tabulate the caregiver_rela variable including missing values
tabulate caregiver_rela, missing


**device ownership
gen owns_device = (dl3_2_mobilephone == 1) | (dl3_3_smartphone == 1) | (dl3_4_computer == 1) | (dl3_5_tabletcomputer == 1)
recode owns_device (0 = 1) (1 = 2)
label define owns_device 1 "no" 2 "yes"
label values owns_device owns_device

ta owns_device,missing

*internet access
gen internet_acc = dl3_1_internet
recode internet_acc (0 = 1) (1 = 2)
label define internet_acc 1 "no" 2 "yes"
label values internet_acc internet_acc
ta internet_acc,missing

**constructing wealth index variable
* Housing characteristics for wealth index

gen crowding= (new_hhsize/new_hhsize)<3												//Persons per room less than 3 is the recommended standard
gen impcook=inrange(ch16_prepare_food,4,5)										   //Improved cook stove
gen handwash=inlist(ch17_source_water,1,3) 			                                //Hand washing facility available
gen impwater=inlist(ch18_source_drink,1,2,3,4,5,14,15) 						      	//Improved water (using dry season only, and ignoring unimproved source even if treated)
gen imptoilet=inlist(ch19_toilet,1,2,3)					                           //Improved toilet
gen impfuel=inlist(ch21_fuel_cooking,1,2,3,5)										//cooking fuel

foreach v of varlist ch22_tv ch23_radio ch24_automobile ch25_scooter ch26_bicycle ch27_landline ch28_mobilephone ch29_stove ch30_computer ch31_oven ch32_washmachine{
 cap recode `v' (-9=.)
}
gen television=ch22_tv==1
gen radio=ch23_radio==1
gen automobile=ch24_automobile==1
gen scooter=ch25_scooter==1
gen bicycle=ch26_bicycle==1
gen landline=ch27_landline==1
gen mobilephone=ch28_mobilephone==1
gen stove=ch29_stove==1
gen computer=ch30_computer==1
gen oven=ch31_oven==1
gen washmachine=ch32_washmachine==1

lab var television "Television"
lab var radio "Radio"
lab var automobile "automobile"
lab var bicycle "Personal bicycle"
lab var landline "landline"
lab var mobilephone "Mobile Phone"
lab var stove "Improved Cooking Stove"
lab var computer "Personal Computer"
lab var oven "Oven"
lab var washmachine "washing machine"

order television-washmachine, after(impfuel)

*Wealth index using assets and housing characteristics 	

egen totass=rsum(crowding-washmachine)  
						
levelsof state, local(levs)
 
 foreach l of local levs {
   factor crowding-washmachine if state==`l'
   rotate
   predict f`l'* if state==`l'
   egen wealthindex_`l'=rmean(f`l'*) if state==`l'
   egen wquintile_`l'=cut(wealthindex_`l') if state==`l', group(5)
  
   drop f`l'*
   
}

  egen wealthindex=rsum(wealthindex_*), m
  egen wquintile=rsum(wquintile_*)
  drop wealthindex_* wquintile_*
  
	/*
	corr totass wealthindex 														//corr of 0.8860 between totass and wealth index indicates good fit
	*/
  
  compress			
 


* Recode the wquintile variable
recode wquintile (0=1) (1=2) (2=3) (3=4) (4=5)
label define wquintile_labels 1 "Poorest" 2 "Poorer" 3 "Middle" 4 "Richer" 5 "Richest"
label values wquintile wquintile_labels
tabulate wquintile, missing

* recode residence
local labels "Rural Semi-urban Urban"
local i = 1
gen residence_num = .
foreach label in `labels' {
    replace residence_num = `i' if residence == "`label'"
    local i = `i' + 1
}

label define residence_labels 1 "Rural" 2 "Semi-urban" 3 "Urban"
label values residence_num residence_labels
drop residence
rename residence_num residence
tabulate residence, missing

*recode school type
local labels "Boarding Day"
local i = 1
gen school_type_num = .
foreach label in `labels' {
    replace school_type_num = `i' if school_type == "`label'"
    local i = `i' + 1
}
label define school_type_labels 1 "Boarding" 2 "Day"
label values school_type_num school_type_labels
drop school_type
rename school_type_num school_type
tabulate school_type, missing




***************************************************************************************************************************
****************************************************************************************************************************	
****************************************************DESCRIPTIVE STATISTICS************************************************

tabulate age
tabulate new_state
tabulate residence
tabulate marital_status
tabulate school_type
tabulate religion
tabulate newhhsize_cat
tabulate owns_device
tabulate internet_acc
tabulate wquintile
tabulate caregiver_sex
tabulate caregiver_rela

*order age new_state residence marital_status school_type religion newhhsize_cat new_wquintile caregiver_sex


tabulate age owns_device, chi2 column row
tabulate new_state owns_device, chi2 column row
tabulate residence owns_device, chi2 column row
tabulate school_type owns_device, chi2 column row
tabulate religion owns_device, chi2 column row
tabulate wquintile owns_device, chi2 column row

tabulate age internet_acc, chi2 column row
tabulate new_state internet_acc, chi2 column row
tabulate residence internet_acc, chi2 column row
tabulate school_type internet_acc, chi2 column row
tabulate religion internet_acc, chi2 column row
tabulate wquintile internet_acc, chi2 column row


***************************************************************************************************************************
****************************************************************************************************************************
*Digital Literacy: Create this variable following the DigComp framework

foreach var in dg1_1_privsettngs dg1_2_locsettngs dg1_3_securitysett dg1_4_store dg1_5_privbrowse dg1_6_blockads ///
               dg1_7_progcode dg1_8_keysearch dg1_9_website dg1_10_webinfo dg1_11_advncesearch dg1_12_checkinfo ///
               dg1_13_trustwebst dg1_14_mediumtool dg1_15_disablevid dg1_16_shareimg dg1_17_emoticons dg1_18_reportcontent ///
               dg1_19_recog_bully dg1_20_create dg1_21_editimage dg1_22_viewonline dg1_23_online_contnt dg1_24_sponsored  ///
               dg1_25_copyright dg1_27_firstsearch dg1_28_same_info dg1_29_contct_post dg1_30_neg_impact dg1_31_hashtaguse dg1_32_pay_advert {
    
    // Confirm numeric variable and replace special values with missing (assume people with missing are 1 = Not at all true of me)
    capture confirm numeric variable `var'
    if !_rc {
        replace `var' = 1 if inlist(`var', .a, .b, .c, .d)
    }
    
    // Recode missing 66 and 99 to 0
    replace `var' = 1 if `var' == . | `var' == 66 | `var' == 99
}

* Tabulate the variables to check the distribution, including missing values
foreach var of varlist dg1_1_privsettngs dg1_2_locsettngs dg1_3_securitysett dg1_4_store dg1_5_privbrowse dg1_6_blockads ///
               dg1_7_progcode dg1_8_keysearch dg1_9_website dg1_10_webinfo dg1_11_advncesearch dg1_12_checkinfo ///
               dg1_13_trustwebst dg1_14_mediumtool dg1_15_disablevid dg1_16_shareimg dg1_17_emoticons dg1_18_reportcontent ///
               dg1_19_recog_bully dg1_20_create dg1_21_editimage dg1_22_viewonline dg1_23_online_contnt dg1_24_sponsored  ///
               dg1_25_copyright  {
    tabulate `var', missing
}

* Loop through each variable to create a new variable with collapsed categories(missing, 1-3, 66 and 99 all coded 1 meaning no skill, 4 and 5 coded 2 meaning skilled)
foreach var of varlist dg1_1_privsettngs dg1_2_locsettngs dg1_3_securitysett dg1_4_store dg1_5_privbrowse dg1_6_blockads ///
               dg1_7_progcode dg1_8_keysearch dg1_9_website dg1_10_webinfo dg1_11_advncesearch dg1_12_checkinfo ///
               dg1_13_trustwebst dg1_14_mediumtool dg1_15_disablevid dg1_16_shareimg dg1_17_emoticons dg1_18_reportcontent ///
               dg1_19_recog_bully dg1_20_create dg1_21_editimage dg1_22_viewonline dg1_23_online_contnt dg1_24_sponsored  ///
               dg1_25_copyright {

    gen `var'_new = .
    replace `var'_new = 1 if  `var' == 1 | `var' == 2 | `var' == 3  // Low and Average skilled
    replace `var'_new = 2 if `var' == 4 | `var' == 5  // High skilled

    * Label the new variable
    label define `var'_lbl 1 "No Skill" 2 "Skilled"
    label values `var'_new `var'_lbl
}

* Check the distribution of the new variables
foreach var of varlist dg1_1_privsettngs dg1_2_locsettngs dg1_3_securitysett dg1_4_store dg1_5_privbrowse dg1_6_blockads ///
               dg1_7_progcode dg1_8_keysearch dg1_9_website dg1_10_webinfo dg1_11_advncesearch dg1_12_checkinfo ///
               dg1_13_trustwebst dg1_14_mediumtool dg1_15_disablevid dg1_16_shareimg dg1_17_emoticons dg1_18_reportcontent ///
               dg1_19_recog_bully dg1_20_create dg1_21_editimage dg1_22_viewonline dg1_23_online_contnt dg1_24_sponsored  ///
               dg1_25_copyright {
    tabulate `var'_new
}


/// a).Information and data literacy (dg1_8_keysearch dg1_9_website dg1_10_webinfo dg1_11_advncesearch dg1_12_checkinfo dg1_13_trustwebst)

* Create a new variable that sums the scores of the specified variables
egen info_data_lit = rowtotal(dg1_8_keysearch_new dg1_9_website_new dg1_10_webinfo_new dg1_11_advncesearch_new dg1_12_checkinfo_new dg1_13_trustwebst_new)
ta info_data_lit

* Create a list of the variables to combine.
local varlist dg1_8_keysearch_new dg1_9_website_new dg1_10_webinfo_new dg1_11_advncesearch_new dg1_12_checkinfo_new dg1_13_trustwebst_new

* Create a new variable called InfoDataLit.
* Generate the new categorical variable and initialize it to missing
gen info_data_lit2 = .

* Define the conditions and assign values to the new variable
* Example categorization:
* 1 - Low skill if all variables are 1
* 2 - Medium skill if at least one variable is 2
* 3 - High skill if all variables are 2

* High skill if all variables are 2
replace info_data_lit2 = 3 if dg1_8_keysearch_new == 2 & dg1_9_website_new == 2 & dg1_10_webinfo_new == 2 & dg1_11_advncesearch_new == 2 & dg1_12_checkinfo_new == 2 & dg1_13_trustwebst_new == 2

* Medium skill if at least one variable is 2 but not all
replace info_data_lit2 = 2 if (dg1_8_keysearch_new == 2 | dg1_9_website_new == 2 | dg1_10_webinfo_new == 2 | dg1_11_advncesearch_new == 2 | dg1_12_checkinfo_new == 2 | dg1_13_trustwebst_new == 2) & ///
                              !(dg1_8_keysearch_new == 2 & dg1_9_website_new == 2 & dg1_10_webinfo_new == 2 & dg1_11_advncesearch_new == 2 & dg1_12_checkinfo_new == 2 & dg1_13_trustwebst_new == 2)

* Low skill if all variables are 1
replace info_data_lit2 = 1 if dg1_8_keysearch_new == 1 & dg1_9_website_new == 1 & dg1_10_webinfo_new == 1 & dg1_11_advncesearch_new == 1 & dg1_12_checkinfo_new == 1 & dg1_13_trustwebst_new == 1
* Define the value labels
label define info_data_lit2_label 1 "No skill" 2 "Average skill" 3 "High skill"

* Assign the labels to the new variable
label values info_data_lit2 info_data_lit2_label

ta info_data_lit2


///b).Communication and Collaboration: (dg1_14_mediumtool dg1_15_disablevid dg1_16_shareimg dg1_17_emoticons dg1_18_reportcontent)
egen com_colla_lit = rowtotal(dg1_14_mediumtool_new dg1_15_disablevid_new dg1_16_shareimg_new dg1_17_emoticons_new dg1_18_reportcontent_new)
ta com_colla_lit

gen com_colla_lit2 = .
replace com_colla_lit2 = 3 if dg1_14_mediumtool_new == 2 & dg1_15_disablevid_new == 2 & dg1_16_shareimg_new == 2 & dg1_17_emoticons_new == 2 & dg1_18_reportcontent_new == 2

replace com_colla_lit2 = 2 if (dg1_14_mediumtool_new == 2 | dg1_15_disablevid_new == 2 | dg1_16_shareimg_new == 2 | dg1_17_emoticons_new == 2 |  dg1_18_reportcontent_new == 2) & ///
                              !(dg1_14_mediumtool_new == 2 & dg1_15_disablevid_new == 2 & dg1_16_shareimg_new == 2 & dg1_17_emoticons_new == 2 & dg1_18_reportcontent_new == 2)
replace com_colla_lit2 = 1 if dg1_14_mediumtool_new == 1 & dg1_15_disablevid_new == 1 & dg1_16_shareimg_new == 1 & dg1_17_emoticons_new == 1 & dg1_18_reportcontent_new == 1
label define com_colla_lit2_label 1 "No skill" 2 "Average skill" 3 "High skill"
label values com_colla_lit2 com_colla_lit2_label
ta com_colla_lit2


/// c). Digital Content Creation: (dg1_20_create dg1_21_editimage dg1_22_viewonline dg1_23_online_contnt dg1_25_copyright)

egen digcont_creat_lit  = rowtotal(dg1_20_create_new dg1_21_editimage_new dg1_22_viewonline_new dg1_23_online_contnt_new dg1_25_copyright_new)
ta digcont_creat_lit

gen digcont_creat_lit2 = .
replace digcont_creat_lit2 = 3 if dg1_20_create_new == 2 & dg1_21_editimage_new == 2 & dg1_22_viewonline_new == 2 & dg1_23_online_contnt_new == 2 & dg1_25_copyright_new == 2

replace digcont_creat_lit2 = 2 if (dg1_20_create_new == 2 | dg1_21_editimage_new == 2 | dg1_22_viewonline_new == 2 | dg1_23_online_contnt_new == 2 |  dg1_25_copyright_new == 2) & ///
                              !(dg1_20_create_new == 2 & dg1_21_editimage_new == 2 & dg1_22_viewonline_new == 2 & dg1_23_online_contnt_new == 2 & dg1_25_copyright_new == 2)
replace digcont_creat_lit2 = 1 if dg1_20_create_new == 1 & dg1_21_editimage_new == 1 & dg1_22_viewonline_new == 1 & dg1_23_online_contnt_new == 1 & dg1_25_copyright_new == 1
label define digcont_creat_lit2_label 1 "No skill" 2 "Average skill" 3 "High skill"
label values digcont_creat_lit2 digcont_creat_lit2_label
ta digcont_creat_lit2

///d).Safety: (dg1_1_privsettngs dg1_2_locsettngs dg1_3_securitysett dg1_5_privbrowse dg1_6_blockads dg1_19_recog_bully dg1_24_sponsored)

egen safety_lit = rowtotal(dg1_1_privsettngs_new dg1_2_locsettngs_new dg1_3_securitysett_new dg1_5_privbrowse_new dg1_6_blockads_new dg1_19_recog_bully_new dg1_24_sponsored_new)
ta safety_lit


gen safety_lit2 = .
replace safety_lit2 = 3 if dg1_1_privsettngs_new == 2 & dg1_2_locsettngs_new == 2 & dg1_3_securitysett_new == 2 & dg1_5_privbrowse_new == 2 & ///
                            dg1_6_blockads_new == 2 & dg1_6_blockads_new == 2 & dg1_19_recog_bully_new == 2 & dg1_19_recog_bully_new == 2

replace safety_lit2 = 2 if (dg1_1_privsettngs_new == 2 | dg1_2_locsettngs_new == 2 | dg1_3_securitysett_new == 2 | dg1_5_privbrowse_new == 2 | ///
                            dg1_6_blockads_new == 2 | dg1_6_blockads_new == 2 | dg1_19_recog_bully_new == 2 | dg1_19_recog_bully_new == 2) & ///
                              !(dg1_1_privsettngs_new == 2 & dg1_2_locsettngs_new == 2 & dg1_3_securitysett_new == 2 & dg1_5_privbrowse_new == 2 & ///
                            dg1_6_blockads_new == 2 & dg1_6_blockads_new == 2 & dg1_19_recog_bully_new == 2 & dg1_19_recog_bully_new == 2)
							  
							  
replace safety_lit2 = 1 if dg1_1_privsettngs_new == 1 & dg1_2_locsettngs_new == 1 & dg1_3_securitysett_new == 1 & dg1_5_privbrowse_new == 1 & ///
                            dg1_6_blockads_new == 1 & dg1_6_blockads_new == 1 & dg1_19_recog_bully_new == 1 & dg1_19_recog_bully_new == 1
label define safety_lit2_label 1 "No skill" 2 "Average skill" 3 "High skill"
label values safety_lit2 safety_lit2_label
ta safety_lit2


///e).Problem Solving: (dg1_4_store dg1_7_progcode)

egen probsolving_lit = rowtotal (dg1_4_store_new dg1_7_progcode_new)
ta probsolving_lit

gen probsolving_lit2 = .
replace probsolving_lit2 = 3 if dg1_4_store_new == 2 & dg1_7_progcode_new == 2 

replace probsolving_lit2 = 2 if (dg1_4_store_new == 2 | dg1_7_progcode_new == 2 ) & !(dg1_4_store_new == 2 & dg1_7_progcode_new == 2 )
replace probsolving_lit2 = 1 if dg1_4_store_new == 1 & dg1_7_progcode_new == 1 
label define probsolving_lit2_label 1 "No skill" 2 "Average skill" 3 "High skill"
label values probsolving_lit2 probsolving_lit2_label
ta probsolving_lit2





//// Digital Literacy (All Variables)

egen dig_lit = rowtotal(dg1_8_keysearch_new dg1_9_website_new dg1_10_webinfo_new dg1_11_advncesearch_new dg1_12_checkinfo_new dg1_13_trustwebst_new ///
                      dg1_14_mediumtool_new dg1_15_disablevid_new dg1_16_shareimg_new dg1_17_emoticons_new dg1_18_reportcontent_new ///
					  dg1_20_create_new dg1_21_editimage_new dg1_22_viewonline_new dg1_23_online_contnt_new dg1_25_copyright_new ///
					  dg1_1_privsettngs_new dg1_2_locsettngs_new dg1_3_securitysett_new dg1_5_privbrowse_new dg1_6_blockads_new dg1_19_recog_bully_new dg1_24_sponsored_new ///
					  dg1_4_store_new dg1_7_progcode_new)
ta dig_lit
gen dig_lit2 = .
replace dig_lit2 = 3 if dg1_8_keysearch_new == 2 & dg1_9_website_new == 2 &  dg1_10_webinfo_new == 2 &  dg1_11_advncesearch_new == 2 & dg1_12_checkinfo_new == 2 &  dg1_13_trustwebst_new == 2 & ///
                      dg1_14_mediumtool_new == 2 & dg1_15_disablevid_new == 2 &  dg1_16_shareimg_new == 2 &  dg1_17_emoticons_new == 2 &  dg1_18_reportcontent_new == 2 &  ///
					  dg1_20_create_new == 2 & dg1_21_editimage_new == 2 & dg1_22_viewonline_new == 2 & dg1_23_online_contnt_new == 2 & dg1_25_copyright_new == 2 & ///
					  dg1_1_privsettngs_new == 2 & dg1_2_locsettngs_new == 2 & dg1_3_securitysett_new == 2 & dg1_5_privbrowse_new == 2 & dg1_6_blockads_new == 2 & dg1_19_recog_bully_new == 2 & dg1_24_sponsored_new == 2 & ///
					  dg1_4_store_new == 2 & dg1_7_progcode_new == 2 

replace dig_lit2 = 2 if (dg1_8_keysearch_new == 2 | dg1_9_website_new == 2 |  dg1_10_webinfo_new == 2 |  dg1_11_advncesearch_new == 2 | dg1_12_checkinfo_new == 2 |  dg1_13_trustwebst_new == 2 | ///
                      dg1_14_mediumtool_new == 2 | dg1_15_disablevid_new == 2 |  dg1_16_shareimg_new == 2 |  dg1_17_emoticons_new == 2 |  dg1_18_reportcontent_new == 2 | ///
					  dg1_20_create_new == 2 | dg1_21_editimage_new == 2 | dg1_22_viewonline_new == 2 | dg1_23_online_contnt_new == 2 | dg1_25_copyright_new == 2 | ///
					  dg1_1_privsettngs_new == 2 | dg1_2_locsettngs_new == 2 | dg1_3_securitysett_new == 2 | dg1_5_privbrowse_new == 2 | dg1_6_blockads_new == 2 | dg1_19_recog_bully_new == 2 | dg1_24_sponsored_new == 2 | ///
					  dg1_4_store_new == 2 | dg1_7_progcode_new == 2  ) & !(dg1_8_keysearch_new == 2 & dg1_9_website_new == 2 &  dg1_10_webinfo_new == 2 &  dg1_11_advncesearch_new == 2 & dg1_12_checkinfo_new == 2 &  dg1_13_trustwebst_new == 2 & ///
                      dg1_14_mediumtool_new == 2 & dg1_15_disablevid_new == 2 &  dg1_16_shareimg_new == 2 &  dg1_17_emoticons_new == 2 &  dg1_18_reportcontent_new == 2 &  ///
					  dg1_20_create_new == 2 & dg1_21_editimage_new == 2 & dg1_22_viewonline_new == 2 & dg1_23_online_contnt_new == 2 & dg1_25_copyright_new == 2 & ///
					  dg1_1_privsettngs_new == 2 & dg1_2_locsettngs_new == 2 & dg1_3_securitysett_new == 2 & dg1_5_privbrowse_new == 2 & dg1_6_blockads_new == 2 & dg1_19_recog_bully_new == 2 & dg1_24_sponsored_new == 2 & ///
					  dg1_4_store_new == 2 & dg1_7_progcode_new == 2  )

replace dig_lit2 = 1 if dg1_8_keysearch_new == 1 & dg1_9_website_new == 1 &  dg1_10_webinfo_new == 1 &  dg1_11_advncesearch_new == 1 & dg1_12_checkinfo_new == 1 &  dg1_13_trustwebst_new == 1 & ///
                      dg1_14_mediumtool_new == 1 & dg1_15_disablevid_new == 1 &  dg1_16_shareimg_new == 1 &  dg1_17_emoticons_new == 1 &  dg1_18_reportcontent_new == 1 &  ///
					  dg1_20_create_new == 1 & dg1_21_editimage_new == 1 & dg1_22_viewonline_new == 1 & dg1_23_online_contnt_new == 1 & dg1_25_copyright_new == 1 & ///
					  dg1_1_privsettngs_new == 1 & dg1_2_locsettngs_new == 1 & dg1_3_securitysett_new == 1 & dg1_5_privbrowse_new == 1 & dg1_6_blockads_new == 1 & dg1_19_recog_bully_new == 1 & dg1_24_sponsored_new == 1 & ///
					  dg1_4_store_new == 1 & dg1_7_progcode_new == 1 
					  
label define dig_lit2_label 1 "No skill" 2 "Average skill" 3 "High skill"
label values dig_lit2 dig_lit2_label
ta dig_lit2

				  
/////Digital Information Literacy:This encompasses not only the ability to navigate digital platforms and access information but also to critically evaluate the reliability, relevance, and potential impact of the information retrieved. 

* Loop through each variable to create a new variable with collapsed categories(missing, 1,3, 66 and 99 all coded 0 meaning no literacy,2 for literacy)
foreach var of varlist  dg1_27_firstsearch dg1_28_same_info dg1_29_contct_post dg1_30_neg_impact dg1_31_hashtaguse dg1_32_pay_advert {

    gen `var'_new = .
    replace `var'_new = 1 if  `var' == 1 | `var' == 3  // no literacy
    replace `var'_new = 2 if `var' == 2  // literacy

    * Label the new variable
    label define `var'_lbl 1 "No literacy" 2 "literacy"
    label values `var'_new `var'_lbl
}

* Check the distribution of the new variables
foreach var of varlist  dg1_27_firstsearch dg1_28_same_info dg1_29_contct_post dg1_30_neg_impact dg1_31_hashtaguse dg1_32_pay_advert {
    tabulate `var'_new
}

egen diginfo_lit = rowtotal (dg1_27_firstsearch_new dg1_28_same_info_new dg1_29_contct_post_new dg1_30_neg_impact_new dg1_31_hashtaguse_new dg1_32_pay_advert_new)
ta diginfo_lit


***************************************************************************************************************************
****************************************************************************************************************************
*Knowledge of Productivity Programs 
// Define the list of variables to loop over
foreach var in dl2_1_create_doc dl2_2_edit_doc dl2_3_format_doc dl2_4_table_doc dl2_5_doc_languge ///
           dl2_6_create_sheet dl2_7_insert_sheet dl2_9_chart_sheet dl2_10_create_slides ///
           dl2_11_graphics dl2_12_create_dtbase dl2_13_uery_dtbase dl2_14_report_dtbase {

// Confirm numeric variable and replace special values with missing
    capture confirm numeric variable `var'
    if !_rc {
        replace `var' = . if inlist(`var', .a, .b, .c, .d)
    }		   
		   	   
		   
	* Recode 66 and 99 to missing
    replace `var' = 0 if `var' == .|`var' == 66 | `var' == 99
}

* Loop through each variable to create a new variable with collapsed categories(missing, 1-3, 66 and 99 all coded 0 meaning no knowledge, 4 and 4 coded 1 meaning knowledgeble)
foreach var of varlist dl2_1_create_doc dl2_2_edit_doc dl2_3_format_doc dl2_4_table_doc dl2_5_doc_languge ///
           dl2_6_create_sheet dl2_7_insert_sheet dl2_9_chart_sheet dl2_10_create_slides ///
           dl2_11_graphics dl2_12_create_dtbase dl2_13_uery_dtbase dl2_14_report_dtbase {

    gen `var'_new = .
    replace `var'_new = 1 if `var' == 0 | `var' == 1 | `var' == 2 | `var' == 3  // No knowledge
    replace `var'_new = 2 if `var' == 4 | `var' == 5  // knowledge

    * Label the new variable
    label define `var'_lbl 1 "No knowledge" 2 "knowledge"
    label values `var'_new `var'_lbl
}
* Check the distribution of the new variables
foreach var of varlist dl2_1_create_doc dl2_2_edit_doc dl2_3_format_doc dl2_4_table_doc dl2_5_doc_languge ///
           dl2_6_create_sheet dl2_7_insert_sheet dl2_9_chart_sheet dl2_10_create_slides ///
           dl2_11_graphics dl2_12_create_dtbase dl2_13_uery_dtbase dl2_14_report_dtbase {
    tabulate `var'_new
}

//create knoweldeg of production programs score

egen pdnprog_lit = rowtotal(dl2_1_create_doc_new dl2_2_edit_doc_new dl2_3_format_doc_new dl2_4_table_doc_new dl2_5_doc_languge_new ///
                        dl2_6_create_sheet_new dl2_7_insert_sheet_new dl2_9_chart_sheet_new dl2_10_create_slides_new ///
                        dl2_11_graphics_new dl2_12_create_dtbase_new dl2_13_uery_dtbase_new dl2_14_report_dtbase_new )
ta pdnprog_lit
	   
***************************************************************************************************************************
****************************************************************************************************************************	

** Digital Financial literacy
// Define the list of variables to loop over

foreach var in dl3_1_internet dl3_2_mobilephone dl3_3_smartphone dl3_4_computer dl3_5_tabletcomputer ///
              dl3_6_online_search dl3_7_device_search dl3_8_mobile_account dl3_9_calls dl3_10_emails dl3_11_txtmessage ///
              dl3_12_photos dl3_13_brwse_internt dl3_14_softapp dl3_15_videocall dl3_16_music dl3_17_games ///
              dl3_18_recordvideo dl3_19_recommend dl3_20_financl_transctn dl3_21_shoponline dl3_22_purchse_good ///
              dl3_23_online_bankin dl3_24_mobile_bankin dl3_25_dgfin_service dl3_26_find_finservice ///
              dl3_27_initiat_transac dl3_28_complte_trnsction dl3_29_corrct_error dl3_30_cancel_trnsctn {

    // Confirm numeric variable and replace special values with missing
    capture confirm numeric variable `var'
    if !_rc {
        replace `var' = . if inlist(`var', .a, .b, .c, .d)
    }		   
		   
	// Recode 66 and 99 to missing
    replace `var' = 0 if `var' == .|`var' == 66 | `var' == 99
}

// Tabulate the variables to check the distribution
foreach var in dl3_1_internet dl3_2_mobilephone dl3_3_smartphone dl3_4_computer dl3_5_tabletcomputer ///
              dl3_6_online_search dl3_7_device_search dl3_8_mobile_account dl3_9_calls dl3_10_emails dl3_11_txtmessage ///
              dl3_12_photos dl3_13_brwse_internt dl3_14_softapp dl3_15_videocall dl3_16_music dl3_17_games ///
              dl3_18_recordvideo dl3_19_recommend dl3_20_financl_transctn dl3_21_shoponline dl3_22_purchse_good ///
              dl3_23_online_bankin dl3_24_mobile_bankin dl3_25_dgfin_service dl3_26_find_finservice ///
              dl3_27_initiat_transac dl3_28_complte_trnsction dl3_29_corrct_error dl3_30_cancel_trnsctn {
    tabulate `var', missing
}

foreach var in dl3_1_internet dl3_2_mobilephone dl3_3_smartphone dl3_4_computer dl3_5_tabletcomputer ///
              dl3_6_online_search dl3_7_device_search dl3_8_mobile_account dl3_9_calls dl3_10_emails dl3_11_txtmessage ///
              dl3_12_photos dl3_13_brwse_internt dl3_14_softapp dl3_15_videocall dl3_16_music dl3_17_games ///
              dl3_18_recordvideo dl3_19_recommend dl3_20_financl_transctn dl3_21_shoponline dl3_22_purchse_good ///
              dl3_23_online_bankin dl3_24_mobile_bankin dl3_25_dgfin_service dl3_26_find_finservice ///
              dl3_27_initiat_transac dl3_28_complte_trnsction dl3_29_corrct_error dl3_30_cancel_trnsctn {

    * Recode 0 to 1 and 1 to 2
    recode `var' (0=1) (1=2)

    * Update labels to reflect new coding
    label define `var'_label 1 "NO" 2 "YES"
    label values `var' `var'_label

    * Verify the recoding by tabulating the recoded variable with missing values
    tabulate `var', missing
}





    // Conduct factor analysis
    factor `var'  dl3_1_internet dl3_2_mobilephone dl3_3_smartphone dl3_4_computer dl3_5_tabletcomputer ///
               dl3_6_online_search dl3_7_device_search dl3_8_mobile_account dl3_9_calls dl3_10_emails dl3_11_txtmessage ///
               dl3_12_photos dl3_13_brwse_internt dl3_14_softapp dl3_15_videocall dl3_16_music dl3_17_games ///
               dl3_18_recordvideo dl3_19_recommend dl3_20_financl_transctn dl3_21_shoponline dl3_22_purchse_good ///
               dl3_23_online_bankin dl3_24_mobile_bankin dl3_25_dgfin_service dl3_26_find_finservice ///
               dl3_27_initiat_transac dl3_28_complte_trnsction dl3_29_corrct_error dl3_30_cancel_trnsctn , pcf

    // Rotate factors to improve interpretability
    rotate, varimax

    // Scree plot to determine the number of factors
    screeplot
	/// 6 factors but there a factor on digital financial literacy. Use those variables to create a variable for financial digital literacy
	
// Compute the composite score by averaging the normalized values
egen digfin_lit = rowtotal(dl3_6_online_search dl3_7_device_search dl3_13_brwse_internt dl3_14_softapp ///
                             dl2_6_create_sheet dl2_7_insert_sheet dl2_9_chart_sheet dl2_10_create_slides ///
                             dl2_11_graphics dl2_12_create_dtbase dl2_13_uery_dtbase dl2_14_report_dtbase ///
							 dl3_20_financl_transctn dl3_21_shoponline dl3_22_purchse_good ///
                             dl3_23_online_bankin dl3_24_mobile_bankin dl3_25_dgfin_service dl3_26_find_finservice ///
                             dl3_27_initiat_transac dl3_28_complte_trnsction dl3_29_corrct_error dl3_30_cancel_trnsctn )

// Summarize the composite score to check
summarize digfin_lit


* Agency variable construction
/* Items AA1.1 to AA1.7: These questions assess the individual’s freedom to engage in social activities without adult supervision- social agency.
Items AA1.7 to AA1.13: These questions are focused on the individual’s perceived influence within their family and social circles- personal agency.
Items AA1.14 to AA1.20: These questions measure the individual’s autonomy in making personal decisions- decisional agency.
*/

// Define the list of variables to loop over
local vars aa1_1_activity aa1_2_party aa1_3_friends aa1_4_youthcntr aa1_5_religncntr aa1_6_oppsex aa1_6_samesex ///
           aa1_7_opinion aa1_8_parnt_listn aa1_9_advice aa1_10_tell aa1_11_speakup aa1_12_hurt aa1_13_askhelp ///
           aa1_14_cloth aa1_15_freetime aa1_16_eat aa1_17_friends aa1_18_eductn aa1_19_marry aa1_20_spouse

* Loop through each specified variable and apply the replacements
foreach var of local vars {
    capture confirm numeric variable `var'
    if !_rc {
        replace `var' = . if `var' == .a
        replace `var' = . if `var' == .b
        replace `var' = . if `var' == .c
        replace `var' = . if `var' == .d
    }
}

foreach var in aa1_1_actvity aa1_2_party aa1_3_friends aa1_4_youthcntr aa1_5_religncntr aa1_6_oppsex aa1_6_samesex ///
               aa1_7_opinion aa1_8_parnt_listn aa1_9_advice aa1_10_tell aa1_11_speakup aa1_12_hurt aa1_13_askhelp ///
               aa1_14_cloth aa1_15_freetime aa1_16_eat aa1_17_friends aa1_18_eductn aa1_19_marry aa1_20_spouse {
    
    * Recode 0 to 1, 1 to 2, and 2 to 3
    recode `var' (0=1) (1=2) (2=3)

    * Update labels to reflect new coding
    label define `var'_label 1 "Never/rarely" 2 "sometimes" 3 "often"
    label values `var' `var'_label

    * Verify the recoding by tabulating the recoded variable with missing values
    tabulate `var', missing
}


// Conduct factor analysis with principal component factoring (questions 7-17 load highy together cut off 0.45)
factor aa1_1_actvity aa1_2_party aa1_3_friends aa1_4_youthcntr aa1_5_religncntr aa1_6_oppsex aa1_6_samesex ///
       aa1_7_opinion aa1_8_parnt_listn aa1_9_advice aa1_10_tell aa1_11_speakup aa1_12_hurt aa1_13_askhelp ///
       aa1_14_cloth aa1_15_freetime aa1_16_eat aa1_17_friends aa1_18_eductn aa1_19_marry aa1_20_spouse, pcf
	
    
	
	
	
	
factor aa1_7_opinion aa1_8_parnt_listn aa1_9_advice aa1_10_tell aa1_11_speakup aa1_12_hurt aa1_13_askhelp ///
       aa1_14_cloth aa1_15_freetime aa1_16_eat aa1_17_friends, pcf

// Rotate factors using varimax for better interpretability
rotate, varimax

// Generate a scree plot to evaluate the number of factors
screeplot



// Compute the composite variable for agency score
egen agency_score = rowmean(aa1_7_opinion aa1_8_parnt_listn aa1_9_advice aa1_10_tell aa1_11_speakup aa1_12_hurt aa1_13_askhelp ///
                            aa1_14_cloth aa1_15_freetime aa1_16_eat aa1_17_friends)
	   
// Calculate Cronbach's alpha
 alpha `v' aa1_7_opinion aa1_8_parnt_listn aa1_9_advice aa1_10_tell aa1_11_speakup aa1_12_hurt aa1_13_askhelp aa1_14_cloth ///  Scale reliability coefficient:      0.7662
           aa1_15_freetime aa1_16_eat aa1_17_friends    
	   
summarize agency_score

***************************************************************************************************************************
****************************************************************************************************************************
* Goal Setting
// Define the list of variables to loop over
local aa2_1_goals aa2_2_goals aa2_3_goals aa2_4_plans aa2_5_achieve aa2_6_prioritize aa2_7_success aa2_8_fsuccess

// Loop through each specified variable and apply the replacements
foreach var of local vars {
    // Confirm numeric variable and replace special values with missing
    capture confirm numeric variable `var'
    if !_rc {
        replace `var' = . if inlist(`var', .a, .b, .c, .d)
    }
    
    // Recode missing 66 and 99 to .
    replace `var' = . if  `var' == 66 | `var' == 99
}

// Mean imputation for missing values
foreach var of local vars {
    egen `var'_imputed = rowmean(`var')
}

// Tabulate the variables
foreach var of local vars {
    tabulate `var' `var'_imputed
}
// Loop over each variable
foreach v of local vars {
   
    // Conduct factor analysis
    factor `v'  aa2_1_goals aa2_2_goals aa2_3_goals aa2_4_plans aa2_5_achieve aa2_6_prioritize aa2_7_success aa2_8_fsuccess, pcf ///just one factor here

    // Rotate factors to improve interpretability
    rotate, varimax

    // Scree plot to determine the number of factors
    screeplot
	

    // Create the composite variable for a single factor
    egen goalsetting_score = rowmean( aa2_1_goals aa2_2_goals aa2_3_goals aa2_4_plans aa2_5_achieve aa2_6_prioritize aa2_7_success aa2_8_fsuccess)

    // Calculate Cronbach's alpha
    alpha `v'  aa2_1_goals aa2_2_goals aa2_3_goals aa2_4_plans aa2_5_achieve aa2_6_prioritize aa2_7_success aa2_8_fsuccess
	///Scale reliability coefficient:      0.8392
}
***************************************************************************************************************************
****************************************************************************************************************************
*school engagement
* School Engagement Variables
// Define the list of variables to loop over
* School Engagement Variables
// Define the list of variables to loop over
local vars ed1_1_misslessn ed1_2_attntive ed1_3_assigntask ed1_4_finishtask ed1_5_participte ed1_6_confident ed1_7_attntion ed1_8_completetask ed1_9_capable

// Loop through each specified variable and apply the replacements
foreach var of local vars {
    // Confirm numeric variable and replace special values with missing
    capture confirm numeric variable `var'
    if !_rc {
        replace `var' = . if inlist(`var', .a, .b, .c, .d)
    }
    
    // Recode missing 66 and 99 to .
    replace `var' = . if  `var' == 66 | `var' == 99
}

// Mean imputation for missing values
foreach var of local vars {
    egen `var'_imputed = rowmean(`var')
}

// Tabulate the variables
foreach var of local vars {
    tabulate `var' `var'_imputed
}

// Conduct factor analysis
    factor `v' ed1_1_misslessn ed1_2_attntive ed1_3_assigntask ed1_4_finishtask ed1_5_participte ed1_6_confident ed1_7_attntion ed1_8_completetask ed1_9_capable, pcf

    // Rotate factors to improve interpretability
    rotate, varimax

    // Scree plot to determine the number of factors
    screeplot

    // create vvariables
    egen schengage_score = rowmean(ed1_1_misslessn ed1_2_attntive ed1_3_assigntask ed1_4_finishtask ed1_5_participte ed1_6_confident ed1_7_attntion ed1_8_completetask ed1_9_capable)

    // Calculate Cronbach's alpha
    alpha ed1_1_misslessn ed1_2_attntive ed1_3_assigntask ed1_4_finishtask ed1_5_participte ed1_6_confident ed1_7_attntion ed1_8_completetask ed1_9_capable

	summarize schengage_score


***************************************************************************************************************************
****************************************************************************************************************************	

***Gender Attitudes and Beliefs
// Define the list of variables
foreach var in at_1_men_work_only at_3_tolerate_gbv at_5_girls_play_futbal at_6_boys_perfom_bettr ///
                  at_7_ok_woman_disagre  at_11_wife_noconsent ///
                  at_13_wife_argue at_14_wife_refuse_sex at_15_wife_burn_food {

    // Confirm numeric variable and replace special values with missing
    capture confirm numeric variable `var'
    if !_rc {
        replace `var' = . if inlist(`var', .a, .b, .c, .d)
    }
    
    // Recode missing 66 and 99 to .
    replace `var' = . if  `var' == 66 | `var' == 99
}


// Conduct factor analysis
factor  at_1_men_work_only at_3_tolerate_gbv at_5_girls_play_futbal at_6_boys_perfom_bettr ///
       at_7_ok_woman_disagre  at_11_wife_noconsent ///
       at_13_wife_argue at_14_wife_refuse_sex at_15_wife_burn_food, pcf

// Compute the composite indicator for gender attitudes
egen genderatti_comp = rowmean(at_1_men_work_only at_3_tolerate_gbv at_5_girls_play_futbal at_6_boys_perfom_bettr ///
                                          at_7_ok_woman_disagre  ///
                                          at_11_wife_noconsent at_13_wife_argue at_14_wife_refuse_sex at_15_wife_burn_food)

// Calculate Cronbach's alpha
alpha at_1_men_work_only at_3_tolerate_gbv at_5_girls_play_futbal at_6_boys_perfom_bettr ///
      at_7_ok_woman_disagre  at_11_wife_noconsent ///
      at_13_wife_argue at_14_wife_refuse_sex at_15_wife_burn_food

// Summarize the composite indicator
summarize genderatti_comp



// Define a new variable to store the recategorized attitudes
gen gender_att = .

// Recategorize each attitude variable
foreach var in at_1_men_work_only at_3_tolerate_gbv at_5_girls_play_futbal at_6_boys_perfom_bettr ///
               at_7_ok_woman_disagre at_11_wife_noconsent at_13_wife_argue at_14_wife_refuse_sex at_15_wife_burn_food {
                                
    // Recategorize responses
    replace gender_att = 1 if `var' == 4 | `var' == 5 // Positive Attitudes
    replace gender_att = 2 if `var' == 1 | `var' == 2 // Negative Attitudes
    replace gender_att = 3 if `var' == 3 // Neutral Attitudes
}

// Label the new variable
label define gender_attitudes_labels 1 "Positive " 2 "Negative"  3 "Neutral Attitudes"
label values gender_att gender_attitudes_labels

// Tabulate the recategorized attitudes
tab gender_att


save "final_analysis.dta", replace

* Keep only the specified variables
keep adolescent_id school_id lga ward new_state residence school_type age age_sex age_preg marital_status   ///
religion functional_disability siblings siblings_cat new_hhsize newhhsize_cat caregiver_sex owns_device  ///
internet_acc wealthindex wquintile dg1_1_privsettngs_new dg1_2_locsettngs_new dg1_3_securitysett_new ///
dg1_4_store_new dg1_5_privbrowse_new dg1_6_blockads_new dg1_7_progcode_new dg1_8_keysearch_new dg1_9_website_new  ///
 dg1_10_webinfo_new dg1_11_advncesearch_new dg1_12_checkinfo_new dg1_13_trustwebst_new dg1_14_mediumtool_new   ///
 dg1_15_disablevid_new dg1_16_shareimg_new dg1_17_emoticons_new dg1_18_reportcontent_new dg1_19_recog_bully_new ///
 dg1_20_create_new dg1_21_editimage_new dg1_22_viewonline_new dg1_23_online_contnt_new dg1_24_sponsored_new   ///
 dg1_25_copyright_new info_data_lit com_colla_lit digcont_creat_lit safety_lit probsolving_lit dig_lit   ///
 info_data_lit2 com_colla_lit2 digcont_creat_lit2 safety_lit2 probsolving_lit2 /// 
 dg1_27_firstsearch_new dg1_28_same_info_new dg1_29_contct_post_new dg1_30_neg_impact_new dg1_31_hashtaguse_new   ///
 dg1_32_pay_advert_new diginfo_lit dl2_1_create_doc_new dl2_2_edit_doc_new dl2_3_format_doc_new dl2_4_table_doc_new   ///
 dl2_5_doc_languge_new dl2_6_create_sheet_new dl2_7_insert_sheet_new dl2_9_chart_sheet_new dl2_10_create_slides_new  ///
 dl2_11_graphics_new dl2_12_create_dtbase_new dl2_13_uery_dtbase_new dl2_14_report_dtbase_new pdnprog_lit digfin_lit ///
 agency_score ed1_1_misslessn_imputed ed1_2_attntive_imputed ed1_3_assigntask_imputed ed1_4_finishtask_imputed   ///
 ed1_5_participte_imputed ed1_6_confident_imputed ed1_7_attntion_imputed ed1_8_completetask_imputed ed1_9_capable_imputed schengage_score genderatti_comp

 drop if age == 20
 
* Save the new dataset without replacing the old one
save "lca_dataset.dta", replace

ta age
