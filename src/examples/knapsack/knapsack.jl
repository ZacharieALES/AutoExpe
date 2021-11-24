using JSON
using Random
include("../../runExpe.jl")

"""
Represents an instance of the knapsack problem
"""
mutable struct KnapsackInstance

    weights::Vector{Int}

    values::Vector{Int}

    function KnapsackInstance()
        return new()
    end 
end

"""
KnapsackInstance constructor
"""
function KnapsackInstance(jsonPath::String)

    this = KnapsackInstance()
    
    stringData = join(readlines(jsonPath))
    instanceData = JSON.parse(stringData)
    
    this.weights = instanceData["weights"]
    this.values = instanceData["values"]

    return this
end

"""
Solve a knapsack instance by adding random objects to random knapsacks
"""
function randomResolution(param::Dict{String, Any})
    return knapsackHeuristicResolution(param, isRandom = true)
end


"""
Solve a knapsack instance by sorting the objects according to their value/weight and adding them to a knapsack as full as possible
"""
function ratioResolution(param::Dict{String, Any})
    return knapsackHeuristicResolution(param, isRandom = false)
end 

"""
Heuristically solve a knapsack instance.
The order in which the objects are sorted and the knapsack in which they are added are defined by the argument "isRandom".
"""
function knapsackHeuristicResolution(param::Dict{String, Any}; isRandom::Bool=false)

    instance = KnapsackInstance(param["instancePath"])

    n = length(instance.weights)
    m = param["knapsackCount"]
    K = param["knapsacksSize"]

    order = nothing

    if isRandom
        # Get a random order for the objects
        order = shuffle(1:n)
    else 
        # Otherwise order the objects according to the ratio value/weight
        ratio = instance.values ./ instance.weights
        order = reverse(sortperm(ratio))
    end 

    # Current value of the objective and weight of each knapsack
    objectiveValue = 0
    knapsacksWeight = Vector{Int}(zeros(m))
    knapsacksContent = Vector{Vector{Int}}()

    for knapsackId in 1:m
        push!(knapsacksContent, Vector{Int}())
    end 

    # For each object
    for objectId in order

        knapsackId = -1

        # If the knapsack is chosen randomly
        if isRandom
            knapsackId = getRandomKnapsack(K, instance.weights[objectId], knapsacksWeight)
        else
            knapsackId = getFullestKnapsack(K, instance.weights[objectId], knapsacksWeight)
        end
        
        # If the object fits in a knapsack
        if knapsackId != -1
            knapsacksWeight[knapsackId] += instance.weights[objectId]
            objectiveValue += instance.values[objectId]
            push!(knapsacksContent[knapsackId], objectId)
        end 
    end
    
    results = Dict{String, Any}()
    results["objectiveValue"] = objectiveValue
    results["knapsacksWeight"] = knapsacksWeight
    results["knapsacksContent"] = knapsacksContent

    return results
end 

function getRandomKnapsack(K::Int, objectWeight::Int, knapsacksWeight::Vector{Int})

    m = length(knapsacksWeight)
    
    # Randomly choose a knapsack to add the object     
    knapsackId = ceil(Int, m * rand())
    knapsackTested = 0
    validKnapsackFound = false

    # While all the knapsack have not been tested and a knapsack in which the object fits has not been found
    while knapsackTested < m && !validKnapsackFound

        # If the object fits
        if knapsacksWeight[knapsackId] + objectWeight <= K
            validKnapsackFound = true
        else
            # Get the next knapsack id
            knapsackId = max(1, rem(knapsackId + 1, m+1))
            knapsackTested += 1
        end
    end

    if !validKnapsackFound
        return -1
    else
        return knapsackId
    end 
end 

function getFullestKnapsack(K::Int, objectWeight::Int, knapsacksWeight::Vector{Int})

    m = length(knapsacksWeight)
    bestKnapsackId = -1
    bestRemainingWeight = 0

    for knapsackId in 1:m

        remainingWeight = K - knapsacksWeight[knapsackId] + objectWeight
        
        # If the object fits in the knapsack and
        # - it is the first one; or
        # - there is less remaining weight in it than in the currently best knapsack found
        if  remainingWeight > 0 && (bestKnapsackId == -1 || remainingWeight < bestRemainingWeight)
            bestKnapsackId = knapsackId
            bestRemainingWeight = remainingWeight
        end 
    end

    return bestKnapsackId
end 

"""
Let assume that we need the value of n in the result tables but we forgot
to add it in already obtained results files.

Two potentially expensive solutions would be:
- to add n manually in each result; or
- to restart the experiment from scratch.

To do it faster you can:
1 - define this function which returns n for a given instance;
2 - create a json file which only contains a String with the name of this function (i.e.,  "addNToResults");
3 - use function addToSavedResults (from runExpe.jl) with the json file as an input.
"""
function addNToResults(instancePath::String)
    instance = KnapsackInstance(instancePath)
    results = Dict{String, Any}()
    results["n"] = length(instance.weights)
    return results
end 
