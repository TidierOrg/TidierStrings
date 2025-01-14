"""
$docstring_str_count
"""
function str_count(column, pattern::Union{String,Regex}; overlap::Bool=false)
    if ismissing(column)
        return (column)
    end

    if pattern isa String
        pattern = Regex(pattern) # treat pattern as regular expression
    end

    # Count the number of matches for the regular expression
    return length(collect(eachmatch(pattern, column, overlap=overlap)))
end

"""
$docstring_str_detect
"""
function str_detect(column, pattern::Union{String,Regex})
    if ismissing(column)
        return (column)
    end
    if pattern isa String
        or_groups = split(pattern, '|')

        or_results = []
        for or_group in or_groups
            and_patterns = split(or_group, '&')

            and_results = []
            for and_pattern in and_patterns
                trimmed_pattern = strip(and_pattern)
                push!(and_results, occursin(trimmed_pattern, column))
            end

            push!(or_results, all(and_results))
        end

        return any(or_results)
    else
        # For regular expressions, directly use occursin
        return occursin(pattern, column)
    end
end

"""
$docstring_str_locate
"""
function str_locate(string::AbstractString, pattern::Union{AbstractString,Regex})
    if isa(pattern, Regex)
        regex_pattern = pattern
    else
        regex_pattern = Regex(pattern)
    end

    match = Base.match(regex_pattern, string)

    if match === nothing
        return (NaN, NaN)
    else
        return (first(match.offset), last(match.offset))
    end
end

"""
$docstring_str_locate_all
"""
function str_locate_all(string::AbstractString, pattern::Union{AbstractString,Regex})
    if isa(pattern, Regex)
        regex_pattern = pattern
    else
        regex_pattern = Regex(pattern)
    end

    matches = collect(eachmatch(regex_pattern, string))

    return [(first(m.offset), last(m.offset)) for m in matches]
end

"""
$docstring_str_replace
"""
function str_replace(column, pattern::Union{String,Regex}, replacement::String)
    if ismissing(column)
        return (column)
    end

    if pattern isa String
        patterns = split(pattern, '|')
        first_occurrences = [(p, findfirst(Regex(p), column)) for p in patterns]
        # Filter out patterns that were not found
        found_occurrences = filter(x -> x[2] !== nothing, first_occurrences)
        # If none of the patterns are found, return the original column
        if isempty(found_occurrences)
            return column
        end
        # Get the first pattern among the found patterns
        first_pattern = sort(found_occurrences, by=x -> x[2].start)[1][1]
        # Replace the first occurrence of the first found pattern
        column = replace(column, Regex(first_pattern) => replacement, count=1)
    else
        # For regular expressions, directly use replace
        column = replace(column, pattern => replacement, count=1) # Only replace the first occurrence
    end
    # Replace multiple consecutive spaces with a single space
    column = replace(column, r"\s+" => " ")
    return column
end

"""
$docstring_str_replace_all
"""
function str_replace_all(column, pattern::Union{String,Regex}, replacement::String)
    if ismissing(column)
        return column
    end

    regex_pattern = isa(pattern, String) ? Regex(pattern) : pattern

    column = replace(column, regex_pattern => replacement)

    return replace(column, r"\s+" => " ")
end



"""
$docstring_str_remove
"""
function str_remove(column, pattern::Union{String,Regex})
    if ismissing(column)
        return (column)
    end

    if pattern isa String
        patterns = split(pattern, '|')
        first_occurrences = [(p, findfirst(Regex(p), column)) for p in patterns]
        # Filter out patterns that were not found
        found_occurrences = filter(x -> x[2] !== nothing, first_occurrences)
        # If none of the patterns are found, return the original column
        if isempty(found_occurrences)
            return column
        end
        # Get the first pattern among the found patterns
        first_pattern = sort(found_occurrences, by=x -> x[2].start)[1][1]
        # Remove the first occurrence of the first found pattern
        column = replace(column, Regex(first_pattern) => "", count=1)
    else
        # For regular expressions, directly use replace
        column = replace(column, pattern => "", count=1) # Only remove the first occurrence
    end
    # Replace multiple consecutive spaces with a single space
    column = replace(column, r"\s+" => " ")
    return column
end

"""
$docstring_str_remove_all
"""
function str_remove_all(column, pattern::Union{String,Regex})
    if ismissing(column)
        return (column)
    end

    if pattern isa String
        patterns = split(pattern, '|')
        for p in patterns
            column = replace(column, Regex(strip(p)) => "")
        end
    else
        # For regular expressions, directly use replace
        column = replace(column, pattern => "")
    end
    # Replace multiple consecutive spaces with a single space
    column = replace(column, r"\s+" => " ")
    return column
end

#"""
#$docstring_str_split
#"""
#function str_split(column::Union{Missing, String}, pattern::Union{String, Regex}, n::Int=2)
#    if ismissing(column)
#        return(column)
#    end
#    split_parts = split(column, pattern)
#    return split_parts[1:min(end, n)]
#end

"""
$docstring_str_starts
"""
function str_starts(string::AbstractString, pattern::Union{AbstractString,Regex}; negate::Bool=false)::Bool
    if ismissing(string)
        return (string)
    end
    if pattern isa Regex
        match_result = match(pattern, string) !== nothing
    elseif pattern isa AbstractString
        match_result = startswith(string, pattern)
    else
        error("Pattern must be either a Regex or an AbstractString.")
    end

    return negate ? !match_result : match_result
end
"""
$docstring_str_ends
"""
function str_ends(string::AbstractString, pattern::Union{AbstractString,Regex}; negate::Bool=false)::Bool
    if ismissing(string)
        return (string)
    end
    if pattern isa Regex
        match_result = match(pattern, string) !== nothing
    elseif pattern isa AbstractString
        match_result = endswith(string, pattern)
    else
        error("Pattern must be either a Regex or an AbstractString.")
    end

    return negate ? !match_result : match_result
end


"""
$docstring_str_subset
"""
function str_subset(column, pattern::Union{String,Regex})
    processor = x -> begin
        if ismissing(x)
            return x
        end

        matched = false

        if pattern isa String
            or_groups = split(pattern, '|')
            for or_group in or_groups
                trimmed_pattern = strip(or_group)
                if occursin(trimmed_pattern, x)
                    matched = true
                    break
                end
            end
        else
            matched = occursin(pattern, x)
        end

        return matched ? x : ""
    end

    return column isa Vector{String} ? map(processor, column) : processor(column)
end

"""
$docstring_str_which
"""
function str_which(strings::Vector{T}, pattern::Union{AbstractString,Regex}; negate::Bool=false)::Vector{Int} where {T}
    indices = Int[]
    for (i, s) in enumerate(strings)
        if pattern isa Regex && occursin(pattern, s)
            push!(indices, i)
        elseif pattern isa AbstractString && !ismissing(s) && occursin(pattern, s)
            push!(indices, i)
        end
    end

    if negate
        return setdiff(1:length(strings), indices)
    else
        return indices
    end
end


"""
$docstring_str_extract
"""
function str_extract(input::AbstractString, pattern::Union{String,Regex})
    # Convert pattern to Regex if it's a string
    regex_pattern = isa(pattern, String) ? Regex(pattern) : pattern

    # Find the first match, return missing if none found
    m = match(regex_pattern, input)
    return m === nothing ? missing : m.match
end

"""
$docstring_str_extract_all
"""
function str_extract_all(string::AbstractString, pattern::Union{String,Regex}; captures::Bool=false)
    # Convert pattern to Regex if it's a string
    regex_pattern = isa(pattern, String) ? Regex(pattern) : pattern

    # function to convert default 'nothing' when match unsuccessful to 'missing'
    to_missing(l) = [ifelse(isnothing(c), missing, c) for c in l]

    # Collect matches or captures
    matches = captures ?
              [to_missing(m.captures) for m in eachmatch(regex_pattern, string)] :
              [String(m.match) for m in eachmatch(regex_pattern, string)]

    # Return missing if no matches found
    return isempty(matches) ? missing : matches
end
