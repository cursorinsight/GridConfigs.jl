###-----------------------------------------------------------------------------
### Copyright (C) The GridConfigs contributors
###
### SPDX-License-Identifier: MIT
###-----------------------------------------------------------------------------

module YAMLExt

import GridConfigs: GridConfig
import YAML

function GridConfig(io::IO, ::Val{:YAML})
    return GridConfig(YAML.load(io; dicttype = Dict{String, Any}))
end

function GridConfig(file::AbstractString, ::Val{:YAML})
    return GridConfig(YAML.load_file(file; dicttype = Dict{String, Any}))
end

end # module YAMLExt
