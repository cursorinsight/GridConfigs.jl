###-----------------------------------------------------------------------------
### Copyright (C) The GridConfigs contributors
###
### SPDX-License-Identifier: MIT
###-----------------------------------------------------------------------------

module JSONExt

import GridConfigs: GridConfig
import JSON

function GridConfig(io::IO, ::Val{:JSON}; kwargs...)
    return GridConfig(JSON.parse(io; kwargs...))
end

function GridConfig(file::AbstractString, ::Val{:JSON}; kwargs...)
    return GridConfig(JSON.parsefile(file; kwargs...))
end

end # JSONExt
