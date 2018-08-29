# Importing Dictionary Data from Microsoft Excel 
*Author: Rainer Hind (rainer.hind@york.ac.uk, rainerhind@gmail.com)*

The goal of this process is to take the XLSX document provided by Alex Medcalfe at the Borthwick, which has a tab for each dictionary letter, and export it to a CSV with all the entries. This is problematic since the ordering/naming of the headers in each tab is inconsistent. The VBA script mentioned below takes the set of all header names, and puts them in a single tab, and then places the fields from the rows in the appropriate column.

The import rake task then does some normalisation on the header names, so that `source1 place` is seen as equivalent to `source 1 Place` (note the capitalisation and spacing differences). It will also treat `source X archival ref` the same as `source X ref`, since the two are intended to be equivalent, and are both used in the source document.

For reference, the process was completed on a 2012 Macbook Pro running `OSX 10.12.6`, with `Excel version 16.12`. Since Excel doesn't include the same VBA libraries on OSX as it does on Windows, a `Dictionary` VBA class is included which emulates functionality used in the VBA script for OSX users.

**Preparatory Steps (in original XLSX file)**
 1. Delete any empty sheets/tabs in the Excel doc
 2. Delete the 'Cut Entries' tab if it exists

**CSV Export Steps**
 1. Using the source .xlsx document, enable the developer tab	
	 - `File->Options->Customize ribbon->Customize the Ribbon->Main Tabs->Developer` at time of writing, Google it if not
2. Go to `Developer` tab, select `Visual Basic`
3. In the opened window, `File -> Import file`, browse to `import_files` in the YHD directory & select `YHD_Excel_Tab_Merger.bas`
4. **OSX ONLY** 
	- `File -> Import`, browse to `import_files` in the YHD directory and select Dictionary.cls from `VBA-Dictionary-1.4.1` directory
	- *This emulates Microsoft VBA functionality which is not included in OSX Excel version*
5. Returning to the regular Excel window, select developer tab
6. Click `Macros` in ribbon at the top
7. Select `CombineSheetsWithDifferentHeaders` and press `Run`
8. The macro will run and create a new tab. This process may take several minutes, and probably won't appear to be doing anything whilst it runs. When it completes, it will display a pop up message
9. Switch to the new, merged tab
10. Save the merged tab to a CSV:
	- `File->Save As`
	- Set `File Format: Select CSV UTF-8 (Comma delimited) (.csv)`
	- Save As `Filename: yhd`
	- Press `Save`
	- A pop up should open explaining the *workbook cannot be saved as there are multiple sheets*. Press `OK`.
11. You now should have yhd.csv, which can be placed in the YHD project directory (conventionally it should go in `/import_files`, although the import script should locate it anywhere in the project dir.)

**NOTE:** Be careful opening the .csv file in Excel. The default CSV parser will automatically convert fields beginning with `-` to a sum, which results in those fields being corrupted. If saved after opening in Excel, the CSV will contain invalid values and the import script. If you really need to open it in Excel after exporting, use the Import function of Excel instead, and preferably avoid saving it after.

**Importing the CSV**
1. After placing `yhd.csv` in the YHD project directory, open a command prompt in the YHD directory
2. Run `rails yhd:import` which will import the data from the CSV