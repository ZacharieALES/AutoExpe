# AutoExpe
Automate repetitive taks in numerical experiments and the generation of result tables.

## Is it useful to me?
This package can be useful if you have:
* 1 problem (e.g., a graph clustering problem);
* at least 1 instance of this problem (e.g, at least 1 graph);
* at least 1 resolution method to solve this problem (e.g., k-nearest neighbors, single-link, ...);
* (optional) parameters of the problem (e.g., number of clusters, maximal size of the clusters, ...).

and if you want to automate:
* the resolution of each instance with each method for each value of the parameters;
* the creation of latex result tables.

## What it does and what it does not

To use it, you provide:
* the resolution methods (you still have to code that!);
* the path of the instances;
* the different values of each parameters;
* (optional) the format of each result table.

The package does the rest.

## Format of the JSON file used to define the experiment
The user must provide a dictionary in a JSON file describing the experiment.

This dictionary must at least contain an entry of key `"resolutionMethods"` and an entry of key `"instancesPath"`.

The entry `"resolutionMethods"` represents the different methods used to solve the instances. One method can either be defined by:
* a string with the name of the julia method (ex: `"function1"`); or
* a dictionary with a string `"name"` which is the name of the julia method and optionally a String `"module"` which represents the julia module in which the method is defined (ex: `{"name": "function1", "module": "Main"}`).

The entry `"resolutionMethods"` can be an array if several methods are considered (ex : `"resolutionMethods": "function1"`, or `"resolutionMethods": ["function1", {"name": "function2", "module": "MyModule"}]`).

The entry `"extensions"` is optional and specifies the accepted filename extensions of the instance files (by default only txt and json are accepted). This entry can either be a single extension or an array of extensions (ex: `"txt"` or `["json", "txt"]`).

The entry `"instancePath"` represents the instances to solve. This entry can contain:
* the path of single instances (ex: `"./data/instance1.txt"` or `["./data/instance1.txt", "./data/instance2.txt"]`);
* the path of folders (ex: `"./data"`). All files inside the folder which have a valid extension is added to the list of instances. By default the folder is browsed non recursively. To browse it recursively, the folder must be specified by a dictionary with an entry "name" and an entry `"isRecursive"` set to `"true"` (ex : `{"name": "./data", "isRecursive": true}`).

IV - Format of the JSON file used to create the latex output tables
The user must provide one JSON file describing each latex result table he wants to obtain. 

Such a file must contain an array (delimited by []) of objects (delimited by {}). Example of the structure of such a file:
    [{ TABLE_PARAMETERS },
     { ROW_PARAMETER },
     { COLUMN_PARAMETER }
    ]

Each object in this array either represents:
1. the table parameters (e.g., caption, vertical lines, ...); or
2. a row parameter: an entry in the result files which value in the latex table will vary across the rows; or
3. a column parameter: describes the content of a column in the result table;
4. a group of columns: several columns in the table that will appear under a common label (e.g., a group with the label "Time" can contains several columns with the resolution time of several methods)

TODO: Add example

 We then detail how each of these objects must be structured.

### Table parameters
This entry is optional. If it is used, it must contain a string "caption" which represents the caption of the table.

The other entries are optional:
* integer  `"maxRowsInATable"`: maximal number of lines in a table, used to avoid tables higher than a page which lead to hidden rows (default value: `30`);
* boolean `"leftVline"`: true if a vertical line is drawn on the left of the table (default value: `true`);
* boolean `"rightVline"`: idem for the right side (default value: `true`);
* boolean `"vlineAfterRowParams"`: true if a vertical line is drawn between the columns which represent the different row parameters (default value: `true`);
* integer `"maxNonScientificValue"`: greater numerical values in the table will be represented using the scientific notation (default: `999999`);
* boolean `"expandInstances"`: true if the table the result of each instances and not mean values over all the instances  (default: `false`);
* boolean `"hideInstancesExtension"`: true if the extension of the instance file is not displayed (only apply if `"expandInstances"` is `true`).

### Row parameters
A row parameter must contain a string `"rowParameterName"` which value is the name of the parameter as it appears in the result files.

The other entries are optional:
* string `"displayedName"`: name of the parameter that will appear in the latex table (default value: the value of `"rowParameterName"`);
* array of integers `"indexes"`: if the row parameter appears in an array of dimension D in the result files, this entry is an array of size D;
* boolean `"hline"`: true if a horizontal line is drawn between rows in which the value of the parameter changes (default value `false`).

TODO: example.

### Column parameters
The values displayed in a column of can directly corespond to a unique value in the result file (e.g.,: the resolution time) or computed from several values in the result file (e.g., if it is the max of two values). The entries required to compute the value of a column are specified in an array `"columnParameters"`. Each element of this array corresponds to a value.

Each entry of the array columnParameters must contain a string `"name"` which correspond to the name of the entry in the result files. It can also contain an array of indexes (similarly to row parameters). It can also contain a string `"method"` which represent the name of the resolution method as specified in the experiment JSON file. If this field is not specified, the default value specified in the field `"method"` is used (the one defined in the column entry but outside of columnParameters).

The other entries are optional:
* a boolean `"vline"`: true if a vertical line is drawn after this column (default value: `false`);
* a string `"function"`: represents the function used to compute the value in the column (e.g., `"gap"`, `"mean"`, ...).
* a string `"resolutionMethodName"`: default resolution method associated to the elements of the array columnParameters which do not have a field of the same name (useful when several element of the array columnParameters correspond to the same method);
* an integer `"digits"`: number of significant figures displayed (default: 2);
* a string `"suffix"`: string added after each entry of the column (ex: `"min"`, `"%"`, `"g"`, ...);
* a string `"prefix"`: string added before each entry of the column (ex: `"min"`, `"%"`, `"g"`, ...);
* a boolean `"ignoreBold"`: used when the column is in a group, true if the value in the column are ignored when computing the best value of the group.

Donner un exemple.

### Group of columns
A group must contain a string `"columnGroupName"` which corresponds to the common label displayed above the corresponding columns.

It must also contain an array `"column"` which elements are column paramters as defined in the previous section.

The other entries are optional:
* boolean `"vlineAfter"`: true if a vertical line must be drawn after the group (default value: `false`);
* boolean `"highlightBestValue"`: true if the best value of the groupe must appear in bold (default value: `false`);
* boolean `"isBestValueMinimal"`: true if the best value of the group is the lowest one; false if it is the highest one (default value: `true`).

Note that to use latex mathematical notations in the JSON file of a table (ex: in the displayed name of a column), you need put the expression between dollars and replace any backslash by two backslashes (ex : `$\\alpha$`).

## Resolution methods format
Currently resolution methods must be code in Julia but eventually it should be able to use any language. The julia resolution method must:
* take a single argument of type `Dictionary{Key, Any}` which, among others, contains the value of the parameters and the path of the current instance (which enables the method to access the data related to the instance);
* return a `Dictionary{Key, Any}` which contains all the results to save.

