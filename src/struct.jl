using Printf

"""
Represents the information required to retrieve a value v in a json result entry
"""
mutable struct ValueInformation

    # Key in the dictionary which contains the value
    key::String

    # If the value is included in a d-dimensional array, indexesDimension contains the d successive indexes at which v is located.
    # ex: if indexes = [2, 3], then v = dictionary[key][2, 3]
    # Otherwise (i.e., if the value associated to the key is directly v and is not contained in an array), the array is empty
    indexes::Vector{Int}

    # Name of the resolution method from which the value must be obtained (empty if it can be any resolution method)
    resolutionMethod::String

    function ValueInformation()
        return new()
    end 
end

"""
ValueInformation constructor
"""
function ValueInformation(key::String, indexes::Vector{Int}=Vector{Int}([]))

    this = ValueInformation()
    this.key = key
    this.indexes = indexes
    this.resolutionMethod = ""

    return this
end

function Base.show(io::IO, vi::ValueInformation)
    print(io, vi.key)

    if vi.indexes != []
        print(io, vi.indexes)
    end 
end  

"""
Parameters of an automatic experiment
"""
mutable struct ExpeParameters 

    # Path of each instance file to solve
    instancesPath::Vector{String}

    # Resolution methods called to solve each instance
    resolutionMethods::Vector{Function}

    # Path of the folder in which the results are saved
    outputPath::String

    # True if instance already solved before starting the experiment must be solved again
    recomputeSavedResults::Bool

    # True if the results which have not been solved before the experiment are solved
    computeUnsolvedResults::Bool

    # How verbose is the output of the experiment
    # Possible values from less verbose to more verbose:
    # :None, :Standard, :Debug, :All
    verbosity::Symbol

    latexOutputFile::String

    # Each path corresponds to a json file describing how to build a latex table (empty if there is no latex table to print)
    latexFormatPath::Vector{String}

    # Minimum number of minutes between two compilations of the latex table (avoid compiling to often if the resolution methods are fast)
    minLatexCompilationInterval::Int

    # Each array represents the different values of a parameter taken in the experiment
    # ex :
    # ("clustersNumber", [2, 4, 6])
    # ("maxClusterSize", [10, 20, 30])
    #
    # Each instance will be solved for all possible combinations of these arrays
    # In the example, the combinations are:
    # (2, 10), (2, 20), (2, 30), (4, 10), (4, 20), (4, 30), (6, 10), (6, 20), (6, 30)
    parametersToCombine::Dict{String, Vector{Any}}
    
    function ExpeParameters()   
        return new()         
    end
end                          
 
"""
Constructor of the parameters in which the path of each instance is specified
"""
function ExpeParameters(instancesPath::Vector{String}, resolutionMethods::Vector{Function}; recomputeSavedResults::Bool=false, verbosity::Symbol=:Standard, outputPath::String="./results/.expeResults/", latexFormatPath::Vector{String}=Vector{String}([]), minLatexCompilationInterval::Int=30, computeUnsolvedResults::Bool=true, latexOutputFile::String="./results/" * Dates.format(now(), "yyyy_mm_dd-HHhMM_SS") * "_resultTable.tex")
 
    this = ExpeParameters()     

    this.verbosity = verbosity
    this.outputPath = outputPath
    this.instancesPath = instancesPath
    this.resolutionMethods = resolutionMethods
    this.latexOutputFile = latexOutputFile
    this.latexFormatPath = latexFormatPath
    this.recomputeSavedResults = recomputeSavedResults
    this.parametersToCombine = Dict{String, Vector{Any}}()
    this.computeUnsolvedResults = computeUnsolvedResults
    this.minLatexCompilationInterval = minLatexCompilationInterval

    if occursin("results/.expeResults/", outputPath)
        mkpath("./results/.expeResults")
    end
    
    if occursin("./results/", latexOutputFile)
        mkpath("./results")
    end 
 
    return this              
end 

"""
Constructor of the parameters in which the folder which includes the instances is specified

Input
- extension: the instances file names must match this extension
    Can or cannot start with a dot (e.g., "txt" or ".txt")
- filters: the instances file names must include each element of filters array
"""
function ExpeParameters(instancesFolder::String, resolutionMethods::Vector{Function}; recomputeSavedResults::Bool=false, verbosity::Symbol=:Standard, outputPath::String="./", latexFormatPath::Vector{String}=[], minLatexCompilationInterval::Int=30, computeUnsolvedResults::Bool=true, extension::String="", filters::Vector{String}=[])
 
    this = ExpeParameters()     

    this.verbosity = verbosity
    this.outputPath = outputPath
    this.resolutionMethods = resolutionMethods
    this.recomputeSavedResults = recomputeSavedResults
    this.latexFormatPath = latexFormatPath
    this.parametersToCombine = Dict{String, Vector{Any}}()
    this.computeUnsolvedResults = computeUnsolvedResults
    this.minLatexCompilationInterval = minLatexCompilationInterval

    # Get all the instance file which match the extension and the filters
    this.instancesPath = []

    instanceFolder = strip(instancesFolder)

    # Ensure that the folder path finishes with a slash
    if instancesFolder[end] != "/"
        instancesFolder *= "/"
    end 

    # If an extension is specified and it does not start with a dot
    if extension != "" && extension[1] != "."
        extension = "." * extension
    end 

    for file in readdir(instancesFolder)
        isFileValid = true

        # If an extension is specified, test if it mathces it
        if extension != ""
            if length(file) < length(extension) || file[end-length(extension)+1:end] != extension
                isFileValid = false
            end 
        end

        filterId = 1

        while filterId <= size(filters, 1) && isFileValid
            if !occursin(filters[filterId], file)
                isFileValid = false
            end 
            filterId += 1
        end

        if isFileValid
            push!(this.instancesPath, instancesFolder * file)
        end 
    end

    return this              
end 


"""
Variable which different values appear in the rows of the latex table
"""
mutable struct RowVariable

    # Information of the variable in the result files
    valInfo::ValueInformation

    # Name displayed in the header of the table
    displayedName::String

    # True if the table includes a horizontal line between different values of this variable
    hlineBetweenValues::Bool

    function RowVariable()
        return new()
    end
end

"""
Row variable constructor
"""
function RowVariable(valInfo::ValueInformation; displayedName::String=valInfo.key, hlineBetweenValues::Bool=false)

    this = RowVariable()
    this.valInfo = valInfo
    this.displayedName = displayedName
    this.hlineBetweenValues = hlineBetweenValues

    return this
end


"""
Represents one result column
"""
mutable struct Column

    # Name of the column in the table
    columnName::String

    # Name of the variables in the result file which are used to compute the value of the column
    valInfos::Vector{ValueInformation}

    # True if there is a vertical line after this column
    vlineAfter::Bool

    # Number of digits after the decimal 
    digits::Int

    # Function which specifies how the value of the column is computed from the vector of variables namesInFile
    computeValue::Function

    # Prefix added at the beginning of each entry in this column
    prefix::String
    
    # Suffix added at the end of each entry in this column
    suffix::String

    # True if the values in this column are ignored when finding the best value of a column group
    ignoreBold::Bool

    # Attribute by which each numerical value in the column will be multiplied
    multiplier::Float64
    
    function Column()
        return new()
    end
end

function emptyFunction()
end 

"""
Column constructor
"""
function Column(valInfos::Vector{ValueInformation}; columnName::String="", vlineAfter::Bool=false, computeValue=emptyFunction, digits::Int=2, prefix::String="", suffix::String="", ignoreBold::Bool=false, multiplier::Float64=1.0)

    this = Column()
    this.valInfos = valInfos
    this.vlineAfter = vlineAfter
    this.computeValue = computeValue
    this.digits = digits
    this.prefix = prefix
    this.suffix = suffix
    this.ignoreBold = ignoreBold
    this.multiplier = multiplier 

    if columnName != ""
        this.columnName = columnName
    else

        this.columnName = ""
        if this.computeValue != emptyFunction
            this.columnName = String(nameof(computeValue)) * "("
        end

        for viId in 1:size(valInfos, 1)
            this.columnName *= string(valInfos[viId])

            if viId < size(valInfos, 1)
                this.columnName *= ", "
            end 
        end 

        if this.computeValue != emptyFunction
            this.columnName *= ")"
        end 
    end 
    
    return this
end

"""
Represents several columns which are regrouped under the same title
"""
mutable struct ColumnGroup

    # Name of the group
    groupName::String

    # The columns it contains
    columns::Vector{Column}

    # True if there is a vertical line after the last column of the group
    vlineAfter::Bool

    # True if the best value(s) of the group must appear in bold
    highlightBestValue::Bool
    
    # True if in this group the lower the value, the better
    isBestValueMinimal::Bool

    function ColumnGroup()
        return new()
    end
end

"""
ColumnGroup constructor
"""
function ColumnGroup(groupName::String, columns::Vector{Column}; isBestValueMinimal::Bool=true, highlightBestValue::Bool=false, vlineAfter::Bool=false)

    this = ColumnGroup()
    this.groupName = groupName
    this.columns = columns
    this.vlineAfter = vlineAfter
    this.isBestValueMinimal = isBestValueMinimal
    this.highlightBestValue = highlightBestValue
    
    return this
end

"""
Main parameters of a latex table
"""
mutable struct TableParameters

    caption::String

    maxRowsInATable::Int

    expandInstances::Bool
    
    hideInstancesExtension::Bool

    leftVline::Bool

    rightVline::Bool

    vlineAfterRowParams::Bool

    # Maximal value which is not represented using the scientific notation
    maxNonScientificValue::Int

    function TableParameters(;caption::String="Latex table automatically generated via julia package AutoExpe.jl.", maxRowsInATable::Int=30, expandInstances::Bool=false, leftVline::Bool=true, rightVline::Bool=true, vlineAfterRowParams::Bool=true, maxNonScientificValue::Int=99999)

        this = new()
        
        this.caption = caption
        this.maxRowsInATable = maxRowsInATable
        this.expandInstances = expandInstances
        this.leftVline = leftVline
        this.rightVline = rightVline
        this.vlineAfterRowParams = vlineAfterRowParams
        this.maxNonScientificValue = maxNonScientificValue
        this.hideInstancesExtension = false
        
        return this
    end
end


"""
Represents a value in a table
"""
mutable struct TableValue

    # Value which can be numerical, symbol, text, ...
    value::Any

    # String representation of the value as displayed in the latex table
    displayedValue::String
    
    isNumerical::Bool

    # True if the value is computed using methods which do not have the maximal number of results 
    isMissingMethodResults::Bool

    # True if the value is ignored when finding the best value of a column group
    ignoreBold::Bool
    
    function TableValue()
        return new()
    end 
end

"""
TableValue constructor
"""
function TableValue(value::Any, isNumerical::Bool, isMissingMethodResults::Bool, maxNonScientificValue::Integer, column::Column)

    this = TableValue()
    this.value = value
    this.isNumerical = isNumerical
    this.isMissingMethodResults = isMissingMethodResults
    this.ignoreBold = column.ignoreBold

    if isNumerical
        if value > maxNonScientificValue
            this.displayedValue = @sprintf("%.2E", value)
        else
            this.displayedValue = string(value)
        end 
    else
        if value == nothing
            this.displayedValue = ""
        else
            this.displayedValue = string(value)
        end 
    end

    if isMissingMethodResults && this.displayedValue != ""
        this.displayedValue *= raw"""^\dag""" 
    end

    if this.displayedValue != ""
        if column.prefix != ""
            this.displayedValue = "\\mbox{" * column.prefix * "}" * this.displayedValue
        end

        if column.suffix != ""
            this.displayedValue *= "\\mbox{" * column.suffix * "}"
        end 
    end 
    
    return this
end

"""
Contains all the results associated to a given method for a given instance in a row of a latex table
"""
mutable struct MethodResults

    # Results for this instances for a given row
    results::Vector{Dict{String, Any}}

    # Name of the instance
    resolutionMethodName::String

    # True if the method has the maximal number of results for this instance in this row
    hasAllResults::Bool
    
    function MethodResults()
        return new()
    end 
end

"""
MethodResults constructor
"""
function MethodResults(resolutionMethodName::String, results::Vector{Dict{String, Any}})

    this = MethodResults()

    this.results = results
    this.resolutionMethodName = resolutionMethodName
    return this
end

"""
Contains all the results associated to a given instance for a combination in a latex table
"""
mutable struct InstanceResults

    # Path of the instance
    instancePath::String

    # Results for this combination and this instance for each resolution method
    methodResults::Dict{String, MethodResults}

    # Values of each result column for this instance in this row
    # computedResults[i][j] is the jth result obtained for column i
    computedResults::Vector{Vector{Any}}

    # Text displayed in each result column for this instance in this row
    # displayedValues[i] is the result displayed in column i
    # (used only if the table does not display mean values of the instances, otherwise CombinationResults.displayedValues is considered)
    displayedValues::Vector{TableValue}
    
    function InstanceResults()
        return new()
    end 
end

"""
InstanceResults constructor

Input
- parameters: parameters of the current experiment;
- instancePath: path of the instance;
- instanceResults: all the results for this instance
"""
function InstanceResults(parameters::ExpeParameters, instancePath::String, instanceResults::Vector{Dict{String, Any}})

    this = InstanceResults()

    this.methodResults = Dict{String, MethodResults}()
    this.computedResults = Vector{Vector{Any}}()
    this.displayedValues = Vector{TableValue}()

    maximalNumberOfResults = -1

    # For each resolution method
    for resolutionMethod in parameters.resolutionMethods
        resolutionMethodName = string(nameof(resolutionMethod))

        # Get all its results
        methodResults = Vector{Dict{String, Any}}()
        for result in instanceResults
            if result["resolutionMethodName"] == resolutionMethodName
                push!(methodResults, result)
            end 
        end

        # If results are found
        if size(methodResults, 1) > 0
            this.methodResults[resolutionMethodName] = MethodResults(resolutionMethodName, methodResults)
            if size(methodResults, 1) > maximalNumberOfResults
                maximalNumberOfResults = size(methodResults, 1)
            end 
        end
    end 

    for (methodName, methodResults) in this.methodResults
        methodResults.hasAllResults = size(methodResults.results, 1) == maximalNumberOfResults
    end
    
    return this
end


"""
Represents all the relevant information related to the results of a combination of the row parameters.
"""
mutable struct CombinationResults

    # Value of the parameters in this row
    combination::Vector{Any}

    # Results in this row
    # instanceResults[instancePath] contains all the results in this row for the instance at path instancePath
    instancesResults::Dict{String, InstanceResults}

    # Indicates on which columns a horizontal line must be drawn after the row (nothing if no line must be drawn)
    # clineColumns[1]: column at which the line starts
    # clineColumns[2]: column at which the line ends
    clineColumns::Vector{Int}

    # Values displayed for the combination
    # (used only if the table displays mean values of the instances, otherwise instancesResults.)
    displayedValues::Vector{TableValue}
    
    function CombinationResults()
        return new()
    end 
end

"""
CombinationResults constructor

Input
- parameters: the parameters of the current experiment
- combination: the value of each row parameters in the row;
- combinationResults: all the results for all instances in the combination
"""
function CombinationResults(parameters::ExpeParameters, combination::Vector{Any}, combinationResults::Vector{Dict{String, Any}})

    this = CombinationResults()

    this.instancesResults = Dict{String, InstanceResults}()
    this.combination = combination
    this.clineColumns = Vector{Int}()
    this.displayedValues = Vector{TableValue}()

    # For each instance
    for instancePath in parameters.instancesPath

        # Get all its results
        instanceResults = Vector{Dict{String, Any}}()
        for result in combinationResults
            if result["auto_expe_instance_path"] == instancePath
                push!(instanceResults, result)
            end 
        end

        # If results are found
        if size(instanceResults, 1) > 0
            this.instancesResults[instancePath] = InstanceResults(parameters, instancePath, instanceResults)
        end
    end

    return this
end




function isMissingResults(instanceResults::InstanceResults, methodName::String)
    if haskey(instanceResults.methodResults, methodName)
        return !instanceResults.methodResults[methodName].hasAllResults
    else
        return true
    end 
end 
