VERSION = "0.0.1"
local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")
local os = import("os")

local cwd = config.ConfigDir .. "/plug/intab/"

function is_file(fn)
	local a, b = os.Stat(fn)
	if a == nil then
		return false
	end
	
	return not a:IsDir()
end

function onStdout(text)
	micro.CurPane():AddTab( )
	micro.CurPane():OpenCmd( {text} )
end

function dummy(text)
end


function host()
	micro.Log( "Run as host" )
    local f = io.open(cwd .. "pid", "w+")
    f:write(os.Getpid())
    f:close()
    
    shell.ExecCommand("mkfifo", cwd .. "pipe" )
    shell.JobSpawn("tail", { "-f", cwd .. "pipe" } , onStdout, dummy, dummy, {})
end

function client()
	micro.Log( "Run as client" )
	local filepath = import("filepath")
	
	if(#os.Args < 2) then
		micro.Log( "Run blank" )
		return false
	end
	
	local fn = os.Args[2]
	
	if( is_file(fn) == false ) then
		micro.Log( "Run blank" )
		return false
	end
	
	local path, e = filepath.Abs( fn )
	
	micro.Log( "Send to host", path )
	local f = io.open(cwd .. "pipe", "w")
    f:write(path)
    f:close()
	
	micro.CurPane():QuitCmd({})
end



function init() 
	
	local f = io.open(cwd .. "pid", "r")
    if f == nil then
        host()
        return
    end
    
    local pid = f:read("*a")
    f:close()
    
    f = io.open("/proc/" .. pid .. "/comm", "r")
    if f == nil then
        host()
        return
    end    
    
    local exec = f:read("*a")
    f:close()
    
    if exec:sub(0,5) == "micro" then
        client()
    else
        host()
    end
	
end


