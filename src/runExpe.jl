using JSON
using Dates

include("struct.jl")
include("generateLatexTables.jl")

function autoExpe(expeJsonPath::String)

    parameters = readExpeFormat(expeJsonPath)
    
    # Number of resolution performed in this experiment
    resolutionCount = length(parameters.resolutionMethods) * length(parameters.instancesPath)
    for (key, value) in parameters.parametersToCombine
        resolutionCount *= length(value)
    end

    resolutionId = 0
    isFirstResolution = false
    savedResultsFound = false
    
    for instancePath in parameters.instancesPath

        instanceName = splitext(basename(instancePath))[1]
        outputFile = parameters.outputPath * "/" * instanceName * ".json"
        outputFile = replace(outputFile, "//" => "/")
        
        # Variable which contains all the results of the instance
        # Each result is a Dict which contains:
        # - one entry with the key "resolutionMethodName"
        # - one entry for each parameter
        # - one entry for each result
        instanceResults = Vector{Dict{String, Any}}()

        # Get the results previously computed for this instance if any
        if isfile(outputFile)
            println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS"), " Reading previous results from file \"", outputFile, "\"")
            stringdata=join(readlines(outputFile))

            try
                instanceResults = JSON.parse(stringdata)
            catch e
                id = 1
                newName = outputFile * "_" * string(id)

                while isfile(newName)
                    id += 1
                    newName = outputFile * "_" * string(id)
                end 
                println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS") ,
                    " Warning: Unable to read the JSON result file. A new one will be created and the older one is moved to \"", newName, "\"")
            end 
                
        end 
            
        if parameters.verbosity != :None
            println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS"), " Solving instance ", instancePath, " (", floor(Int, 100 * resolutionId / resolutionCount),"%)")
        end 

        # Associate one index to each parameter in the dictionary of parameters to combine
        # combinationId[i] is the index of the value of parameter i that will be considered in the next combination
        combinationId = Vector{Int}()

        # Variable used for experiments which do not have combination of parameters
        isFirstCombination = true

        # Set the time of the next compilation (another may happen before if saved results are found)
        nextCompilationTime = Dates.now() + Dates.Minute(parameters.minLatexCompilationInterval) 
        isFirstLatexCompiled = false
         
        # While there are combinations of parameters to consider for this instance
        while getNextCombinationId!(combinationId, parameters.parametersToCombine) || isFirstCombination

            # Get the value of the parameters in the combination from their ids
            dictCombination = getCombination(combinationId, parameters.parametersToCombine)
            dictCombination["instancePath"] = instancePath

            # Get these parameters in an array
            combinationKeys = collect(keys(dictCombination))

            if parameters.verbosity != :None
                println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS"),"\t Parameters: ", getString(dictCombination), " (", floor(Int, 100 * resolutionId / resolutionCount),"%)")
            end 

            # For each method
            for methodId in 1:length(parameters.resolutionMethods)

                currentMethodName = string(nameof(parameters.resolutionMethods[methodId]))
                if parameters.verbosity != :None
                    print(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS") , "\t\t Resolution method \"", currentMethodName, "\" (", floor(Int, 100 * resolutionId / resolutionCount),"%)... ")
                end 
                resolutionId += 1

                ## Test if the resolution must be done or not
                mustSolve = parameters.computeUnsolvedResults

                # If unsolved results must be solved and if results already saved must not be recomputed, then test if this result is already solved
                if parameters.computeUnsolvedResults && !parameters.recomputeSavedResults

                    resultId = 1
                    combinationFoundInResults = false

                    # While we have not tested that all the solved combinations are different from the one we want to compute
                    while resultId <= length(instanceResults) && !combinationFoundInResults

                        resultDict = instanceResults[resultId]
                        
                        # If the result corresponds to the current resolution method
                        if resultDict["resolutionMethodName"] == currentMethodName

                            # Test all the parameters of the combination to see if they are equal to the parameter of the result
                            combinationFoundInResults = true
                            paramId = 1
                            while paramId <= length(combinationKeys) && combinationFoundInResults

                                # If any parameter does not correspond, the result is not a match
                                if !haskey(resultDict, combinationKeys[paramId]) || resultDict[combinationKeys[paramId]] != dictCombination[combinationKeys[paramId]]
                                    combinationFoundInResults = false
                                end
                                paramId += 1
                            end
                        end
                        resultId += 1
                    end

                    if combinationFoundInResults
                        print("Skipped (already solved)")
                        savedResultsFound = true
                    end
                    
                    mustSolve = !combinationFoundInResults
                end

                println()

                # If the combination must be solved for this method
                if mustSolve

                    # Create the latex result table if:
                    # 1    - a latex format is specified; and either
                    # 2.1  - the next compilation time is reached; or
                    # 2.2 (- no latex table has yet been created; and
                    #      - results have been obtained in previous run(s))
                    # Note: Condition 2.2 enables the user to see all the results of previous runs immediatly after starting the experiment
                    if parameters.latexFormatPath != [] && (Dates.now()  > nextCompilationTime  || (!isFirstLatexCompiled &&  savedResultsFound))
                        println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS") , " Creating the latex table(s) in file ", parameters.latexOutputFile)
                        createTexTables(parameters)
                        nextCompilationTime = Dates.now() + Dates.Minute(parameters.minLatexCompilationInterval)
                        isFirstLatexCompiled = true
                    end 

                    # Solve it
                    startingTime = time()
                    dictResults = parameters.resolutionMethods[methodId](dictCombination)
                    resolutionTime = time() - startingTime

                    dictResults["auto_expe_resolution_time"] = resolutionTime

                    # The results saved both contain the experiment results and the combination of parameters considered
                    outputResult = merge(dictCombination, dictResults)
                    outputResult["resolutionMethodName"] = currentMethodName
                    push!(instanceResults, outputResult)
                    
                    if parameters.verbosity != :None
                        println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS"), "\t\t Results: ", getString(dictResults))
                    end

                    # and save them
                    open(outputFile, "w") do fout
                        JSON.print(fout, instanceResults, 4)
                    end
                    println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS"), " Wrote in ", outputFile)

                else
                    if parameters.verbosity == :Debug || parameters.verbosity == :All
                        println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS"), "\t\t Skipped (already solved for this method).")
                    end 
                end 
            end

            isFirstCombination = false
        end
    end

    if parameters.latexFormatPath != nothing
        println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS") , " Creating the latex table(s) in file ", parameters.latexOutputFile)
        createTexTables(parameters)
    end
    
end 
    
function getNextCombinationId!(combinationId::Vector{Int}, parameters::Dict{String, Vector{Any}})

    isFirstCombination = isempty(combinationId)

    nextCombinationFound = false

    paramKeys = collect(keys(parameters))
    keyId = 1

    while !nextCombinationFound && keyId <= length(paramKeys)

        keyName = paramKeys[keyId]
        valueArray = parameters[keyName]

        if isFirstCombination
            if length(valueArray) > 0
                push!(combinationId, 1)
            else
                println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS"), " Parameter ", key, "has an empty size (value: ", valueArray, ").")
            end
        else
            # If the id keyId can be incremented
            if combinationId[keyId] < length(valueArray)

                # Increment it
                combinationId[keyId] += 1

                # And set the previous ids to 1
                for secondKeyId in 1:keyId - 1
                    combinationId[secondKeyId] = 1
                end

                nextCombinationFound = true
            end
        end

        keyId += 1
    end

    return nextCombinationFound
end 

function getCombination(combinationId::Vector{Int}, parameters::Dict{String, Vector{Any}})

    combination = Dict{String, Any}()

    paramKeys = collect(keys(parameters))
    
    for keyId in 1:length(paramKeys)

        keyName = paramKeys[keyId]
        valueArray = parameters[keyName]
        value = valueArray[combinationId[keyId]]
        combination[keyName] = value
    end

    return combination
    
end 

function getString(dict::Dict{String, Any})
    result = ""

    for (key, val) in dict
        result *= string(key) * " = \"" * string(val) * "\", "
    end

    return result
end

"""
Get the path of the instances in the json experiment

Input
- paths: each path can correspond to an instance file or to a folder. A folder is specified either by a String (its path) or a Dictionary with key "path" (and optionally key "isRecursive"). This argument either contain one folder or an array of folders;
- extensions: list of valid instance name extensions.
"""
function readInstances(paths, extensions::Vector{String})

    individualInstances = Vector{String}()

    # If there is only one instance entry
    if typeof(paths) <: Dict || typeof(paths) == String
        paths = [paths]
    end 
    
    for pathEntry in paths

        isRecursive = false

        cPath = ""
        if typeof(pathEntry) == String
            cPath = pathEntry
        elseif typeof(pathEntry) <: Dict && haskey(pathEntry, "path")
            cPath = pathEntry["path"]
            if haskey(pathEntry, "isRecursive")
                isRecursive = pathEntry["isRecursive"]
            end
        else
            println("Warning: instance path ignored since it is not represented by a String or a Dictionary with a key \"path\":\n\tpath: ", pathEntry)
        end 

        if isfile(cPath)
            if isExtensionValid(cPath, extensions)
                push!(individualInstances, cPath)
            else
                println("Warning: File ignored since its extension is not valid.\n\tpath: ", cPath, "\n\tValid extensions: ", extensions)
            end
        elseif isdir(cPath)
            append!(individualInstances, readInstanceFolder(cPath, extensions, isRecursive))
        else
            println("Warning: Instance path ignored since it does not correspond to an existing file or folder:\n\tinstance path: ", cPath)
        end
    end

    return individualInstances
end

"""
Find all the instances with a valid extension in a folder

Input:
- folderPath: path of the folder
- extensions: list of the valid extensions
- isRecursive: true if instances are sought recursively
"""
function readInstanceFolder(folderPath::String, extensions::Vector{String}, isRecursive::Bool)

    instances = Vector{String}()
    for file in readdir(folderPath)
        if isdir(file) && isRecursive
            append!(instances, readInstanceFolder(file, extensions, isRecursive))
        elseif isExtensionValid(file, extensions)
            push!(instances, folderPath * "/" * file)
        else
            println("Warning: data file ignored since it is either a folder or a file with an invalid extension.\n\tfile path: ", file)
        end 
    end

    return instances
end 

"""
Test if a file extension is included in a list of extensions

Input
- path: the path to test;
- validExtensions: list of the valid extensions.
"""
function isExtensionValid(path::String, validExtensions::Vector{String})

    extension = "" 
    if occursin('.', path)
        extension = path[findlast(isequal('.'), path)+1:end]
    end

    return extension in validExtensions || "." * extension in validExtensions
end  

"""
Get several julia functions.

Input:
- iMethods: Dictionary with an entry "name" (the name of the julia
function) and an optional entry "module" (the module in which the
function can be found). To specify several functions, iMethods can be
an array of such dictionaries. If the module is not specified, the
Main module will be considered in priority. If it is not in the Main
module, all the other loaded modules will be considered.

Output:
- vector of Function which correspond to the found functions.
"""
function getMethods(iMethods)

    # If there is only one method
    if !(typeof(iMethods) <: Vector)
        iMethods = [iMethods]
    end

    methods = Vector{Function}()

    # For each method
    for method in iMethods
        cName = nothing
        cModule = nothing

        # If it is defined by a string
        if typeof(method) == String
            cName = method

        # If it is defined by a Dict
        elseif typeof(method) <: Dict && haskey(method, "name")
            cName = method["name"]
            if haskey(method, "module")
                cModule = method["module"]
            else
                println("A resolution method must be a String or a Dictionary which contains key \"name\". Ignoring the following method:\n\tmethod: ", method, "\n\ttype: ", typeof(method))
            end
        end 

        # If the function is defined properly
        if cName != nothing

            # If its module is specified
            if cModule != nothing
                try
                    push!(methods, getfield(cModule, Symbol(cName)))
                catch e
                    println("Warning: unable to find method ", cName, " in module ", cModule)
                end
            else
                println("Debug: no module specified for method ", cName)

                moduleFound = false

                # First look for the method in the Main module
                try
                    push!(methods, getfield(Main, Symbol(cName)))
                    moduleFound = true
		    println("Debug: method found in package Main.")
                catch e
                    println("Debug: no function of name ", cName, " found in module Main")
                end

                # If the method is not in the main module test all loaded modules
                if !moduleFound

                    # Get all the loaded modules
                    modules =  Base.loaded_modules_array()
                    validModules = Vector{Tuple{Module, Function}}()
                    for moduleId in 1:length(modules)
                        try
                            f = getfield(modules[moduleId], Symbol(cName))
                            push!(modules, (modules[moduleId], f))
                        catch e
                        end
                    end

                    if length(validModules) == 0
                        println("Warning: no function ", cName, " found for any loaded module. This method is ignored")
                    else
                        if length(validModules) > 1
                            println("Warning: several loaded modules contain a function ", cName, ". We consider the one from module ", validModules[1][1])
                        else
                            println("Debug: loading function ", cName, " from module ", validModules[1][1])
                        end 
                        push!(methods, validModules[1][2])
                    end 
                end 
            end 
        end 
    end

    return methods

end 

"""
Read the format of the experiment from a json file
"""
function readExpeFormat(jsonFilePath::String)
    
    stringdata=join(readlines(jsonFilePath))
    expeDict = JSON.parse(stringdata)

    if !isa(expeDict, Dict)
       println("Error: The json file describing the experiment (", jsonFilePath, ") does not contain a dictionary.")
       return nothing
    end    

    # Test if the experiment format is valid
    if !haskey(expeDict, "instancesPaths") || !haskey(expeDict, "resolutionMethods")
        println("Error: The json file describing the experiment must contain a dictionary with at least an entry \"resolutionMethods\" and an entry \"instancesPaths\"")
        return nothing
    end

    # Get the valid extensions (txt and json by default)
    extensions = Vector{String}(["txt", "json"])

    if haskey(expeDict, "instanceExtensions")
        extensions = expeDict["instanceExtensions"]

        # If there is only one extension
        if !(typeof(extensions) <: Vector)
            extensions = [extensions]
        end 
    end 

    # Get all the instances
    instancesPath = Vector{String}()
    
    if haskey(expeDict, "instancesPaths")
        append!(instancesPath, readInstances(expeDict["instancesPaths"], extensions))
    end

    # Get all the methods
    methods = getMethods(expeDict["resolutionMethods"])

    parameters = ExpeParameters(instancesPath, methods)

    # Get all the optional parameters
    if haskey(expeDict, "outputPath")
        if typeof(expeDict["outputPath"]) != String
            println("Warning: the outputPath of the experiment must be a String (current value: ", expeDict["outputPath"], " current type: ", typeof(expeDict["outputPath"]), ")")
        else
            parameters.outputPath = expeDict["outputPath"]
        end 
    end  

    if haskey(expeDict, "recomputeSavedResults")
        if typeof(expeDict["recomputeSavedResults"]) != Bool
            println("Warning: the recomputeSavedResults of the experiment must be a boolean (current value: ", expeDict["recomputeSavedResults"], " current type: ", typeof(expeDict["recomputeSavedResults"]), ")")
        else
            parameters.recomputeSavedResults = expeDict["recomputeSavedResults"]
        end
    end 

    if haskey(expeDict, "computeUnsolvedResults")
        if typeof(expeDict["computeUnsolvedResults"]) != Bool
            println("Warning: the computeUnsolvedResults of the experiment must be a boolean (current value: ", expeDict["computeUnsolvedResults"], " current type: ", typeof(expeDict["computeUnsolvedResults"]), ")")
        else
            parameters.computeUnsolvedResults = expeDict["computeUnsolvedResults"]
        end
    end 

    if haskey(expeDict, "latexOutputFile")
        if typeof(expeDict["latexOutputFile"]) != String
            println("Warning: the latexOutputFile of the experiment must be a String (current value: ", expeDict["latexOutputFile"], " current type: ", typeof(expeDict["latexOutputFile"]), ")")
        else
            parameters.latexOutputFile = expeDict["latexOutputFile"]
        end
    end 

    if haskey(expeDict, "latexFormatPath")
        if typeof(expeDict["latexFormatPath"]) != String && !(typeof(expeDict["latexFormatPath"]) <: Vector)
            println("Warning: the latexFormatPath of the experiment must be a String or a vector of Strings (current value: ", expeDict["latexFormatPath"], " current type: ", typeof(expeDict["latexFormatPath"]), ")")
        else
            if !(typeof(expeDict["latexFormatPath"]) <: Vector)
                parameters.latexFormatPath = [expeDict["latexFormatPath"]]
            else 
                parameters.latexFormatPath = expeDict["latexFormatPath"]
            end 
        end
    end

    if haskey(expeDict, "minLatexCompilationInterval")
        if typeof(expeDict["minLatexCompilationInterval"]) != Int
            println("Warning: the minLatexCompilationInterval of the experiment must be an integer (current value: ", expeDict["minLatexCompilationInterval"], " current type: ", typeof(expeDict["minLatexCompilationInterval"]), ")")
        else
            parameters.minLatexCompilationInterval = expeDict["minLatexCompilationInterval"]
        end
    end 

    if haskey(expeDict, "parametersToCombine")
        if !(typeof(expeDict["parametersToCombine"]) <: Dict)
            println("Warning: the parametersToCombine of the experiment must be a Dictionary (current value: ", expeDict["parametersToCombine"], " current type: ", typeof(expeDict["parametersToCombine"]), ")")
        else
            parameters.parametersToCombine = expeDict["parametersToCombine"]
        end
    end 
    
    return parameters
end

function addValuesToResults(expeJsonPath::String, addingFunctionJsonPath::String)

    # Read the experiment parameters in order to find the instances path
    parameters = readExpeFormat(expeJsonPath)

    # Get the function which get the additional result entries
    stringdata=join(readlines(addingFunctionJsonPath))
    functionDict = JSON.parse(stringdata)
    addingFunction = getMethods(functionDict)

    if length(addingFunction) != 1
        println("Warning: when adding entries in existing saved results, the json file must only contain one dictionary with an entry \"name\" and optionally an entry \"module\". However, ", length(addingFunction), " valid functions have been found from file ", addingFunctionJsonPath, ".")
    end
    
    addingFunction = addingFunction[1] 
    
    for instancePath in parameters.instancesPath

        instanceName = splitext(basename(instancePath))[1]
        outputFile = parameters.outputPath * "/" * instanceName * ".json"
        outputFile = replace(outputFile, "//" => "/")
        
        # Variable which contains all the results of the current instance
        # Each result is a Dict which contains:
        # - one entry with the key "resolutionMethodName"
        # - one entry for each parameter
        # - one entry for each result
        instanceResults = Vector{Dict{String, Any}}()

        # Get the results previously computed for this instance if any
        if isfile(outputFile)
            println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS"), " Reading previous results from file \"", outputFile, "\"")
            stringdata=join(readlines(outputFile))

            try
                instanceResults = JSON.parse(stringdata)
                additionalResults = addingFunction(instancePath)  

                # For each result of the current instance, add it the additional results
                for singleResult in instanceResults
                    merge!(singleResult, additionalResults)
                end 

                # Save the updated results
                open(outputFile, "w") do fout
                    JSON.print(fout, instanceResults, 4)
                end

            catch e
                println(Dates.format(now(), "yyyy/mm/dd - HHhMM:SS") ,
                " Warning: Unable to read the JSON result file.")
            end 
                
        end
    end     
end 
    
