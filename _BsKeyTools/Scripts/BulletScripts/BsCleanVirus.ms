/*
 * @Description: 杀毒工具
 * @Author: Bullet.S
 * @Date: 2022-02-13 15:37:02
 * @LastEditors: Bullet.S
 * @LastEditTime: 2026-02-09 18:30:48
 * @Email: animator.bullet@foxmail.com
 */
global curVerBsCleanVirus = "2.4.1"
global rolBsCleanVirus
global rolBsVirusScanLog
global rolBatchCleanVirus
global iniStartupBsCleanVirus = 0
global iniVerboseLevel = 1
global batchStopFlag = false
try(destroyDialog rolBsCleanVirus)catch()
try(destroyDialog rolBsVirusScanLog) catch()
try(destroyDialog rolBatchCleanVirus) catch()

Global BulletConfig = execute ("@\"" + (getDir #maxData) + "\\BulletConfig.ini\"")  --配置文件路径

try(FileIn ((getDir #scripts) + "\\BulletScripts\\fnSaveLoadConfig.ms"))
catch(messagebox "打开失败，工具可能安装不完全，\r\n\r\n建议查看设置中的帮助或重新安装...                            " beep:false)
try(FileIn ((getDir #scripts) + "\\BulletScripts\\fnGetColorTheme.ms"))
catch(messagebox "打开失败，工具可能安装不完全，\r\n\r\n建议查看设置中的帮助或重新安装...                            " beep:false)
stLoadConfigAll.fnLoadConfigBsCleanVirus ()

rollout rolBsVirusScanLog "病毒扫描日志  【杀毒不会破坏源文件，请注意杀毒后保存/另存文件！】" (
	dotNetControl lbxLog "system.windows.forms.listView" height: 400 width: 850 offset: [-13, -5]
	
	button btnClearAllLog "清除所有日志" align: #left height: 25 width: 100 pos: [10, -50]
	button btnExportLog "导出日志" align: #left height: 25 width: 80 pos: [115, -50]
		
	struct signature_log (
		fn getLogFile = (
			d = execute ("@\"" + (getDir #maxData) + "\\scanlog.ini\"")
			return d
		), 
		
		fn getVerboseLevel = (
			ini = getLogFile()
			v = getIniSetting ini "SETTINGS" "VERBOSELEVEL"
			if(v == "") do return 1
			return try(v as integer) catch(1)
		),
		
		fn setVerboseLevel lvl = (
			ini = getLogFile()
			setIniSetting ini "SETTINGS" "VERBOSELEVEL" (lvl as string)
		),
		
		fn getLogType type = (
			return case type of (
				#threat: "Threat"
				#warn: "Warning"
				default: "Default"
			)
		),
		
		fn getTranslatedLogType type = (
			return case type of (
				#threat: "威胁"
				#warn:  "警告"
				default:  "默认"
			)
		),
		
		fn getTime = (
			t = #()
			for i in getLocalTime() do (
				s = (i as string)
				if(s.count < 2) do s = "0" + s
				append t s
			)
			
			return t[4] + "." + t[2] + "." + t[1] + " " + t[5] + ":" + t[6] + ":" + t[7]
		),
		
		fn write msg type: #threat = (
			ini = getLogFile()
			
			s = getLogType type
			k = getTime()
			
			setIniSetting ini s k msg
		),
		
		fn get type: #threat = (
			ini = getLogFile()
			s = getLogType type
			s = getTranslatedLogType type
			
			out = #()
			
			for i in (getIniSetting ini s) do (
				tmp = #()
				tmp[1] = i
				tmp[2] = s
				tmp[3] = (getIniSetting ini s i)
				append out tmp
			)
			
			return out
		),
		
		fn getAll = (
			out = #()
			ini = getLogFile()
			
			for i in (getIniSetting ini) where i != "SETTINGS" do (
								
				for ii in (getIniSetting ini i) do (
					tmp = #()
					tmp[1] = ii
					tmp[2] = i
					tmp[3] = (getIniSetting ini i ii)

					append out tmp
				)
			)
			
			return out
		),
		
		fn clearAll = (
			out = #()
			ini = getLogFile()
			
			for i in (getIniSetting ini) where i != "SETTINGS" do (
				delIniSetting ini i
			)
		)
	)
	
	fn setBottomBarVertPos = (
		v = 36
		size = GetDialogSize rolBsVirusScanLog
		btnClearAllLog.pos.y = size.y - v
		btnExportLog.pos.y = size.y - v
	)
	
	fn getDotNetColor r g b = (DotNetClass "System.Drawing.Color").fromargb r g b 
	
	fn initDotNet =
	(	
		setBottomBarVertPos()
		
		align = dotNetClass "HorizontalAlignment"
		
		lbxLog.Clear()
		lbxLog.View = (dotNetClass "System.Windows.Forms.View").Details	
		lbxLog.FullRowSelect = true
		lbxLog.GridLines = true		
		lbxLog.ShowItemToolTips = true
		lbxLog.MultiSelect = false
		lbxLog.CheckBoxes = false
		lbxLog.HideSelection = false
		lbxLog.Columns.Add "#" 35
		lbxLog.Columns.Add ("日期") 130
		lbxLog.Columns.Add ("类型") 70 align.center
		lbxLog.Columns.Add ("信息") (850 - 35 - 130 - 70 - 5) 
					
		lbxLog.Update()
		lbxLog.Refresh()
	)
		
	fn getSelectedId =
	(
		c = lbxLog.SelectedItems.Count - 1		
		id = 0		
		for i = 0 to c do id = lbxLog.SelectedItems.Item[i].Index + 1
		return id
	)
	
	fn getSelectedItem =
	(
		item = undefined
		c = lbxLog.SelectedItems.Count - 1					
		for i = 0 to c do item = lbxLog.SelectedItems.Item[i]
		return item
	)
	
	fn setDotnetBoldFont = (
		bold = (dotnetclass "System.Drawing.FontStyle").Bold
		return dotnetobject "System.Drawing.Font" "Arial" 8 bold
	)
	
	fn addToLbxList r =
	(				
		lbxLog.Items.Clear()
		rows = #()	
		i = 1
		for x in r do	
		(
			li = dotNetObject "System.Windows.Forms.ListViewItem" ""
			li.useItemStyleForSubItems = false
			bold = (dotnetclass "System.Drawing.FontStyle").Bold
						
			li.text = (i as string) + "."
			li.subitems.add x[1]	
			
			type = case x[2] of (
				"Threat": "威胁"
				"Warning":  "警告"
				default:  "默认"
			)
			
			li.subitems.add type
					
			msg = substituteString x[3] "病毒检测并删除" "病毒已移除"
			msg = substituteString msg "病毒已检测到但没有从脚本自启文件夹移除!" "检测到但未删除"
			
			li.subitems.add msg
			li.tag = x[3]		
			
			bg = getDotNetColor 183 183 183; fg = getDotNetColor 67 67 67
			
			case x[2] of (
				"Threat": (
					bg = getDotNetColor 147 196 125
					fg = getDotNetColor 56 118 79
				)
				"Warning": (
					bg = getDotNetColor 255 229 153
					fg = getDotNetColor 215 144 0
				)
			)
			
			li.subItems.Item[2].backColor = bg
			li.subItems.Item[2].foreColor = fg
			li.subItems.Item[2].Font = setDotnetBoldFont()
						
			append rows li		
			i += 1
		)
		
		lbxLog.Items.addRange rows
	)	
	
	fn buildThreatList = (
		
		slog = signature_log()
		r = slog.getAll()
				
		addToLbxList r
	)
		
	fn clearAllLog = (
		slog = signature_log()
		slog.clearAll()
		
		buildThreatList()
	)
	
	fn exportLogToTxt filepath = (
		try (
			local slog = signature_log()
			local logs = slog.getAll()
			
			-- 尝试使用.NET File.WriteAllLines（更简单可靠）
			try (
				local fileClass = dotNetClass "System.IO.File"
				local encodingClass = dotNetClass "System.Text.Encoding"
				
				-- 构建所有行
				local lines = #()
				append lines ("病毒扫描日志 - 导出时间：" + (slog.getTime()))
				append lines "====================================="
				
				for i = 1 to logs.count do (
					local log = logs[i]
					append lines ("#" + (i as string) + "  日期：" + log[1] + "  类型：" + log[2])
					append lines ("    信息：" + log[3])
					append lines ""
				)
				
				append lines "====================================="
				append lines ("共 " + (logs.count as string) + " 条记录")
				
				-- 转换为.NET数组
				local dotNetLines = dotNetObject "System.Collections.ArrayList"
				for line in lines do dotNetLines.Add line
				
				-- 使用UTF8编码写入文件
				fileClass.WriteAllLines filepath (dotNetLines.ToArray (dotNetClass "System.String")) encodingClass.UTF8
				
				return true
			) catch (
				-- Fallback: 使用传统MaxScript方式
				local f = createFile filepath
				if f != undefined do (
					format "病毒扫描日志 - 导出时间：%\n" (slog.getTime()) to:f
					format "=====================================\n" to:f
					
					for i = 1 to logs.count do (
						local log = logs[i]
						format "#%  日期：%  类型：%\n" i log[1] log[2] to:f
						format "    信息：%\n\n" log[3] to:f
					)
					
					format "=====================================\n" to:f
					format "共 % 条记录\n" logs.count to:f
					
					close f
					return true
				)
				return false
			)
		) catch (
			return false
		)
	)
	
	fn exportLogToCsv filepath = (
		try (
			local slog = signature_log()
			local logs = slog.getAll()
			
			-- 尝试使用.NET File.WriteAllLines
			try (
				local fileClass = dotNetClass "System.IO.File"
				local encodingClass = dotNetClass "System.Text.Encoding"
				
				-- 构建所有行
				local lines = #()
				append lines "序号,日期,类型,信息"
				
				for i = 1 to logs.count do (
					local log = logs[i]
					-- 转义CSV中的逗号和引号
					local msg = substituteString log[3] "\"" "\"\""
					if (findString msg ",") != undefined then (
						msg = "\"" + msg + "\""
					)
					append lines ((i as string) + "," + log[1] + "," + log[2] + "," + msg)
				)
				
				-- 转换为.NET数组
				local dotNetLines = dotNetObject "System.Collections.ArrayList"
				for line in lines do dotNetLines.Add line
				
				-- 使用UTF8编码写入文件
				fileClass.WriteAllLines filepath (dotNetLines.ToArray (dotNetClass "System.String")) encodingClass.UTF8
				
				return true
			) catch (
				-- Fallback: 使用传统MaxScript方式
				local f = createFile filepath
				if f != undefined do (
					format "序号,日期,类型,信息\n" to:f
					
					for i = 1 to logs.count do (
						local log = logs[i]
						local msg = substituteString log[3] "\"" "\"\""
						if (findString msg ",") != undefined then (
							msg = "\"" + msg + "\""
						)
						format "%,%,%,%\n" i log[1] log[2] msg to:f
					)
					
					close f
					return true
				)
				return false
			)
		) catch (
			return false
		)
	)
	
	fn exportLog = (
		try (
			-- 检查是否有日志
			local slog = signature_log()
			local logs = slog.getAll()
			
			if logs.count == 0 do (
				messageBox "当前没有日志记录可导出！" title:"提示"
				return undefined
			)
			
			-- 确认对话框
			local result = queryBox "是否导出日志？\n\n将同时导出 TXT 和 CSV 两种格式。\n\n[是] = 导出日志\n[否] = 取消" title:"导出日志"
			
			if result == true then (
				-- 生成默认文件名（带时间戳）
				local t = getLocalTime()
				local timestamp = (t[1] as string) + (if t[2] < 10 then "0" else "") + (t[2] as string) + (if t[3] < 10 then "0" else "") + (t[3] as string) + "_" + (if t[5] < 10 then "0" else "") + (t[5] as string) + (if t[6] < 10 then "0" else "") + (t[6] as string)
				local defaultName = "病毒扫描日志_" + timestamp
				
				-- 选择保存位置（只显示txt类型，简单可靠）
				local filepath = getSaveFileName caption:"选择导出位置（将同时生成.txt和.csv两个文件）" filename:defaultName types:"文本文件 (*.txt)|*.txt"
				
				if filepath != undefined do (
					-- 分解路径，去掉扩展名
					local basePath = getFilenamePath filepath
					local baseName = getFilenameFile filepath
					
					-- 构建最终的文件路径
					local txtPath = basePath + baseName + ".txt"
					local csvPath = basePath + baseName + ".csv"
					
					-- 执行导出
					local txtSuccess = exportLogToTxt txtPath
					local csvSuccess = exportLogToCsv csvPath
					
					if txtSuccess and csvSuccess then (
						messageBox ("日志已成功导出到：\n\n" + txtPath + "\n" + csvPath) title:"导出成功"
					) else if txtSuccess then (
						messageBox ("TXT 导出成功，CSV 导出失败！\n\n" + txtPath) title:"部分成功"
					) else if csvSuccess then (
						messageBox ("CSV 导出成功，TXT 导出失败！\n\n" + csvPath) title:"部分成功"
					) else (
						messageBox "导出失败！请检查文件路径是否有效或是否有写入权限。" title:"错误"
					)
				)
			)
		) catch (
			local errMsg = "导出日志时发生错误：\n\n" + (getCurrentException())
			messageBox errMsg title:"错误"
		)
	)
	
	fn getOnlineHelp = (
		shellLaunch "http://3dground.net/manual/prune-scene#virus-active-protecton" ""
	)
	
	fn contextMenuItem m n enabled: true =
	(
		item = undefined	
		c = m.Items.Count - 1
		for i = c to 0 by - 1 where c > 0 do
		(
			ii = m.Items.Item[i].Text
			if(ii == n) do
			(
				item = m.Items.Item[i]
				item.Enabled = enabled
				exit
			)
		)
		
		return item
	)
	
	fn bindContextMenu =
	(
		id = getSelectedId()
			
		contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"
			
		if(id != 0) do (		
			lngOnlineHelp =  "在线帮助"
			dotNet.addEventHandler (contextMenu.Items.Add(lngOnlineHelp)) "Click" getOnlineHelp				
		)
					
		lbxLog.ContextMenuStrip = contextMenu
	)
	
	on lbxLog MouseUp do
	(		
		bindContextMenu()
	)
			
	on rolBsVirusScanLog open do (
		initDotNet()		
		buildThreatList()
	)
	
	on rolBsVirusScanLog resized size do (
		lbxLog.width = size.x
		lbxLog.height = size.y - 50
		
		setBottomBarVertPos()
	)
	
	on btnClearAllLog pressed do clearAllLog()
	
	on btnExportLog pressed do exportLog()
)

-- The official engine checks files during load/save; capture its counts before loading.
fn BsVirusOfficialCounts =
(
    if (getIniSetting (getMAXIniFile()) "SecurityTools" "LoadSecurityTools") == "0" do
        throw "官方场景安全防护已关闭，请先在首选项的安全页面开启。"
    local counts = try (#(SecurityTools.GetProblemFoundCount(), SecurityTools.GetProblemFixedCount())) catch(undefined)
    if counts==undefined do throw "无法读取官方查杀结果，请安装支持当前 Max 的 Scene Security Tools。"
    counts
)

fn BsVirusThreatRecords slog =
(
    for row in (slog.get type:#threat) collect (row[1] + "\t" + row[3])
)

fn BsVirusOfficialDelta before after =
(
    if after[1]<before[1] or after[2]<before[2] do
        throw "官方检测计数发生重置，本文件结果无法确认，请重新开始批量查杀。"
    #(after[1]-before[1], after[2]-before[2])
)

struct BsVirusBatchEntry (filePath, state=#pending, threatCount=0, saved=false, stamp="")
dotNet.loadAssembly "System.Xml"
struct BsVirusBatchProgress
(
    statePath, entries=#(), autoSave=false, recursive=false, activeFile="",

    fn pathKey value = (toLower ((dotNetClass "System.IO.Path").GetFullPath value)),
    fn fileStamp value =
    (
        try
        (
            local info=dotNetObject "System.IO.FileInfo" value
            if info.Exists then (info.Length as string)+":"+(info.LastWriteTimeUtc.ToString "O") else ""
        ) catch ("")
    ),
    fn isComplete entry =
    (
        entry.saved and (findItem #(#clean,#cleaned) entry.state)>0 and entry.stamp!="" and
        (fileStamp entry.filePath)==entry.stamp and
        (activeFile=="" or (pathKey activeFile)!=(pathKey entry.filePath))
    ),
    fn completedCount = (for entry in entries where entry.saved collect entry).count,

    fn readState filePath =
    (
        local settings=dotNetObject "System.Xml.XmlReaderSettings"
        settings.DtdProcessing=(dotNetClass "System.Xml.DtdProcessing").Prohibit
        local reader=(dotNetClass "System.Xml.XmlReader").Create filePath settings
        local doc=dotNetObject "System.Xml.XmlDocument"
        local failure=undefined
        try (doc.Load reader) catch (failure=getCurrentException())
        reader.Close()
        if failure!=undefined do throw failure
        local root=doc.DocumentElement
        if root.Name!="BsCleanVirusBatch" or (root.GetAttribute "format")!="1" do throw "断点记录格式不正确。"
        local rows=#()
        local storedVersion=root.GetAttribute "tool"
        local sameTool=storedVersion==curVerBsCleanVirus or (curVerBsCleanVirus=="2.4.1" and storedVersion=="2.4")
        local nodes=root.SelectNodes "File"
        if nodes.Count>0 do for nodeIndex=0 to nodes.Count-1 do
        (
            local node=nodes.Item nodeIndex
            local file=node.GetAttribute "path"
            if file=="" do throw "断点记录缺少文件路径。"
            local state=case (node.GetAttribute "state") of
            (
                "pending": #pending
                "clean": #clean
                "cleaned": #cleaned
                "unsaved": #unsaved
                "error": #error
                default: undefined
            )
            local threats=try ((node.GetAttribute "threats") as integer) catch (-1)
            if state==undefined or threats<0 do throw "断点记录包含无效的处理结果。"
            append rows (BsVirusBatchEntry filePath:((dotNetClass "System.IO.Path").GetFullPath file) state:state threatCount:threats saved:(sameTool and (node.GetAttribute "saved")=="1") stamp:(node.GetAttribute "stamp"))
        )
        #(rows, (root.GetAttribute "autoSave")=="1", (root.GetAttribute "recursive")=="1", root.GetAttribute "active")
    ),
    fn load =
    (
        local data=undefined, existed=false
        for candidate in #(statePath,statePath+".bak") do
        (
            if data==undefined and doesFileExist candidate do
            (
                existed=true
                data=try (readState candidate) catch (undefined)
            )
        )
        if data==undefined then
        (
            if existed do throw "断点记录及备份无法读取，请先清空列表再建立新任务。"
            false
        )
        else
        (
            entries=data[1]; autoSave=data[2]; recursive=data[3]; activeFile=data[4]
            for entry in entries where not (isComplete entry) do
            (
                entry.saved=false
                if (findItem #(#clean,#cleaned) entry.state)>0 do (entry.state=#pending; entry.threatCount=0)
            )
            true
        )
    ),
    fn save =
    (
        local doc=dotNetObject "System.Xml.XmlDocument"
        local root=doc.CreateElement "BsCleanVirusBatch"
        doc.AppendChild root
        root.SetAttribute "format" "1"
        root.SetAttribute "tool" curVerBsCleanVirus
        root.SetAttribute "autoSave" (if autoSave then "1" else "0")
        root.SetAttribute "recursive" (if recursive then "1" else "0")
        root.SetAttribute "active" activeFile
        for entry in entries do
        (
            local node=doc.CreateElement "File"
            node.SetAttribute "path" entry.filePath
            node.SetAttribute "state" (entry.state as string)
            node.SetAttribute "threats" (entry.threatCount as string)
            node.SetAttribute "saved" (if entry.saved then "1" else "0")
            node.SetAttribute "stamp" entry.stamp
            root.AppendChild node
        )
        (dotNetClass "System.IO.Directory").CreateDirectory (getFilenamePath statePath)
        local temp=statePath+"."+((dotNetClass "System.Guid").NewGuid()).ToString("N")+".tmp"
        local failure=undefined
        try
        (
            doc.Save temp
            if doesFileExist statePath then
                (dotNetClass "System.IO.File").Replace temp statePath (statePath+".bak")
            else
                (dotNetClass "System.IO.File").Move temp statePath
        ) catch (failure=getCurrentException())
        if failure!=undefined do
        (
            try ((dotNetClass "System.IO.File").Delete temp) catch ()
            throw ("无法保存断点，已停止继续处理：\n"+failure)
        )
        true
    ),
    fn prepare files saveFiles includeChildren =
    (
        load()
        local oldKeys=for entry in entries collect (pathKey entry.filePath)
        local rows=#(), keys=#()
        for file in files do
        (
            local key=pathKey file
            if (findItem keys key)==0 do
            (
                local index=findItem oldKeys key
                append rows (if index>0 then entries[index] else BsVirusBatchEntry filePath:((dotNetClass "System.IO.Path").GetFullPath file))
                append keys key
            )
        )
        entries=rows; autoSave=saveFiles; recursive=includeChildren; activeFile=""
        save()
        for entry in entries collect entry.filePath
    ),
    fn beginFile index =
    (
        activeFile=entries[index].filePath
        entries[index].saved=false
        entries[index].state=#pending
        entries[index].threatCount=0
        save()
    ),
    fn finishFile index result =
    (
        local entry=entries[index]
        entry.state=result[1]; entry.threatCount=result[2]
        entry.saved=autoSave and (findItem #(#clean,#cleaned) entry.state)>0
        entry.stamp=if entry.saved then fileStamp entry.filePath else ""
        if entry.saved and entry.stamp=="" do throw "无法确认已保存文件的状态，未记录为完成。"
        activeFile=""
        save()
    ),
    fn clear = (entries=#(); activeFile=""; save())
)


rollout rolBatchCleanVirus "批量查杀病毒" (
	-- 待扫描文件列表
	label lblFileList "待扫描文件列表：" pos:[10, 10]
	dotNetControl lbxFiles "system.windows.forms.listView" height: 160 width: 620 pos: [10, 30]
	
	-- 操作按钮行
	button btnAddFiles "添加文件" width: 85 height: 25 pos: [10, 200]
	button btnAddFolder "添加文件夹" width: 90 height: 25 pos: [100, 200]
	button btnClearList "清空列表" width: 80 height: 25 pos: [195, 200] toolTip:"清空文件列表和断点，从头开始；不会删除模型文件。"
	checkbox chkRecursive "扫描子文件夹" pos: [290, 203] checked: false
	checkbox chkAutoSave "查杀后立即保存" pos: [410, 203] checked: false
	
	-- 扫描进度区域
	label lblProgressTitle "扫描进度：" pos:[10, 240]
	label lblStatus "等待开始..." pos: [10, 260] width: 620
	progressBar pbProgress "" width: 620 height: 22 pos: [10, 280] color: green
	
	-- 扫描报告区域
	label lblReportTitle "扫描报告：" pos:[10, 315]
	dotNetControl lbxReport "system.windows.forms.listView" height: 130 width: 620 pos: [10, 335]
	
	-- 底部控制按钮
	button btnStart "开始 / 继续" width: 100 height: 30 pos: [10, 475] toolTip:"继续上次任务；已成功保存且未变化的文件会跳过。"
	button btnStop "停止" width: 100 height: 30 pos: [115, 475] enabled: false
	
	local fileList = #()
	local scanResults = #()
	local checkpoint = undefined
	
	fn getDotNetColor r g b = (DotNetClass "System.Drawing.Color").fromargb r g b
	
	fn initDotNet = (
		align = dotNetClass "HorizontalAlignment"
		
		-- 初始化文件列表
		lbxFiles.Clear()
		lbxFiles.View = (dotNetClass "System.Windows.Forms.View").Details	
		lbxFiles.FullRowSelect = true
		lbxFiles.GridLines = true
		lbxFiles.MultiSelect = false
		lbxFiles.CheckBoxes = false
		lbxFiles.HideSelection = false
		lbxFiles.Columns.Add "#" 40
		lbxFiles.Columns.Add "路径" 570
		
		-- 初始化报告列表
		lbxReport.Clear()
		lbxReport.View = (dotNetClass "System.Windows.Forms.View").Details	
		lbxReport.FullRowSelect = true
		lbxReport.GridLines = true
		lbxReport.MultiSelect = false
		lbxReport.CheckBoxes = false
		lbxReport.HideSelection = false
		lbxReport.Columns.Add "#" 40
		lbxReport.Columns.Add "文件" 360
		lbxReport.Columns.Add "状态" 100 align.center
		lbxReport.Columns.Add "威胁数" 70 align.center
		
		lbxFiles.Update()
		lbxFiles.Refresh()
		lbxReport.Update()
		lbxReport.Refresh()
	)
	
	fn collectMaxFiles folder recursive = (
		local result = #()
		local pattern = folder + "\\*.max"
		result = getFiles pattern
		
		if recursive do (
			dirs = getDirectories (folder + "\\*")
			for d in dirs do (
				join result (collectMaxFiles d true)
			)
		)
		return result
	)
	
	fn updateFileList = (
		local failure = undefined
		lbxFiles.BeginUpdate()
		try
		(
			lbxFiles.Items.Clear()
			local idx = 1
			for f in fileList do
			(
				li = dotNetObject "System.Windows.Forms.ListViewItem" (idx as string)
				li.subitems.add f
				lbxFiles.Items.add li
				idx += 1
			)
		)
		catch (failure = getCurrentException())
		lbxFiles.EndUpdate()
		if failure!=undefined do throw failure
	)
	

	fn addFilesToList files = (
		for f in files where (findItem fileList f) == 0 do (
			append fileList f
		)
		updateFileList()
	)
	
	fn addFolderToList folder = (
		-- 立即扫描文件夹中的.max文件
		local foundFiles = collectMaxFiles folder chkRecursive.checked
		
		if foundFiles.count > 0 then (
			-- 添加找到的文件到列表
			for f in foundFiles where (findItem fileList f) == 0 do (
				append fileList f
			)
			updateFileList()
			
			-- 显示提示
			local msg = "从文件夹找到 " + (foundFiles.count as string) + " 个 .max 文件"
			if chkRecursive.checked then (
				msg += "（包含子文件夹）"
			)
			lblStatus.text = msg
		) else (
			messageBox ("文件夹中没有找到 .max 文件！\n\n路径：" + folder) title:"提示"
		)
	)
	
	fn getAllMaxFiles = (
		-- 直接返回文件列表，因为已经在添加时扫描过了
		return fileList
	)
	
	fn updateReport filename status threatCount = (
		li = dotNetObject "System.Windows.Forms.ListViewItem" ((scanResults.count + 1) as string)
		li.subitems.add (filenameFromPath filename)
		
		statusText = case status of (
			#clean: "✓ 干净"
			#cleaned: "⚠ 已清理"
			#unsaved: "⚠ 清理未保存"
			#interrupted: "⏸ 中断待重试"
			#error: "✗ 错误"
			default: "未知"
		)
		li.subitems.add statusText
		li.subitems.add (threatCount as string)
		
		bg = getDotNetColor 255 255 255
		fg = getDotNetColor 0 0 0
		
		case status of (
			#clean: (
				fg = getDotNetColor 56 118 79
			)
			#cleaned: (
				fg = getDotNetColor 215 144 0
			)
			#unsaved: (
				fg = getDotNetColor 215 144 0
			)
			#interrupted: (
				fg = getDotNetColor 215 144 0
			)
			#error: (
				fg = getDotNetColor 200 0 0
			)
		)
		
		li.subItems.Item[2].foreColor = fg
		
		lbxReport.Items.add li
		append scanResults #(filename, status, threatCount)
	)
	
	fn scanFile filepath =
	(
		local threatCount = 0, status = #error
		local oldQuiet = getQuietMode()
		local slog = signature_log()
		local oldVerbose = slog.getVerboseLevel()
		local failure = undefined
		try
		(
			local officialBefore = BsVirusOfficialCounts()
			local beforeRecords = BsVirusThreatRecords slog
			setQuietMode true
			if (slog.setVerboseLevel 3)!=true do throw "无法启用批量静默查杀的日志设置。"
			if not (loadMaxFile filepath useFileUnits:true quiet:true) do throw "文件打开失败，未执行查杀或保存。"
			local mscCleaned = 0
			for f in getFiles (((getDir #scripts) + "\\BulletScripts\\ScanVirus\\") + "signature.*.mcr") do
			(
				local ruleFailure = undefined
				local ruleResult = try (fileIn f) catch (ruleFailure = getCurrentException(); false)
				if ruleFailure!=undefined do throw ("查杀规则执行失败：" + (filenameFromPath f) + "\n" + ruleFailure)
				if (getFilenameFile f)=="signature.worm.alienbrains" and ruleResult==true do mscCleaned+=1
			)
			local official = BsVirusOfficialDelta officialBefore (BsVirusOfficialCounts())
			local newRecords = for record in (BsVirusThreatRecords slog) where (findItem beforeRecords record)==0 collect record
			local signatureCount = amax newRecords.count mscCleaned
			threatCount = official[1] + signatureCount
			if official[2]<official[1] do throw "官方检测到的问题未全部清理，本文件未自动保存。"
			-- Auto-save applies to every successfully checked file, including cleanup performed on load.
			if chkAutoSave.checked do
			(
				if not (saveMaxFile filepath useNewFile:false quiet:true) do throw "文件保存失败，磁盘上的原文件未确认已清理。"
				local afterSave = BsVirusOfficialDelta officialBefore (BsVirusOfficialCounts())
				if afterSave[2]<afterSave[1] do throw "保存时仍检测到未清理的问题，请查看官方安全日志。"
				official = afterSave
				threatCount = official[1] + signatureCount
			)
			status = if threatCount>0 then (if chkAutoSave.checked then #cleaned else #unsaved) else #clean
			slog.write ("批量查杀：" + (filenameFromPath filepath) + " - 官方检测 " + (official[1] as string) +
				"，官方修复 " + (official[2] as string) + "，特征检测 " + (signatureCount as string) +
				(if chkAutoSave.checked then "；已保存" else "；未保存")) type:#default
		)
		catch (failure = getCurrentException(); status = #error)
		setQuietMode oldQuiet
		local restored = try (slog.setVerboseLevel oldVerbose) catch(false)
		if restored!=true do (status = #error; if failure==undefined do failure = "无法恢复原来的查杀日志设置。")
		if failure!=undefined do slog.write ("批量查杀：" + (filenameFromPath filepath) + " - " + failure) type:#warn
		#(status, threatCount)
	)
	
	fn restoreProgress =
	(
		if checkpoint.load() do
		(
			fileList = for entry in checkpoint.entries collect entry.filePath
			chkAutoSave.checked = checkpoint.autoSave
			chkRecursive.checked = checkpoint.recursive
			updateFileList()
			local failure = undefined
			lbxReport.BeginUpdate()
			try
			(
				lbxReport.Items.Clear()
				scanResults = #()
				for i=1 to checkpoint.entries.count do
				(
					local entry = checkpoint.entries[i]
					if checkpoint.activeFile!="" and (checkpoint.pathKey entry.filePath)==(checkpoint.pathKey checkpoint.activeFile) then
					(
						updateReport entry.filePath #interrupted entry.threatCount
						lbxFiles.Items.Item[i-1].Selected = true
						lbxFiles.Items.Item[i-1].EnsureVisible()
					)
					else if entry.saved or (findItem #(#error,#unsaved) entry.state)>0 do
						updateReport entry.filePath entry.state entry.threatCount
				)
			)
			catch (failure = getCurrentException())
			lbxReport.EndUpdate()
			if failure!=undefined do throw failure
			if fileList.count>0 do
			(
				lblStatus.text = "已恢复断点：已保存 " + (checkpoint.completedCount() as string) + "/" + (fileList.count as string) +
					(if checkpoint.activeFile!="" then "；上次中断：" + filenameFromPath checkpoint.activeFile else "；点击开始 / 继续")
				pbProgress.value = (100.0 * checkpoint.completedCount() / fileList.count) as integer
			)
		)
	)
	
	fn startBatchScan = (
		-- 收集所有文件
		local allFiles = getAllMaxFiles()
		local totalFiles = allFiles.count
		
		if totalFiles == 0 do (
			messageBox "没有选择任何文件！请先添加文件或文件夹。                    " title:"提示"
			return undefined
		)
		
		-- 确认对话框
		local confirmMsg = "批量查杀列表共有 " + (totalFiles as string) + " 个文件。\n已保存且未变化的文件会跳过，仅打开待处理文件。\n\n"
		confirmMsg += "⚠ 重要提示：\n"
		confirmMsg += "1. 当前场景将被重置\n"
		confirmMsg += "2. 请先保存当前文件！\n\n"
		if chkAutoSave.checked then (
			confirmMsg += "已勾选\"立即保存\"，查杀后将自动覆盖原文件。\n\n"
		) else (
			confirmMsg += "未勾选\"立即保存\"，查杀后不会保存更改。\n\n"
		)
		confirmMsg += "是否确认开始批量查杀？"
		
		local result = queryBox confirmMsg title:"批量查杀确认"
		if result != true do (
			return undefined
		)
		
		local batchFailure = undefined
		try
		(
			allFiles = checkpoint.prepare allFiles chkAutoSave.checked chkRecursive.checked
			fileList = allFiles
			totalFiles = allFiles.count
			updateFileList()
		)
		catch (batchFailure = getCurrentException())
		if batchFailure!=undefined do
		(
			messageBox batchFailure title:"无法保存断点"
			return undefined
		)
		-- 开始扫描
		batchStopFlag = false
		btnStart.enabled = false
		btnStop.enabled = true
		btnAddFiles.enabled = false
		btnAddFolder.enabled = false
		btnClearList.enabled = false
		chkRecursive.enabled = false
		chkAutoSave.enabled = false
		
		local reused = 0
		local pending = #()
		local reportBuffered = false
		try
		(
			lbxReport.BeginUpdate()
			reportBuffered = true
			lbxReport.Items.Clear()
			scanResults = #()
			-- prepare 已核对文件状态；合并显示旧结果，只把未完成项加入本轮。
			for i = 1 to totalFiles do
			(
				local entry = checkpoint.entries[i]
				if entry.saved then
				(
					reused += 1
					updateReport entry.filePath entry.state entry.threatCount
				)
				else append pending i
			)
			lbxReport.EndUpdate()
			reportBuffered = false
			lblStatus.text = "已跳过 " + (reused as string) + " 个已完成文件；待处理 " + (pending.count as string) + " 个"
			pbProgress.value = (100.0 * reused / totalFiles) as integer
			windows.processPostedMessages()
			for n = 1 to pending.count while (not batchStopFlag) do
			(
				local i = pending[n]
				local filepath = allFiles[i]
				lblStatus.text = "正在处理 (" + (n as string) + "/" + (pending.count as string) + ")，已跳过 " + (reused as string) + ": " + (filenameFromPath filepath)
				checkpoint.beginFile i
				local result = scanFile filepath
				checkpoint.finishFile i result
				updateReport filepath result[1] result[2]
				pbProgress.value = (100.0 * (reused+n) / totalFiles) as integer
				windows.processPostedMessages()
			)
		)

		catch (batchFailure = getCurrentException(); batchStopFlag = true)
		if reportBuffered do lbxReport.EndUpdate()
		if batchFailure!=undefined do messageBox ("本轮已停止，可从已保存的断点继续。\n\n" + batchFailure) title:"批量任务中断"
		
		if batchStopFlag then (
			lblStatus.text = "已停止，断点已保留；已保存 " + (checkpoint.completedCount() as string) + "/" + (totalFiles as string) + " 个文件"
		) else (
			lblStatus.text = "本轮完成；已保存 " + (checkpoint.completedCount() as string) + "/" + (totalFiles as string) + "；本次跳过 " + (reused as string)
			local cleanCount = (for r in scanResults where r[2] == #clean collect r).count
			local cleanedCount = (for r in scanResults where r[2] == #cleaned collect r).count
			local unsavedCount = (for r in scanResults where r[2] == #unsaved collect r).count
			local errorCount = (for r in scanResults where r[2] == #error collect r).count
			
			local summaryMsg = "批量查杀完成！\n\n"
			summaryMsg += "共检查: " + (totalFiles as string) + " 个文件\n"
			summaryMsg += "本次跳过已完成: " + (reused as string) + " 个\n"
			summaryMsg += "✓ 干净: " + (cleanCount as string) + " 个\n"
			summaryMsg += "⚠ 已清理: " + (cleanedCount as string) + " 个\n"
			if unsavedCount > 0 do summaryMsg += "⚠ 清理未保存: " + (unsavedCount as string) + " 个\n"
			if errorCount > 0 do (
				summaryMsg += "✗ 错误: " + (errorCount as string) + " 个\n"
			)
			
			messageBox summaryMsg title:"批量查杀完成"
		)
		
		btnStart.enabled = true
		btnStop.enabled = false
		btnAddFiles.enabled = true
		btnAddFolder.enabled = true
		btnClearList.enabled = true
		chkRecursive.enabled = true
		chkAutoSave.enabled = true
	)
	
	on rolBatchCleanVirus open do (
		checkpoint = BsVirusBatchProgress statePath:(pathConfig.appendPath (getDir #maxData) "BsCleanVirusBatchProgress.xml")
		initDotNet()
		try (restoreProgress())
		catch (lblStatus.text = "断点读取失败，可清空列表后重新建立任务。"; messageBox (getCurrentException()) title:"断点记录")
	)
	
	on btnAddFiles pressed do (
		try (
			-- 使用 DotNet OpenFileDialog 支持多选（Max 2010+支持）
			local ofd = dotNetObject "System.Windows.Forms.OpenFileDialog"
			ofd.Title = "选择Max文件"
			ofd.Filter = "3ds Max Files (*.max)|*.max|All files (*.*)|*.*"
			ofd.Multiselect = true
			
			-- 设置初始目录（如果当前有打开的文件）
			if maxFilePath != undefined and maxFilePath != "" then (
				ofd.InitialDirectory = maxFilePath
			)
			
			local result = ofd.ShowDialog()
			local dialogResult = dotNetClass "System.Windows.Forms.DialogResult"
			
			if result == dialogResult.OK do (
				-- 直接获取文件名数组，MaxScript会自动转换.NET集合
				local files = ofd.FileNames
				
				-- 转换为MaxScript数组
				local fileArray = #()
				for f in files do (
					append fileArray f
				)
				
				if fileArray.count > 0 do (
					addFilesToList fileArray
				)
			)
		) catch (
			-- Fallback: 如果.NET方法失败，提示用户手动拖放或使用旧版Max
			messageBox "多文件选择功能需要 3ds Max 2010 或更高版本。\n\n请尝试：\n1. 使用\"添加文件夹\"功能\n2. 升级Max版本" title:"提示"
		)
	)
	
	on btnAddFolder pressed do (
		local folder = getSavePath caption:"选择文件夹"
		if folder != undefined do (
			addFolderToList folder
		)
	)
	
	on btnClearList pressed do (
		try
		(
			checkpoint.autoSave = chkAutoSave.checked
			checkpoint.recursive = chkRecursive.checked
			checkpoint.clear()
			fileList = #()
			scanResults = #()
			updateFileList()
			lbxReport.Items.Clear()
			pbProgress.value = 0
			lblStatus.text = "列表和断点已清空，等待开始..."
		)
		catch (messageBox (getCurrentException()) title:"无法清空断点")
	)
	
	on btnStart pressed do (
		startBatchScan()
	)
	
	on btnStop pressed do (
		batchStopFlag = true
		lblStatus.text = "正在停止..."
	)
	
	on rolBatchCleanVirus resized size do (
		local newWidth = size.x - 20
		local newHeight = size.y
		
		-- 调整宽度
		lbxFiles.width = newWidth
		lbxFiles.height = 160
		
		lblStatus.width = newWidth
		pbProgress.width = newWidth
		
		lbxReport.width = newWidth
		lbxReport.height = newHeight - 375
		
		-- 调整按钮位置
		local btnY = newHeight - 40
		btnStart.pos.y = btnY
		btnStop.pos.y = btnY
		
		lblReportTitle.pos.y = newHeight - 200
		lbxReport.pos.y = newHeight - 180
	)
)

rollout rolBsCleanVirus  ("BsCleanVirus_v" + curVerBsCleanVirus)
(
    local startupBsCleanVirusTools = (getDir #Scripts) + "\\BulletScripts\\StartupMS\\BsCleanVirusStartup.ms"
	local startupLocalPath = (getDir #StartupScripts)+ "\\BsCleanVirusStartup.ms"

    group "【解析自 PruneScene 免费功能，仅供学习】"
    (
        checkbutton ckbStartup "主动防御 [杀毒自启] " width:130 height:30 pos:[10,20]
        checkbutton ckbSilent "静默" width:35 height:30 pos:[145,20]
		button btnCleanNow "立即查杀" width:70 height:30 pos:[185,20]
        button btnBatchClean "批量查杀" width:75 height:30 pos:[260,20]
        button btnCleanLog "日志" width:45 height:30 pos:[340,20]
    )

    group "杀毒特征库"
    (
        listbox lbxVirusLib "" width:365 height:12 pos:[10,75] readonly:true
    )

    HyperLink lnkPruneScene "杀毒特征来源：PruneScene" color:myfgColor hovercolor:myClickColor visitedcolor:myClickColor 
        pos:[15,255] width:170 address:"http://3dground.net/manual/prune-scene#virus-active-protecton"

    HyperLink lnkBsNotion "解析修改：Bullet.S" color:myfgColor hovercolor:myClickColor visitedcolor:myClickColor 
        pos:[260,255] width:120 address:"https://space.bilibili.com/2031113/lists/560782"

    fn fnRefreshVirusLib =
    (
        lbxVirusLib.Items = #()
        arrSignatureFiles = (getFiles (((getDir #scripts) + "\\BulletScripts\\ScanVirus\\")+ "signature.*.mcr"))
        lbxVirusLib.Items = for i in arrSignatureFiles collect (getFilenameFile i)
        lbxVirusLib.selection = 0
    )

    on rolBsCleanVirus open do
    (
        stLoadConfigAll.fnLoadConfigBsCleanVirus()  ---------------脚本配置等赋值
		stSetConfigAll.fnSetConfigBsCleanVirus()  ----------------保存配置到ini文件
		iniVerboseLevel = stLoadConfigAll.fnGetVerboseLevel()
        ckbStartup.state = (SIOFile.Exists rolBsCleanVirus.startupLocalPath)
		ckbSilent.state = if iniVerboseLevel == 1 then false else true
        fnRefreshVirusLib()
    )

	on rolBsCleanVirus close do -- 关闭时记忆配置
	(
        stSetConfigAll.fnSetConfigBsCleanVirus ()
	)

    on btnCleanNow pressed do
    (
        for f in getFiles (((getDir #scripts) + "\\BulletScripts\\ScanVirus\\")+ "signature.*.mcr") do
        (
            try(FileIn f) 
            catch(messagebox "加载杀毒失败，可能脚本错误或安装不完全，\r\n\r\n建议查看设置中的帮助或重新安装，还有问题烦请联系我...                            " beep:false)
        )
        messageBox "检测结束，请注意弹窗和查看日志！并且注意保存/另存文件！                                                 "
        try(destroyDialog rolBsVirusScanLog) catch()
        createDialog rolBsVirusScanLog 850 450 style: #(#style_toolwindow, #style_resizing, #style_sysmenu, #style_toolwindow)
    )

	on btnBatchClean pressed do 
    (
        try(destroyDialog rolBatchCleanVirus) catch()
        createDialog rolBatchCleanVirus 650 510 style: #(#style_toolwindow, #style_resizing, #style_sysmenu)
    )

    on btnCleanLog pressed do 
    (
        try(destroyDialog rolBsVirusScanLog) catch()
        createDialog rolBsVirusScanLog 850 450 style: #(#style_toolwindow, #style_resizing, #style_sysmenu, #style_toolwindow)
    )

    on ckbStartup changed state do
    (
        if (not state) then 
        (
            fnDelFileDir startupLocalPath;iniStartupBsCleanVirus = 0
            messagebox "已经关闭杀毒自启，请重新启动3dsMax！                                          "
        )
		else 
		(
			if (not (SIOFile.Exists startupLocalPath)) then
			(
				try 
				(
					-- SIOFile.Copy startupBsCleanVirusTools startupLocalPath
					FileIO.Copyfile startupBsCleanVirusTools startupLocalPath UIOption
					messagebox ("已经打开主动防御，如安装杀毒卫士，\r\n\r\n请把插件进程管理中的\"signature\"相关回调启用！                                                                ")
					setFileAttribute startupLocalPath #readOnly true
                    iniStartupBsCleanVirus = 1
                    for f in getFiles (((getDir #scripts) + "\\BulletScripts\\ScanVirus\\")+ "signature.*.mcr") do
                    (
                        try(FileIn f) 
                        catch(messagebox "加载杀毒失败，可能脚本错误或安装不完全，\r\n\r\n建议查看设置中的帮助或重新安装，还有问题烦请联系我...                            " beep:false)
                    )
				)
				catch
				(
					-- messagebox ("自启失败，烦请管理员运行 max 或手动处理：\r\n\r\n把 BsCleanVirusStartup.ms 复制到\r\n\r\n" + (getDir #StartupScripts) + "                    ")
					-- (shellLaunch (getfilenamepath startupBsCleanVirusTools) "")
				)
			)
            else (messagebox "已经开启自启，请勿重复操作！                                          ")
		)
        stSetConfigAll.fnSetConfigBsCleanVirus ()
    )

	on ckbSilent changed state do 
	(
		if state then iniVerboseLevel = 3 else iniVerboseLevel = 1
		stSetConfigAll.fnSetVerboseLevel iniVerboseLevel
	)
------------------------------------------------------------------------------------------------------
)
Createdialog rolBsCleanVirus 390 280 fgcolor:myFgColor