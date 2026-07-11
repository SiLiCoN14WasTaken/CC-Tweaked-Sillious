-- CONFIG
local url = "https://raw.githubusercontent.com/yourusername/yourrepo/main/script.txt"
local filename = "script.txt"
local pageWidth = 25   -- characters per line on a printed page
local linesPerPage = 21 -- lines per page, leaving margin room
local pageDelay = 5     -- seconds to wait between pages so you can remove them

-- Download the latest version
print("Downloading latest file...")
local response = http.get(url)
if not response then
    print("Failed to download file")
    return
end

local file = fs.open(filename, "w")
file.write(response.readAll())
file.close()
response.close()
print("Download complete.")

-- Find the printer peripheral
local printer = peripheral.find("printer")
if not printer then
    print("No printer found! Make sure one is connected.")
    return
end

-- Read the downloaded file into raw lines
local rawLines = {}
local readFile = fs.open(filename, "r")
if readFile then
    local line = readFile.readLine()
    while line do
        table.insert(rawLines, line)
        line = readFile.readLine()
    end
    readFile.close()
else
    print("Failed to open downloaded file")
    return
end

-- Word-wrap each raw line to fit the page width
local function wrapLine(text, width)
    local wrapped = {}
    if text == "" then
        table.insert(wrapped, "")
        return wrapped
    end
    local currentLine = ""
    for word in text:gmatch("%S+") do
        if #currentLine == 0 then
            currentLine = word
        elseif #currentLine + 1 + #word <= width then
            currentLine = currentLine .. " " .. word
        else
            table.insert(wrapped, currentLine)
            currentLine = word
        end
    end
    if #currentLine > 0 then
        table.insert(wrapped, currentLine)
    end
    return wrapped
end

local wrappedLines = {}
for _, rawLine in ipairs(rawLines) do
    local pieces = wrapLine(rawLine, pageWidth)
    for _, piece in ipairs(pieces) do
        table.insert(wrappedLines, piece)
    end
end

print("Total printed lines after wrapping: " .. #wrappedLines)
print("Estimated pages needed: " .. math.ceil(#wrappedLines / linesPerPage))

-- Print using the printer peripheral, with page numbers and delay
local lineIndex = 1
local pageNumber = 1

while lineIndex <= #wrappedLines do
    if not printer.newPage() then
        print("Failed to start new page (out of paper/ink?)")
        break
    end

    -- reserve line 1 for the page number, content starts on line 2
    printer.setCursorPos(1, 1)
    printer.write("Page " .. pageNumber)

    local row = 2
    for i = 1, (linesPerPage - 1) do
        if lineIndex > #wrappedLines then break end
        printer.setCursorPos(1, row)
        printer.write(wrappedLines[lineIndex])
        lineIndex = lineIndex + 1
        row = row + 1
    end

    if not printer.endPage() then
        print("Failed to end page (paper jam / out of ink?)")
        break
    end

    print("Printed page " .. pageNumber .. ". Waiting " .. pageDelay .. "s before continuing...")
    pageNumber = pageNumber + 1

    if lineIndex <= #wrappedLines then
        os.sleep(pageDelay)
    end
end

print("Printing complete. Total pages: " .. (pageNumber - 1))
