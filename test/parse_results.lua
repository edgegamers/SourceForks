local ansicolors = require 'lib.ansicolors'

local ARGS = {...}

local good = true;
local count_good = 0;
local count_warn = 0;
local count_error = 0;

local function cprint(format,...)
    print(ansicolors( string.format(format, ...)))
end

cprint("{magenta}[GDC]   {reset}========================================================")

cprint("{magenta}[GDC]   {reset}Checking '%s'...", ARGS[1])

local function STATUS(note, iserror, iswarn)
    return {
        IsError = iserror,
        IsWarn = iswarn,
        Note = note,
    }
end

local sig_status = {
    UNKNOWN = STATUS("No signature provided", false, true),
    MIDFUNC = STATUS("Signature is mid-function", false, true),
    NOTFOUND = STATUS("Signature has no matches", true),
    MULTIPLE = STATUS("Signature has multiple matches", true),
    --  Linux only. Think it was missed in a refactor, but is functionally the same as MULTIPLE.
    CHECK = STATUS("Signature has multiple matches", true),
    GOOD = STATUS("Found"),
}

local function DoSigStatus(fancyosname, signame, binary, status)
    local statustype = sig_status[status]

    if statustype.IsError then
        cprint("{red}[ERROR] {blue}%s{reset} (%s):\t%s -> %s", binary, fancyosname, signame, statustype.Note)
        good = false
        count_error = count_error + 1
        return;
    end

    if statustype.IsWarn then
        cprint("{yellow}[WARN]  {blue}%s{reset} (%s):\t%s -> %s", binary, fancyosname, signame, statustype.Note)
        count_warn = count_warn + 1
        return;
    end

    count_good = count_good + 1
end

for line in io.lines("output.temp") do
    local hasextra, name, binary, winstat, linuxstat = line:match("(%!?) S: ([%w%p]+)%s+%((%w+)%) %- w: (%w+)%s*%- l: (%w+)")

    if name ~= null then
        DoSigStatus("Windows", name, binary, winstat)
        DoSigStatus("Linux", name, binary, linuxstat)
    end
end

cprint("{magenta}[GDC]   {reset}Done!")
cprint("{magenta}[GDC]   {green}%i Passed", count_good)
cprint("{magenta}[GDC]   {%s}%i Warnings", (count_warn == 0 and "green") or "yellow", count_warn)
cprint("{magenta}[GDC]   {%s}%i Errors", (count_error == 0 and "green") or "red", count_error)

cprint("{magenta}[GDC]   {reset}========================================================")


if good then
    return 0
end
os.exit( -1 )