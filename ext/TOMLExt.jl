###-----------------------------------------------------------------------------
### Copyright (C) The GridConfigs contributors
###
### SPDX-License-Identifier: MIT
###-----------------------------------------------------------------------------

module TOMLExt

import GridConfigs: GridConfig
import TOML

function GridConfig(io::IO, ::Val{:TOML})
    return GridConfig(TOML.parse(io))
end

function GridConfig(file::AbstractString, ::Val{:TOML})
    return GridConfig(TOML.parsefile(file))
end

end # module TOMLExt
