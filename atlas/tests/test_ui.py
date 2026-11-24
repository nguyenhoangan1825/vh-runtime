from pathlib import Path
import json,subprocess
import argparse,tempfile
P=Path(__file__).resolve().parent
parser=argparse.ArgumentParser()
parser.add_argument('--source',default=str(P/'source.lua'))
parser.add_argument('--luau',default=str(P.parent/'luau_tools/luau'))
args=parser.parse_args()
source=Path(args.source).read_text()
helper=source[source.index('-- Vietnamese display text + width-aware rows.'):source.index('\nlocal uiParts = {}')]
pre=r'''
local queue={}
local deferredCount=0
local task={defer=function(fn)deferredCount+=1;table.insert(queue,fn)end}
local function flush()
 local count=0
 while #queue>0 do count+=1;assert(count<1000,"Layout refresh feedback loop");local fn=table.remove(queue,1);fn()end
end
local function signal()
 local s={listeners={}}
 function s:Connect(fn)
  local c={Connected=true}
  self.listeners[c]=fn
  function c:Disconnect()self.Connected=false;s.listeners[self]=nil end
  return c
 end
 function s:Fire(...)
  local copy={};for c,fn in pairs(self.listeners)do copy[c]=fn end
  for c,fn in pairs(copy)do if c.Connected then fn(...)end end
 end
 return s
end
local UDim2={new=function(xs,xo,ys,yo)return {X={Scale=xs,Offset=xo},Y={Scale=ys,Offset=yo}}end}
function UDim2.fromOffset(x,y)return UDim2.new(0,x,0,y)end
function UDim2.fromScale(x,y)return UDim2.new(x,0,y,0)end
local UDim={new=function(s,o)return {Scale=s,Offset=o}end}
local Vector2={new=function(x,y)return {X=x,Y=y}end}
local Color3={new=function(...)return {...}end,fromRGB=function(...)return {...}end}
local Enum={TextTruncate={None="None"},TextXAlignment={Left="Left"},TextYAlignment={Top="Top",Center="Center"},Font={GothamBold="Bold",GothamSemibold="Semibold"},ScrollingDirection={Y="Y"}}
local methods={}
local function ancestry(object)
 object.AncestryChanged:Fire()
 for _,child in ipairs(object:GetChildren())do ancestry(child)end
end
local function descendantsAdded(parent,object)
 while parent do
  parent.DescendantAdded:Fire(object)
  for _,child in ipairs(object:GetDescendants())do parent.DescendantAdded:Fire(child)end
  parent=parent.Parent
 end
end
local function absolute(o)
 local size=o.Size;local parent=o.Parent
 local px,py=parent and parent.AbsoluteSize.X or 0,parent and parent.AbsoluteSize.Y or 0
 local value={X=px*size.X.Scale+size.X.Offset,Y=py*size.Y.Scale+size.Y.Offset}
 local old=o.AbsoluteSize
 rawget(o,"data").AbsoluteSize=value
 if old.X~=value.X or old.Y~=value.Y then
  o:GetPropertyChangedSignal("AbsoluteSize"):Fire()
  for _,child in ipairs(o:GetChildren())do absolute(child)end
 end
end
local Instance={}
function Instance.new(class)
 local data={ClassName=class,Name=class,Visible=true,Size=UDim2.new(0,100,0,20),Position=UDim2.new(0,0,0,0),AbsoluteSize={X=100,Y=20},ZIndex=1,Text="",TextSize=13,Font="Semibold",TextColor3={1,1,1},AncestryChanged=signal(),Destroying=signal(),MouseButton1Click=signal(),DescendantAdded=signal()}
 local o={data=data,signals={},children={}}
 data.MouseEnter=signal();data.MouseLeave=signal()
 return setmetatable(o,{__index=function(self,k)
  if methods[k]or data[k]~=nil then return methods[k]or data[k]end
  for _,child in ipairs(self.children)do if child.Name==k then return child end end
 end,__newindex=function(self,k,v)
  local old=data[k];if old==v then return end
  if k=="Parent"then
   if old then for i,child in ipairs(old.children)do if child==self then table.remove(old.children,i);break end end end
   data[k]=v
   if v then table.insert(v.children,self)end
   absolute(self);ancestry(self)
   if v then descendantsAdded(v,self)end
  else data[k]=v end
  if k=="Size"then absolute(self)end
  local sig=self.signals[k];if sig then sig:Fire()end
 end})
end
function methods:IsA(class)return self.ClassName==class or class=="GuiObject" and self.ClassName~="ScreenGui" and self.ClassName~="UICorner"end
function methods:GetPropertyChangedSignal(k)if not self.signals[k]then self.signals[k]=signal()end;return self.signals[k]end
function methods:GetChildren()return table.clone(self.children)end
function methods:GetDescendants()local a={};for _,x in ipairs(self.children)do table.insert(a,x);for _,y in ipairs(x:GetDescendants())do table.insert(a,y)end end;return a end
function methods:Clone()
 local clone=Instance.new(self.ClassName)
 for k,v in pairs(self.data)do
  if k~="Parent"and k~="ClassName"and not(type(v)=="table"and v.listeners)then clone[k]=v end
 end
 for _,child in ipairs(self:GetChildren())do child:Clone().Parent=clone end
 return clone
end
function methods:FindFirstChild(name)for _,x in ipairs(self.children)do if x.Name==name then return x end end end
function methods:Destroy()self.Destroying:Fire();for _,x in ipairs(self:GetChildren())do x:Destroy()end;self.Parent=nil end
local service={}
local measureCount=0
function service:GetTextSize(text,size,font,bounds)
 measureCount+=1
 local lines,width=0,0
 for line in string.gmatch(text.."\n","(.-)\n")do
  local measured=(utf8.len(line)or #line)*size*.56
  lines+=math.max(1,math.ceil(measured/bounds.X));width=math.max(width,math.min(bounds.X,measured))
 end
 return {X=width,Y=lines*(size+3)}
end
local function getService()return service end
local connections={Add=function(self,id,c)end}
local canceled={}
local threads={Cancel=function(self,id)table.insert(canceled,id)end}
local workspace={CurrentCamera={ViewportSize=Vector2.new(800,600)}}
local copied
local function setclipboard(s)copied=s end
local ui={}
'''
body=r'''
local passed={}
local function check(name,condition)assert(condition,name);table.insert(passed,name)end
local screen=Instance.new("ScreenGui");screen.Size=UDim2.fromOffset(800,600)
local box=Instance.new("Frame");box.Size=UDim2.fromOffset(260,500);box.Parent=screen
local function makeLabel(text,parent)
 local label=Instance.new("TextLabel");label.Text=text;label.Size=UDim2.new(1,0,0,17);label.Parent=parent;return label
end
local label=makeLabel("Field coverage: green = player inside; red = empty. Labels show current occupants.",box)
local binding=ui.ReadableRow(label,label,{minHeight=17});flush()
check("Long Vietnamese descriptions wrap and grow",label.Size.Y.Offset>30 and binding.visual.TextWrapped and binding.visual.Text==ui.viDictionary[label.Text])
local narrow=label.Size.Y.Offset;box.Size=UDim2.fromOffset(580,500);flush()
check("Widening the window reduces description height",label.Size.Y.Offset<narrow)
box.Size=UDim2.fromOffset(150,500);flush()
check("Narrowing the window reflows without cropping",binding.visual.Size.X.Offset<=150 and label.Size.Y.Offset>=narrow)
local raw=label.Text;label.Text="Preview works while farming is off. Stump visuals follow its trimmed idle footprint.";flush()
check("Dynamic text is translated without changing the raw value",label.Text~="" and label.Text~=binding.visual.Text and binding.visual.Text==ui.viDictionary[label.Text])
local switch=Instance.new("Frame");switch.Name="Switch";switch.Size=UDim2.new(1,0,0,20);switch.Parent=box
local title=makeLabel("Field Idle: Smileys & Combos Only",switch)
local sw=ui.ReadableRow(title,switch,{left=25,right=34,minHeight=25});flush()
check("Checkbox titles leave room for checkbox and help button",sw.visual.Position.X.Offset==25 and sw.visual.Size.X.Offset==91 and switch.Size.Y.Offset>25)
local callbacks=0
local help=ui.InlineHelp(switch,box,"test","Invisible collision borders prevent drifting out while gathering. They activate after entry and disappear during travel, combos and showers. Idle quadrants use their own borders; Stump follows its custom footprint.",function()callbacks+=1 end)
flush();local button=switch:FindFirstChild("Indicator")
check("Help starts closed in the same settings folder",not help.Visible and help.Parent==box)
button.MouseButton1Click:Fire();flush()
check("Help expands inline and stays visible",help.Visible and help.Size.Y.Offset>30 and button.Text=="−")
button.MouseButton1Click:Fire();flush()
check("Help closes without touching a setting callback",not help.Visible and button.Text=="?" and callbacks>=2)
local slider=Instance.new("Frame");slider.Size=UDim2.fromOffset(160,20);slider.Parent=box
local st=makeLabel("Minimum Time Left To Farm Precise (secs)",slider)
local sb=ui.ReadableRow(st,slider,{left=7,right=52});flush()
check("Long slider title reserves numeric value space",sb.visual.Size.X.Offset==101 and slider.Size.Y.Offset>20)
local function center(object)return object.Position.Y.Scale*object.Parent.AbsoluteSize.Y+object.Position.Y.Offset+object.Size.Y.Offset/2 end
local number=makeLabel("30",slider);number.Position=UDim2.new(1,-45,.5,-10);number.Size=UDim2.fromOffset(45,20)
check("Multiline slider caption and value share vertical centre",sb.visual.TextYAlignment=="Center" and math.abs(center(sb.visual)-center(number))<.01)
slider.Size=UDim2.fromOffset(400,slider.Size.Y.Offset);st.Text="Minimum Level";flush()
check("Single line slider caption aligns with the numeric value",math.abs(center(sb.visual)-center(number))<.01 and sb.visual.Text=="Level thấp nhất")
check("Help button is centred even on a wrapped switch row",math.abs(center(button)-switch.Size.Y.Offset/2)<.01)
for _,width in ipairs({80,85,90})do
 local nav=Instance.new("TextButton");nav.Text="        Webhook";nav.Size=UDim2.fromOffset(width,23);nav.Parent=box
 local nb=ui.ReadableRow(nav,nav,{left=27,right=3,minHeight=23,singleLine=true});flush()
 local bounds=service:GetTextSize(nb.visual.Text,nb.visual.TextSize,nb.visual.Font,Vector2.new(100000,100000))
 check("Webhook fits a single navigation row at width "..width,not nb.visual.TextWrapped and bounds.X<=nb.visual.Size.X.Offset and nav.Size.Y.Offset==23)
end
local action=Instance.new("TextButton");action.Text="Copy Stuck Report";action.Size=UDim2.fromOffset(91,20);action.Parent=box
local ab=ui.ReadableRow(action,action,{left=5,right=5});flush()
check("Action buttons retain API text and show Vietnamese",action.Text=="Copy Stuck Report" and ab.visual.Text=="Chép log khi bị đứng")
local wide=Instance.new("Frame");wide.Size=UDim2.fromOffset(400,20);wide.Parent=box;ui.ClampRowWidth(wide,box,400);flush()
check("Fixed-width controls shrink to fit their column",wide.Size.X.Offset==box.AbsoluteSize.X-12)
local popup=ui.ShowReadableNotice(screen,"test",string.rep("Mô tả dài cần đọc đủ. ",100));flush()
local scroll=popup:FindFirstChild("ScrollingFrame")
check("Long notices fit the screen and expose scrollable full text",popup.Size.X.Offset<=764 and popup.Size.Y.Offset<=530 and scroll.CanvasSize.Y.Offset>scroll.AbsoluteSize.Y)
check("Notice is not scheduled to vanish after four seconds",canceled[#canceled]=="Tooltip" and #queue==0)
local copy=popup:FindFirstChild("TextButton")
-- The first button is close; the second is copy.
for _,c in ipairs(popup:GetChildren())do if c:IsA("TextButton")and c.Text=="Chép mô tả"then c.MouseButton1Click:Fire()end end
check("Full descriptions can be copied",copied and string.find(copied,"Mô tả dài",1,true)~=nil)
label:Destroy();flush()
check("Destroyed rows release their layout bindings",ui.readableRows[label]==nil)
local same=makeLabel("Stable row",box);local layouts=0
local stable=ui.ReadableRow(same,same,{onLayout=function()layouts+=1 end});flush()
local beforeMeasure,beforeLayouts=measureCount,layouts
for _=1,20 do stable.Refresh();flush()end
check("Repeated identical refresh does not measure or scan folders",measureCount==beforeMeasure and layouts==beforeLayouts)
same.TextColor3=Color3.fromRGB(100,120,140);flush()
check("Colour change updates immediately without text measurement",stable.visual.TextColor3==same.TextColor3 and measureCount==beforeMeasure)
same.AncestryChanged:Fire();same:GetPropertyChangedSignal("AbsoluteSize"):Fire();flush()
check("Unchanged width and ancestry do not schedule text measurement",measureCount==beforeMeasure)
local copies=0;local owner={}
for _=1,100 do ui.QueueLayout(owner,function()copies+=1 end)end
flush();check("A burst of 100 folder refresh requests runs once",copies==1)
local firstHeight=ui.TextHeight("Shared measurement",200,"Semibold",13)
local saved=measureCount;ui.TextHeight("Shared measurement",200,"Semibold",13)
check("Shared font measurements are cached",measureCount==saved)
local view={enabled=true,worker=true,stopped=false,now=3601,privateId="private",mondo=true}
check("Hop status distinguishes an empty private ID",string.find(ui.MondoHopStatus({enabled=true,worker=true,now=3601,privateId="",mondo=true}),"PrivateServerId",1,true)~=nil)
view.mondo=false;check("Hop status distinguishes Mondo not detected",string.find(ui.MondoHopStatus(view),"chưa phát hiện",1,true)~=nil)
view.now=4600;check("Hop status distinguishes the time window",string.find(ui.MondoHopStatus(view),"ngoài khung",1,true)~=nil)
view.now=3601;view.session={hour=1,done=true}
check("Hop status distinguishes a completed hourly session",string.find(ui.MondoHopStatus(view),"đã kết thúc",1,true)~=nil)
view.session={hour=1,done=false};view.retrySeconds=9
local untouched=view.session.done
check("Hop status reports retries without changing the session",string.find(ui.MondoHopStatus(view),"9 giây",1,true)~=nil and view.session.done==untouched)
print("UI_CHECKS_PASSED",#passed)
'''
# Exercise the exact navigation function from the source, without constructing its folders.
a=source.index('\tui.AddTab = function(');b=source.index('\n\t\ttabApi.AddFolder = function(',a)
navigation=source[a:b]+'\n return tabApi\nend\n'
nav_setup='\nEnum.AutomaticSize={Y="Y"};Enum.ScrollBarInset={None="None"}\nEnum.EasingStyle={Linear="Linear"};Enum.EasingDirection={In="In"}\nlocal screen=Instance.new("ScreenGui");screen.Size=UDim2.fromOffset(900,600)\nlocal ImageLabel=Instance.new("Frame");ImageLabel.Size=UDim2.fromOffset(750,400);ImageLabel.Parent=screen\nlocal ScrollingFrame=Instance.new("ScrollingFrame");ScrollingFrame.Size=UDim2.fromOffset(90,400);ScrollingFrame.Parent=ImageLabel\nlocal isDesktop=true\nlocal activeTabButton,activeTabFrame,activeTabFrame2\nlocal TweenService={Create=function()return {Play=function()end}end}\nlocal TweenInfo={new=function()return {}end}\nlocal uiParts={}\nuiParts.tabbutton=Instance.new("TextButton");uiParts.tabbutton.Size=UDim2.fromOffset(90,23)\nlocal icon=Instance.new("ImageLabel");icon.Name="TabIcon";icon.Size=UDim2.fromOffset(12,12);icon.Parent=uiParts.tabbutton\nuiParts.tab=Instance.new("Frame");uiParts.tab.Size=UDim2.new(1,-12,1,0)\nui.ObserveReadableRows(screen)\n'
nav_body='\nui.AddTab("A","",false,true);ui.AddTab("B","",true,false);ui.AddTab("C","",false,false)\nfor _,name in ipairs({"A","B","C"})do\n for i=1,30 do\n  local label=Instance.new("TextLabel");label.Text="Một mô tả cần xuống hàng cho mục "..name..i\n  label.Size=UDim2.new(1,-12,0,17);label.Parent=uiParts[name]\n  ui.ReadableRow(label,label,{minHeight=17})\n end\nend\nflush()\nlocal buttons={}\nfor _,button in ipairs(ScrollingFrame:GetChildren())do if button:IsA("TextButton")then buttons[string.gsub(button.Text,"^ +","")]=button end end\nfor _,name in ipairs({"B","C","A"})do buttons[name].MouseButton1Click:Fire();flush()end\nlocal nativeBefore,defersBefore=measureCount,deferredCount\nlocal treeEvents=0\nscreen.DescendantAdded:Connect(function()treeEvents+=1 end)\nfor _=1,10 do for _,name in ipairs({"B","C","A"})do buttons[name].MouseButton1Click:Fire();flush()end end\nlocal warmCalls=measureCount-nativeBefore\nlocal warmDefers=deferredCount-defersBefore\ncheck("Thirty warm switches do not remeasure text or enqueue layout",warmCalls==0 and warmDefers==0)\ncheck("Tab switches do not reparent GUI descendants",treeEvents==0)\ncheck("Leaving a two-column tab hides both columns",not uiParts.B.Visible and not uiParts.B2.Visible and uiParts.A.Visible)\n'
assert 'Nền DarkBotGen'not in source
body=body.replace('print("UI_CHECKS_PASSED",#passed)','')
path=Path(tempfile.gettempdir())/'atlas_vi4_ui_regression.luau';path.write_text(pre+helper+body+nav_setup+navigation+nav_body+'\nprint("UI_CHECKS_PASSED",#passed)\n')
r=subprocess.run([args.luau,str(path)],capture_output=True,text=True)
print(r.stdout+r.stderr)
if r.returncode:raise SystemExit(r.returncode)
