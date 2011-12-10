-- LOAD PARTICLE LIB
local Particles = require("lib_particle_candy")

local physics = require("physics")
physics.start()
physics.setDrawMode( "normal" ) 
display.setStatusBar( display.HiddenStatusBar )
require "LevelHelperLoader"


---Analytics

require "analytics"

analytics.init( "484676566" )

loader = LevelHelperLoader:initWithContentOfFile("UInterface.plhs")
loader:enableRetina(true)
loader:instantiateSprites()
--loader:instantiateObjects(physics)

-- scaleConstant is used to decide how big the objects are
scaleConstant = 0.5


--------------------FUNCTIONS FOR DRAGGING-------------------------
local function dragBody( event )
	local body = event.target
	local phase = event.phase
	local x,y = event.x,event.y
	local stage = display.getCurrentStage()
	local parent = event.target.parent


	if "began" == phase then
		local c = audio.findFreeChannel()
		stage:setFocus( body, event.id )
		body.isFocus = true
		body.bodyType = "dynamic"
		
		playRandomSoundInArray(popSounds)
	--	audio.play(particleSound,{ loops = -1,fadeIn = 300})
	

		-- Create a temporary touch joint and store it in the object for later reference
		body.tempJoint = physics.newJoint( "touch", body, event.x, event.y )
		
		analytics.logEvent( body.uniqueName .. " is draged" )
		print ("logged ".. body.uniqueName)

	elseif body.isFocus then
		if "moved" == phase then

			-- Update the joint to track the touch
			body.tempJoint:setTarget( event.x, event.y )

		elseif "ended" == phase or "cancelled" == phase then
			stage:setFocus( body, nil )
			body.isFocus = false
			
			--audio.fadeOut({time=30 } )
				--playRandomSoundInArray(popSounds)
--	audio.play(puffSound)
			-- Remove the joint when the touch ends                 
			body.tempJoint:removeSelf()
			if body.isAttached == false then
				body.bodyType = "static"
			end
			
			
			
			if body.otherObject ~= nil and body.isAttached == false then
				if body.otherObject.parent == nil or body.otherObject.parent == body.parent.parentGroup then
					body.pivotJoint = physics.newJoint( "pivot", newObject, newObject.otherObject, event.x,event.y)
					--body.isSensor = false
					body.angularDamping = 5
					body.isFixedRotation = false
					body.bodyType = body.originalType
					body.isAttached = true
					audio.play(puffSound)
					analytics.logEvent( body.uniqueName .. " is connected with " .. body.otherObject.uniqueName )
					print (body.uniqueName .. " is connected with " .. body.otherObject.uniqueName)
					
					---starting explosion emitter
					expEmitter.x = event.x
					expEmitter.y = event.y
					Particles.StartEmitter("Explosion1",true)

					-- setting the rotation limits
					if body.parent.rotationLimits ~= nil then

						body.pivotJoint.isLimitEnabled = true
						body.pivotJoint:setRotationLimits(-body.parent.rotationLimits,body.parent.rotationLimits)
					end

				end
			end
			
			local isGarbage = garbageBounds.xMin <= x and garbageBounds.xMax >= x and garbageBounds.yMin <= y and garbageBounds.yMax >= y

			if isGarbage then
				body:removeSelf()
				audio.play(trashSound)
			end

		end
	end

	-- Stop further propagation of touch event
	return true
end



function attachOnCollision(self,event)
	local phase = event.phase
	--self.otherObject = event.other
	if "began"== phase then
		if (event.other.parent == self.otherGroup or self.otherGroup == nil) then
		self.otherObject = event.other
	end
	
	elseif "ended" == phase then
		self.otherObject = nil
		--		print "collisionEnded"
	end	
end

local function onTouchCreateNewObject( event )
	local t = event.target
	local phase = event.phase

	if "began" == phase then
		-- Make target the top-most object
		parent = t.parent
		--parent:insert( t )
		stage = display.getCurrentStage()
		stage:setFocus( t ,event.id)

		-- Spurious events can be sent to the target, e.g. the user presses 
		-- elsewhere on the screen and then moves the finger over the target.
		-- To prevent this, we add this flag. Only when it's true will "move"
		-- events be sent to the target.
		t.isFocus = true
		analytics.logEvent( t.uniqueName .. " is created" )

		-- Store initial position
		t.x0 = event.x - t.x
		t.y0 = event.y - t.y

		playRandomSoundInArray(t.objectSounds)

		-- create New Object
		newObject = loader:newObjectWithUniqueName(t.uniqueName,physics)
		newObject.originalType = newObject.bodyType
		newObject.bodyType = "dynamic"
		newObject.x = t.x
		newObject.y = t.y
		newObject.xScale = scaleConstant
		newObject.yScale= scaleConstant
		newObject.alpha = 1
		newObject.objectSounds= t.objectSounds
		newObject.isFixedRotation = true
		newObject.isSensor = true
		newObject.isAttached = false
		parent.newObjectGroup:insert(newObject)
		newObject.collision = attachOnCollision
		newObject:addEventListener("collision",newObject)

		local scaleFactor = 0.07

		oldScale = newObject.xScale
		newObject.xScale = newObject.xScale + scaleFactor
		newObject.yScale = newObject.yScale + scaleFactor
		newObject.tempJoint = physics.newJoint( "touch", newObject, event.x, event.y )
		newObject.otherObject = nil

		playRandomSoundInArray(popSounds)


		--	stage:setFocus( newObject, event.id )
		newObject.isFocus = true

	elseif newObject.isFocus then

		if "moved" == phase then

			newObject.tempJoint:setTarget( event.x, event.y )

		elseif "ended" == phase or "cancelled" == phase then

			local x,y = event.x, event.y


			local isGarbage = garbageBounds.xMin <= x and garbageBounds.xMax >= x and garbageBounds.yMin <= y and garbageBounds.yMax >= y

			if not isGarbage then
				newObject:addEventListener( "touch" , dragBody )
				newObject.xScale = oldScale
				newObject.yScale = oldScale
			else 
				newObject:removeSelf()
				audio.play(trashSound)
				analytics.logEvent( t.uniqueName .. " is garbage" )
			end
			display.getCurrentStage():setFocus( nil )
			newObject.isFocus = false

			-- Remove the joint when the touch ends                 
			newObject.tempJoint:removeSelf()
			newObject.bodyType = "static"
		
			local body = newObject
			


			if body.otherObject ~= nil and body.isAttached == false then
				if body.otherObject.parent == nil or body.otherObject.parent == body.parent.parentGroup then
					body.pivotJoint = physics.newJoint( "pivot", newObject, newObject.otherObject, event.x,event.y)
					--body.isSensor = false
					body.angularDamping = 5
					body.isFixedRotation = false
					body.bodyType = body.originalType
					body.isAttached = true
					
						---starting explosion emitter
						expEmitter.x = event.x
						expEmitter.y = event.y
						Particles.StartEmitter("Explosion1",true)
						
						analytics.logEvent( body.uniqueName .. " is connected with " .. body.otherObject.uniqueName .. " on creation" )
						print (body.uniqueName .. " is connected on creation with " .. body.otherObject.uniqueName)
						
						audio.play(puffSound) 

					-- setting the rotation limits
					if body.parent.rotationLimits ~= nil then

						body.pivotJoint.isLimitEnabled = true
						body.pivotJoint:setRotationLimits(-body.parent.rotationLimits,body.parent.rotationLimits)
					end

				end
			end
		end

	end
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
		
		playRandomSoundInArray(t.objectSounds)
		
		-- create New Object
		newSprite = loader:newSpriteWithUniqueName(t.uniqueName)
		newSprite.x = t.x
		newSprite.y = t.y
		newSprite.xScale = scaleConstant
		newSprite.yScale= scaleConstant
		newSprite.alpha = 1
		newSprite.objectSounds= t.objectSounds
		parent.newObjectGroup:insert(newSprite)
		
		local scaleFactor = 0.07
		
		oldScale = newSprite.xScale
		newSprite.xScale = newSprite.xScale + scaleFactor
		newSprite.yScale = newSprite.yScale + scaleFactor
		
		audio.play(popSound)
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
				newSprite.xScale = oldScale
				newSprite.yScale = oldScale

			else 
				newSprite:removeSelf()
				audio.play(trashSound)
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

			audio.play(popSound)
			playRandomSoundInArray(t.objectSounds)
			--playRandomSoundInArray(fartingSounds)

			-- Store initial position
			t.x0 = event.x - t.x
			t.y0 = event.y - t.y

			local scaleFactor = 0.07

			oldScale = t.xScale
			t.xScale = t.xScale + scaleFactor
			t.yScale = t.yScale + scaleFactor
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
					audio.play(trashSound)
				end

				display.getCurrentStage():setFocus( nil )
				t.xScale = oldScale
				t.yScale = oldScale
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
		analytics.logEvent( t.uniqueName .. " is pushed" )

		-- Spurious events can be sent to the target, e.g. the user presses 
		-- elsewhere on the screen and then moves the finger over the target.
		-- To prevent this, we add this flag. Only when it's true will "move"
		-- events be sent to the target.
		playRandomSoundInArray(robotSounds)
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
		
		-- play robot sound
	--	playRandomSoundInArray(robotSounds)
		
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
local function loadSoundsInArray(directory,extension)



	--- creating a local array of particular voices
	local array = {}
	for i = 1,20 do
		local sound = audio.loadSound(directory..i..extension)

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

---- creating arrays of voice samples
for i = 1,9 do
	local voiceArray = loadSoundsInArray("content/voices/voice"..i.."/",".mp3")
	voiceArrays[i] = voiceArray
end
print("voicesArrays "..#voiceArrays)
playRandomSoundInArray(voiceArrays[math.random(1,9)])

popSound = audio.loadSound("content/sounds/pop.mp3")


trashSound = audio.loadSound("content/sounds/trash.mp3")


robotSounds = loadSoundsInArray("content/sounds/robot/",".mp3")
print("robotSounds"..#robotSounds)

fartingSounds = loadSoundsInArray("content/sounds/farting/",".mp3")
print("farts"..#fartingSounds)

popSounds = loadSoundsInArray("content/sounds/pop/",".mp3")

particleSound = audio.loadSound("content/sounds/particle.mp3")

puffSound = audio.loadSound("content/sounds/puff/1.mp3")

----------------------localGarbageBIN---------------------------------------
garbage = display.newRoundedRect(225,650,750,100,20);
garbage:setFillColor(255,142,185,255)
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


----- setting angular min max for each group

heads_inScene.rotationLimits = 20
eyes_inScene.rotationLimits = 6
hat_inScene.rotationLimit = 5
hair_inScene.rotationLimits = 3
mouths_inScene.rotationLimits = 2
legsNArms_inScene.rotationLimits = 40



--- setting allowable interaction groups

eyes_inScene.parentGroup = heads_inScene
heads_inScene.parentGroup = body_inScene
legsNArms_inScene.parentGroup = body_inScene
hat_inScene.parentGroup = body_inScene
mouths_inScene.parentGroup = heads_inScene
hair_inScene.parentGroup = heads_inScene

groups = {}

-------------setting Angular damping for each group ------------------
-- first a general value for all
for i = 1,#groups do
	groups[i].angularDamping = 10 -- high number because unless spicified we don't want to much rotation
end
-- Special Cases
legsNArms_inScene.angularDamping = 1



---------------------LOADING EYES------------------------------------
local eyesUI = loader:spritesWithTag(5)--something is wrong here LevelHelper_TAG.IUEYES
local eyesGroup = display.newGroup()
eyesGroup.newObjectGroup = eyes_inScene

for i = 1,#eyesUI do
	eyesUI[i].alpha = 1
	--eyesUI[i]:addEventListener( "touch", onTouchCreateNewSprite ) -- for sprites
	eyesUI[i]:addEventListener( "touch", onTouchCreateNewObject )
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
	--headsUI[i]:addEventListener( "touch", onTouchCreateNewSprite )-- Sprites
	headsUI[i]:addEventListener( "touch", onTouchCreateNewObject )
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
	armsUI[i]:addEventListener( "touch", onTouchCreateNewObject )
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
	legsUI[i]:addEventListener( "touch", onTouchCreateNewObject )
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
	hairUI[i]:addEventListener( "touch", onTouchCreateNewObject )
	hairGroup:insert(hairUI[i])
end
print(hairGroup.numChildren)
hairGroup:setReferencePoint(display.CenterReferencePoint)

hairGroup.alpha = 0
hairGroup.isVisible = false

----------------------LOADING MOUTHS---------------------------------
---------------------------------------------------------
--local mouthUI = loader:spritesWithTag(10)--something is wrong here LevelHelper_TAG.IUEYES
local mouthUI = {}
local mouthGroup = display.newGroup()
mouthGroup.newObjectGroup = mouths_inScene

for i = 1, 10 do
	if (i<10) then
	mouthUI[i]=loader:spriteWithUniqueName("mouth_"..i)
elseif i == 10 then
	mouthUI[10]=loader:spriteWithUniqueName("mouth_a")
end

	if i<11 then
		mouthUI[i].objectSounds= voiceArrays[i]

	end
	mouthUI[i].alpha = 1
	mouthUI[i]:addEventListener( "touch", onTouchCreateNewObject )
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
	hatUI[i]:addEventListener( "touch", onTouchCreateNewObject )
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
	bodyUI[i]:addEventListener( "touch", onTouchCreateNewObject )
	bodyUI[i].physicsModel = "static"
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
--Particles.SetEmitterSound("E1", particleSound, 0, true, {loops = -1})

Particles.CreateEmitter("Explosion1", screenW*0.5, screenH*0.5, 180, false, false)

Particles.CreateParticleType ("Explosion", {
	imagePath		= "content/particle/explosion.png",
	imageWidth		= 64,	
	imageHeight		= 64,	
	velocityStart		= 65,	
	velocityVariation	= 65,
	velocityChange		= -1.0,
	directionVariation	= 330,
	alphaStart		= 0,		
	alphaVariation		= .25,		
	fadeInSpeed		= 2.0,	
	fadeOutSpeed		= -0.85,	
	fadeOutDelay		= 500,	
	scaleStart		= 0.01,	
	scaleVariation		= 0.2,
	scaleInSpeed		= 0.5,
	weight			= 0,	
	autoOrientation 	= true,	
	rotationVariation	= 360,
	killOutsideScreen	= true,	
	lifeTime		= 4000,  
	useEmitterRotation	= false,
	emissionShape		= 0,
	emissionRadius		= 30,
	blendMode		= "add",
	colorChange		= {-100,-100,-100},
	} )
	
	Particles.AttachParticleType("Explosion1", "Explosion"	, 25, 0,0) 
	
	expEmitter = Particles.GetEmitter("Explosion1")


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

