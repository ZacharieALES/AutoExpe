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
      key is  missing, the `Main`  module is first considered  and the
      all other loaded modules.

The  entry  `"resolutionMethods"`  can  only  contain  one  resolution
method:

    "resolutionMethods": "function1"

or an array or resolution methods if several are considered:

    "resolutionMethods": ["function1", {"name": "function2", "module": "MyModule"}]

### extensions (optional)

Considered filename extensions  for the instance files  (by default only
txt and  json extensions  are considered).  This entry  can either  be a
single extension:

    "extensions": "txt"
	
or an array of extensions:

    "extensions": ["json", "txt"]

### instancePath (mandatory)

Path of the instance files. This entry can contain:
* the path of single instances

        "instancePath": "./data/instance1.txt"
or 

        "instancePath": ["./data/instance1.txt", "./data/instance2.txt"]
	
* the path of folders:

        "instancePath": "./data"
		
   All files inside the folder which have a valid extension is added to
   the list of instances.  By default the folder is browsed non
   recursively. To browse it recursively, the folder must be specified
   by a dictionary with an entry "name" and an entry `"isRecursive"` set
   to `"true"`:
 
         "instancePath": {"name": "./data", "isRecursive": true}

