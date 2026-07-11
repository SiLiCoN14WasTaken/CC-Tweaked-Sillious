local lines = {}
local file = fs.open("myfile.txt", "r")

if file then
    local line = file.readLine()
    while line do
        local key, value = line:match("^(%S+)%s*=%s*(%S+)$")
        if key and value then
            lines[key] = tonumber(value)
        end
        line = file.readLine()
    end
    file.close()
else
    print("Failed to open file")
end

print(lines.Red)    -- 1
print(lines.Blue)   -- 1
print(lines.Green)  -- 1
