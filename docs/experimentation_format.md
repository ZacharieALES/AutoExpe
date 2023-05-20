# Format of experiment file

To perform an experiment, you must describe it in a JSON file which only contains a dictionary.

## Example: knapsack experiment file

Here is the experiment file considered in the knapsack example located
in [src/examples/knapsack](../src/examples/knapsack):

    {
        "instancesPaths":"./data",
        "resolutionMethods": ["randomResolution", "ratioResolution"],
        "latexFormatPath":  ["./config/averageTable.json", "./config/expandedTable.json"],
        "latexOutputFile": "./results/result_tables.tex",
        "parametersToCombine": {"knapsackCount": [1, 2, 3], "knapsacksSize": [10, 20, 30]}
    }
    

## Entries of an experiment dictionary

### resolutionMethods (mandatory)

Resolution methods used to solve the instances in this experiment. One method can either be defined by:
* a string with the name of a julia method (e.g., `"function1"`); or
* a dictionary (e.g.,`{"name": "function1", "module": "Main"}`) which includes:
    * a key `"name"` (mandatory) which value is a string equal to the name of the Julia method; and
    * a key `"module"` (optional) which value is a string equal to the
      name of the Julia module in which the method is defined. If this
      key is  missing, the `Main`  module is first considered  and then
      all other loaded modules.

The  entry  `"resolutionMethods"`  can  either only  contain  one  resolution
method:

    "resolutionMethods": "function1"

or an array or resolution methods if several are considered:

    "resolutionMethods": ["function1", {"name": "function2", "module": "MyModule"}]

### extensions (optional)

Allowed  filename extensions  for the instance files  (by default only
txt and  json extensions  are considered).  This entry  can either  be a
single extension:

    "extensions": "txt"
	
or an array of extensions:

    "extensions": ["json", "txt"]

### instancePath (mandatory)

Path of the instance files. This entry can contain:
* the path of a single instance:

        "instancePath": "./data/instance1.txt"

* the path of several instances:

        "instancePath": ["./data/instance1.txt", "./data/instance2.txt"]
	
* the path of folders:

        "instancePath": "./data"
		
   In that last case, all files inside the folder which have a valid extension is added to
   the list of instances.  By default the folder is browsed non
   recursively. To browse it recursively, the folder must be specified
   by a dictionary with an entry `"name"` and an entry `"isRecursive"` set
   to `"true"`:
 
         "instancePath": {"name": "./data", "isRecursive": true}


The reference directory  for relative paths is the  directory in which
julia is executed.

### parametersToCombine (optional)

List of all parameters (if any) and their value(s). Each algorithm will be applied
to each instance for all possible combinations of the parameters. 

Examples:

    # The parameters combinations (m, K) of the first example are:
    # (1, 10), (1, 20), (1, 30), (2, 10), (2, 20), (2, 30), (3, 10),
    # (3, 20), and (3, 30)
    "parametersToCombine": {"m": [1, 2, 3], "K": [10, 20, 30}]
    "parametersToCombine": {"knapsackCount": [1, 2, 3]}
	
	

### latexOutputFile (optional)

Path of the [latex format file(s)](./latex_table_format.md). An array can be used if several latex tables are generated.

Examples:

    "latexFormatPath": "./MY_TABLE_FORMAT.json"
    "latexFormatPath": ["./config/averageTable.json", "./config/expandedTable.json"]

### latexOutputFile (optional)

Path in which the .tex file of the tables is created and compiled.

### outputPath (optional)

Path in which the result files are stored (default value: "./results/.expeResults/").
