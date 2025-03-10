help( [[
A module to activate Spack and configure it to install packages in a directory specified by the user in the environment variable $SPACK_USER_PREFIX. The set-up is such that you use a common central Spack instance in /appl/lumi/spack, but you install packages in your own directory. Thus, you cannot change the configurations and update the Spack package repository. This has to be done by LUMI User Support Team . But you save the hassle of having to clone your own spack directory and write the configuration files.  
]]
)
whatis("Version: 22.08")
whatis("Keywords: Spack")
whatis("Description: the Spack package manager configured to install in a user specified directory. Spack release version 0.19.0 with minor patches to some packages.")

family( 'LUMI_SoftwareStack' )

local spackroot = "/appl/lumi/spack/22.08/0.19.0-user"
local userdir = os.getenv("SPACK_USER_PREFIX")

require("lfs")

-- Utility to check for the existence of a directory
function isDir(name)
    if type(name)~="string" then
      return false
    end
    local cwd = lfs.currentdir()
    local is = lfs.chdir(name) and true or false
    lfs.chdir(cwd)
    return is
end

if mode() == "load" then
  -- Check that $SPACK_USER_PREFIX is set
  if userdir == nil then
    LmodError("Please set $SPACK_USER_PREFIX to where you want to install Spack packages. We recommend using your project persistent storage for this. E.g. /project/project_<project-number>/spack")
  end

  -- Sanity check of the path
  if string.sub(userdir,1,6) == "/appl/" then
    LmodError("You cannot set $SPACK_USER_PREFIX to somewhere in the /appl filesystem, because it is read-only.")
  end

  LmodMessage("$SPACK_USER_PREFIX = " .. userdir)
  
  -- Check that the install directory actually exists, create it otherwise
  -- Note: the code below does not create the subdirectories 22.08/0.18.1, if they don't exist
  -- they will be created in the next step anyhow
  if not isDir(userdir) then
    LmodMessage("Creating the directory " .. userdir)
    ok,_,_ = os.execute("mkdir -p " .. userdir)
    if not ok then
      LmodError("The directory (" .. userdir .. ") specified in $SPACK_USER_PREFIX does not exist and the Spack module tried to create it, but it did not work.")
    end
  end
  
  -- Check for the modules directory and try to create it
  local moduledir = userdir .. "/22.08/0.19.0/modules/tcl"
  if not isDir(moduledir) then
    LmodMessage("Creating the Spack modules directory " .. (userdir .. "/modules/tcl"))
    ok,_,_ = os.execute("mkdir -p " .. userdir .. "/22.08/0.19.0/modules/tcl")
    if not ok then
      LmodError("The modules directory (" .. moduledir .. ") specified in $SPACK_USER_PREFIX does not exist and the Spack module tried to create it, but it did not work.")
    end
  end

  -- Check for the cache directory and try to create it
  local cachedir = userdir .. "/22.08/0.19.0/cache"
  if not isDir(cachedir) then
    LmodMessage("Creating the Spack cache directory " .. (userdir .. "/cache"))
    ok,_,_ = os.execute("mkdir -p " .. userdir .. "/22.08/0.19.0/cache")
    if not ok then
      LmodError("The cache directory (" .. cachedir .. ") specified in $SPACK_USER_PREFIX does not exist and the Spack module tried to create it, but it did not work.")
    end
  end

  LmodMessage("Spack module directory = " .. moduledir)
  LmodMessage("Spack cache directory = " .. cachedir)
end

-- This adds the "spack" binary (but not the spack shell functions)
prepend_path("PATH",spackroot .. "/bin")

-- The Spack root directory needs to be set
setenv("SPACK_ROOT",spackroot)

-- Override the user settings in the home directory
setenv("SPACK_DISABLE_LOCAL_CONFIG","true")

-- Only make the MODULEPATH change visible to LMOD when loading, unloading or 
-- showing a module to avoid interfereing with, e.g., module spider.
-- With the exception that it can always be make visible to LMOD if 
-- specifically requested through criteria coded in SitePackage.lua.
if mode() == 'load' or mode() == 'unload' or mode() == 'show' or is_full_spider() then
  -- Add Spack's modules
  prepend_path("MODULEPATH",userdir .. "/22.08/0.19.0/modules/tcl/linux-sles15-zen")
  prepend_path("MODULEPATH",userdir .. "/22.08/0.19.0/modules/tcl/linux-sles15-zen2")
  prepend_path("MODULEPATH","/appl/lumi/spack/22.08/0.19.0/share/spack/modules/linux-sles15-zen")
  prepend_path("MODULEPATH","/appl/lumi/spack/22.08/0.19.0/share/spack/modules/linux-sles15-zen2")
end
