--[[
//  This file was created by LevelHelper
//  http://www.levelhelper.org
//
//  LevelHelperLoader.lua
//  Author: Bogdan Vladu
//  Copyright 2011 Bogdan Vladu. All rights reserved.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
//
//  This software is provided 'as-is', without any express or implied
//  warranty.  In no event will the authors be held liable for any damages
//  arising from the use of this software.
//  Permission is granted to anyone to use this software for any purpose,
//  including commercial applications, and to alter it and redistribute it
//  freely, subject to the following restrictions:
//  The origin of this software must not be misrepresented; you must not
//  claim that you wrote the original software. If you use this software
//  in a product, an acknowledgment in the product documentation would be
//  appreciated but is not required.
//  Altered source versions must be plainly marked as such, and must not be
//  misrepresented as being the original software.
//  This notice may not be removed or altered from any source distribution.
//  By "software" the author refers to this code file and not the application 
//  that was used to generate this file.
//
////////////////////////////////////////////////////////////////////////////////////////////////////////
//  Version history
//  ...
//  v3.1 Fixed a wb issue
//  v3.2 Added image subfolder
//  v3.3 Added setNext/PreviousFrameWithRepeatOnSprite and setFrameOnSprite(spr frameNo)
//  v3.3.1 fixed imageSubFolder
//  v3.4 fixed image names
//  v3.5 Added function LevelHelperLoader:spriteAForJointWithUniqueName(uniqueName)  and
//	           function LevelHelperLoader:spriteBForJointWithUniqueName(uniqueName) --LH--
//  v3.6 Fixed box2d shape issue on circle when on ipad/iphone4
//  v3.7 Changed speeds of parallax/animation/bezier path to be as close as test scene
//       the problem is that corrona approximates and it changes the values as it wants
//  v3.8 Added support for iPhone 4S retina
//  v3.9 Reverted changes to bezier path speed. It was not working correctly
////////////////////////////////////////////////////////////////////////////////////////////////////////
--]]

--[[ HELP - READ THIS TO GET STARTED

Please see the Corona Code Explain tutorial on www.levelhelper.org 

Prerequisite
	Add your level file (LevelHelper scene file) inside your project directory
	Add all the image files used in creating this level
	

INFORMATION THAT CAN BE FOUND ON A DISPLAY OBJECT (SPRITE) added by LevelHelper

-Available all the time
coronaSprite.numberOfFrames
coronaSprite.uniqueName
coronaSprite.tag
	
-Available if the sprite is inside a parallax
coronaSprite.LHParallaxRatioX
coronaSprite.LHParallaxRatioY
coronaSprite.LHParallaxContinuous
coronaSprite.LHParallaxDirection
coronaSprite.LHParallaxSpeed
coronaSprite.LHParallaxInitialX
coronaSprite.LHParallaxInitialY

-Available if the sprite is following a path
coronaSprite.bezierPathTimeInterval
coronaSprite.bezierPathPoints
coronaSprite.bezierPathInc
coronaSprite.bezierPathPreviousPoint
coronaSprite.bezierPathIsCyclic
coronaSprite.bezierPathRestartOtherEnd

-When getting a joint using jointWithUniqueName you can get the display objects of that joint using

joint.bodyA
joint.bodyB
--]]

LevelHelper_TAG =
{ 
	DEFAULT_TAG 	= 0,
	PRINCESS 			= 1,
	GROUND 			= 2,
	UIBIGHEAD 			= 3,
	IUSMALLHEAD 			= 4,
	NUMBER_OF_TAGS 	= 5
}

local LHGroup = nil
LevelHelperLoader = {} 

local lh_imageSubFolder = ""
local LHUpdate = true;
local enableRetina = false
local retinaRatio = 1.0 --used for retina - if retina enabled this will be 2.0
local convertLevel = true
local convertRatio = {x = 1.0, y = 1.0}
local LHGlobalAnims = nil --expose LHAnims to global level - do not access this in any way
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:initWithContentOfFile(levelFile) -- pass level file as string

	if levelFile == "" then
		print("Invalid level file given!")
	end
		
	LHUpdate = true;
	
	local object = {LHSprites = {},
					LHAnims = {},
					LHBeziers = {},
					LHParallax = {},
					LHJoints = {},
					LHWbInfo = {},
					sprites = {}, --array of LevelHelperSprite
					joints = {}, --array of LevelHelperJoint (more types)
					loadedSprites = {},
					loadedJoints = {},
					loadedPaths = {},
					loadedParallax = {},
					textureFilesUsed = {},
					LHGravityInfo = nil,
					LHGameWorldSize = nil,
					loadedWorldBoundaries = nil,
					loadedBezierBodies = {},
					notUsed = 1
					}
	setmetatable(object, { __index = LevelHelperLoader })  -- Inheritance
	
	object:loadLevelHelperSceneFile(levelFile, system.ResourceDirectory)
	object:enableRetina(false)
	    
  	if nil ~= string.find(system.getInfo("model"), "iPad")  or  
	   nil ~= string.find(system.getInfo("model"), "iPhone4") or 
	   nil ~= string.find(system.getInfo("architectureInfo"), "iPhone4,1")  then
			object:enableRetina(true)
    end


	return object

end

function LevelHelperLoader:enableRetina(value)
	enableRetina = value
	
	if value then
		retinaRatio = 2.0
	else
		retinaRatio = 1.0
	end
end
function LevelHelperLoader:convertLevel(value)
	convertLevel = value
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:initWithContentOfFileFromResourceDir(levelFile, resourceDirectory)

	if levelFile == "" then
		print("Invalid level file given!")
	end
	LHUpdate = true;
	local object = {LHSprites = {},
					LHAnims = {},
					LHBeziers = {},
					LHParallax = {},
					LHJoints = {},
					LHWbInfo = {},
					sprites = {}, --array of LevelHelperSprite
					joints = {}, --array of LevelHelperJoint (more types)
					loadedSprites = {},
					loadedJoints = {},
					loadedPaths = {},
					loadedParallax = {},
					textureFilesUsed = {},
					LHGravityInfo = nil,
					LHGameWorldSize = nil,
					loadedWorldBoundaries = nil,
					loadedBezierBodies = {},
					notUsed = 1
					}
	setmetatable(object, { __index = LevelHelperLoader })  -- Inheritance

	object:loadLevelHelperSceneFile(levelFile, resourceDirectory)
	object:enableRetina(false)
	
	if nil ~= string.find(system.getInfo("model"), "iPad")  or  
	   nil ~= string.find(system.getInfo("model"), "iPhone4") or 
	   nil ~= string.find(system.getInfo("architectureInfo"), "iPhone4,1")  then
			object:enableRetina(true)
    end

	return object
	
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:instantiateSprites()
	
	assert(self.notUsed,"\nASSERT\nYou can't use both methods \"instantiateSprites()\" and \"instantiateObjects()\".\nPlease use only one.\n\"instantiateSprites()\" - when you don't want physic\n\"instantiateObjects()\" - when you want physic")
	
	self.notUsed = nil
	
	--we need to first create the path so we can assign the path to sprite on creation
    for i = 1, #self.LHBeziers do
        local bezier = self.LHBeziers[i]
        if true == bezier["IsPath"] then
        	self:createBezierPathFromDictionary(bezier)
        end
    end
	
	LHGlobalAnims = self.LHAnims
	
	for i = 1, #self.LHSprites do
		local lhSprite = self.LHSprites[i]
		local my_sprite = LH_createSpriteInstance(lhSprite)
	
		self.loadedSprites[lhSprite["UniqueName"]] = {	tag = lhSprite["Tag"],
					 									coronaSprite = my_sprite }
					 									
		my_sprite.LHUniqueName = lhSprite["UniqueName"];
		
		if nil == string.find(lhSprite["PathName"], "None") then
			self:createPathOnSprite(my_sprite, lhSprite);
        end
	end
	
	for p = 1, #self.LHParallax do
		local currentParallax = self.LHParallax[p]
		if currentParallax["ContinuousScrolling"] then
			self:createParallaxScrolling(currentParallax)
		else
			self:createParallax(currentParallax)
		end
	end
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:instantiateSpritesInGroup(theGroup)

	LHGroup = theGroup
	
	self:instantiateSprites();
	
	LHGroup = nil
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:instantiateObjects(physics)

	assert(self.notUsed, "\nASSERT\nYou can't use both methods \"instantiateSprites()\" and \"instantiateObjects()\".\nPlease use only one.\n\"instantiateSprites()\" - when you don't want physic\n\"instantiateObjects()\" - when you want physic")
	
	self.notUsed = nil
	
	 --we need to first create the path so we can assign the path to sprite on creation
    for i = 1, #self.LHBeziers do
        local bezier = self.LHBeziers[i]
        if false == bezier["IsPath"] then
        	self:createBezierBodyFromDictionary(bezier, physics)
        else
        	self:createBezierPathFromDictionary(bezier)
      	end
    end

	LHGlobalAnims = self.LHAnims

	for i = 1, #self.LHSprites do
		local lhSprite = self.LHSprites[i]
		local my_sprite = nil
		if lhSprite["Type"] == 3 then -- no physic
			my_sprite = LH_createSpriteInstance(lhSprite)
		else
			my_sprite = lh_createObjectInstance(lhSprite, physics)
		end
		
		self.loadedSprites[lhSprite["UniqueName"]] = {	tag = lhSprite["Tag"],
					 									coronaSprite = my_sprite }
		my_sprite.LHUniqueName = lhSprite["UniqueName"];
		
		if nil == string.find(lhSprite["PathName"], "None") then
			self:createPathOnSprite(my_sprite, lhSprite);
        end
	end
	
	--add joints

	for j = 1, #self.LHJoints do
		local currentJoint = self.LHJoints[j]
		local joint = self:createJoint(physics, currentJoint);
		
		local objA = self.loadedSprites[currentJoint["ObjectA"]].coronaSprite;
		local objB = self.loadedSprites[currentJoint["ObjectB"]].coronaSprite;


		self.loadedJoints[currentJoint["UniqueName"]] = { coronaJoint = joint, bodyA = objA, bodyB = objB }
	end
	
	for p = 1, #self.LHParallax do
		local currentParallax = self.LHParallax[p]
		if currentParallax["ContinuousScrolling"] then
			self:createParallaxScrolling(currentParallax)
		else
			self:createParallax(currentParallax)
		end
	end
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setGravity(physics)

if self.LHGravityInfo.x == 0 and self.LHGravityInfo.y == 0 then
	print("LevelHelper WARNING: No gravity is defined in the scene but you are calling \"setGravity\" method.")
	return
end

	physics.setGravity( self.LHGravityInfo.x, -1* self.LHGravityInfo.y )
	
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setNextFrameAndRepeatOnSprite(coronaSprite)
	coronaSprite.currentFrame = coronaSprite.currentFrame + 1;
	if coronaSprite.currentFrame > coronaSprite.numberOfFrames then
		coronaSprite.currentFrame = 1;
	end
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setNextFrameAndRepeatOnSpriteWithUniqueName(uniqueName)
	coronaSprite = self:spriteWithUniqueName(uniqueName)
	self:setNextFrameAndRepeatOnSprite(coronaSprite)
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setFrameOnSprite(coronaSprite, frameNumber)
	coronaSprite.currentFrame = frameNumber;
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setNextFrameOnSprite(coronaSprite)
	coronaSprite.currentFrame = coronaSprite.currentFrame + 1;
	if coronaSprite.currentFrame > coronaSprite.numberOfFrames then
		coronaSprite.currentFrame = coronaSprite.numberOfFrames;
	end
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setNextFrameOnSpriteWithUniqueName(uniqueName)
	coronaSprite = self:spriteWithUniqueName(uniqueName)
	self:setNextFrameOnSprite(coronaSprite)
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setPreviousFrameAndRepeatOnSprite(coronaSprite)
	coronaSprite.currentFrame = coronaSprite.currentFrame - 1;
	if coronaSprite.currentFrame <= 0 then
		coronaSprite.currentFrame = coronaSprite.numberOfFrames;
	end
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setPreviousFrameAndRepeatOnSpriteWithUniqueName(uniqueName)
	coronaSprite = self:spriteWithUniqueName(uniqueName)
	self:setPreviousFrameAndRepeatOnSprite(coronaSprite)
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setPreviousFrameOnSprite(coronaSprite)

	coronaSprite.currentFrame = coronaSprite.currentFrame - 1;
	if coronaSprite.currentFrame <= 0 then
		coronaSprite.currentFrame =1;
	end
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:setPreviousFrameOnSpriteWithUniqueName(uniqueName)

coronaSprite = self:spriteWithUniqueName(uniqueName)
self:setPreviousFrameOnSprite(coronaSprite)

end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:pauseAnimationOnSprite(coronaSprite)
	if(nil ~= coronaSprite) then
		coronaSprite:pause()
	end
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:pauseAnimationOnSpriteWithUniqueName(uniqueName)
	coronaSprite = self:spriteWithUniqueName(uniqueName)
	self:pauseAnimationOnSprite(coronaSprite)
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:startAnimationOnSprite(coronaSprite)
	if(nil ~= coronaSprite) then
		coronaSprite:play()
	end
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:startAnimationOnSpriteWithUniqueName(uniqueName)
	coronaSprite = self:spriteWithUniqueName(uniqueName)
	self:startAnimationOnSprite(coronaSprite)
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
--corona sprite must already have an animation on it
function LevelHelperLoader:startAnimationWithUniqueNameOnSprite(animName, coronaSprite)
	coronaSprite:prepare(animName)
	coronaSprite:play()	
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:startAnimationWithUniqueNameOnSpriteWithUniqueName(animName, spriteUniqueName)	
	coronaSprite = self:spriteWithUniqueName(spriteUniqueName)
	self:startAnimationWithUniqueNameOnSprite(animName, coronaSprite)
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function moveParallax(coronaSpr)
		
if false == LHUpdate then
	return
end

	 local wbConv = {x = 1.0, y = 1.0}
    
    if convertLevel then
        wbConv = convertRatio;
    end


	local spr = coronaSpr
	
	local p = {x = spr.x, y = spr.y}
	direction = spr.LHParallaxDirection
	speed = spr.LHParallaxSpeed/0.7

---------------------------------------------------------------	
if direction == 0 then --left to right
	p.x = p.x + spr.LHParallaxRatioX*speed
	p.y = p.y + spr.LHParallaxRatioY*speed

if(0 < spr.LHParallaxInitialX)then
	if spr.x > display.contentWidth+spr.LHParallaxInitialX then
		spr.x = 0 - display.contentWidth + spr.LHParallaxInitialX
	end
else
	if spr.x > display.contentWidth+ (display.contentWidth + spr.LHParallaxInitialX) then
		spr.x = spr.LHParallaxInitialX
	end
end
	p.x = spr.x + spr.LHParallaxRatioX*speed
---------------------------------------------------------------
elseif direction == 1 then --right to left
	p.x = p.x - spr.LHParallaxRatioX*speed
	p.y = p.y - spr.LHParallaxRatioY*speed
if(display.contentWidth > spr.LHParallaxInitialX) then
	if(spr.x < -display.contentWidth + spr.LHParallaxInitialX) then
		spr.x = display.contentWidth + spr.LHParallaxInitialX
	end
else
	if(spr.x < -display.contentWidth  + (spr.LHParallaxInitialX - display.contentWidth)) then
		spr.x = spr.LHParallaxInitialX
	end
end
	p.x = spr.x - spr.LHParallaxRatioX*speed;
---------------------------------------------------------------
elseif direction == 2 then -- up to down
	p.x = p.x + spr.LHParallaxRatioX*speed
	p.y = p.y + spr.LHParallaxRatioY*speed

if(spr.LHParallaxInitialY > 0)then
	if display.contentHeight + spr.LHParallaxInitialY < spr.y then
		spr.y = 0 - display.contentHeight + spr.LHParallaxInitialY
	end
else
	if spr.y > display.contentHeight + (display.contentHeight + spr.LHParallaxInitialY) then
		spr.y = spr.LHParallaxInitialY
	end
end
p.y = spr.y + spr.LHParallaxRatioY*speed
---------------------------------------------------------------
elseif direction == 3 then --down to up
	p.x = p.x - spr.LHParallaxRatioX*speed
	p.y = p.y - spr.LHParallaxRatioY*speed

if(spr.LHParallaxInitialY < display.contentHeight)then
	if -display.contentHeight + spr.LHParallaxInitialY > spr.y then
		spr.y = display.contentHeight + spr.LHParallaxInitialY
	end
else
	if spr.y < -display.contentHeight + (spr.LHParallaxInitialY - display.contentHeight) then
		spr.y = spr.LHParallaxInitialY
	end
end
	p.y = spr.y - spr.LHParallaxRatioY*speed
end
---------------------------------------------------------------	
	local moveSprToNextPt = function() return moveParallax( coronaSpr ) end
	transition.to( spr, { time= coronaSpr.LHParallaxSpeed/3000, 
								x=p.x, 
								y=p.y,
								onComplete=moveSprToNextPt } )
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:createParallaxScrolling(parallaxDict)

	local continuous 	= parallaxDict["ContinuousScrolling"]
	local direction 	= parallaxDict["Direction"]
	local speed 		= parallaxDict["Speed"]
	local uniqueName 	= parallaxDict["UniqueName"]
	local spritesInParallax = parallaxDict["Sprites"]
	
	for i = 1, #spritesInParallax do
		local curSprInfo = spritesInParallax[i]
		
		local ratioX = curSprInfo["RatioX"]
		local ratioY = curSprInfo["RatioY"]
		local sprName= curSprInfo["SpriteName"]
		
		local localSprite = self:spriteWithUniqueName(sprName)
				
		localSprite.LHParallaxRatioX = ratioX
		localSprite.LHParallaxRatioY = ratioY
		localSprite.LHParallaxContinuous = continuous
		localSprite.LHParallaxDirection = direction
		localSprite.LHParallaxSpeed = speed
		localSprite.LHParallaxInitialX = localSprite.x
		localSprite.LHParallaxInitialY = localSprite.y
		
		local performParallaxMovement = function() return moveParallax( localSprite ) end
		timer.performWithDelay(1.0/60.0, performParallaxMovement, 1)   		
	end	
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:translateParallaxWithUniqueName(uniqueParallaxName, deltaX, deltaY)

	local parallaxSprites = self.loadedParallax[uniqueParallaxName]
	
	for i = 1, #parallaxSprites do
	
		local localSprite = parallaxSprites[i]
		
		localSprite.x = localSprite.x + deltaX * localSprite.LHParallaxRatioX
		localSprite.y = localSprite.y + deltaY * localSprite.LHParallaxRatioY
	end
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:createParallax(parallaxDict)

	local continuous 	= parallaxDict["ContinuousScrolling"]
	local direction 	= parallaxDict["Direction"]
	local speed 		= parallaxDict["Speed"]
	local uniqueName 	= parallaxDict["UniqueName"]
	local spritesInParallax = parallaxDict["Sprites"]
	
	local parallaxSprites = {}
	for i = 1, #spritesInParallax do
		local curSprInfo = spritesInParallax[i]
		
		local ratioX = curSprInfo["RatioX"]
		local ratioY = curSprInfo["RatioY"]
		local sprName= curSprInfo["SpriteName"]
		
		local localSprite = self:spriteWithUniqueName(sprName)
				
		localSprite.LHParallaxRatioX = ratioX
		localSprite.LHParallaxRatioY = ratioY
		localSprite.LHParallaxContinuous = continuous
		localSprite.LHParallaxDirection = direction
		localSprite.LHParallaxSpeed = speed
		localSprite.LHParallaxInitialX = localSprite.x
		localSprite.LHParallaxInitialY = localSprite.y

		parallaxSprites[#parallaxSprites +1] = localSprite;
	end	

	self.loadedParallax[uniqueName] = parallaxSprites
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function pointOnCurve(p1, p2, p3, p4, t)
	local var1
	local var2
	local var3
    local vPoint = {x = 0.0, y = 0.0}
    
    var1 = 1 - t
    var2 = var1 * var1 * var1
    var3 = t * t * t
    vPoint.x = var2*p1.x + 3*t*var1*var1*p2.x + 3*t*t*var1*p3.x + var3*p4.x
    vPoint.y = var2*p1.y + 3*t*var1*var1*p2.y + 3*t*t*var1*p3.y + var3*p4.y

	return vPoint;
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function inversePoints(points)

	invertedPoints = {}
	for i = #points,1,-1 do
		invertedPoints[#invertedPoints+1] = points[i]
	end
	
	return invertedPoints
end
----------------------------------------------------------------------------------------------------
function moveAlongPath(coronaSpr)

	local p = {x = 0, y = 0};
	
	local inc = coronaSpr.bezierPathInc;
	p.x = coronaSpr.bezierPathPoints[inc].x;
	p.y = coronaSpr.bezierPathPoints[inc].y;
	coronaSpr.bezierPathInc = inc + 1;	
		
	if inc == #coronaSpr.bezierPathPoints and coronaSpr.bezierPathIsCyclic then
	
		if false == coronaSpr.bezierPathRestartOtherEnd then
			coronaSpr.bezierPathPoints = inversePoints(coronaSpr.bezierPathPoints)
		end
		inc = 1
		coronaSpr.bezierPathInc = 1
	end
	
	local moveSprToNextPt = function() return moveAlongPath( coronaSpr ) end
	
	transition.to( coronaSpr, { time= coronaSpr.bezierPathTimeInterval*1000,--/0.7, 
								--transition= easing.linear
								x=p.x, 
								y=p.y,
								onComplete=moveSprToNextPt } )
	
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:createPathOnSprite(coronaSprite, spriteProp)

	if nil == coronaSprite then
		return
	end
	
	if nil == spriteProp then
		return
	end

	local uniqueName = spriteProp["PathName"];
    local isCyclic = 	spriteProp["PathIsCyclic"]
    local pathSpeed = 	spriteProp["PathSpeed"]
    local startPoint = 	spriteProp["PathStartPoint"] --0 is first 1 is end
	local pathOtherEnd = spriteProp["PathOtherEnd"] --false means will restart where it finishes
    
    local pathInfo = self.loadedPaths[uniqueName]
    local points = pathInfo.points
   	local curveNo = pathInfo.noOfCurves

   if nil == points then
   		return
   end
   
   local interval = pathSpeed/#points
   
   coronaSprite.bezierPathTimeInterval = interval
   coronaSprite.bezierPathPoints = points
   coronaSprite.bezierPathInc = 1
   coronaSprite.bezierPathPreviousPoint = {x = coronaSprite.x, y = coronaSprite.y}
   coronaSprite.bezierPathIsCyclic = isCyclic
   coronaSprite.bezierPathRestartOtherEnd = pathOtherEnd
   
   	if 1 == startPoint then
			coronaSprite.bezierPathPoints = inversePoints(coronaSprite.bezierPathPoints)
	end

	local myTimerFunc = function() return moveAlongPath( coronaSprite ) end
	timer.performWithDelay(1.0/60.0, myTimerFunc, 1.0)   
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:createBezierPathFromDictionary(bezierDict)

	 local wbConv = {x = 1.0, y = 1.0}
    
    if convertLevel then
        wbConv = convertRatio;
    end

	local curvesInShape = bezierDict["Curves"]
	local bezierUniqueName = bezierDict["UniqueName"]
	local MAX_STEPS = 25;

	pointsInPath = {}
	for i= 1, #curvesInShape do
		local curve = curvesInShape[i]
    	local endCtrlPt   = pointFromString(curve["EndControlPoint"])
        local startCtrlPt = pointFromString(curve["StartControlPoint"])
        local endPt       = pointFromString(curve["EndPoint"])
        local startPt     = pointFromString(curve["StartPoint"])
  
  		if false == bezierDict["IsSimpleLine"] then
	  		
            local t = 0.0
            while ( t >= 0.0 and  t <= 1 + (1.0 / MAX_STEPS) ) do
            	local vPoint = pointOnCurve(startPt, startCtrlPt, endCtrlPt, endPt, t)
				vPoint.x = vPoint.x*wbConv.x
				vPoint.y = vPoint.y*wbConv.y
				pointsInPath[#pointsInPath+1] = vPoint                

        		t = t + 1.0 / MAX_STEPS
            end
  		else
  		
	  		startPt.x = startPt.x*wbConv.x
			startPt.y = startPt.y*wbConv.y

  			pointsInPath[#pointsInPath+1] = startPt
  			
  			if i == #curvesInShape-1 then
  		  		endPt.x = endPt.x*wbConv.x
				endPt.y = endPt.y*wbConv.y

	  			pointsInPath[#pointsInPath+1] = endPt
  			end
  		end
	end
	
	pathInfo = { points = pointsInPath, noOfCurves = #curvesInShape}
	
	self.loadedPaths[bezierUniqueName] = pathInfo;
end
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:createBezierBodyFromDictionary(bezierDict, physics)

	 local wbConv = {x = 1.0, y = 1.0}
    
    if convertLevel then
        wbConv = convertRatio;
    end

	local curvesInShape = bezierDict["Curves"]
	
	local ldensity = bezierDict["Density"]
	local lfriction = bezierDict["Friction"]
	local lrestitution = bezierDict["Restitution"]
		
    local collisionFilter = { 	categoryBits = bezierDict["Category"], 
								maskBits = bezierDict["Mask"], 
								groupIndex =  bezierDict["Group"] } 

	local MAX_STEPS = 25;

	for i= 1, #curvesInShape do
		local curve = curvesInShape[i]
    	local endCtrlPt   = pointFromString(curve["EndControlPoint"])
        local startCtrlPt = pointFromString(curve["StartControlPoint"])
        local endPt       = pointFromString(curve["EndPoint"])
        local startPt     = pointFromString(curve["StartPoint"])
  
  		if false == bezierDict["IsSimpleLine"] then
	  		
  			local prevPoint
            local firstPt = true
            
            local t = 0.0
            while ( t >= 0.0 and  t <= 1 + (1.0 / MAX_STEPS) ) do
            	local vPoint = pointOnCurve(startPt, startCtrlPt, endCtrlPt, endPt, t)
				            
                if false == firstPt then
	                local borderTop = display.newLine( 0,0, 0,0 )
  					shape = { prevPoint.x*wbConv.x, prevPoint.y*wbConv.y, vPoint.x*wbConv.x, vPoint.y*wbConv.y }
					physics.addBody( borderTop, "static", { density=ldensity, 
															friction=lfriction, 
															bounce=lrestitution, 
															shape=shape, 
															filter = collisionFilter} )
					
					borderTop.isSensor = bezierDict["IsSenzor"]
					
					borderTop.tag = bezierDict["Tag"];
					
					if LHGroup ~= nil then
						LHGroup:insert(borderTop)
					end
					
					self.loadedBezierBodies[#self.loadedBezierBodies +1] = borderTop
                end
                
                prevPoint = vPoint;
                firstPt = false;
        
        		t = t + 1.0 / MAX_STEPS
            end
  		else
	  		local borderTop = display.newLine( 0,0, 0,0 )
  			shape = { startPt.x*wbConv.x,startPt.y*wbConv.y, endPt.x*wbConv.x,endPt.y*wbConv.y }
			physics.addBody( borderTop, "static", { density=ldensity, 
													friction=lfriction, 
													bounce=lrestitution, 
													shape=shape, 
													filter = collisionFilter } )
			borderTop.isSensor = bezierDict["IsSenzor"]
			
			borderTop.tag = bezierDict["Tag"];
			
			self.loadedBezierBodies[#self.loadedBezierBodies +1] = borderTop
  		end
	end
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:instantiateObjectsInGroup(physics, theGroup)

	LHGroup = theGroup

	self:instantiateObjects(physics)
	
	LHGroup = nil
	
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:hasWorldBoundaries()

if #self.LHWbInfo == 1 then

	local wbInfo = self.LHWbInfo[1];
    local rect = rectFromString(wbInfo["WBRect"])
   
   	if rect.size.width == 0 or rect.size.height == 0 then
   		return false
   	end
   	
	return true
end

return false
	
end
----------------------------------------------------------------------------------------------------
----------------------------------------------------------------------------------------------------
function LevelHelperLoader:getGameWorldRect()
	local wbConv = {x = 1.0, y = 1.0}
    
    if convertLevel then
        wbConv = convertRatio;
    end
	local rect = self.LHGameWorldSize;
	
	return {origin = {x = rect.origin.x*wbConv.x, y = rect.origin.y*wbConv.y}, 
			size = {width = rect.size.width*wbConv.x, height = rect.size.height*wbConv.y}}
end

function LevelHelperLoader:getWorldBoundariesRect()

	if false == self:hasWorldBoundaries() then
		print("LevelHelper ERROR: Please create world boundaries inside LevelHelper in order to call \"getWorldBoundariesRect\" method.")
		return
	end

	local wbConv = {x = 1.0, y = 1.0}
    
    if convertLevel then
        wbConv = convertRatio;
    end
    
	local wbInfo = self.LHWbInfo[1];
    local rect = rectFromString(wbInfo["WBRect"])
    
	return {origin = {x = rect.origin.x*wbConv.x, y = rect.origin.y*wbConv.y}, 
			size = {width = rect.size.width*wbConv.x, height = rect.size.height*wbConv.y}}
end

function LevelHelperLoader:createWorldBoundaries(physics)
	self.loadedWorldBoundaries = self:createWorldBoundariesWithTag(physics, 0, 0, 0, 0)
end
function LevelHelperLoader:createWorldBoundariesWithTag(physics, tagTop, tagLeft, tagRight, tagBottom)

	if false == self:hasWorldBoundaries() then
		print("LevelHelper ERROR: Please create world boundaries inside LevelHelper in order to call \"createWorldBoundaries\" method.")
		return
	end


    local wbConv = {x = 1.0, y = 1.0}
    
    if convertLevel then
        wbConv = convertRatio;
    end
    
    local wbInfo = self.LHWbInfo[1];
	
    local friction = wbInfo["Friction"]
    local density = wbInfo["Density"]
    local restitution = wbInfo["Restitution"]
    local rect = rectFromString(wbInfo["WBRect"])
    
    
    local collisionFilter = { 	categoryBits = wbInfo["Category"], 
								maskBits = wbInfo["Mask"], 
								groupIndex = wbInfo["Group"] } 
								
    local borderTop = display.newLine( 0,0, 0,0 )
    borderTop.tag = tagTop
  	shape = { 	rect.origin.x*wbConv.x, 
  				rect.origin.y*wbConv.y, 
  				(rect.origin.x + rect.size.width)*wbConv.x, 
  				rect.origin.y*wbConv.y }
	physics.addBody( borderTop, "static", { density=density, 
											friction=friction, 
											bounce=restitution, 
											shape=shape, 
											filter = collisionFilter } )

    local borderLeft = display.newLine( 0,0, 0,0 )
    borderLeft.tag = tagLeft
  	shape = { 	rect.origin.x*wbConv.x, 
  				rect.origin.y*wbConv.y, 
  				rect.origin.x*wbConv.x, 
  				(rect.origin.y + rect.size.height)*wbConv.y}
	physics.addBody( borderLeft, "static", { density=density, 
											friction=friction, 
											bounce=restitution, 
											shape=shape, 
											filter = collisionFilter } )

    local borderRight = display.newLine( 0,0, 0,0 )
    borderRight.tag = tagRight
  	shape = { 	(rect.origin.x + rect.size.width)*wbConv.x,
  				rect.origin.y*wbConv.y, 
  				(rect.origin.x + rect.size.width)*wbConv.x, 
  				(rect.origin.y + rect.size.height)*wbConv.y}
	physics.addBody( borderRight, "static", { density=density, 
											friction=friction, 
											bounce=restitution, 
											shape=shape, 
											filter = collisionFilter } )

    local borderBottom = display.newLine( 0,0, 0,0 )
    borderBottom.tag = tagBottom
  	shape = { 	rect.origin.x*wbConv.x, 
  				(rect.origin.y + rect.size.height)*wbConv.y, 
	  			(rect.origin.x + rect.size.width)*wbConv.x, 
  				(rect.origin.y + rect.size.height)*wbConv.y}
	physics.addBody( borderBottom, "static", { density=density, 
											friction=friction, 
											bounce=restitution, 
											shape=shape, 
											filter = collisionFilter } )
			
	return {borderTop, borderLeft, borderRight, borderBottom}
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:spriteWithUniqueName(uniqueName)

	if nil ~= self.loadedSprites[uniqueName] then
		return self.loadedSprites[uniqueName].coronaSprite;
	end
	
	return nil
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:isSpriteWithUniqueNameInLevel(uniqueName)

	if nil ~= self.loadedSprites[uniqueName] then
		return true
	end
	
	return false
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:jointWithUniqueName(uniqueName) --LH--

	if nil ~= self.loadedJoints[uniqueName] then
		return self.loadedJoints[uniqueName].coronaJoint;
	end
	
	return nil
end

function LevelHelperLoader:spriteAForJointWithUniqueName(uniqueName) --LH--

	if nil ~= self.loadedJoints[uniqueName] then
		return self.loadedJoints[uniqueName].bodyA;
	end
	
	return nil
end

function LevelHelperLoader:spriteBForJointWithUniqueName(uniqueName) --LH--

	if nil ~= self.loadedJoints[uniqueName] then
		return self.loadedJoints[uniqueName].bodyB;
	end
	
	return nil
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:isJointWithUniqueNameInLevel(uniqueName) --LH--

	if nil ~= self.loadedJoints[uniqueName] then
		return true
	end
	
	return false
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:spritesWithTag(tag)

	local foundSprites = {}
	
	for k, v in pairs (self.loadedSprites) do
		if tag == v.tag then
			table.insert(foundSprites, v.coronaSprite)
  		end
	end
		
	return foundSprites
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:newSpriteWithUniqueName(uniqueName)

	for i = 1, #self.LHSprites do
		local spr = self.LHSprites[i];
		if nil ~= string.find(uniqueName, spr["UniqueName"]) then
			return LH_createSpriteInstance(self.LHSprites[i])
		end
	end
	
	return nil
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:newObjectWithUniqueName(uniqueName, physics)


	for i = 1, #self.LHSprites do		
		local spr = self.LHSprites[i];
		if nil ~= string.find(uniqueName, spr["UniqueName"]) then -- self.LHSprites[i].uniqueName) then
			return lh_createObjectInstance(self.LHSprites[i], physics)
		end
	end
	
	return nil
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:removeSpriteWithUniqueName(uniqueName)

	if nil ~= self.loadedSprites[uniqueName] then
	
		---------------------------------------------------
		--IF SPRITE REMOVED ALREADY 
		---------------------------------------------------
		if nil ~= self.loadedSprites[uniqueName].coronaSprite then
			self.loadedSprites[uniqueName].coronaSprite:removeSelf()
			self.loadedSprites[uniqueName].coronaSprite = nil
		end
		---------------------------------------------------
		self.loadedSprites[uniqueName] = nil;
	end
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:removeAllSprites()

	LHUpdate = false;
	for k, v in pairs (self.loadedSprites) do		
		if v ~= nil then
			self:removeSpriteWithUniqueName(k)
		end
	end

if nil ~= self.loadedWorldBoundaries then	
	self.loadedWorldBoundaries[1]:removeSelf();
	self.loadedWorldBoundaries[2]:removeSelf();
	self.loadedWorldBoundaries[3]:removeSelf();
	self.loadedWorldBoundaries[4]:removeSelf();
end

for i = 1, #self.loadedBezierBodies do
	self.loadedBezierBodies[i]:removeSelf();
end

	self:removeAllJoints()
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:removeJointWithUniqueName(uniqueName)

	if nil ~= self.loadedJoints[uniqueName] then
		self.loadedJoints[uniqueName].coronaJoint:removeSelf()
		self.loadedJoints[uniqueName] = nil;
	end
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:removeAllJoints()

	for k, v in pairs (self.loadedJoints) do		
		self:removeJointWithUniqueName(k)
	end
	
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:removeSpritesWithTag(tag)

	for k, v in pairs (self.loadedSprites) do
		if tag == v.tag then
				v.coronaSprite:removeSelf()
				self.loadedSprites[k] = nil
  		end
	end

end

function LevelHelperLoader:allSprites()
	return self.loadedSprites
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-------PRIVATE METHODS - THIS SHOULD NOT BE USED BY THE USER-----------
-----------------------------------------------------------------------
local helperX = 0
local helperY = 0
local helperWidth = 0
local helperHeight= 0
function rectHelper(a, b, c, d)
	helperX = tonumber(a)
	helperY = tonumber(b)
	helperWidth = tonumber(c)
	helperHeight= tonumber(d)
end
function sizeHelper(a, b)
	helperWidth = tonumber(a)
	helperHeight= tonumber(b)
end
function rectFromString(str)
	string.gsub(str, "{{(.*), (.*)}, {(.*), (.*)}}", rectHelper)
	uvRect = { origin = {x = helperX*retinaRatio, y = helperY*retinaRatio}, size = {width = helperWidth*retinaRatio, height = helperHeight*retinaRatio}}
	
	return uvRect
end
function sizeFromString(str)
	string.gsub(str, "{(.*), (.*)}", sizeHelper) 
	size = { width = helperWidth/retinaRatio, height = helperHeight/retinaRatio}
	return size				
end

function pointFromString(str)
	string.gsub(str, "{(.*), (.*)}", sizeHelper) 
	point = { x = helperWidth, y = helperHeight}
	return point
end

local LHimg = ""
local LHext = ""

function helpImgRetina(a, b)
	LHimg = a
	LHext = b
end

--[[
example of use: loader:imageSubFolder("images/")
--]]
function LevelHelperLoader:imageSubfolder(imgSubFolder)
	lh_imageSubFolder = imgSubFolder
end

function file_exists(name)

   local f=io.open(name,"r")
   if f~=nil then 
   		io.close(f) 
   		return true 
   	else 
   		return false 
   	end
   	
   	return false
end


function correctImageFile(str)

	local correctStr = str;
	
	local img = string.sub(str, 1, -5)
	local ext = string.sub(str, -3)
	
	if enableRetina then
		
		corrector = img .. "-hd" .. "." .. ext;
		
		correctStr = LHimg .. corrector  .. LHext
	end

	local correctFile = lh_imageSubFolder .. correctStr;
--[[
	if false == file_exists(correctFile) then
		correctFile = lh_imageSubFolder .. str	
		enableRetina = false
		retinaRatio = 1
		print("enters no retina")
	end
--]]
	return correctFile
end

function convertPointForRetina(x, y)

	if enableRetina then
			x = x*retinaRatio
			y = y*retinaRatio
	end
		
	return x, y
end

function LH_createSpriteInstance(lhSprite) -- sprite is a LevelHelperSprite
	
	local sprite = require("sprite")
	    
    local imageFile = correctImageFile(lhSprite["Image"])
    
    local uvRect = rectFromString(lhSprite["UV"])
    
    local sheetData = nil
    local spriteSet = nil
    local spriteInstance = nil


	if nil ~= string.find(lhSprite["AnimName"], " ") then
		sheetData = sheetForSprite( lhSprite["SHName"], 
								  	uvRect,
									sizeFromString(lhSprite["Size"]))

		local spriteSheet = sprite.newSpriteSheetFromData(	imageFile, 
															system.ResourceDirectory,
															sheetData )
														
														--startFrame --frameCount
		spriteSet = sprite.newSpriteSet(spriteSheet, 1, #sheetData.frames)
		
		local loop = 0;
		
		if lhSprite["AnimLoop"] then
		  		loop = 0
	  		else
		  		loop = lhSprite["AnimRepetitions"]
	  		end
	  	
		--AnimAtStart
		
		sprite.add(	spriteSet, 
				lhSprite["UniqueName"], 
				1, #sheetData.frames, lhSprite["AnimSpeed"]*3000, loop)
							
		spriteInstance = sprite.newSprite( spriteSet )						
		spriteInstance:prepare(lhSprite["UniqueName"])					
	else
								
		local setsInfo = {}
		local animSetsFramesInfo = {}
		
		for i =1, #LHGlobalAnims do
			local anim = LHGlobalAnims[i] 
			
	  		local uniqueAnimName = anim["UniqueName"]
	  		
		   	local image = anim["Image"]
    		--local repetitions = anim["Repetitions"]
    		local animSpeed = anim["Speed"]
        
	   	 	sheetData = LH_sheetForLHAnim(anim, sizeFromString(lhSprite["Size"]))
	   	 		
	   	 	local spriteSheet = sprite.newSpriteSheetFromData(	correctImageFile(image), 
																system.ResourceDirectory,
																sheetData )
			local framesInfo = {};
			for j = 1, #sheetData.frames do
				framesInfo[#framesInfo+1] = j
			end
			setsInfo[#setsInfo+1] = {sheet = spriteSheet, frames = framesInfo}
			
			animSetsFramesInfo[#animSetsFramesInfo+1] = {noOfFrames = #sheetData.frames, animName = uniqueAnimName}
		end									
			--spriteSet = sprite.newSpriteMultiSet({{sheet = spriteSheet, frames = {1, 2, 3}}})
		spriteSet = sprite.newSpriteMultiSet(setsInfo)     -- 1, #sheetData.frames)
		
		local curFrame = 1
		for i = 1, #animSetsFramesInfo do
		
			local loop = 0;
			if lhSprite["AnimLoop"] then
		  		loop = 0
	  		else
		  		loop = lhSprite["AnimRepetitions"]
	  		end
	  		
			sprite.add(	spriteSet, 
						animSetsFramesInfo[i].animName,-- uniqueAnimName, 
						curFrame, 
						animSetsFramesInfo[i].noOfFrames, --#sheetData.frames, 
						lhSprite["AnimSpeed"]*3000, 
						loop)
						
			print(lhSprite["AnimSpeed"])
			curFrame = curFrame + animSetsFramesInfo[i].noOfFrames;
						
		end
		
		spriteInstance = sprite.newSprite( spriteSet )						
		spriteInstance:prepare(lhSprite["AnimName"])
	end
	
	spriteInstance:setReferencePoint(display.CenterReferencePoint)
	local point = pointFromString(lhSprite["Position"])
	if LHGroup ~= nil then
		LHGroup:insert(spriteInstance)
	end
	
    if convertLevel then
        point.x = point.x * convertRatio.x;
        point.y = point.y * convertRatio.y;
    end    
    
	spriteInstance.x = point.x
	spriteInstance.y = point.y
	
	--this part is for physic objects
	local scale = sizeFromString(lhSprite["Scale"])
	
	if convertLevel then
        scale.width = scale.width * convertRatio.x;
        scale.height = scale.height * convertRatio.y;
    end
	
	spriteInstance.width = spriteInstance.width * scale.width*1.0
	spriteInstance.height = spriteInstance.height * scale.height*1.0
	--this part is for display of the objects
	
	spriteInstance.xScale = scale.width*1.0
	spriteInstance.yScale = scale.height*1.0

	spriteInstance.rotation = lhSprite["Angle"]
	spriteInstance.alpha = lhSprite["Opacity"]
--	spriteInstance:prepare( lhSprite["SHName"] )
	
	--local color = rectFromString(lhSprite["Color"])
	-- property not supported - only for vector objects
	--spriteInstance:setFillColor(color.origin.x*255,color.origin.y*255,color.size.width*255)

	
	
    if lhSprite["AnimAtStart"]  then															
		spriteInstance:play()
	end	

	spriteInstance.numberOfFrames = #sheetData.frames
	spriteInstance.uniqueName = lhSprite["UniqueName"]
	spriteInstance.tag = lhSprite["Tag"];
	
	return spriteInstance
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function deepcopy(object)
    local lookup_table = {}
    local function _copy(object)
        if type(object) ~= "table" then
            return object
        elseif lookup_table[object] then
            return lookup_table[object]
        end
        local new_table = {}
        lookup_table[object] = new_table
        for index, value in pairs(object) do
            new_table[_copy(index)] = _copy(value)
        end
        return setmetatable(new_table, getmetatable(object))
    end
    return _copy(object)
end

function getPolygonPointsFromStrings(fixtures, scale, sdensity, sfriction, srestitution, scollisionFilter)
-- for CORONA points must be inverse so multiply y by -1 and then inverse the points order
	local finalBodyShape = {}
	local currentFixInfo;
	local currentShapeRevised = {}
	local currentShape = {}
	
	for i = 1, #fixtures do
		local currentFix = fixtures[i]
			
		for j = 1, #currentFix do
			local point = pointFromString(currentFix[j])
			currentShape[#currentShape+1] = point.x
			currentShape[#currentShape+1] = point.y
		end
		
		currentFix = nil;
		
		for k = #currentShape,1,-2 do
			currentShape[k-1] = currentShape[k-1]*scale.width
			currentShape[k] = currentShape[k]*(-1)*scale.height
		end	

		for l = #currentShape,1,-2 do
			currentShapeRevised[#currentShapeRevised + 1] = currentShape[l-1]*retinaRatio;
			currentShapeRevised[#currentShapeRevised + 1] = currentShape[l]*retinaRatio;
		end	
		
		currentFixInfo = { density = sdensity,
						   friction = sfriction,
						   bounce = srestitution,
						   shape = deepcopy(currentShapeRevised),
						   filter = scollisionFilter
								 }
		currentShape = nil
		currentShape = {}
		currentShapeRevised = nil
		currentShapeRevised = {}
		finalBodyShape[#finalBodyShape+1] = currentFixInfo;
	end


	return finalBodyShape
end

function lh_createObjectInstance(lhSprite, physics)

	local sprite = LH_createSpriteInstance(lhSprite)

	local fixtures = lhSprite["ShapeFixtures"]

	local physicType = "static"
	if lhSprite["Type"] == 1 then
		physicType = "kinematic"
	elseif lhSprite["Type"] == 2 then
		physicType = "dynamic"
	end
		
	local scale = sizeFromString(lhSprite["Scale"])
	local border = pointFromString(lhSprite["ShapeBorder"])
	
	if convertLevel then
        scale.width = scale.width * convertRatio.x;
        scale.height = scale.height * convertRatio.y;
    end
	
	local collisionFilter = { 	categoryBits = lhSprite["Category"], 
								maskBits = lhSprite["Mask"], 
								groupIndex = lhSprite["Group"] } 

	if nil == fixtures then
		-- sprite does not have polygon points
		-- check if its circle if not make it rectangle
		local size = sizeFromString(lhSprite["Size"])
		
		if enableRetina then
			size.width = 2*size.width
			size.height= 2*size.height
		end
		local sizeW = (size.width-border.x/2)*scale.width;
		local sizeH = (size.height-border.y/2)*scale.height;	

		
		if enableRetina then
				sizeW = sizeW*retinaRatio
				sizeH = sizeH*retinaRatio
		end
		
		if false == lhSprite["IsCircle"] then
			-- object is not circle
			physics.addBody(sprite, 
							physicType,
							{ density = lhSprite["Density"],
							  friction= lhSprite["Friction"],
							  bounce   = lhSprite["Restitution"],
							  filter = collisionFilter,
							  shape = deepcopy(LH_getQuad(sizeW, sizeH))})
		else
			-- object is circle
			
			local radiusSize = (size.width-border.x/2)/2*scale.width;
			
			if enableRetina then
				radiusSize = radiusSize*retinaRatio
			end
			
			physics.addBody( sprite, 
							physicType,
							{ 	density = lhSprite["Density"], 
								friction = lhSprite["Friction"], 
								bounce = lhSprite["Restitution"], 
								radius = radiusSize, --radiusSize,
								filter = collisionFilter
							} )
		end
	else	
	
		physics.addBody( sprite, 
						 physicType,
						unpack(getPolygonPointsFromStrings(fixtures, 
						 							 scale, 
						 							  lhSprite["Density"],
						 							  lhSprite["Friction"], 
						 							  lhSprite["Restitution"],
						 							  collisionFilter))
						 	)
	end
		
	sprite.isFixedRotation = lhSprite["FixedRot"]
	sprite.isSensor = lhSprite["IsSenzor"]
	
	return sprite
end

function LH_getQuad(width, height)

    pos = { x = 0, y = 0 } 
    
	local quad = { pos.x - width/2, 
			 	   pos.y + height/2,
			 
             	   pos.x - width/2,
             	   pos.y - height/2,
        
	               pos.x + width/2,
      		       pos.y - height/2,
             
            	   pos.x + width/2,
             	   pos.y + height/2}
 
	return quad
 
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
function LevelHelperLoader:createJoint(physics, lhJoint)

	local objA = self.loadedSprites[lhJoint["ObjectA"]].coronaSprite;
	local objB = self.loadedSprites[lhJoint["ObjectB"]].coronaSprite;
	
	if objA == nil then
		return nil
	end
	
	if objB == nil then
		return nil
	end
	
	if objA == objB then
		print("ObjectA equal ObjectB in joint creation - Box2D will assert.")
		return nil
	end
	
	local anchorA = pointFromString(lhJoint["AnchorA"])
	local anchorB = pointFromString(lhJoint["AnchorB"])
	
	if true == lhJoint["CenterOfMass"] then
	print("Center of mass")
		anchorA.x = 0
		anchorB.x = 0
		anchorA.y = 0
		anchorB.y = 0
	end

	local myJoint = nil
	if lhJoint["Type"] == 0 then -- distance joint	

		 myJoint = physics.newJoint( "distance", 
										objA, 
										objB, 
										objA.x +anchorA.x,
										objA.y +anchorA.y,
										objB.x +anchorB.x,
										objB.y +anchorB.y)
		myJoint.frequency = lhJoint["Frequency"]
		myJoint.dampingRatio = lhJoint["Damping"]
		
	elseif lhJoint["Type"] == 1 then -- revolute joint
			
		myJoint = physics.newJoint( "pivot", objA, objB, objA.x +anchorA.x, objA.y +anchorA.y)
		
		myJoint.isMotorEnabled = lhJoint["EnableMotor"]
		myJoint.motorSpeed = (-1)*lhJoint["MotorSpeed"] --for CORONA we inverse to be the same as 
														--as the other engines from left to right
		myJoint.maxMotorTorque = lhJoint["MaxTorque"]
		
		myJoint.isLimitEnabled = lhJoint["EnableLimit"]
		myJoint:setRotationLimits( lhJoint["LowerAngle"], lhJoint["UpperAngle"] )

	else
		print("Unknown joint type in LevelHelper file.")
	end
	
	return myJoint
end
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function sheetForSprite(name, uvRect, size)

local sheet = { 
frames = {
			{
				name = name,
				spriteColorRect = { x = uvRect.origin.x, 
									y = uvRect.origin.y, 
									width = uvRect.size.width, 
									height = uvRect.size.height }, 
				textureRect = { x = uvRect.origin.x, 
								y = uvRect.origin.y, 
								width = uvRect.size.width, 
								height = uvRect.size.height }, 
				spriteSourceSize = { width = size.width, 
									 height= size.height}, 
				spriteTrimmed = false,
				textureRotated = false
			},
		}
	}

	return sheet
end

function LH_sheetForLHAnim(anim, size)

	local sheet = { frames = {} };

	local frames = anim["Frames"]
	for j = 1, #frames do
				
		local curFrame = frames[j]
				
		local uvRect = rectFromString(curFrame["FrameRect"])
		local frameName = curFrame["SpriteName"]	
					
		sheet.frames[#sheet.frames +1] = 
		{
			name = frameName,
			spriteColorRect = { x = uvRect.origin.x, 
								y = uvRect.origin.y, 
								width = uvRect.size.width, 
								height = uvRect.size.height }, 
			textureRect = { x = uvRect.origin.x, 
							y = uvRect.origin.y, 
							width = uvRect.size.width, 
							height = uvRect.size.height }, 
			spriteSourceSize = { width = size.width, 
								 height= size.height}, 
			spriteTrimmed = false,
			textureRotated = false
		}
	end		
	return sheet
end

function LH_animSheetForSprite(lhSprite, size)

   	local sprAnimUniqueName = lhSprite["AnimName"]
	local loop = lhSprite["AnimLoop"]
  	local animSpeed = lhSprite["AnimSpeed"]
	local repetitions = lhSprite["AnimRepetitions"]
			
	for i =1, #LHGlobalAnims do
		local anim = LHGlobalAnims[i] 
	  	local uniqueAnimName = anim["UniqueName"]
        
    	if nil ~= string.find(uniqueAnimName, sprAnimUniqueName) then
	   	 	return LH_sheetForLHAnim(anim, size)
		end
    end
    
	return nil
end



-----------------------------------------------------------------------
-----------------------------------------------------------------------
-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
local lh_currentSpriteInfo = {}
local lh_readSprites = false
--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
local lh_currentAnimInfo = {}
local lh_readAnims = false
----
local lh_currentAnimFramesInfo = {} --this will contain all frames 
local lh_currentFrameInfo = {} --info about the frame
local lh_readAnimFrames = false
--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
local currentBezierInfo = {}
local readBeziers = false
----
local currentBezierCurveInfo = {}
local currentCurveInfo = {}
local readBezierCurves = false;
--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

-->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
local currentParallaxInfo = {}
local readParallax = false
---
local currentParallaxSpritesInfo = {}
local currentParallaxSprInfo = {}
local readParallaxSprites = false
--<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


--local currentJoint = 0
local currentJointInfo = {}
local readJoints = false

--local current

--local currentFixture = 0
local lh_currentPolygonInfo = {}
local lh_currentFixtureInfo = {}
--local currentFixturePoint = 0
local lh_readFixture = false

local readSafeFrame = false
local lh_safeFrame = ""

local wbInfo = {}
local readWB = false

local readGravity = false
local gravityInfo = nil

local readGameWorldSize = false
local gameWorldSizeInfo = nil

local lh_currentKey;

local lh_dict = 0
local lh_array = 0

------------------------------------------------------------------------


function lh_key(arg)
	lh_currentKey = arg
--	print("KEY ")
--	print(arg)
	
	if nil ~= string.find(arg, "ANIMS_INFO") then
		lh_readAnims = true;
	end

	if nil ~= string.find(arg, "BEZIER_INFO") then
		readBeziers = true;
	end
		
	if nil ~= string.find(arg, "JOINTS_INFO") then
		readJoints = true
	end
	
	if nil ~= string.find(arg, "PARALLAX_INFO") then
		readParallax = true
	end

	if nil ~= string.find(arg, "SPRITES_INFO") then
		lh_readSprites = true
	end
	
	if nil ~= string.find(arg, "GameWorld") then
		readGameWorldSize = true
	end

	--if nil ~= string.find(arg,  "GeneralProperties") then
		--currentSprite = currentSprite + 1
	--end
	
	if nil ~= string.find(arg, "WBInfo") then
		readWB = true
	end
	
	if nil ~= string.find(arg, "Frames") then
		if lh_readAnims then
			lh_readAnimFrames = true
			lh_readAnims = false
		end
	end

	if nil ~= string.find(arg, "Curves") then
		if readBeziers then
			readBezierCurves = true
			readBeziers = false
		end
	end
	
	if nil ~= string.find(arg, "Sprites") then
		if readParallax then
			readParallaxSprites = true
			readParallax = false
		end
	end

	if nil ~= string.find(arg, "Gravity") then
		readGravity = true;
	end
	
	
	
	if nil ~= string.find(arg, "ShapeFixtures") then
		lh_readFixture = true
	end
	
	if nil ~= string.find(arg, "SafeFrame") then
		readSafeFrame = true
	end

end

function lh_stringValue(arg)
	lh_pushValue(arg)
end

function lh_emptyStringValue(arg)
	lh_pushValue(" ")
end
function lh_numberValue(arg)
	lh_pushValue(tonumber(arg))
end

function lh_boolValue(arg)
	lh_pushValue(arg)
end

function lh_pushValue(arg)
--	print("CURRENT KEY")
--	print(lh_currentKey)
--	print("VALUE")
--	print(arg)
	
	if lh_readAnims then
		lh_currentAnimInfo[lh_currentKey] = arg
	end

	if readBeziers then
		currentBezierInfo[lh_currentKey] = arg
	end
	
	if readParallax then
		currentParallaxInfo[lh_currentKey] = arg
	end
	
	if lh_readSprites then
		lh_currentSpriteInfo[lh_currentKey] = arg
	end
	
	if readJoints then
		currentJointInfo[lh_currentKey] = arg
	end
	
	if readWB then
		wbInfo[lh_currentKey] = arg
	end
	
	if lh_readAnimFrames then
		lh_currentFrameInfo[lh_currentKey] = arg
	end
	
	if readBezierCurves then
		currentCurveInfo[lh_currentKey] = arg
	end
	
	if readParallaxSprites then
		currentParallaxSprInfo[lh_currentKey] = arg
	end
	
	if lh_readFixture then
		lh_currentFixtureInfo[#lh_currentFixtureInfo+1] = arg
	end
	
	if readGravity then
		gravityInfo = pointFromString(arg)
		readGravity = false
	end
	
	if readGameWorldSize then
		gameWorldSizeInfo = rectFromString(arg)
		readGameWorldSize = false
	end
	
	if readSafeFrame then
		lh_safeFrame = arg;
		readSafeFrame = false;
	end
end

function lh_arrayBegin(arg)
	lh_array = lh_array+1
	
--	print("lh_array begin")
--	print(lh_array)
end

function lh_noArray(arg)

	lh_readFixture = false	
	lh_readAnimFrames = false
	readBezierCurves = false
	readParallaxSprites = false
	
	--if lh_readAnims then
		lh_readAnims = false
	--end
	
	--if readBeziers then
		readBeziers = false
	--end
	
	--if readParalax then
		readParallax = false
	--end
	
	--if readJoints then
		readJoints = false
	--end
	
end


function lh_arrayEnd(arg)
	lh_array = lh_array-1

	if lh_array == 0 then
		--if lh_readAnims then
			lh_readAnims = false
		--end
		
		--if readBeziers then
			readBeziers = false
		--end
		
		--if readParallax then
			readParallax = false
		--end
		
		--if lh_readSprites then
			lh_readSprites = false
		--end
		
		--if readJoints then
			readJoints = false
		--end
	end
		
	if lh_array == 2 then
		if lh_readFixture then
			lh_currentPolygonInfo[#lh_currentPolygonInfo+1] = deepcopy(lh_currentFixtureInfo)
			lh_currentFixtureInfo = nil;
			lh_currentFixtureInfo = {}
		end
	end
	
	if lh_array == 1 then
			
		if lh_readAnimFrames then
			lh_currentAnimInfo["Frames"] = deepcopy(lh_currentAnimFramesInfo)
			lh_readAnims = true
			lh_readAnimFrames= false
				
			lh_currentAnimFramesInfo = nil
			lh_currentAnimFramesInfo = {}
		end

		if readBezierCurves then
			currentBezierInfo["Curves"] = deepcopy(currentBezierCurveInfo)
			readBeziers = true
			readBezierCurves= false
				
			currentBezierCurveInfo = nil
			currentBezierCurveInfo = {}
		end

		if readParallaxSprites then
			currentParallaxInfo["Sprites"] = deepcopy(currentParallaxSpritesInfo)
			readParallax = true
			readParallaxSprites= false
				
			currentParallaxSpritesInfo = nil
			currentParallaxSpritesInfo = {}
		end

			
		if lh_readFixture then
			lh_currentSpriteInfo["ShapeFixtures"] = deepcopy(lh_currentPolygonInfo)
			lh_readFixture = false
			--currentFixture = 0
			lh_currentPolygonInfo = nil
			lh_currentPolygonInfo = {}
		end
	end
end

function lh_dictBegin(arg)
	lh_dict = lh_dict+1
--	print("lh_dict VALUE")
--	print(lh_dict)
 
	--if lh_dict == 2 then
	--	if lh_readAnims then
	--		currentAnim = currentAnim + 1
	--	end
	--	if readJoints then
--			print("PUSH new joint")
	--		currentJoint = currentJoint + 1
	--	end
	--end
end
function  LevelHelperLoader:dictEnd()
	lh_dict = lh_dict-1
--	print("lh_dict VALUE")
--	print(lh_dict)
	if lh_dict == 1 then
	
		if lh_readAnims then
			self.LHAnims[#self.LHAnims+1] = deepcopy(lh_currentAnimInfo)

			lh_currentAnimInfo = nil
			lh_currentAnimInfo = {}
		end
		
		if readBeziers then
			self.LHBeziers[#self.LHBeziers+1] = deepcopy(currentBezierInfo)
			currentBezierInfo = nil
			currentBezierInfo = {}
		end

		if readParallax then
			self.LHParallax[#self.LHParallax+1] = deepcopy(currentParallaxInfo)
			currentParallaxInfo = nil
			currentParallaxInfo = {}
		end
		
		if lh_readSprites then
			self.LHSprites[#self.LHSprites+1] = deepcopy(lh_currentSpriteInfo)

			lh_currentSpriteInfo = nil
			lh_currentSpriteInfo = {}
		end
		
		if readWB then
--			print("end wb")
			self.LHWbInfo[#self.LHWbInfo+1] = deepcopy(wbInfo)
			wbInfo = nil
			wbInfo = {}
			readWB = false
		end
		
		if readJoints then
			--print("pushing the newly created joint")
			self.LHJoints[#self.LHJoints+1] = deepcopy(currentJointInfo)
		end
	end
	
	if lh_dict == 2 then	
		if lh_readAnimFrames then
			lh_currentAnimFramesInfo[#lh_currentAnimFramesInfo+1] = deepcopy(lh_currentFrameInfo)
			lh_currentFrameInfo = nil
			lh_currentFrameInfo = {}
		end
		
		if readBezierCurves then
			currentBezierCurveInfo[#currentBezierCurveInfo+1] = deepcopy(currentCurveInfo)
			currentCurveInfo = nil
			currentCurveInfo = {}
		end
		
		if readParallaxSprites then
			currentParallaxSpritesInfo[#currentParallaxSpritesInfo+1] = deepcopy(currentParallaxSprInfo)
			currentParallaxSprInfo = nil
			currentParallaxSprInfo = {}
		end
	end
end

function LevelHelperLoader:loadLevelHelperSceneFile(levelFile, resourceDirectory)

	local path = system.pathForFile(levelFile, resourceDirectory)

	local file = io.open(path, "r")
 
 	-- Determine if file exists
	if file then
   		
   		for line in file:lines() do
   		--print(line)
			string.gsub(line, "<key>(.*)</key>", lh_key)
			string.gsub(line, "<string>(.*)</string>", lh_stringValue)
			string.gsub(line, "<string></string>", lh_emptyStringValue)
			string.gsub(line, "<real>(.*)</real>", lh_numberValue)
			string.gsub(line, "<integer>(.*)</integer>", lh_numberValue)
	
			if nil ~= string.find(line, "<true/>") then
				lh_boolValue(true)
			end
			if nil ~= string.find(line, "<false/>") then
				lh_boolValue(false)
			end
	
			string.gsub(line, "<dict>", lh_dictBegin)
			
			-- Tiger1:classname()
			-- classname = function(self) return(self.class.name) end}
		--	string.gsub(line, "</dict>", self:dictEnd())

			if nil ~= string.find(line, "</dict>") then
				self:dictEnd()
			end

			string.gsub(line, "<array>", lh_arrayBegin)
			string.gsub(line, "</array>", lh_arrayEnd)
			string.gsub(line, "<array/>", lh_noArray)
		end
    	
   		io.close (file)
	else
    	print( "Level file not found. Please add your level in the project directory." )
	end

	--self.worldBoundaries = rectFromString(wb)

	self.LHGravityInfo = gravityInfo

	self.LHGameWorldSize = gameWorldSizeInfo

	if convertLevel then
	   	local point = pointFromString(lh_safeFrame)
		local winSize = {width = display.contentWidth, height = display.contentHeight}
		
        convertRatio.x = winSize.width/point.x;
        convertRatio.y = winSize.height/point.y;
	end

	currentSprite = 0
	lh_currentSpriteInfo = {}
	lh_readSprites = false
	currentJoint = 0
	currentJointInfo = {}
	readJoints = false

	currentAnim = 0;
	lh_currentAnimInfo = {}
	lh_readAnims = false

	currentBezier = 0;
	currentBezierInfo = {}
	readBeziers = false

	currentParallax = 0;
	currentParallaxInfo = {}
	readParallax = false

	currentFixture = 0
	lh_currentPolygonInfo = {}
	lh_currentFixtureInfo = {}
	currentFixturePoint = 0
	lh_readFixture = false

	--wb = ""
	readWB = false
	lh_currentKey = "";
	lh_dict = 0
	lh_array = 0



 --For debuging
 --[[
 	for i = 1, #self.LHAnims do
	print("-----------------------------------------------------------------------")
	print("ANIM INFO")
	print("-----------------------------------------------------------------------")
		for k, v in pairs (self.LHAnims[i]) do
			print(k)
			print(v)
			if nil ~= string.find(k, "Frames") then
			print("------------------------")
				for fk, fv in pairs (v) do
					for ffk, ffv in pairs (fv) do
						print(ffk)
						print(ffv)
					end
				end	
			print("------------------------")
			end
		end
	end
	
	print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
 	
 	for i = 1, #self.LHBeziers do
	print("-----------------------------------------------------------------------")
	print("BEZIER INFO")
	print("-----------------------------------------------------------------------")
		for k, v in pairs (self.LHBeziers[i]) do
			print(k)
			print(v)
			if nil ~= string.find(k, "Curves") then
			print("------------------------")
				for fk, fv in pairs (v) do
					print("-->>>>")
					for ffk, ffv in pairs (fv) do
						print(ffk)
						print(ffv)
					end
				end	
			print("------------------------")
			end
		end
	end

	print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")
	
	
	for i = 1, #self.LHParallax do
	print("-----------------------------------------------------------------------")
	print("PARALLAX INFO")
	print("-----------------------------------------------------------------------")
		for k, v in pairs (self.LHParallax[i]) do
			print(k)
			print(v)
			if nil ~= string.find(k, "Sprites") then
			print("------------------------")
				for fk, fv in pairs (v) do
					print("-->>>>")
					for ffk, ffv in pairs (fv) do
						print(ffk)
						print(ffv)
					end
				end	
			print("------------------------")
			end
		end
	end

	print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

	for i = 1, #self.LHJoints do
	print("-----------------------------------------------------------------------")
	print("JOINT INFO")
	print("-----------------------------------------------------------------------")
		for k, v in pairs (self.LHJoints[i]) do
			print(k)
			print(v)
		end
	end

	print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

	for i = 1, #self.LHSprites do
	print("-----------------------------------------------------------------------")
	print("SPRITE INFO")
	print("-----------------------------------------------------------------------")
		for k, v in pairs (self.LHSprites[i]) do
			print(k)
			print(v)
		end
	end
	
	print("XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX")

	for i = 1, #self.LHWbInfo do
	print("-----------------------------------------------------------------------")
	print("WB INFO")
	print("-----------------------------------------------------------------------")
		for k, v in pairs (self.LHWbInfo[i]) do
			print(k)
			print(v)
		end
	end
	--]]	
	--print("WORLD_BOUNDARIES")
	--print(worldBoundaries)		
end





















