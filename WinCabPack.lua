
local lfs = require("lfs")
local function cls()
	os.execute([[cls]])
end
local function getFolderStats(path)
    -- Initialize counters
    local totalSize = 0
    local numFolders = 0
    local numFiles = 0

    local function scanDirectory(directory)
        for entry in lfs.dir(directory) do
            -- Ignore the special entries '.' and '..'
            if entry ~= "." and entry ~= ".." then
                local fullPath = directory .. '/' .. entry
                local mode = lfs.attributes(fullPath, "mode")

                if mode == "directory" then
                    -- If the entry is a directory, recurse into it
                    numFolders = numFolders + 1
                    scanDirectory(fullPath)
                elseif mode == "file" then
                    -- If the entry is a file, increment the file count and add its size
                    numFiles = numFiles + 1
                    totalSize = totalSize + (lfs.attributes(fullPath, "size") or 0)
                end
            end
        end
    end

    -- Start the scanning process from the root path provided
    scanDirectory(path)

    return totalSize, numFolders, numFiles
end


local function makeTempPath(path,ext)
	local TempFilePath = nil
	local TempFileName = nil
	repeat
	
	TempFileName = os.tmpname().. ext
	TempFileName = TempFileName:sub(2,#TempFileName)
	TempFilePath = path .. "/"..TempFileName
	until (TempFilePath and (not lfs.attributes(TempFilePath)))
	return TempFilePath, TempFileName
end
local makeFile = function(name,data)
	local file = io.open(name,"w")
	file:write(data)
	file:close()
	return file
end

local function generateEXE(params)
	Settings = {
	["password"] = false or params["password"],
	["batScriptPath"] = false or params["batScriptPath"]
	}

    local dir = string.match(Settings.batScriptPath, "(.+)/[^/]*%.exe$")
    local batFileName = string.match(Settings.batScriptPath, ".+/([^/]*%.exe)$")
	--local dir = string.match(batScriptPath, "(.+)/[^/]*$")
	--local TargetFileName = string.match(batScriptPath, ".+/([^/]*)$")
	if not dir then
		return
	end
	local sedFilePath, sedFileName = makeTempPath(dir,".sed")
	local runnerFilePath, runnerFileName = makeTempPath(dir,".bat")
	local zipFilePath, zipFileName = makeTempPath(dir,".zip")
	local finnishBatFilePath, finnishBatFileName = makeTempPath(dir,".bat")
	local zip7FilePath, zip7FileName = makeTempPath(dir,".exe")
    local runnerCode = [[

@echo off

]]..(Settings.password and [[
powershell -window normal -command ""
echo Please enter password.
set /p password=
powershell -window hidden -command ""
]]..zip7FileName..[[ x ]]..zipFileName..[[ -p:"%password%"]] or
zip7FileName..[[ x ]]..zipFileName)..[[



del ]]..zip7FileName..[[

del ]]..zipFileName..[[

cls

del ]]..runnerFileName..[[ && "]]..batFileName..[["
]]
    makeFile(runnerFilePath,runnerCode)
    local sedFile = io.open(sedFilePath, "w")
    if not sedFile then
        print("Error opening SED file for writing.")
        return
    end
    
    sedFile:write([[
[Version]
Class=IEXPRESS
SEDVersion=3
[Options]
PackagePurpose=InstallApp
ShowInstallProgramWindow=]]..params.HideConsole..[[

HideExtractAnimation=1
UseLongFileName=1
InsideCompressed=0
CAB_FixedSize=0
CAB_ResvCodeSigning=0
RebootMode=N
InstallPrompt=%InstallPrompt%
DisplayLicense=%DisplayLicense%
FinishMessage=%FinishMessage%
TargetName=%TargetName%
FriendlyName=%FriendlyName%
AppLaunched=%AppLaunched%
PostInstallCmd=%PostInstallCmd%
AdminQuietInstCmd=%AdminQuietInstCmd%
UserQuietInstCmd=%UserQuietInstCmd%
SourceFiles=SourceFiles
[Strings]
InstallPrompt=
DisplayLicense=
FinishMessage=
]])
    

	
	sedFile:write("TargetName=" .. (params.outputPath and (params.outputPath:gsub("/","\\")) or (dir:gsub("/","\\")).."\output.exe") .. "\n")
    sedFile:write("FriendlyName=bat2exe\n")
    sedFile:write("AppLaunched=cmd /c \"" .. runnerFileName .. "\"\n")
	
    sedFile:write("PostInstallCmd=<None>\n")
    sedFile:write("AdminQuietInstCmd=\n")
    sedFile:write("UserQuietInstCmd=\n")
    sedFile:write("FILE0=\"" .. runnerFileName .. "\"\n")
    sedFile:write("FILE1=\"" .. zipFileName .. "\"\n")
    sedFile:write("FILE2=\"" .. zip7FileName .. "\"\n")
    
    sedFile:write("[SourceFiles]\n")
    sedFile:write("SourceFiles0=" .. dir:gsub("/","\\") .. "\\\n")
    sedFile:write("[SourceFiles0]\n")
    for i = 0, 2 do
        sedFile:write("%FILE" .. i .. "%=\n")
    end
    
    sedFile:close()
	
	batchcode = [[
@echo off
copy "7za.exe" "]]..(dir:gsub("/","\\"))..[[\]]..zip7FileName..[["
"7za.exe" a -tzip "]]..(dir:gsub("/","\\"))..
[[\]]..zipFileName..[[" "]]..(dir:gsub("/","\\"))..
[[\*" -x!]]..finnishBatFileName..[[ -x!]]..sedFileName..
[[ -x!]]..runnerFileName..
[[ -x!]]..zip7FileName..
[[ -mx9 ]]..
(Settings.password and [[-p:"]]..Settings.password..[["]] or "")..[[

]]

	
	
	
	makeFile(finnishBatFilePath, batchcode)
	
	if lfs.attributes((params.outputPath:gsub("\\","/"))) then
		os.remove((params.outputPath:gsub("\\","/")))
	end
	os.execute([["]]..finnishBatFilePath..[["]])
	
	
	lfs.chdir(dir)
	os.execute([[iexpress /N ]]..sedFileName)

	os.remove(finnishBatFilePath)
	os.remove(runnerFilePath)
	os.remove(zipFilePath)
	os.remove(zip7FilePath)
	os.remove(sedFilePath)
	return lfs.attributes(dir .. "/output.exe")
end


local exeSettings = {
	["batScriptPath"] = arg[1],
	["password"] = arg[2],
	["outputPath"] = arg[3],
	["HideConsole"] = arg[4]
}

cls()
print([[Enter the path to the .bat file you wish to package into a .exe]])
print([[All files and folders within the root directory of the .bat file will be packaged as well.]])
print([[You can drag a folder into this window.]])

exeSettings.batScriptPath = exeSettings.batScriptPath or io.read()
exeSettings.batScriptPath = exeSettings.batScriptPath:gsub("\\","/"):gsub([["]],"")
cls()

if not arg[1] then
	print([[Target File: ]]..exeSettings.batScriptPath)
	-- Example usage
	local path = string.match(exeSettings.batScriptPath, "(.+)/[^/]*$")
	local totalSize, numFolders, numFiles = getFolderStats(path)
	print("Total Size: " .. totalSize .. " bytes")
	print("Folders: " .. numFolders)
	print("Files: " .. numFiles)
	print([[Add a password. (Encrypted with AES-256)]])
	print([[Leave blank and press Enter to skip.]])
	exeSettings.password = exeSettings.password or io.read()
end


if exeSettings.password == "" then
	exeSettings.password = false
end
if exeSettings.outputPath == "" then
	exeSettings.outputPath = false
end
cls()
generateEXE(exeSettings)


