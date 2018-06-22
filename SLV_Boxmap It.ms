/*  
[INFO] 

NAME = SLV_UVW Manager
VERSION = 1.0.0
AUTHOR = MastaMan
DEV = VISCO
HELP = 

[1.0.0]

* First release =

[ABOUT]

Store your UVW Map.=

[TEST]

[SCRIPT]
*/	

global _FORM_TOUCHED = false
global _rUvwManagerMain

try(closeRolloutFloater fUVWMANAGER) catch()
global fUVWMANAGER = newRolloutFloater "Boxmap It" 250 835

fn rebuildListBoxmapIt = (
	try(_rUvwManagerMain.disableUI false) catch()
	try(_rUvwManagerMain.resetToDefaults()) catch()
	try(_rUvwManagerMain.getList()) catch()
)

fn getScriptInfo s releaseInfo: "" =
(		
	if(releaseInfo != "") do
	(
		r = getINISetting s releaseInfo
		return r
	)
	
	v = getINISetting s "INFO" "VERSION"
	a = getINISetting s "INFO" "AUTHOR"
	n = getINISetting s "INFO" "NAME"
	o = getINISetting s "ABOUT"
	c = getINISetting s "INFO" "DEV"
	h = getINISetting s "INFO" "HELP"
	
	r = for i in (getINISetting s) where i != "ABOUT" and i != "SCRIPT" and i != "COPY" collect i
	
	return #(n, a, v, o, r, c, h)
)

fn parseToLine m = 
(
	if(m.count == 0) do return ""
	
	l = ""				
	for i in m do l += i + "\n"
	return l
)

fn useSettings k p w =
(
	/*
		useSettings "key" "value/int/float/bool/bool_not" "r/w" 
	*/
	
	u = sysInfo.username
	d = getFilenamePath  (getThisScriptFilename())
	n = filenameFromPath (getThisScriptFilename())			
	settingsFile = d + @"ini\" + u + "_" + n + ".ini"
		
	v = maxVersion()
	v = 2000 + ((v[1] / 1000) - 2)
	
	t = v as string
	
	case w of
	(
		"r":
		(
			s = getINISetting settingsFile t k
			case p of
			(
				"int": return s as integer
				"float": return s as float
				"bool": if s == "true" or s.count < 1 then true else false
				"bool_not": if s == "true" then true else false
				
				default: return s
			)
		)
		default: return setINISetting settingsFile t k (p as string)
	)
)	

fn checkVray =
(
	for r in RendererClass.classes where matchpattern (r as string) pattern:"*V_Ray_Adv*" do return true		
	return false	
)

rollout  _rUvwManagerMain "" 
(	
	dotNetControl tabControl "System.Windows.Forms.Tabcontrol" height: 25 width: 280 offset: [-10, 0]
	
	dotNetControl lbxList "system.windows.forms.listView" height: 275 width: 240 offset: [-13, 0]	
	button btnApplyMapping "Boxmap It" width: 210 height: 35
	checkbox cbxAutoCollapse "Auto Collapse"
	
	label lblEmpty1 "" height: 1
	progressbar hr "" height: 2
	label lblEmpty2 "" height: 1
	
	button btnAdd "Create New" width: 100 height: 25 align: #left across: 2
	button btnDel "Delete Items" width: 100 height: 25 align: #right
		
	group "Name:" (
		edittext edtName ""
	)
	
	group "Box Settings:" (
		spinner spnLength "Length:  " fieldWidth: 70 range: [0.0, 1e9, units.decodeValue "100cm"] type: #worldunits align: #right offset: [-80, 0]
		spinner spnWidth "Width:  " fieldWidth: 70 range: [0.0, 1e9, units.decodeValue "100cm"] type: #worldunits align: #right offset: [-80, 0]
		spinner spnHeight "Height:  " fieldWidth: 70 range: [0.0, 1e9, units.decodeValue "100cm"] type: #worldunits align: #right offset: [-80, 0]
		
		spinner spnUTile "U Tile:  " fieldWidth: 70 range: [1, 1e9, 1] type: #float align: #right offset: [26, 15] across: 2
		checkbox cbxUTileFlip "Flip" offset: [35, 15] 
		
		spinner spnVTile "V Tile:  " fieldWidth: 70 range: [1, 1e9, 1] type: #float align: #right offset:  [26, 0] across: 2
		checkbox cbxVTileFlip "Flip" offset: [35, 0] 
		
		spinner spnWTile "W Tile:  " fieldWidth: 70 range: [1, 1e9, 1] type: #float align: #right offset:  [26, 0] across: 2
		checkbox cbxWTileFlip "Flip" offset: [35, 0] 
		
		checkbox cbxRealWorldMapSize "Real-World Map Size" offset: [0, 15]
	)
	
	group "Channel:" (
		spinner spnMapChannel "Map Channel:  " range: [1, 100, 1] fieldWidth: 30 type: #integer align: #left
	)
	
	group "Rotation:" (
		spinner spnRotateX "Rotate X:  " fieldWidth: 70 range: [-360.0, 360.0, 0.0] type: #float align: #right offset: [-80, 0]
		spinner spnRotateY "Rotate Y:  " fieldWidth: 70 range: [-360.0, 360.0, 0.0] type: #float align: #right offset: [-80, 0]
		spinner spnRotateZ "Rotate Z:  " fieldWidth: 70 range: [-360.0, 360.0, 0.0] type: #float align: #right offset: [-80, 0]
	
	)
	
	fn makeTab t = dotNetObject "System.Windows.Forms.TabPage" t
	
	fn generateUniqueID = 
	(
		c = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz1234567890"
		code = ""
		
		sec = 4
		secNum = 5
		
		for i in 1 to sec do 
		(
			for ii in 1 to secNum do code += c[random 1 c.count] 
			if(i != sec) do code += ""
		)
		
		return "UVW_" + code
	)
	
	fn initTc tc =
	(		
		tabs = #()
		tabs[1] = makeTab "Scene"
		tabs[2] = makeTab "My Library"
		tabs[3] = makeTab "Favorite"
		tabs[4] = makeTab "Shared"
			
		for t in tabs do tc.controls.add t		
	)
	
	fn getTab = (
		return tabControl.SelectedTab.TabIndex + 1
	)
	
	fn initDotNet = (	
		lbxList.Clear()
		lbxList.View = (dotNetClass "System.Windows.Forms.View").Details	
		lbxList.FullRowSelect = true
		lbxList.GridLines = true		
		lbxList.ShowItemToolTips = true
		lbxList.MultiSelect = false
		lbxList.CheckBoxes = true
		lbxList.HideSelection = false
		lbxList.Columns.Add "#" 22
		lbxList.Columns.Add "Name" 200
			
		lbxList.Update()
		lbxList.Refresh()
		
		initTc tabControl
	)
	
	fn disableUI d = (
		for i in _rUvwManagerMain.controls do try(i.enabled = d)catch()
		
		lbxList.enabled = true
		btnApplyMapping.enabled = true
		cbxAutoCollapse.enabled = true
		btnAdd.enabled = true
		btnDel.enabled = true		
		tabControl.enabled = true
	)
	
	fn getSelectedId =
	(
		c = lbxList.SelectedItems.Count - 1
		
		id = 0
		
		for i = 0 to c do 
		(		
			id = lbxList.SelectedItems.Item[i].Index + 1			
		)
	
		return id
	)
	
	fn getSelectedUID =
	(
		c = lbxList.SelectedItems.Count - 1
		
		id = 0
		
		for i = 0 to c do 
		(		
			id = lbxList.SelectedItems.Item[i].tag
		)
	
		return id
	)
	
	fn selectByUID uid: 0 =
	(
		if(uid == undefined or uid == 0) do return false
		
		c = lbxList.Items.Count - 1
			
		for i = 0 to c where lbxList.Items.Item[i].tag == uid do 
		(			
			lbxList.Items.Item[i].Selected = true			
			return i + 1
		)			
		
		return 0
	)
	
	fn getCheckedUID =
	(
		c = lbxList.Items.Count - 1
		
		uid = #()
		
		for i = 0 to c where lbxList.Items.Item[i].checked do 
		(
			append uid (lbxList.Items.Item[i].tag)
		)
	
		return uid
	)
	
	fn addToLbxList r =	(				
		lbxList.Items.Clear()
		rows = #()	
		i = 1
		for x in r do	
		(
			li = dotNetObject "System.Windows.Forms.ListViewItem" ""
			li.UseItemStyleForSubItems=true
			
			li.subitems.add x[1]
			li.tag = x[2]
			
			append rows li		
			i += 1
		)
		
		lbxList.Items.addRange rows
	)	
	
	
	fn implode a tag: ";" = 
	(
		s = ""
		for i in a do s += i as string + tag
		return trimRight s tag
	)

	fn explode s tag: ";" = return filterString s tag splitEmptyTokens: false
	fn trim s = trimLeft (trimRight s)
	
	fn getIni = getFileNamePath (getThisScriptFileName()) + @"ini\" + (sysInfo.username) + "_uvw_manager.ini"
	fn getSharedIni = getFileNamePath (getThisScriptFileName()) + @"ini\" +  "shared_uvw_manager.ini"
	
	fn resetToDefaults = (
		edtName.text = ""
		
		spnLength.value = units.decodeValue "100cm"
		spnWidth.value = units.decodeValue "100cm"
		spnHeight.value = units.decodeValue "100cm"
		spnUTile.value = 1.0
		spnVTile.value = 1.0
		spnWTile.value = 1.0
		cbxUTileFlip.checked = false
		cbxVTileFlip.checked = false
		cbxWTileFlip.checked = false
		cbxRealWorldMapSize.checked = false
		spnMapChannel.value = 1
		spnRotateX.value = 0.0
		spnRotateY.value = 0.0
		spnRotateZ.value	= 0.0	
	)	
	
	fn saveProp p d = try(fileProperties.addProperty #custom p d) catch()
	fn getProp p =
	(
		i = fileProperties.findProperty #custom p		
		if(i != 0) do return  fileProperties.getPropertyValue #custom i
		return ""		
	)
	
	fn deleteUVWSetting uid: 0 type: -1 = (
		if(uid == undefined or uid == 0) do return false	
		
		if(type == -1) do type = getTab()
		ini = getIni()
		
		case type of (
			1: (							
				try(fileProperties.deleteProperty #custom uid) catch()
			)
			2: (
				delIniSetting ini "YOUR" uid
			)
			3: (
				delIniSetting ini "FAVORITE" uid
			)
			4: (
				ini = getSharedIni()
				delIniSetting ini "SHARED" uid
			)
		)
	)
	
	fn saveUVWSettings name: "" uid: 0 type: -1 = (
		if(uid == undefined or uid == 0) do return false		
		
		if(type == -1) do type = getTab()
		ini = getIni()
		
		settings = #()
		settings[1] = name
		
		settings[2] = spnLength.value
		settings[3] = spnWidth.value
		settings[4] = spnHeight.value
		
		settings[5] = spnUTile.value
		settings[6] = spnVTile.value
		settings[7] = spnWTile.value
		
		settings[8] = cbxUTileFlip.checked
		settings[9] = cbxVTileFlip.checked
		settings[10] = cbxWTileFlip.checked
		
		settings[11] = cbxRealWorldMapSize.checked
		
		settings[12] = spnMapChannel.value
		
		settings[13] = spnRotateX.value
		settings[14] = spnRotateY.value
		settings[15] = spnRotateZ.value
		
		
		packed = implode settings
		
		case type of (
			1: (
				saveProp uid packed
			)
			2: (
				setIniSetting ini "YOUR" uid packed
			)
			3: (
				setIniSetting ini "FAVORITE" uid packed
			)
			4: (
				ini = getSharedIni()
				setIniSetting ini "SHARED" uid packed
			)
			#copy: (
				setIniSetting ini "COPY" uid packed
			)
		)
	)
	
	fn trySetSetting s v = execute ("_rUvwManagerMain." + s + " = " + v)
		
	fn getUVWSettings uid:0 type: -1 = (
		if(uid == undefined or uid == 0) do return false	
		ini = getIni()
		if(type == -1) do type = getTab()
		
		settings = #()
		
		case type of (
			1: (
				settings = explode (getProp uid)
			)
			2: (
				settings = explode (getIniSetting ini "YOUR" uid)
			)
			3: (
				settings = explode (getIniSetting ini "FAVORITE" uid)
			)
			4: (
				ini = getSharedIni()
				settings = explode (getIniSetting ini "SHARED" uid)
			)
			#copy:  (
				keys = getIniSetting ini "COPY"
				if(keys.count == 0) do return false
				
				settings = explode (getIniSetting ini "COPY" uid)				
			)
		)
		
		if(settings.count == 0) do return resetToDefaults()
		
		trySetSetting "edtName.text" ("\"" + settings[1] + "\"")
		
		trySetSetting "spnLength.value" settings[2]		
		trySetSetting "spnWidth.value" settings[3]		
		trySetSetting "spnHeight.value" settings[4]	
		
		trySetSetting "spnUTile.value" settings[5]		
		trySetSetting "spnVTile.value" settings[6]		
		trySetSetting "spnWTile.value" settings[7]		
		
		trySetSetting "cbxUTileFlip.checked" settings[8]		
		trySetSetting "cbxVTileFlip.checked" settings[9]		
		trySetSetting "cbxWTileFlip.checked" settings[10]		
		
		trySetSetting "cbxRealWorldMapSize.checked" settings[11]		
		
		trySetSetting "spnMapChannel.value" settings[12]		
		
		trySetSetting "spnRotateX.value" settings[13]				
		trySetSetting "spnRotateY.value" settings[14]				
		trySetSetting "spnRotateZ.value" settings[15]				
	)
	
	fn getList enable: false = (
		type = getTab()
		ini = getIni()
		if(type == 4) do ini = getSharedIni()
		
		resetToDefaults()
		disableUI enable
		
		list = #()		
		
		if(type == 1) do (
			for i in 1 to (fileProperties.getNumProperties #custom) do (
				k = fileProperties.getPropertyName #custom i
				v = fileProperties.getPropertyValue #custom i
				if(findString k "UVW_" == undefined) do continue
				
				settings = explode v
				t = #()
				t[1] = settings[1]
				t[2] = k
				
				append list t
			)
		)
		
		if(type == 2 or type == 3 or type == 4) do (
			n = case type of (
				2: "YOUR"
				4: "SHARED"
				default: "FAVORITE"
			)
			
			for k in (getIniSetting ini n) do (
				v = getIniSetting ini n k
				settings = explode v
				t = #()
				t[1] = settings[1]
				t[2] = k
				
				append list t
			)
		)
	
		addToLbxList list
	)
	
	
	fn quickSave = (
		id = getSelectedId()
		if(id == 0) do return false
		
		uid = lbxList.Items.Item[id - 1].tag
		
		name = edtName.text
		
		if(name.count == 0) do name = "Unknown UVW"
		
		saveUVWSettings name: name uid: uid					
	)
	
	fn deleteSetting = (
		uids = getCheckedUID()
		id = getSelectedId()
			
		if(uids.count > 0) then (
			q = queryBox ("Do you really want to delete " + uids.count as string + " items?") title: "Confirm?"
			if(not q) do return false
			
			for i in uids do (
				deleteUVWSetting uid: i
			)
		) else (
			if(id == 0) do return messageBox "Please select or check items for delete!" title: "Warning!"
			q = queryBox ("Do you really want to delete selected item?") title: "Confirm?"
			if(not q) do return false
			
			uid = lbxList.Items.Item[id - 1].tag
			deleteUVWSetting uid: uid
		)
				
		disableUI false
		resetToDefaults()
		
		getList()	
	)
	
	fn addToFavorite = (
		id = getSelectedId()
		uids = getCheckedUID()
		
		if(uids.count > 0) then (
			q = queryBox ("Do you really want add to favorite " + uids.count as string + " items?") title: "Confirm?"
			if(not q) do return false
			
			for i in uids do (
				getUVWSettings uid: i
				name = edtName.text
				saveUVWSettings name: name uid: i type: 3
			)			
		) else (
			if(id == 0) do return messageBox "Please select or check items for add to favorite!" title: "Warning!"
			uid = lbxList.Items.Item[id - 1].tag
			name = edtName.text
			if(name.count == 0) do name = "Unknown UVW"
			saveUVWSettings name: name uid: uid type: 3			
		)	
	)
	
	fn removeFromFavorite = (
		deleteSetting()
	)
		
	fn shareSetting = (
		id = getSelectedId()
		uids = getCheckedUID()		
		type = getTab()
		u = sysInfo.username
		
		if(uids.count > 0) then (
			q = queryBox ("Do you really want to share " + uids.count as string + " items?") title: "Confirm?"
			if(not q) do return false
			
			for i in uids do (
				getUVWSettings uid: i
				name = edtName.text + " (" + u + ")"
				
				uid = generateUniqueID()
				saveUVWSettings name: name uid: uid type: 4
			)			
		) else (
			if(id == 0) do return messageBox "Please select or check items for add to favorite!" title: "Warning!"
			uid = lbxList.Items.Item[id - 1].tag
			name = edtName.text + " (" + u + ")"
			if(name.count == 0) do name = "Unknown UVW"
			saveUVWSettings name: name uid: uid type: 4		
		)
			
		messageBox "Items shared! Find your item in Shared List!" title: "Success!" beep: false
		
		resetToDefaults()
		disableUI false
		getList()
	)
	
	fn saveShareSetting = (
		id = getSelectedId()	
		uids = getCheckedUID()		
		type = getTab()
		u = sysInfo.username
		
		if(uids.count > 0) then (
			q = queryBox ("Do you really want to save " + uids.count as string + " shared items?") title: "Confirm?"
			if(not q) do return false
			
			for i in uids do (
				getUVWSettings uid: i type: type
				--name = substituteString edtName.text (" ("+ u +")")
				name = edtName.text
				if(name.count == 0) do name = "Unknown UVW"
				saveUVWSettings name: name uid: i type: 2
			)			
		) else (
			if(id == 0) do return messageBox "Please select or check items for add to favorite!" title: "Warning!"
			uid = lbxList.Items.Item[id - 1].tag
			getUVWSettings uid: uid type: type			
			--name = substituteString edtName.text (" ("+ u +")")
			name = edtName.text
			if(name.count == 0) do name = "Unknown UVW"			
			saveUVWSettings name: name uid: uid type: 2		
		)
			
		resetToDefaults()
		disableUI false
		getList()
	)
	
	fn isCopyPasteAllow = (
		ini = getIni()
		keys = getIniSetting ini "COPY"
		return keys.count > 0
	)
	
	fn clearCopyBuffer = (
		ini = getIni()
		keys = delIniSetting ini "COPY"				
	)
	
	fn copySetting = (		
		id = getSelectedId()
		uids = getCheckedUID()
		
		if(uids.count > 0) then (
			q = queryBox ("Do you really want to copy " + uids.count as string + " items?") title: "Confirm?"
			if(not q) do return false
			
			for i in uids do (
				getUVWSettings uid: i
				name = edtName.text
				if(name.count == 0) do name = "Unknown UVW"
				
				uid = generateUniqueID()
				saveUVWSettings name: name uid: uid type: #copy				
			)			
		) else (
			if(id == 0) do return messageBox "Please select or check items for copy!" title: "Warning!"
			uid = generateUniqueID()
			name = edtName.text
			if(name.count == 0) do name = "Unknown UVW"
			saveUVWSettings name: name uid: uid type: #copy		
		)	
	)
	
	fn pasteSetting = (			
		if(not isCopyPasteAllow()) do return false
		
		type = getTab()	
		u = sysInfo.username
		ini = getIni()	
		
		keys = getIniSetting ini "COPY"
			
		for uid in keys do (	
			getUVWSettings uid: uid type: #copy
			
			a = case type of (
				4: " (" + u + ")"
				default: " (Copied)"
			)
			
			name = edtName.text + a
			
			i = generateUniqueID()
			saveUVWSettings name: name uid: i 
		)
		
		clearCopyBuffer()	
		
		resetToDefaults()
		disableUI false
		getList()
	)
		
	fn messageBoxName = (
		ini = getIni()
		delIniSetting ini "TMP" "NAME"
		
		rollout rBoxName "Please enter the name!" (
			group "Enter the name:" (
				edittext edtBoxName ""
			)
			
			button btnCreate "Create" across: 2 width: 100 height: 25 offset: [0, 5] align: #left
			button btnCancel "Cancel" width: 100 height: 25 offset: [0, 5] align: #right
			
			on btnCancel pressed do (
				iniFile = _rUvwManagerMain.getIni()
				delIniSetting iniFile "TMP" "NAME"
				
				try(destroyDialog rBoxName)catch()
			)
			
			fn createName = (
				if(edtBoxName.text.count < 2) do (
					messageBox "Please enter the name (min. 2 symbols)!" title: "Warning!"
					return false
				)
				
				iniFile = _rUvwManagerMain.getIni()
				setIniSetting iniFile "TMP" "NAME" (edtBoxName.text)
				
				return true
			)
			
			on btnCreate pressed do (
				q = createName()
				if(q) do try(destroyDialog rBoxName)catch()
			)
			
			on edtBoxName entered v do (
				q = createName()
				if(q) do try(destroyDialog rBoxName)catch()
			)
				
			on edtBoxName changed v do (
				bad = #(";", "=", "|")
		
				for i in bad do v = substituteString v i ""			
				edtBoxName.text = v	
			)		

			on rBoxName open do (
				setFocus edtBoxName
			)
		)
		
		createDialog rBoxName 250 100 escapeEnable: false modal: true
		
		return getIniSetting ini "TMP" "NAME"
	)
	
	fn createNew = (
		q = messageBoxName()
		if(q.count < 2) do return false
				
		defaultName = q
		if(edtName.text == defaultName) do return messageBox "Double add new item!" title: "Warning!"
		
		uid = generateUniqueID()
		resetToDefaults()
		
		disableUI true
		
		saveUVWSettings name:defaultName uid: uid
		getUVWSettings uid: uid
		
		--messageBox "New item \"New UVW\" added!" title: "Success!" beep: false
		
		getList()		
		
		id = selectByUID uid: uid
		
		if(id != 0) do (
			getUVWSettings uid: uid
			disableUI true
		)	
	)
	
	fn bindContextMenu =
	(
		id = getSelectedId()
		uid = getSelectedUID()
		type = getTab()
		
		--if(id == 0) do return false
		--if(uid == undefined or uid == 0) do return false
				
		contextMenu = dotNetObject "System.Windows.Forms.ContextMenuStrip"			
		--		
		li = contextMenu.Items.Add("Create New")
		dotNet.addEventHandler li "Click" createNew
		---
		contextMenu.Items.Add("-")	
		---		
		li = contextMenu.Items.Add("Add to Favorite")
		dotNet.addEventHandler li "Click" addToFavorite
		li.enabled = (type != 3 and id != 0) 		
		
		if(type == 3) do (
			li = contextMenu.Items.Add("Remove from Favorite")
			dotNet.addEventHandler li "Click" removeFromFavorite
			li.enabled = id != 0
		)
		---		
		contextMenu.Items.Add("-")	
		---		
		li = contextMenu.Items.Add("Share Items")
		dotNet.addEventHandler li "Click" shareSetting
		li.enabled = id != 0 and type != 4
		
		li = contextMenu.Items.Add("Save Shared to My Library")
		dotNet.addEventHandler li "Click" saveShareSetting
		li.enabled = id != 0 and type == 4
		---	
		contextMenu.Items.Add("-")		
		---		
		li = contextMenu.Items.Add("Copy Items")
		dotNet.addEventHandler li "Click" copySetting
		li.enabled = id != 0	
		---		
		li = contextMenu.Items.Add("Paste Items")			
		dotNet.addEventHandler li "Click" pasteSetting				
		li.enabled = isCopyPasteAllow()
		---
		contextMenu.Items.Add("-")	
		---	
		li = contextMenu.Items.Add("Delete Items")
		dotNet.addEventHandler li "Click" deleteSetting
		li.enabled = id != 0
				
		lbxList.ContextMenuStrip = contextMenu	
	)
	

	on tabControl MouseDown a do 
	(			
		getList()		
	)
	
	on lbxList MouseUp a do (
		id = getSelectedId()
		
		
		bindContextMenu()
		
		
		if(id == 0) do (
			resetToDefaults()
			disableUI false
			return false
		)
		
		uid = lbxList.Items.Item[id - 1].tag
		
		getUVWSettings uid: uid
		disableUI true
	)
	
	
	
	on edtName changed v do (
		bad = #(";", "=", "|")
		
		for i in bad do v = substituteString v i ""			
		edtName.text = v
		
		quickSave()
		
		id = getSelectedId()
		if(id == 0) do return false
		
		lbxList.Items.Item[id - 1].Subitems.Item[1].Text = v
	)
	
	
		
	on btnAdd pressed do (		
		createNew()
	)
		
	on btnDel pressed do (
		deleteSetting()
	)
	
	on btnApplyMapping pressed do (
		id = getSelectedId()		
		if(id == 0) do return messageBox "Please select item from list!" title: "Warning!"
		if(selection.count == 0) do return messageBox "Please select object!" title: "Warning!"
				
		m = UvwMap()
		m.maptype = 4
		
		m.name = edtName.text
		
		m.length = spnLength.value
		m.width = spnWidth.value
		m.height = spnHeight.value
		
		m.utile = spnUTile.value
		m.vtile = spnVTile.value 
		m.wtile = spnWTile.value
		
		m.uflip = cbxUTileFlip.checked
		m.vflip = cbxVTileFlip.checked
		m.wflip = cbxWTileFlip.checked
		
		m.realWorldMapSize = cbxRealWorldMapSize.checked
		
		m.mapChannel = spnMapChannel.value
			
		try(modPanel.addModToSelection m ui:on) catch(
			messageBox "Can't apply UVW to selected objects!" title: "Error!"
			return false
		)
		
		obj = modPanel.getCurrentObject()
		
		rp = matrix3 1
		preRotateX rp spnRotateX.value 
		preRotateY rp spnRotateY.value  
		preRotateZ rp spnRotateZ.value 
		
		obj.gizmo.rotation = rp.rotationPart
			
		if(cbxAutoCollapse.checked) do try(maxOps.CollapseNodeTo $ 1 off)catch()
	)
	
	on spnLength changed v do quickSave()
	on spnWidth changed v do quickSave()
	on spnHeight changed v do quickSave()
	
	
	on spnUTile changed v do quickSave()
	on spnVTile changed v do quickSave()
	on spnWTile changed v do quickSave()
	
	on cbxUTileFlip changed v do quickSave()
	on cbxVTileFlip changed v do quickSave()
	on cbxWTileFlip changed v do quickSave()
	
	on cbxRealWorldMapSize changed v do quickSave()
	
	on spnMapChannel changed v do quickSave()
	
	
	on spnRotateX changed v do quickSave()
	on spnRotateY changed v do quickSave()
	on spnRotateZ changed v do quickSave()
	
	fn getControlsPosY = for i in _rUvwManagerMain.controls collect i.pos.y 
	
	global controlsPosY =#()
	global floaterHeightY = 835
	global rolloutHeightY = 0
	global lbxHeight = 0
	global floaterWindowPos = [0.0, 0.0]
	
	fn onResize y = (		
		h = y - floaterHeightY
		
		if(h < 0) do return false	
		
		useSettings "SIZEY" y "w"
		
		lbxList.height = lbxHeight + h
		_rUvwManagerMain.height = rolloutHeightY + h
		
		for i in 1 to _rUvwManagerMain.controls.count do (
			c = _rUvwManagerMain.controls[i]
			if(classOf c == dotNetControl) do continue			
			c.pos.y = controlsPosY[i] + h			
		)		
	)
	
	fn saveWindowPos =
	(
		useSettings "X"  floaterWindowPos[1] "w"
		useSettings "Y"  floaterWindowPos[2] "w"		
	)
	
	on _rUvwManagerMain open do (
		callbacks.removeScripts id:#postNew_BoxmapIt
		callbacks.removeScripts id:#postReset_BoxmapIt
		callbacks.removeScripts id:#filePostOpen_BoxmapIt
		
		callbacks.addScript #systemPostNew "rebuildListBoxmapIt()" id:#postNew_BoxmapIt
		callbacks.addScript #systemPostReset "rebuildListBoxmapIt()" id:#postReset_BoxmapIt
		callbacks.addScript #filePostOpen "rebuildListBoxmapIt()" id:#filePostOpen_BoxmapItl
		
		
		initDotNet()
		
		getList()
				
		disableUI false
		
		controlsPosY = getControlsPosY()
		rolloutHeightY = _rUvwManagerMain.height
		lbxHeight = lbxList.height
					
		sizey = useSettings "SIZEY" "float" "r"
		if(sizey > 0.0) do (
			onResize sizey
			fUVWMANAGER.size.y = sizey
		)	

		x = (useSettings "X" "float" "r")
		y = (useSettings "Y" "float" "r")

		if(x > 0.0 or y > 0.0) do (
			try(fUVWMANAGER.pos = [x, y]) catch()			
		)		
	)
	
	on _rUvwManagerMain close do (
		callbacks.removeScripts id:#postNew_BoxmapIt
		callbacks.removeScripts id:#postReset_BoxmapIt
		callbacks.removeScripts id:#filePostOpen_BoxmapIt
		
		saveWindowPos()
	)

	on _rUvwManagerMain resized s do onResize s[2]
		
	on _rUvwManagerMain moved p do (
		floaterWindowPos = p
	)
)

rollout _rAbout "About" 
(
	label lblName "" 
	label lblVer "" 
	
	label lblAuthor "" height: 30
	label lblCopy ""  height: 30
	
	on _rAbout open do
	(		
		i = getScriptInfo (getThisScriptFilename())
			
		lblName.caption = i[1]
		lblAuthor.caption = i[2]
		lblVer.caption = i[3]
		lblCopy.caption = i[6]
	)
)



addRollout _rUvwManagerMain fUVWMANAGER rolledUp:false border: false
addRollout _rAbout fUVWMANAGER rolledUp:true 