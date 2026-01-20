require "import"
import "android.widget.*"
import "android.view.*"
import "android.app.*"
import "android.os.*"
import "java.io.*"
import "android.text.*"
import "android.content.*"
import "android.net.Uri"
import "android.graphics.Typeface"
import "com.androlua.*"
local GITHUB_USER = "mn7717306-lgtm"
local GITHUB_REPO = "CODE-REFINER-PRO"
local GITHUB_BRANCH = "main"
local CURRENT_VERSION = "1.0.1"
local PLUGIN_PATH = "/storage/emulated/0/解说/Plugins/Code Refiner Pro/main.lua"
local VERSION_URL = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..GITHUB_BRANCH.."/version.txt"
local CODE_URL = "https://raw.githubusercontent.com/"..GITHUB_USER.."/"..GITHUB_REPO.."/"..GITHUB_BRANCH.."/main.lua"
local context = this 
local savePath = Environment.getExternalStorageDirectory().toString() .. "/CodeStudio_Notes/"
if not File(savePath).exists() then File(savePath).mkdirs() end
local function checkAndUpdate()
 Thread(Runnable{
 run = function()
 pcall(function()
 local url = java.net.URL(VERSION_URL)
 local conn = url.openConnection()
 conn.setConnectTimeout(3000)
 conn.setReadTimeout(3000)
 local input = conn.getInputStream()
 local reader = BufferedReader(InputStreamReader(input))
 local newVersion = reader.readLine()
 reader.close()
 if newVersion and newVersion ~= CURRENT_VERSION then
 local codeUrl = java.net.URL(CODE_URL)
 local codeConn = codeUrl.openConnection()
 codeConn.setConnectTimeout(5000)
 codeConn.setReadTimeout(5000)
 local codeInput = codeConn.getInputStream()
 
 local codeReader = BufferedReader(InputStreamReader(codeInput))
 local newCode = ""
 local line = codeReader.readLine()
 while line do
 newCode = newCode .. line .. "\n"
 line = codeReader.readLine()
 end
 codeReader.close()
 
 local currentFile = File(PLUGIN_PATH)
 local backupPath = PLUGIN_PATH .. ".backup"
 
 if currentFile.exists() then
 local currentContent = ""
 local f = io.open(currentFile.getPath(), "r")
 if f then
 currentContent = f:read("*a")
 f:close()
 end
 
 local bf = io.open(backupPath, "w")
 if bf then
 bf:write(currentContent)
 bf:close()
 end
 end
 
 local newFile = io.open(PLUGIN_PATH, "w")
 if newFile then
 newFile:write(newCode)
 newFile:close()
 
 local handler = Handler(Looper.getMainLooper())
 handler.post(Runnable{
 run = function()
 if mainDlg then
 mainDlg.hide()
 end
 Toast.makeText(context, "Update complete. Please restart plugin.", Toast.LENGTH_LONG).show()
 end
 })
 end
 end
 end)
 end
 }).start()
end
checkAndUpdate()
pcall(function()
 local builder = StrictMode.VmPolicy.Builder()
 StrictMode.setVmPolicy(builder.build())
end)
function notify(msg)
 Toast.makeText(context, tostring(msg), Toast.LENGTH_SHORT).show()
end
local mainLayout = LinearLayout(context)
mainLayout.setOrientation(1)
mainLayout.setBackgroundColor(0xFF121212)
local topBar = LinearLayout(context)
topBar.setPadding(25, 25, 25, 25)
topBar.setBackgroundColor(0xFF1F1F1F)
local header = TextView(context)
header.setText("CODE REFINER PRO v"..CURRENT_VERSION)
header.setTextColor(0xFF00FF00)
header.setTextSize(18)
header.setTypeface(Typeface.DEFAULT_BOLD)
topBar.addView(header)
mainLayout.addView(topBar)
local scroller = ScrollView(context)
local scrollParams = LinearLayout.LayoutParams(-1, 0, 1.0)
scroller.setLayoutParams(scrollParams)
local editor = EditText(context)
editor.setHint("Paste code here...")
editor.setHintTextColor(0xFF666666)
editor.setTextColor(0xFFFFFFFF)
editor.setGravity(48)
editor.setBackgroundColor(0xFF1E1E1E)
editor.setPadding(35, 35, 35, 35)
pcall(function()
 local lenF = luajava.bindClass("android.text.InputFilter$LengthFilter")(5000000)
 local fArr = luajava.newArray("android.text.InputFilter", {lenF})
 editor.setFilters(fArr)
end)
scroller.addView(editor)
mainLayout.addView(scroller)
local statusBar = LinearLayout(context)
statusBar.setPadding(25, 12, 25, 12)
statusBar.setBackgroundColor(0xFF252525)
local statusTxt = TextView(context)
statusTxt.setText("Characters: 0 | Words: 0 | Lines: 0")
statusTxt.setTextColor(0xFF00FF00)
statusTxt.setTextSize(14)
statusBar.addView(statusTxt)
mainLayout.addView(statusBar)
local function updateStatus()
 local txt = tostring(editor.getText())
 local chars = #txt
 local words = 0
 for _ in txt:gmatch("%S+") do words = words + 1 end
 local lines = 1
 for _ in txt:gmatch("\n") do lines = lines + 1 end
 statusTxt.setText("Characters: "..chars.." | Words: "..words.." | Lines: "..lines)
end
editor.addTextChangedListener(TextWatcher{
 onTextChanged=function(s, start, before, count)
 updateStatus()
 if count > 100 then
 local txt = tostring(s)
 local ac = txt:gsub("\n+", "\n"):gsub("[ \t]+", " "):gsub("^%s+", ""):gsub("%s+$", "")
 if txt ~= ac then
 editor.setText(tostring(ac))
 notify("Auto Cleaned")
 end
 end
 end
})
function formatAndCopy()
 local input = tostring(editor.getText())
 if input == "" then notify("Editor is empty") return end
 local formatted = {}
 for s in input:gmatch("[^\r\n]*") do
 if s:find("function%s+") or s:find("public%s+") or s:find("local%s+function") then
 table.insert(formatted, "\n\n" .. s)
 else
 table.insert(formatted, s)
 end
 end
 context.getSystemService(Context.CLIPBOARD_SERVICE).setText(tostring(table.concat(formatted, "\n")))
 notify("Formatted and Copied!")
end
function advanceSplitter()
 local input = tostring(editor.getText())
 if input == "" then notify("No text to split") return end
 local editNum = EditText(context)
 editNum.setHint("How many parts?")
 editNum.setInputType(2)
 local sDlg = LuaDialog(context)
 sDlg.setTitle("Split Text")
 sDlg.setView(editNum)
 sDlg.setPositiveButton("Split", function()
 local numParts = tonumber(tostring(editNum.getText()))
 if not numParts or numParts < 1 then notify("Invalid number") return end
 local partSize = math.ceil(#input / numParts)
 local parts = {}
 for i=1, numParts do
 table.insert(parts, input:sub((i-1)*partSize+1, math.min(i*partSize, #input)))
 end
 local function showPart(idx)
 if idx < 1 or idx > #parts then return end
 local lay = LinearLayout(context) lay.setOrientation(1)
 local txtShow = EditText(context) txtShow.setText(tostring(parts[idx]))
 txtShow.setLayoutParams(LinearLayout.LayoutParams(-1, 0, 1.0))
 lay.addView(txtShow)
 local btnLay = LinearLayout(context) btnLay.setOrientation(0)
 local function makeBtn(lbl, fn)
 local b = Button(context) b.setText(lbl) b.setTextSize(9)
 local lp = LinearLayout.LayoutParams(0, -2, 1.0)
 b.setLayoutParams(lp) b.setOnClickListener(fn)
 return b
 end
 local pDlg = LuaDialog(context) pDlg.setView(lay)
 if idx > 1 then btnLay.addView(makeBtn("Previous", function() pDlg.hide() showPart(idx-1) end)) end
 btnLay.addView(makeBtn("Copy", function() context.getSystemService(Context.CLIPBOARD_SERVICE).setText(tostring(parts[idx])) notify("Copied") end))
 if idx < #parts then btnLay.addView(makeBtn("Next", function() pDlg.hide() showPart(idx+1) end)) end
 btnLay.addView(makeBtn("Cancel", function() pDlg.hide() end))
 lay.addView(btnLay) pDlg.setTitle("Part "..idx.." of "..#parts) pDlg.show()
 end
 showPart(1)
 end)
 sDlg.setNegativeButton("Cancel", nil)
 sDlg.show()
end
function cleanCode()
 local t = tostring(editor.getText())
 if t == "" then notify("Editor is empty") return end
 editor.setText(tostring(t:gsub("\n+", "\n"):gsub("[ \t]+", " ")))
 notify("Cleaned")
end
function removeComments()
 local input = tostring(editor.getText())
 if input == "" then notify("Editor is empty") return end
 local text = input:gsub("/%*.-%*/", ""):gsub("%-%-%[%[.-%]%]", "")
 local lines = {}
 for line in text:gmatch("[^\r\n]*") do
 if not (line:match("^%s*%-%-") or line:match("^%s*//")) then table.insert(lines, line) end
 end
 editor.setText(tostring(table.concat(lines, "\n")))
 notify("Comments Removed")
end
function extractFunctions(text)
 local functions = {}
 for func in text:gmatch("function%s+([^\n%(]+)") do
 table.insert(functions, "Function: "..func)
 end
 for func in text:gmatch("local%s+function%s+([^\n%(]+)") do
 table.insert(functions, "Local Function: "..func)
 end
 for func in text:gmatch("def%s+([^\n%(]+)") do
 table.insert(functions, "Python Function: "..func)
 end
 return functions
end
function findErrorLocation(errorMsg, code)
 if not errorMsg or errorMsg == "" then return "No error message" end
 if not code or code == "" then return "No code provided" end
 
 local lines = {}
 for line in code:gmatch("[^\r\n]*") do
 table.insert(lines, line)
 end
 
 for i, line in ipairs(lines) do
 if line:find("function") then
 local funcName = line:match("function%s+([^%(%s]+)")
 if funcName and errorMsg:find(funcName) then
 return "Function at line "..i..": "..line
 end
 end
 end
 
 for i=1, #lines do
 if errorMsg:find("line%s+"..i) or errorMsg:find(":%s*"..i.."%s*:") or errorMsg:find("Line%s+"..i) then
 return "Error at line "..i..": "..(lines[i] or "empty")
 end
 end
 
 return "Error location not found"
end
function textReader()
 local mainInput = tostring(editor.getText())
 if mainInput == "" then notify("Nothing to read") return end
 
 local readerLayout = LinearLayout(context)
 readerLayout.setOrientation(1)
 readerLayout.setBackgroundColor(0xFF121212)
 
 local viewContainer = FrameLayout(context)
 viewContainer.setLayoutParams(LinearLayout.LayoutParams(-1, 0, 1.0))
 
 local list = ListView(context)
 local grid = GridView(context)
 grid.setNumColumns(3)
 grid.setGravity(Gravity.CENTER)
 
 viewContainer.addView(list)
 viewContainer.addView(grid)
 readerLayout.addView(viewContainer)
 
 local currentItems = {}
 local currentMode = "Lines"
 local isMultiSelect = false
 local selectedIndices = {}
 
 local function getAdapter(items)
 if not isMultiSelect then
 return ArrayAdapter(context, android.R.layout.simple_list_item_1, items)
 else
 return ArrayAdapter(context, android.R.layout.simple_list_item_multiple_choice, items)
 end
 end
 
 local function updateView(items, mode)
 currentItems = items
 currentMode = mode
 local adapter = getAdapter(items)
 if mode == "Words" or mode == "Characters" then
 list.setVisibility(View.GONE) grid.setVisibility(View.VISIBLE)
 grid.setAdapter(adapter)
 else
 grid.setVisibility(View.GONE) list.setVisibility(View.VISIBLE)
 list.setAdapter(adapter)
 if isMultiSelect then 
 list.setChoiceMode(ListView.CHOICE_MODE_MULTIPLE)
 end
 end
 end
 
 local function setupMode(mode)
 if mode == "Lines" then
 local l = {} for s in mainInput:gmatch("[^\r\n]*") do table.insert(l, s) end
 updateView(l, "Lines")
 elseif mode == "Words" then
 local w = {} for s in mainInput:gmatch("%S+") do table.insert(w, s) end
 updateView(w, "Words")
 elseif mode == "Characters" then
 local c = {} for i=1, #mainInput do table.insert(c, mainInput:sub(i,i)) end
 updateView(c, "Characters")
 elseif mode == "Paragraphs" then
 local paragraphs = {}
 local currentPara = ""
 for line in mainInput:gmatch("[^\r\n]*\n?") do
 if line == "" or line == "\n" then
 if currentPara ~= "" then
 table.insert(paragraphs, currentPara)
 currentPara = ""
 end
 else
 if currentPara == "" then
 currentPara = line:gsub("\n$", "")
 else
 currentPara = currentPara .. "\n" .. line:gsub("\n$", "")
 end
 end
 end
 if currentPara ~= "" then
 table.insert(paragraphs, currentPara)
 end
 updateView(paragraphs, "Paragraphs")
 elseif mode == "Functions" then
 local functions = extractFunctions(mainInput)
 if #functions == 0 then
 updateView({"No functions found"}, "Functions")
 else
 updateView(functions, "Functions")
 end
 end
 end
 
 setupMode("Lines")
 
 local bottomNav = LinearLayout(context)
 bottomNav.setOrientation(1)
 
 local modeBtnRow = LinearLayout(context)
 modeBtnRow.setOrientation(0)
 
 local function createModeButton(text, mode)
 local btn = Button(context)
 btn.setText(text)
 btn.setTextSize(10)
 local lp = LinearLayout.LayoutParams(0, -2, 1.0)
 lp.setMargins(2,2,2,2)
 btn.setLayoutParams(lp)
 btn.setOnClickListener(function()
 setupMode(mode)
 end)
 return btn
 end
 
 modeBtnRow.addView(createModeButton("Lines", "Lines"))
 modeBtnRow.addView(createModeButton("Words", "Words"))
 modeBtnRow.addView(createModeButton("Chars", "Characters"))
 modeBtnRow.addView(createModeButton("Paragraphs", "Paragraphs"))
 modeBtnRow.addView(createModeButton("Functions", "Functions"))
 
 local optionBtnRow = LinearLayout(context)
 optionBtnRow.setOrientation(0)
 
 local function createOptionButton(text, action)
 local btn = Button(context)
 btn.setText(text)
 btn.setTextSize(9)
 local lp = LinearLayout.LayoutParams(0, -2, 1.0)
 lp.setMargins(2,2,2,2)
 btn.setLayoutParams(lp)
 btn.setOnClickListener(action)
 return btn
 end
 
 optionBtnRow.addView(createOptionButton("Multi Select", function()
 isMultiSelect = not isMultiSelect
 selectedIndices = {}
 if isMultiSelect then
 list.setChoiceMode(ListView.CHOICE_MODE_MULTIPLE)
 notify("Multi selection enabled")
 else
 list.setChoiceMode(ListView.CHOICE_MODE_NONE)
 notify("Multi selection disabled")
 end
 updateView(currentItems, currentMode)
 end))
 
 optionBtnRow.addView(createOptionButton("Jump To", function()
 local jumpDlg = LuaDialog(context)
 jumpDlg.setTitle("Jump To Position")
 
 local jumpLayout = LinearLayout(context)
 jumpLayout.setOrientation(1)
 
 local topBtn = Button(context)
 topBtn.setText("Go to Top")
 topBtn.setOnClickListener(function()
 list.setSelection(0)
 jumpDlg.hide()
 end)
 
 local endBtn = Button(context)
 endBtn.setText("Go to End")
 endBtn.setOnClickListener(function()
 list.setSelection(#currentItems-1)
 jumpDlg.hide()
 end)
 
 local lineEdit = EditText(context)
 lineEdit.setHint("Line number")
 lineEdit.setInputType(2)
 
 local goBtn = Button(context)
 goBtn.setText("Go to Line")
 goBtn.setOnClickListener(function()
 local num = tonumber(tostring(lineEdit.getText()))
 if num and num >= 1 and num <= #currentItems then
 list.setSelection(num-1)
 jumpDlg.hide()
 else
 notify("Invalid line number")
 end
 end)
 
 jumpLayout.addView(topBtn)
 jumpLayout.addView(endBtn)
 jumpLayout.addView(lineEdit)
 jumpLayout.addView(goBtn)
 
 jumpDlg.setView(jumpLayout)
 jumpDlg.setNegativeButton("Cancel", nil)
 jumpDlg.show()
 end))
 
 optionBtnRow.addView(createOptionButton("Search", function()
 local searchDlg = LuaDialog(context)
 searchDlg.setTitle("Search in Items")
 
 local searchLayout = LinearLayout(context)
 searchLayout.setOrientation(1)
 
 local searchEdit = EditText(context)
 searchEdit.setHint("Search text")
 
 local resultList = ListView(context)
 
 local searchBtn = Button(context)
 searchBtn.setText("Search")
 searchBtn.setOnClickListener(function()
 local query = tostring(searchEdit.getText()):lower()
 if query == "" then return end
 
 local results = {}
 for i, item in ipairs(currentItems) do
 if tostring(item):lower():find(query) then
 table.insert(results, "Item "..i..": "..tostring(item))
 end
 end
 
 if #results == 0 then
 resultList.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, {"No results"}))
 else
 resultList.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, results))
 
 resultList.onItemClick = function(parent, view, position, id)
 local selected = results[position+1]
 if selected then
 local itemNum = selected:match("Item%s+(%d+)")
 if itemNum then
 list.setSelection(tonumber(itemNum)-1)
 searchDlg.hide()
 end
 end
 end
 end
 end)
 
 searchLayout.addView(searchEdit)
 searchLayout.addView(searchBtn)
 searchLayout.addView(resultList)
 
 searchDlg.setView(searchLayout)
 searchDlg.setNegativeButton("Cancel", nil)
 searchDlg.show()
 end))
 
 optionBtnRow.addView(createOptionButton("Copy All", function()
 context.getSystemService(Context.CLIPBOARD_SERVICE).setText(mainInput)
 notify("Copied all text")
 end))
 
 optionBtnRow.addView(createOptionButton("Delete Selected", function()
 if not isMultiSelect then
 notify("Enable multi selection first")
 return
 end
 
 local sparse = list.getCheckedItemPositions()
 if sparse == nil or sparse.size() == 0 then
 notify("No items selected")
 return
 end
 
 local toDelete = {}
 for i=0, #currentItems-1 do
 if sparse.get(i) then
 table.insert(toDelete, i+1)
 end
 end
 
 if #toDelete == 0 then
 notify("No items selected")
 return
 end
 
 table.sort(toDelete, function(a,b) return a>b end)
 
 for _, idx in ipairs(toDelete) do
 table.remove(currentItems, idx)
 end
 
 if currentMode == "Lines" then
 local newText = table.concat(currentItems, "\n")
 editor.setText(newText)
 mainInput = newText
 end
 
 isMultiSelect = false
 list.setChoiceMode(ListView.CHOICE_MODE_NONE)
 updateView(currentItems, currentMode)
 notify(#toDelete.." items deleted")
 end))
 
 readerLayout.addView(modeBtnRow)
 readerLayout.addView(optionBtnRow)
 
 local readerDlg = LuaDialog(context)
 readerDlg.setTitle("Advanced Text Reader")
 readerDlg.setView(readerLayout)
 readerDlg.setNegativeButton("Close", nil)
 readerDlg.show()
 
 local function handleItemClick(i)
 local idx = i + 1
 if idx > 0 and idx <= #currentItems then
 if isMultiSelect then
 return
 end
 
 local editDlg = LuaDialog(context)
 editDlg.setTitle("Edit Item")
 
 local editLayout = LinearLayout(context)
 editLayout.setOrientation(1)
 
 local editBox = EditText(context)
 editBox.setText(tostring(currentItems[idx]))
 editBox.setLayoutParams(LinearLayout.LayoutParams(-1, 0, 1.0))
 
 local btnRow = LinearLayout(context)
 btnRow.setOrientation(0)
 
 local function addActionBtn(text, action)
 local btn = Button(context)
 btn.setText(text)
 btn.setTextSize(9)
 local lp = LinearLayout.LayoutParams(0, -2, 1.0)
 btn.setLayoutParams(lp)
 btn.setOnClickListener(action)
 btnRow.addView(btn)
 end
 
 addActionBtn("Update", function()
 currentItems[idx] = tostring(editBox.getText())
 if currentMode == "Lines" then
 local newText = table.concat(currentItems, "\n")
 editor.setText(newText)
 mainInput = newText
 end
 updateView(currentItems, currentMode)
 editDlg.hide()
 notify("Item updated")
 end)
 
 addActionBtn("Copy", function()
 context.getSystemService(Context.CLIPBOARD_SERVICE).setText(tostring(editBox.getText()))
 notify("Copied")
 end)
 
 addActionBtn("Delete", function()
 table.remove(currentItems, idx)
 if currentMode == "Lines" then
 local newText = table.concat(currentItems, "\n")
 editor.setText(newText)
 mainInput = newText
 end
 updateView(currentItems, currentMode)
 editDlg.hide()
 notify("Item deleted")
 end)
 
 addActionBtn("Cancel", function()
 editDlg.hide()
 end)
 
 editLayout.addView(editBox)
 editLayout.addView(btnRow)
 editDlg.setView(editLayout)
 editDlg.show()
 end
 end
 
 local function handleItemLongClick(i)
 local idx = i + 1
 if idx > 0 and idx <= #currentItems then
 local optionsDlg = LuaDialog(context)
 optionsDlg.setTitle("Options for Item "..idx)
 
 local layout = LinearLayout(context)
 layout.setOrientation(1)
 
 local function addOptionBtn(text, action)
 local btn = Button(context)
 btn.setText(text)
 btn.setOnClickListener(function()
 optionsDlg.hide()
 action()
 end)
 layout.addView(btn)
 end
 
 addOptionBtn("Edit in Text Box", function()
 local editDlg = LuaDialog(context)
 editDlg.setTitle("Edit Item")
 local editBox = EditText(context)
 editBox.setText(tostring(currentItems[idx]))
 editDlg.setView(editBox)
 editDlg.setPositiveButton("Update", function()
 currentItems[idx] = tostring(editBox.getText())
 if currentMode == "Lines" then
 local newText = table.concat(currentItems, "\n")
 editor.setText(newText)
 mainInput = newText
 end
 updateView(currentItems, currentMode)
 notify("Item updated")
 end)
 editDlg.setNegativeButton("Cancel", nil)
 editDlg.show()
 end)
 
 addOptionBtn("Copy Item", function()
 context.getSystemService(Context.CLIPBOARD_SERVICE).setText(tostring(currentItems[idx]))
 notify("Copied")
 end)
 
 addOptionBtn("Delete Item", function()
 table.remove(currentItems, idx)
 if currentMode == "Lines" then
 local newText = table.concat(currentItems, "\n")
 editor.setText(newText)
 mainInput = newText
 end
 updateView(currentItems, currentMode)
 notify("Item deleted")
 end)
 
 addOptionBtn("Cancel", function()
 optionsDlg.hide()
 end)
 
 optionsDlg.setView(layout)
 optionsDlg.show()
 return true
 end
 return false
 end
 
 list.onItemClick = function(a,v,i,j) handleItemClick(i) end
 list.onItemLongClick = function(a,v,i,j) return handleItemLongClick(i) end
 
 grid.onItemClick = function(a,v,i,j) handleItemClick(i) end
 grid.onItemLongClick = function(a,v,i,j) return handleItemLongClick(i) end
end
function manageFiles()
 local folder = File(savePath)
 local fileList = folder.listFiles()
 if not fileList or #fileList == 0 then notify("No files found") return end
 local names, paths = {}, {}
 for i=0, #fileList-1 do
 table.insert(names, tostring(fileList[i].getName()))
 table.insert(paths, tostring(fileList[i].getAbsolutePath()))
 end
 local listV = ListView(context)
 listV.setAdapter(ArrayAdapter(context, android.R.layout.simple_list_item_1, names))
 local fDl = LuaDialog(context)
 fDl.setTitle("Saved Files")
 fDl.setView(listV)
 fDl.setNegativeButton("Cancel", nil)
 fDl.show()
 listV.onItemClick = function(a, v, i, j)
 local f = io.open(paths[i+1], "r")
 if f then editor.setText(tostring(f:read("*a"))) f:close() notify("Loaded") end
 fDl.hide()
 end
 listV.onItemLongClick = function(a, v, i, j)
 local path = paths[i+1]
 local fileObj = File(path)
 
 local opsDlg = LuaDialog(context)
 opsDlg.setTitle("File Options")
 
 local layout = LinearLayout(context)
 layout.setOrientation(1)
 
 local function addFileOption(text, action)
 local btn = Button(context)
 btn.setText(text)
 btn.setOnClickListener(function()
 opsDlg.hide()
 action()
 end)
 layout.addView(btn)
 end
 
 addFileOption("Rename", function()
 local inp = EditText(context) 
 inp.setText(tostring(fileObj.getName()))
 local renameDlg = LuaDialog(context)
 renameDlg.setTitle("Rename File")
 renameDlg.setView(inp)
 renameDlg.setPositiveButton("OK", function()
 local newName = tostring(inp.getText())
 if newName ~= "" then
 if not newName:match("%.txt$") then newName = newName..".txt" end
 local newFile = File(savePath, newName)
 if fileObj.renameTo(newFile) then
 fDl.hide()
 notify("File renamed")
 else
 notify("Rename failed")
 end
 end
 end)
 renameDlg.setNegativeButton("Cancel", nil)
 renameDlg.show()
 end)
 
 addFileOption("Delete", function()
 if fileObj.delete() then
 fDl.hide() 
 notify("File deleted")
 else
 notify("Delete failed")
 end
 end)
 
 addFileOption("Share as TX File", function()
 local content = ""
 local f = io.open(path, "r")
 if f then content = f:read("*a") f:close() end
 
 local cacheDir = context.getCacheDir()
 local tempFile = File(cacheDir, fileObj.getName())
 local tempOut = io.open(tempFile.getPath(), "w")
 if tempOut then
 tempOut:write(content)
 tempOut:close()
 
 local uri = Uri.fromFile(tempFile)
 local shareIntent = Intent(Intent.ACTION_SEND)
 shareIntent.setType("text/plain")
 shareIntent.putExtra(Intent.EXTRA_STREAM, uri)
 shareIntent.putExtra(Intent.EXTRA_SUBJECT, "Code File: "..fileObj.getName())
 shareIntent.addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
 
 context.startActivity(Intent.createChooser(shareIntent, "Share File"))
 else
 notify("Failed to create share file")
 end
 end)
 
 addFileOption("Copy Content", function()
 local content = ""
 local f = io.open(path, "r")
 if f then content = f:read("*a") f:close() end
 context.getSystemService(Context.CLIPBOARD_SERVICE).setText(content)
 notify("File content copied")
 end)
 
 addFileOption("Cancel", function()
 opsDlg.hide()
 end)
 
 opsDlg.setView(layout)
 opsDlg.show()
 return true
 end
end
local btnArea = LinearLayout(context)
btnArea.setOrientation(1)
local r1 = LinearLayout(context)
r1.setOrientation(0)
local r2 = LinearLayout(context)
r2.setOrientation(0)
local r3 = LinearLayout(context)
r3.setOrientation(0)
function addB(row, lbl, clr, fn)
 local b = Button(context)
 b.setText(tostring(lbl))
 b.setTextSize(10)
 b.setTextColor(0xFFFFFFFF)
 b.setBackgroundColor(clr)
 local lp = LinearLayout.LayoutParams(0, -2, 1.0)
 lp.setMargins(4, 4, 4, 4)
 b.setLayoutParams(lp)
 b.setOnClickListener(fn)
 row.addView(b)
end
addB(r1, "CLEAN", 0xFF2E7D32, function() cleanCode() end)
addB(r1, "NO COMMENTS", 0xFFC62828, function() removeComments() end)
addB(r1, "FORMAT", 0xFF00897B, function() formatAndCopy() end)
addB(r1, "SAVE", 0xFF1565C0, function()
 local txt = tostring(editor.getText())
 if txt == "" then notify("Editor empty") return end
 local inp = EditText(context)
 local saveDlg = LuaDialog(context)
 saveDlg.setTitle("Save File")
 saveDlg.setView(inp)
 saveDlg.setPositiveButton("Save", function()
 local n = tostring(inp.getText())
 if n == "" then n = "Code_"..os.time() end
 if not n:match("%.txt$") then n = n..".txt" end
 local fos = FileOutputStream(File(savePath..n))
 fos.write(String(txt).getBytes())
 fos.close() 
 notify("Saved: "..n)
 end)
 saveDlg.setNegativeButton("Cancel", nil)
 saveDlg.show()
end)
addB(r2, "FILES", 0xFFEF6C00, function() manageFiles() end)
addB(r2, "GO TO LINE", 0xFF6A1B9A, function()
 local inp = EditText(context) 
 inp.setInputType(2)
 inp.setHint("Line number")
 local gotoDlg = LuaDialog(context)
 gotoDlg.setTitle("Go to Line")
 gotoDlg.setView(inp)
 gotoDlg.setPositiveButton("Go", function()
 local n = tonumber(tostring(inp.getText()))
 local text = tostring(editor.getText())
 local lines = {}
 for s in text:gmatch("[^\r\n]*") do table.insert(lines, s) end
 if n and n >= 1 and n <= #lines then
 local position = 0
 for i=1, n-1 do
 position = position + #lines[i] + 1
 end
 editor.setSelection(position)
 notify("Jumped to line "..n)
 else
 notify("Line not found")
 end
 end)
 gotoDlg.setNegativeButton("Cancel", nil)
 gotoDlg.show()
end)
addB(r2, "TEXT READER", 0xFF009688, function() textReader() end)
addB(r3, "SPLIT TEXT", 0xFFE91E63, function() advanceSplitter() end)
addB(r3, "REPLACE ALL", 0xFF5E35B1, function()
 local ly = LinearLayout(context) 
 ly.setOrientation(1)
 local f = EditText(context) 
 f.setHint("Find text")
 local r = EditText(context) 
 r.setHint("Replace with")
 ly.addView(f) 
 ly.addView(r)
 local replaceDlg = LuaDialog(context)
 replaceDlg.setTitle("Replace Text")
 replaceDlg.setView(ly)
 replaceDlg.setPositiveButton("Replace All", function()
 local findText = tostring(f.getText())
 if findText == "" then return end
 local replaceText = tostring(r.getText())
 local ok, res = pcall(function() 
 return tostring(editor.getText()):gsub(findText, replaceText) 
 end)
 if ok then 
 editor.setText(res) 
 notify("Replaced") 
 else
 notify("Replace failed")
 end
 end)
 replaceDlg.setNegativeButton("Cancel", nil)
 replaceDlg.show()
end)
addB(r3, "COPY ALL", 0xFF757575, function()
 context.getSystemService(Context.CLIPBOARD_SERVICE).setText(tostring(editor.getText()))
 notify("All text copied")
end)
btnArea.addView(r1)
btnArea.addView(r2)
btnArea.addView(r3)
mainLayout.addView(btnArea)
local exit = Button(context)
exit.setText("EXIT STUDIO")
exit.setBackgroundColor(0xFFB71C1C)
exit.setTextColor(0xFFFFFFFF)
exit.setOnClickListener(function() mainDlg.hide() end)
mainLayout.addView(exit)
mainDlg = LuaDialog(context)
mainDlg.setView(mainLayout)
mainDlg.show()
notify("Code Refiner Pro v"..CURRENT_VERSION.." - Ready!")
updateStatus()