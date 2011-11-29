-- LOAD PARTICLE LIB
local Particles = require("lib_particle_candy")

local physics = require("physics")
physics.start()
physics.setDrawMode( "hybrid" ) 
display.setStatusBar( display.HiddenStatusBar )
require "LevelHelperLoader"


loader = LevelHelperLoader:initWithContentOfFile("UInterface.plhs")
loader:enableRetina(true)
loader:instantiateSprites()

-- scaleConstant is used to decide how big the objects are
scaleConstant = 0.5


--------------------FUNCTIONS FOR DRAGGING-------------------------
local function dragBody( event )
        local body = event.target
        local phase = event.phase
        local stage = display.getCurrentStage()
 
        if "began" == phase then
                stage:setFocus( body, event.id )
                body.isFocus = true
 
                -- Create a temporary touch joint and store it in the object for later reference
                body.tempJoint = physics.newJoint( "touch", body, event.x, event.y )
 
        elseif body.isFocus then
                if "moved" == phase then
                
                        -- Update the joint to track the touch
                        body.tempJoint:setTarget( event.x, event.y )
 
                elseif "ended" == phase or "cancelled" == phase then
                        stage:setFocus( body, nil )
                        body.isFocus = false
                        
                        -- Remove the joint when the touch ends                 
                        body.tempJoint:removeSelf()
                        
                end
        end
 
        -- Stop further propagation of touch event
        return true
end

local function onTouchCreateNewSprite( event )
    local t = event.target

	-- Print info about the event. For actual production code, you should
	-- not call this function because it wastes CPU resources.
	--printTouch(event)
	

	local phase = event.phase
	if "began" == phase then
		-- Make target the top-most object
		parent = t.parent
		--parent:insert( t )
		display.getCurrentStage():setFocus( t )

		-- Spurious events can be sent to the target, e.g. the user presses 
		-- elsewhere on the screen and then moves the finger over the target.
		-- To prevent this, we add this flag. Only when it's true will "move"
		-- events be sent to the target.
		t.isFocus = true

		-- Store initial position
		t.x0 = event.x - t.x
		t.y0 = event.y - t.y
		
		playRandomSoundInArray(t.voiceSounds)
		
		-- create New Object
		newSprite = loader:newSpriteWithUniqueName(t.uniqueName)
		newSprite.x = t.x
		newSprite.y = t.y
		newSprite.xScale = scaleConstant
		newSprite.yScale= scaleConstant
		newSprite.alpha = 1
		parent.newObjectGroup:insert(newSprite)
		
		--newSprite.
		
	elseif t.isFocus then
		if "moved" == phase then
			-- Make object move (we subtract t.x0,t.y0 so that moves are
			-- relative to initial grab point, rather than object "snapping").
			newSprite.x = event.x - t.x0
			newSprite.y = event.y - t.y0
		elseif "ended" == phase or "cancelled" == phase then
			
			local x,y = event.x, event.y
			--local isGarbage = true
			print ("garbageBounds xMin:" ..garbageBounds.xMin)
			print ("garbageBounds xMax:" ..garbageBounds.xMax)
			print ("garbageBounds yMin:" ..garbageBounds.yMin)
			print ("garbageBounds yMax:" ..garbageBounds.yMax)
			print ("x:"..x)
			print ("y:"..y)
			
			local isGarbage = garbageBounds.xMin <= x and garbageBounds.xMax >= x and garbageBounds.yMin <= y and garbageBounds.yMax >= y
			if not isGarbage then
			
			newSprite:addEventListener( "touch" , onTouch )
			
			
			else 
			newSprite:removeSelf()
			end
			display.getCurrentStage():setFocus( nil )
			
			
			
			t.isFocus = false
		end
	end
	end

function onTouch( event )
	local t = event.target

	-- Print info about the event. For actual production code, you should
	-- not call this function because it wastes CPU resources.
	--printTouch(event)

	local phase = event.phase
	if "began" == phase then
		-- Make target the top-most object
		local parent = t.parent
		--parent:insert( t )
		display.getCurrentStage():setFocus( t )

		-- Spurious events can be sent to the target, e.g. the user presses 
		-- elsewhere on the screen and then moves the finger over the target.
		-- To prevent this, we add this flag. Only when it's true will "move"
		-- events be sent to the target.
		t.isFocus = true

		-- Store initial position
		t.x0 = event.x - t.x
		t.y0 = event.y - t.y
	elseif t.isFocus then
		if "moved" == phase then
			-- Make object move (we subtract t.x0,t.y0 so that moves are
			-- relative to initial grab point, rather than object "snapping").
			t.x = event.x - t.x0
			t.y = event.y - t.y0
		elseif "ended" == phase or "cancelled" == phase then
		local x,y = event.x, event.y
			--local isGarbage = true
			print ("garbageBounds xMin:" ..garbageBounds.xMin)
			print ("garbageBounds xMax:" ..garbageBounds.xMax)
			print ("garbageBounds yMin:" ..garbageBounds.yMin)
			print ("garbageBounds yMax:" ..garbageBounds.yMax)
			print ("x:"..x)
			print ("y:"..y)
			
			local isGarbage = garbageBounds.xMin <= x and garbageBounds.xMax >= x and garbageBounds.yMin <= y and garbageBounds.yMax >= y
			if isGarbage then
			t:removeSelf()
			end
			
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false
		end
	end

	-- Important to return true. This tells the system that the event
	-- should not be propagated to listeners of any objects underneath.
	return true
end
----------------------UI FUNCTIONS---------------------------------
local function setFocusOnGroup ( event )
-- getting the target
 t = event.target
 local t = event.target
 local targetObject = t.targetObject

	-- Print info about the event. For actual production code, you should
	-- not call this function because it wastes CPU resources.
	--printTouch(event)
	

	local phase = event.phase
	if "began" == phase then
		-- Make target the top-most object
		local parent = t.parent
		--parent:insert( t )
		--display.getCurrentStage():setFocus( t )

		-- Spurious events can be sent to the target, e.g. the user presses 
		-- elsewhere on the screen and then moves the finger over the target.
		-- To prevent this, we add this flag. Only when it's true will "move"
		-- events be sent to the target.
		
	   --t.isFocus = true
	 
        t.xScale= 1.8
	    t.yScale= 1.8
	
      end
      
		
		if "moved" == phase then
		
		local bounds = t.stageBounds
		local x,y = event.x,event.y
		local isWhithinBounds = bounds.xMin <= x and bounds.xMax >= x and bounds.yMin <= y and bounds.yMax >= y
	
		display.getCurrentStage():setFocus( t )
		
		if isWhithinBounds then
		t.xScale= 1.8
		t.yScale= 1.8
		t.isFocus = true
		print"whithinbounds"
		--display.getCurrentStage():setFocus( t )
		
		end
		
		if not isWhithinBounds then
		t.xScale= 1.5
		t.yScale= 1.5
		t.isFocus = false
		print"offLimits"
		display.getCurrentStage():setFocus( nil )
		end
		end
		
			-- Make object move (we subtract t.x0,t.y0 so that moves are
			-- relative to initial grab point, rather than object "snapping").
			if "ended" == phase or "cancelled" == phase then
		 transition.to(currentGroup, {time = 1000, alpha=0, onComplete = hideObject(currentGroup)})
	        targetObject.isVisible = true
	        transition.to(targetObject, {time=1000, alpha=1} )
	        currentGroup = targetObject
	        t.xScale= 1.5
		    t.yScale= 1.5
			display.getCurrentStage():setFocus( nil )
			t.isFocus = false
		end

	
	return true
	
end
-------------------------------------------------------------------
---------------------FUNCTIONS FOR MINI ROBOT----------------------
function hideObject( object )
object.isVisible = false
end


local function changeIcon ( event)
-- getting the target
t = event.target
 local t = event.target
 local targetObject = t.targetObjectGroup
 setFocusOnGroup(event)
	-- Print info about the event. For actual production code, you should
	-- not call this function because it wastes CPU resources.
	--printTouch(event)
	

	local phase = event.phase
	if "began" == phase then
		-- Make target the top-most object
		local parent = t.parent
		--parent:insert( t )
		display.getCurrentStage():setFocus( t )

		-- Spurious events can be sent to the target, e.g. the user presses 
		-- elsewhere on the screen and then moves the finger over the target.
		-- To prevent this, we add this flag. Only when it's true will "move"
		-- events be sent to the target.
		t.isFocus = true

		-- Store initial position
		t.x0 = event.x - t.x
		t.y0 = event.y - t.y
	
	
	
	transition.to(t.parent, { time=1000, alpha=0, xScale= 0.5, yScale = 0.5, onComplete = hideObject(t.parent)} )
	
	-- set visibility
	targetObject.isVisible = true
	transition.to(targetObject,{ time=1000, alpha=1.0, xScale = 1, yScale = 1})
	
	
		
	
		elseif t.isFocus then
		if "moved" == phase then
			-- Make object move (we subtract t.x0,t.y0 so that moves are
			-- relative to initial grab point, rather than object "snapping").
			
		elseif "ended" == phase or "cancelled" == phase then
			display.getCurrentStage():setFocus( nil )
			
		    --transition.to(t.parent, {time=100, alpha=1.0} )
		    --transition.to(targetObject,{ time=100, alpha=0.0})
			t.isFocus = false
		end
	end
	
end


--------------------------LOADING SOUNDS ---------------------------------------
local function loadSoundsInArray(directory)

--- creating a local array of particular voices
local array = {}
    for i = 1,20 do
    local sound = audio.loadSound(directory..i..".aif")

    if sound == nil then break
    else 
table.insert(array,sound)
end
  
end
return array
end
function playRandomSoundInArray(array)
if array~=nil then
local r = math.random(#array)
sound = audio.play( array[r] )
end
end

voiceArrays = {}
for i = 1,8 do
local voiceArray = loadSoundsInArray("content/voices/voice"..i.."/")
voiceArrays[i] = voiceArray
end
print("voicesArrays "..#voiceArrays)
playRandomSoundInArray(voiceArrays[8])


----------------------localGarbageBIN---------------------------------------
garbage = display.newRoundedRect(200,650,750,100,20);
garbage:setFillColor(255,0,0,100)
garbage.strokeWidth = 4;
garbage:setStrokeColor(0,0,0,100)
garbageBounds = garbage.stageBounds
print ("garbageBounds " ..garbageBounds.xMin)

--------------------ARRAY to hold all Groups-------------------------
--------------------------Groups holding the right z pos in the scene-------------------



legsNArms_inScene = display.newGroup()
body_inScene = display.newGroup()
heads_inScene = display.newGroup()

hair_inScene = display.newGroup()
hat_inScene = display.newGroup()
mouths_inScene = display.newGroup()
eyes_inScene = display.newGroup()

groups = {}


---------------------LOADING EYES------------------------------------
local eyesUI = loader:spritesWithTag(5)--something is wrong here LevelHelper_TAG.IUEYES
local eyesGroup = display.newGroup()
eyesGroup.newObjectGroup = eyes_inScene

for i = 1,#eyesUI do
eyesUI[i].alpha = 1
eyesUI[i]:addEventListener( "touch", onTouchCreateNewSprite )
eyesGroup:insert(eyesUI[i])
end
print(eyesGroup.numChildren)
eyesGroup.alpha = 0
eyesGroup.isVisible = false

currentGroup = eyesGroup




----------------------LOADING HEADS---------------------------------
---------------------------------------------------------
local headsUI = loader:spritesWithTag(6)--something is wrong here LevelHelper_TAG.IUEYES
local headsGroup = display.newGroup()
headsGroup.newObjectGroup = heads_inScene

for i = 1,#headsUI do
headsUI[i].alpha = 1
headsUI[i]:addEventListener( "touch", onTouchCreateNewSprite )
headsGroup:insert(headsUI[i])
end
print(headsGroup.numChildren)
headsGroup:setReferencePoint(display.CenterReferencePoint)
--headsGroup.x = 585
--headsGroup.y = 687
headsGroup.alpha = 0
headsGroup.isVisible = false

----------------------LOADING ARMS---------------------------------
---------------------------------------------------------
local armsUI = loader:spritesWithTag(7)--something is wrong here LevelHelper_TAG.IUEYES
local armsGroup = display.newGroup()
armsGroup.newObjectGroup = legsNArms_inScene

for i = 1,#armsUI do
armsUI[i].alpha = 1
armsUI[i]:addEventListener( "touch", onTouchCreateNewSprite )
armsGroup:insert(armsUI[i])
end
print(armsGroup.numChildren)
armsGroup:setReferencePoint(display.CenterReferencePoint)
--headsGroup.x = 585
--headsGroup.y = 687
armsGroup.alpha = 0
armsGroup.isVisible = false


----------------------LOADING LEGS---------------------------------
---------------------------------------------------------
local legsUI = loader:spritesWithTag(8)--something is wrong here LevelHelper_TAG.IUEYES
local legsGroup = display.newGroup()
legsGroup.newObjectGroup = legsNArms_inScene

for i = 1,#legsUI do
legsUI[i].alpha = 1
legsUI[i]:addEventListener( "touch", onTouchCreateNewSprite )
legsGroup:insert(legsUI[i])
end
print(legsGroup.numChildren)
legsGroup:setReferencePoint(display.CenterReferencePoint)
--headsGroup.x = 585
--headsGroup.y = 687
legsGroup.alpha = 0
legsGroup.isVisible = false

----------------------LOADING LEGS---------------------------------
---------------------------------------------------------
local hairUI = loader:spritesWithTag(9)--something is wrong here LevelHelper_TAG.IUEYES
local hairGroup = display.newGroup()
hairGroup.newObjectGroup = hair_inScene



for i = 1,#hairUI do
hairUI[i].alpha = 1
hairUI[i]:addEventListener( "touch", onTouchCreateNewSprite )
hairGroup:insert(hairUI[i])
end
print(hairGroup.numChildren)
hairGroup:setReferencePoint(display.CenterReferencePoint)

hairGroup.alpha = 0
hairGroup.isVisible = false

----------------------LOADING MOUTHS---------------------------------
---------------------------------------------------------
local mouthUI = loader:spritesWithTag(10)--something is wrong here LevelHelper_TAG.IUEYES

local mouthGroup = display.newGroup()
mouthGroup.newObjectGroup = mouths_inScene



for i = 1,#mouthUI do
if i<#voiceArrays then
mouthUI[i].voiceSounds = voiceArrays[i]

end
mouthUI[i].alpha = 1
mouthUI[i]:addEventListener( "touch", onTouchCreateNewSprite )
mouthGroup:insert(mouthUI[i])
end
print("nr of mouths "..mouthGroup.numChildren)
mouthGroup:setReferencePoint(display.CenterReferencePoint)


mouthGroup.alpha = 0
mouthGroup.isVisible = false

----------------------LOADING HATS---------------------------------
---------------------------------------------------------
local hatUI = loader:spritesWithTag(11)--something is wrong here LevelHelper_TAG.IUEYES
local hatGroup = display.newGroup()
hatGroup.newObjectGroup = hat_inScene



for i = 1,#hatUI do
hatUI[i].alpha = 1
hatUI[i]:addEventListener( "touch", onTouchCreateNewSprite )
hatGroup:insert(hatUI[i])
end
print(hatGroup.numChildren)
hatGroup:setReferencePoint(display.CenterReferencePoint)

hatGroup.alpha = 0
hatGroup.isVisible = false

----------------------LOADING BODIES---------------------------------
---------------------------------------------------------
local bodyUI = loader:spritesWithTag(12)--something is wrong here LevelHelper_TAG.IUEYES
local bodyUIGroup = display.newGroup()
bodyUIGroup.newObjectGroup = body_inScene


for i = 1,#bodyUI do
bodyUI[i].alpha = 1
bodyUI[i]:addEventListener( "touch", onTouchCreateNewSprite )
bodyUIGroup:insert(bodyUI[i])
end
print(bodyUIGroup.numChildren)
bodyUIGroup:setReferencePoint(display.CenterReferencePoint)

bodyUIGroup.alpha = 0
bodyUIGroup.isVisible = false





--------------------------LOADING ROBOT UI----------------------------------------------

------------------------creating the groups---------------------------------------------
faceGroup = display.newGroup()
--bigHeadGroup = display.newGroup()

bodyGroup = display.newGroup()




------------------UI ICON USED FOR CHOOSING FACIAL FEATURES--------------





robotHat = loader:spriteWithUniqueName("RobotHat")
robotHat.targetObject = hatGroup
robotHat.alpha = 1
faceGroup:insert(robotHat)

robotHair = loader:spriteWithUniqueName("RobotHair")
robotHair.targetObject = hairGroup
robotHair.alpha = 1
faceGroup:insert(robotHair)

robotSmallBody = loader:spriteWithUniqueName("RobotSmallBody")
robotSmallBody.alpha = 1
robotSmallBody.targetObject = bodyUIGroup
faceGroup:insert(robotSmallBody)

robotBigHead = loader:spriteWithUniqueName("RobotBigHead")
robotBigHead.targetObject = headsGroup
robotBigHead.alpha = 1
faceGroup:insert(robotBigHead)

robotEyeR = loader:spriteWithUniqueName("RobotEyeR")
robotEyeR.targetObject = eyesGroup
robotEyeR.alpha = 1
faceGroup:insert(robotEyeR)

robotEyeL = loader:spriteWithUniqueName("RobotEyeL")
robotEyeL.targetObject = eyesGroup
robotEyeL.alpha = 1
faceGroup:insert(robotEyeL)

robotMouth = loader:spriteWithUniqueName("RobotMouth")
robotMouth.targetObject = mouthGroup
robotMouth.alpha = 1
faceGroup:insert(robotMouth)



faceGroup.alpha = 0

-- setting reference point has to be done after objects is loaded
faceGroup:setReferencePoint( display.BottomCenterReferencePoint )

------------------UI ICON USED FOR CHOOSING BODY PARTS ------------------

robotSmallHead = loader:spriteWithUniqueName("RobotSmallHead")
robotSmallHead.targetObject = headsGroup
bodyGroup:insert(robotSmallHead)


robotLegs = loader:spriteWithUniqueName("RobotLegs")
robotLegs.targetObject = legsGroup
bodyGroup:insert(robotLegs)

robotArmL = loader:spriteWithUniqueName("RobotArmL")
robotArmL.targetObject = armsGroup
bodyGroup:insert(robotArmL)

robotArmR = loader:spriteWithUniqueName("RobotArmR")
robotArmR.targetObject = armsGroup
bodyGroup:insert(robotArmR)

robotBody = loader:spriteWithUniqueName("RobotBody")
robotBody.targetObject = bodyUIGroup
bodyGroup:insert(robotBody)


-- setting reference point has to be done after objects is loaded
bodyGroup:setReferencePoint( display.BottomCenterReferencePoint )

-----adding extra targetObject to UI buttons
robotSmallBody.targetObjectGroup = bodyGroup
robotSmallHead.targetObjectGroup = faceGroup



-------------------------ADDING EVENT LISTENERS------------
robotSmallBody:addEventListener("touch",changeIcon)
robotSmallHead:addEventListener("touch",changeIcon)

----------------------------Event LISTENERS FOR CHOOSING THE MENUES-----------------
robotBody:addEventListener("touch",setFocusOnGroup)
robotHat:addEventListener("touch",setFocusOnGroup)
robotMouth:addEventListener("touch",setFocusOnGroup)
robotHair:addEventListener("touch",setFocusOnGroup)
robotLegs:addEventListener("touch",setFocusOnGroup)
robotArmR:addEventListener("touch",setFocusOnGroup)
robotArmL:addEventListener("touch",setFocusOnGroup)

robotEyeL:addEventListener("touch",setFocusOnGroup)
robotEyeR:addEventListener("touch",setFocusOnGroup)
robotBigHead:addEventListener("touch",setFocusOnGroup)




------------------------------------FOR PARTICLES--------------------------------------------------
local screenW = display.contentWidth
local screenH = display.contentHeight



-- DEFINE PARTICLE TYPE PROPERTIES
local Properties 				= {}
Properties.imagePath			= "colored_stars.png"
Properties.imageWidth			= 128	
Properties.imageHeight			= 128	
Properties.velocityStart		= 100	
Properties.velocityVariation	= 25
Properties.directionVariation	= 45
Properties.alphaStart			= 0		
Properties.alphaVariation		= .1		
Properties.fadeInSpeed			= 0.5	
Properties.fadeOutSpeed			= -1.0	
Properties.fadeOutDelay			= 1000	
Properties.scaleStart			= 0.1	
Properties.scaleVariation		= .65
Properties.scaleInSpeed			= 0.25
Properties.weight				= 0.2	
Properties.rotationVariation	= 360
Properties.rotationChange		= 90
Properties.emissionShape		= 0		
Properties.killOutsideScreen	= true	
Properties.lifeTime				= 2000 
Properties.useEmitterRotation	= false	
Properties.blendMode			= "add"
Particles.CreateParticleType ("FairyDust", Properties)

-- CREATE EMITTERS (NAME, SCREENW, SCREENH, ROTATION, ISVISIBLE, LOOP)
Particles.CreateEmitter("E1", screenW*0.5, screenH*0.5, 0, false, true)

-- FEED EMITTERS (EMITTER NAME, PARTICLE TYPE NAME, EMISSION RATE, DURATION, DELAY)
Particles.AttachParticleType("E1", "FairyDust" , 20, 9999999999999,0) 




local Emitter = Particles.GetEmitter("E1")



-- DETECT SCREEN TOUC AND START MOVING EMITTER
function ScreenTouched(event)

	if event.phase == "began" then
		Emitter.x = event.x
		Emitter.y = event.y
		-- TRIGGER THE EMITTERS
     Particles.StartEmitter("E1")
		
	elseif event.phase == "moved" then  
		Emitter.x = event.x
		Emitter.y = event.y
		
	elseif event.phase == "ended" then
		Particles.StopEmitter("E1")
		print(event.phase)
		
	end
	return true
end
Runtime:addEventListener("touch", ScreenTouched)


----------------------------------------------------------------
-- MAIN LOOP
----------------------------------------------------------------
local function main( event )

	-- UPDATE PARTICLES
	Particles.Update()
	
	
end
 
-- timer.performWithDelay( 33, main, 0 )
Runtime:addEventListener( "enterFrame", main )

