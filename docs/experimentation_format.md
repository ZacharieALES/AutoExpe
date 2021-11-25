# Format of the JSON configuration file of an experiment

The JSON which describes an experiment only contains a dictionary.

## List of the possible entries of this dictionary

### resolutionMethods (mandatory)

Resolution methods used to solve the instances. One method can either be defined by:
* a string with the name of the julia method (ex: `"function1"`); or
* a dictionary (ex: `{"name": "function1", "module": "Main"}`) which includes
    * a key `"name"` (mandatory) which value is a string equal to the name of the Julia method; and
    * a key `"module"` (optional) which value is a string equal to the name of the Julia module in which the method is defined.

The entry `"resolutionMethods"` can be an array if several resolution methods are considered (ex: `"resolutionMethods": "function1"`, or `"resolutionMethods": ["function1", {"name": "function2", "module": "MyModule"}]`).

### extensions (optional)

Filename extensions allowed for the instance files (by default only txt and json extensions are accepted). This entry can either be a single extension or an array of extensions (ex: `"txt"` or `["json", "txt"]`).

### instancePath (mandatory)

Path of the instance files. This entry can contain:
* the path of single instances (ex: `"./data/instance1.txt"` or `["./data/instance1.txt", "./data/instance2.txt"]`);
* the path of folders (ex: `"./data"`). All files inside the folder which have a valid extension is added to the list of instances. By default the folder is browsed non recursively. To browse it recursively, the folder must be specified by a dictionary with an entry "name" and an entry `"isRecursive"` set to `"true"` (ex : `{"name": "./data", "isRecursive": true}`).

## Example: knapsack experimentation JSON file

    {
        "instancesPaths":"./data",
        "resolutionMethods": ["randomResolution", "ratioResolution"],
        "latexFormatPath":  ["./config/averageTable.json", "./config/expandedTable.json"],
        "latexOutputFile": "./results/result_tables.tex",
        "parametersToCombine": {"knapsackCount": [1, 2, 3], "knapsacksSize": [10, 20, 30]}
    }
    
